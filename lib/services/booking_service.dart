import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_group.dart';
import '../models/chat_message.dart';
import '../models/formation.dart';
import '../models/user_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new booking group
  Future<String> createBookingGroup(BookingGroup group) async {
    try {
      String groupId = _uuid.v4();
      BookingGroup newGroup = group.copyWith(id: groupId);

      await _firestore
          .collection('groups')
          .doc(groupId)
          .set(newGroup.toFirestore());

      // Create initial formation document
      Formation initialFormation = Formation(
        id: groupId,
        groupId: groupId,
        lastUpdated: DateTime.now(),
        lastUpdatedBy: group.adminId,
      );

      await _firestore
          .collection('formations')
          .doc(groupId)
          .set(initialFormation.toFirestore());

      // Send system message
      await sendSystemMessage(
        groupId,
        'Match created! Start inviting players.',
        group.adminId,
      );

      return groupId;
    } catch (e) {
      throw Exception('Failed to create booking group: $e');
    }
  }

  // Get user's booking groups
  Stream<List<BookingGroup>> getUserBookingGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .where('endTime', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingGroup.fromFirestore(doc))
          .where((group) =>
              group.adminId == userId ||
              group.opponentAdminId == userId ||
              group.playerIds.contains(userId))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    });
  }

  // Invite player to group
  Future<void> invitePlayerToGroup(
    String groupId,
    String playerId,
    String inviterName,
  ) async {
    try {
      // Check if player is already invited or in the group
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();
      BookingGroup group = BookingGroup.fromFirestore(groupDoc);

      if (group.playerIds.contains(playerId) ||
          group.invitedPlayerIds.contains(playerId)) {
        throw Exception('Player is already invited or in the group');
      }

      // Check if player is active
      DocumentSnapshot playerDoc =
          await _firestore.collection('users').doc(playerId).get();
      UserModel player = UserModel.fromFirestore(playerDoc);

      if (!player.isActive) {
        throw Exception('Player is currently unavailable');
      }

      // Add to invited players list
      await _firestore.collection('groups').doc(groupId).update({
        'invitedPlayerIds': FieldValue.arrayUnion([playerId])
      });

      // Send system message
      await sendSystemMessage(
        groupId,
        '$inviterName invited ${player.displayName} to the match',
        group.adminId,
      );

      // TODO: Send push notification to player
    } catch (e) {
      throw Exception('Failed to invite player: $e');
    }
  }

  // Accept group invitation
  Future<void> acceptGroupInvitation(String groupId, String playerId) async {
    try {
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();
      BookingGroup group = BookingGroup.fromFirestore(groupDoc);

      // Check if group has space
      int maxPlayers = group.isDuelAdmins
          ? group.maxPlayersPerTeam * 2
          : group.maxPlayersPerTeam;

      if (group.playerIds.length >= maxPlayers) {
        throw Exception('Group is full');
      }

      // Get player info
      DocumentSnapshot playerDoc =
          await _firestore.collection('users').doc(playerId).get();
      UserModel player = UserModel.fromFirestore(playerDoc);

      WriteBatch batch = _firestore.batch();

      // Move from invited to players list
      batch.update(_firestore.collection('groups').doc(groupId), {
        'invitedPlayerIds': FieldValue.arrayRemove([playerId]),
        'playerIds': FieldValue.arrayUnion([playerId]),
      });

      await batch.commit();

      // Send system message
      await sendSystemMessage(
        groupId,
        '${player.displayName} joined the match! ⚽',
        playerId,
      );
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  // Decline group invitation
  Future<void> declineGroupInvitation(String groupId, String playerId) async {
    try {
      DocumentSnapshot playerDoc =
          await _firestore.collection('users').doc(playerId).get();
      UserModel player = UserModel.fromFirestore(playerDoc);

      // Remove from invited players list
      await _firestore.collection('groups').doc(groupId).update({
        'invitedPlayerIds': FieldValue.arrayRemove([playerId])
      });

      // Send system message
      await sendSystemMessage(
        groupId,
        '${player.displayName} declined the invitation',
        playerId,
      );
    } catch (e) {
      throw Exception('Failed to decline invitation: $e');
    }
  }

  // Set opponent admin for duel admins booking
  Future<void> setOpponentAdmin(
    String groupId,
    String opponentAdminId,
    String inviterName,
  ) async {
    try {
      // Get opponent admin info
      DocumentSnapshot opponentDoc =
          await _firestore.collection('users').doc(opponentAdminId).get();
      UserModel opponent = UserModel.fromFirestore(opponentDoc);

      if (!opponent.isActive) {
        throw Exception('User is currently unavailable');
      }

      await _firestore.collection('groups').doc(groupId).update({
        'opponentAdminId': opponentAdminId,
        'invitedPlayerIds': FieldValue.arrayUnion([opponentAdminId])
      });

      // Send system message
      await sendSystemMessage(
        groupId,
        '$inviterName invited ${opponent.displayName} as opponent team captain',
        opponentAdminId,
      );
    } catch (e) {
      throw Exception('Failed to set opponent admin: $e');
    }
  }

  // Assign player to team (for duel admins)
  Future<void> assignPlayerToTeam(
    String groupId,
    String playerId,
    bool isTeamA,
    String adminId,
  ) async {
    try {
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();
      BookingGroup group = BookingGroup.fromFirestore(groupDoc);

      if (!group.isDuelAdmins) {
        throw Exception('This is not a duel admins match');
      }

      // Check if admin can assign to this team
      bool canAssign = (isTeamA && group.adminId == adminId) ||
          (!isTeamA && group.opponentAdminId == adminId);

      if (!canAssign) {
        throw Exception('You can only assign players to your own team');
      }

      List<String> targetTeam = isTeamA ? group.teamAPlayerIds : group.teamBPlayerIds;
      List<String> otherTeam = isTeamA ? group.teamBPlayerIds : group.teamAPlayerIds;

      // Check team capacity
      if (targetTeam.length >= group.maxPlayersPerTeam) {
        throw Exception('Team is full');
      }

      // Remove from other team if assigned
      List<String> updatedOtherTeam = List.from(otherTeam)..remove(playerId);
      List<String> updatedTargetTeam = List.from(targetTeam);
      
      if (!updatedTargetTeam.contains(playerId)) {
        updatedTargetTeam.add(playerId);
      }

      Map<String, dynamic> updates = {};
      if (isTeamA) {
        updates['teamAPlayerIds'] = updatedTargetTeam;
        updates['teamBPlayerIds'] = updatedOtherTeam;
      } else {
        updates['teamBPlayerIds'] = updatedTargetTeam;
        updates['teamAPlayerIds'] = updatedOtherTeam;
      }

      await _firestore.collection('groups').doc(groupId).update(updates);
    } catch (e) {
      throw Exception('Failed to assign player to team: $e');
    }
  }

  // Send chat message
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _firestore
          .collection('groups')
          .doc(message.groupId)
          .collection('messages')
          .add(message.toFirestore());
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Send system message
  Future<void> sendSystemMessage(
    String groupId,
    String content,
    String senderId,
  ) async {
    try {
      ChatMessage systemMessage = ChatMessage(
        id: '',
        groupId: groupId,
        senderId: senderId,
        senderName: 'System',
        content: content,
        type: MessageType.system,
        timestamp: DateTime.now(),
      );

      await sendMessage(systemMessage);
    } catch (e) {
      throw Exception('Failed to send system message: $e');
    }
  }

  // Get chat messages
  Stream<List<ChatMessage>> getChatMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Update formation
  Future<void> updateFormation(Formation formation) async {
    try {
      await _firestore
          .collection('formations')
          .doc(formation.groupId)
          .set(formation.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update formation: $e');
    }
  }

  // Get formation
  Stream<Formation?> getFormation(String groupId) {
    return _firestore
        .collection('formations')
        .doc(groupId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Formation.fromFirestore(doc);
      }
      return null;
    });
  }

  // Leave group
  Future<void> leaveGroup(String groupId, String playerId) async {
    try {
      DocumentSnapshot playerDoc =
          await _firestore.collection('users').doc(playerId).get();
      UserModel player = UserModel.fromFirestore(playerDoc);

      // Remove from all player lists
      Map<String, dynamic> updates = {
        'playerIds': FieldValue.arrayRemove([playerId]),
        'teamAPlayerIds': FieldValue.arrayRemove([playerId]),
        'teamBPlayerIds': FieldValue.arrayRemove([playerId]),
      };

      await _firestore.collection('groups').doc(groupId).update(updates);

      // Send system message
      await sendSystemMessage(
        groupId,
        '${player.displayName} left the match',
        playerId,
      );
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  // Delete expired groups (to be called by Cloud Function)
  Future<void> deleteExpiredGroups() async {
    try {
      QuerySnapshot expiredGroups = await _firestore
          .collection('groups')
          .where('endTime', isLessThan: Timestamp.now())
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in expiredGroups.docs) {
        // Delete group document
        batch.delete(doc.reference);

        // Delete formation document
        batch.delete(_firestore.collection('formations').doc(doc.id));

        // Delete messages subcollection (Note: In production, use a Cloud Function for this)
        QuerySnapshot messages = await _firestore
            .collection('groups')
            .doc(doc.id)
            .collection('messages')
            .get();

        for (QueryDocumentSnapshot messageDoc in messages.docs) {
          batch.delete(messageDoc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete expired groups: $e');
    }
  }
}
