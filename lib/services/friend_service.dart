import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/friend_request.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users by username or ID
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      query = query.toLowerCase().trim();
      
      // Search by username
      QuerySnapshot usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      // Search by ID
      QuerySnapshot idQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isEqualTo: query)
          .limit(1)
          .get();

      Set<String> userIds = {};
      List<UserModel> users = [];

      // Add users from username search
      for (QueryDocumentSnapshot doc in usernameQuery.docs) {
        if (!userIds.contains(doc.id)) {
          userIds.add(doc.id);
          users.add(UserModel.fromFirestore(doc));
        }
      }

      // Add users from ID search
      for (QueryDocumentSnapshot doc in idQuery.docs) {
        if (!userIds.contains(doc.id)) {
          userIds.add(doc.id);
          users.add(UserModel.fromFirestore(doc));
        }
      }

      return users;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // Send friend request
  Future<void> sendFriendRequest(String currentUserId, String targetUserId, String currentUserName, String? currentUserPhotoUrl) async {
    try {
      // Check if they're already friends
      DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      UserModel currentUser = UserModel.fromFirestore(currentUserDoc);
      
      if (currentUser.friendIds.contains(targetUserId)) {
        throw Exception('You are already friends with this user');
      }

      if (currentUser.sentFriendRequests.contains(targetUserId)) {
        throw Exception('Friend request already sent');
      }

      // Create friend request
      String requestId = _firestore.collection('friendRequests').doc().id;
      FriendRequest request = FriendRequest(
        id: requestId,
        senderId: currentUserId,
        receiverId: targetUserId,
        senderName: currentUserName,
        senderPhotoUrl: currentUserPhotoUrl,
        sentAt: DateTime.now(),
        status: FriendRequestStatus.pending,
      );

      // Start batch write
      WriteBatch batch = _firestore.batch();

      // Add friend request document
      batch.set(_firestore.collection('friendRequests').doc(requestId), request.toMap());

      // Update sender's sent requests
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'sentFriendRequests': FieldValue.arrayUnion([targetUserId])
      });

      // Update receiver's pending requests
      batch.update(_firestore.collection('users').doc(targetUserId), {
        'pendingFriendRequests': FieldValue.arrayUnion([currentUserId])
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requestId, String senderId, String receiverId) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Update friend request status
      batch.update(_firestore.collection('friendRequests').doc(requestId), {
        'status': FriendRequestStatus.accepted.index
      });

      // Add each other as friends
      batch.update(_firestore.collection('users').doc(senderId), {
        'friendIds': FieldValue.arrayUnion([receiverId]),
        'sentFriendRequests': FieldValue.arrayRemove([receiverId])
      });

      batch.update(_firestore.collection('users').doc(receiverId), {
        'friendIds': FieldValue.arrayUnion([senderId]),
        'pendingFriendRequests': FieldValue.arrayRemove([senderId])
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  // Decline friend request
  Future<void> declineFriendRequest(String requestId, String senderId, String receiverId) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Update friend request status
      batch.update(_firestore.collection('friendRequests').doc(requestId), {
        'status': FriendRequestStatus.declined.index
      });

      // Remove from pending/sent lists
      batch.update(_firestore.collection('users').doc(senderId), {
        'sentFriendRequests': FieldValue.arrayRemove([receiverId])
      });

      batch.update(_firestore.collection('users').doc(receiverId), {
        'pendingFriendRequests': FieldValue.arrayRemove([senderId])
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }

  // Get pending friend requests
  Stream<List<FriendRequest>> getPendingFriendRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.index)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get friends list
  Future<List<UserModel>> getFriends(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    
    try {
      List<UserModel> friends = [];
      
      // Firestore 'in' query has a limit of 10, so we need to batch
      for (int i = 0; i < friendIds.length; i += 10) {
        int end = (i + 10 < friendIds.length) ? i + 10 : friendIds.length;
        List<String> batch = friendIds.sublist(i, end);
        
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
            
        friends.addAll(snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
      }
      
      return friends;
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  // Remove friend
  Future<void> removeFriend(String currentUserId, String friendId) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Remove from both users' friend lists
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friendIds': FieldValue.arrayRemove([friendId])
      });

      batch.update(_firestore.collection('users').doc(friendId), {
        'friendIds': FieldValue.arrayRemove([currentUserId])
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }
}
