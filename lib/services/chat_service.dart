import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName;
  String? get currentUserPhoto => _auth.currentUser?.photoURL;
  String? get currentUserEmail => _auth.currentUser?.email;

  // Collections
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _usersCollection => _firestore.collection('users');

  CollectionReference _messagesCollection(String chatId) =>
      _chatsCollection.doc(chatId).collection('messages');

  // Initialize user in Firestore if doesn't exist
  Future<void> initializeUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _usersCollection.doc(user.uid).get();
    if (!userDoc.exists) {
      final userModel = UserModel.fromFirebaseUser(
        user.uid,
        user.email ?? '',
        user.displayName ?? 'Unknown User',
        user.photoURL,
      );
      await _usersCollection.doc(user.uid).set(userModel.toMap());
    }

    // After creating/updating user, check for chats where this user was invited by email
    await _migrateEmailParticipantsToUid(user.email!, user.uid);
  }

  // Migrate email-based participants to Firebase UIDs
  Future<void> _migrateEmailParticipantsToUid(String userEmail, String userId) async {
    try {
      // Find chats where the user's email is in participants
      final chatsWithEmail = await _chatsCollection
          .where('participants', arrayContains: userEmail.toLowerCase())
          .get();

      for (final doc in chatsWithEmail.docs) {
        final chatData = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        // Replace email with Firebase UID
        final updatedParticipants = participants.map((participant) {
          return participant.toLowerCase() == userEmail.toLowerCase() ? userId : participant;
        }).toList();

        // Update participant names and photos
        final participantNames = Map<String, String>.from(chatData['participantNames'] ?? {});
        final participantPhotos = Map<String, String?>.from(chatData['participantPhotos'] ?? {});
        
        // Move data from email key to UID key
        if (participantNames.containsKey(userEmail)) {
          participantNames[userId] = participantNames.remove(userEmail)!;
        }
        if (participantPhotos.containsKey(userEmail)) {
          participantPhotos[userId] = participantPhotos.remove(userEmail);
        }

        // Update the chat document
        await doc.reference.update({
          'participants': updatedParticipants,
          'participantNames': participantNames,
          'participantPhotos': participantPhotos,
        });

        print('✅ Migrated user $userEmail to $userId in chat ${doc.id}');
      }
    } catch (e) {
      print('❌ Error migrating email participants: $e');
    }
  }

  // Stream of user's chats
  Stream<List<ChatModel>> getUserChats() {
    if (currentUserId == null) return Stream.value([]);

    return _chatsCollection
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
          
          // Sort locally by lastMessageTime
          chats.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          return chats;
        });
  }

  // Also get chats where user's email is in participants (for users invited before signup)
  Stream<List<ChatModel>> getUserChatsByEmail() {
    if (currentUserEmail == null) return Stream.value([]);

    return _chatsCollection
        .where('participants', arrayContains: currentUserEmail)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
          
          // Sort locally by lastMessageTime
          chats.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          return chats;
        });
  }

  // Combined stream that gets chats by both UID and email
  Stream<List<ChatModel>> getAllUserChats() {
    if (currentUserId == null) return Stream.value([]);

    // Use rxdart's CombineLatestStream or simple approach
    return getUserChats().asyncMap((chatsByUid) async {
      final chatsByEmailStream = getUserChatsByEmail();
      final chatsByEmail = await chatsByEmailStream.first;
      
      // Combine and deduplicate chats
      final Map<String, ChatModel> uniqueChats = {};
      
      // Add chats found by UID
      for (final chat in chatsByUid) {
        uniqueChats[chat.id] = chat;
      }
      
      // Add chats found by email (avoid duplicates)
      for (final chat in chatsByEmail) {
        if (!uniqueChats.containsKey(chat.id)) {
          uniqueChats[chat.id] = chat;
        }
      }
      
      final allChats = uniqueChats.values.toList();
      
      // Sort by lastMessageTime
      allChats.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return allChats;
    });
  }  // Stream of messages in a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _messagesCollection(chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final messageId = _messagesCollection(chatId).doc().id;
    final now = DateTime.now();

    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId!,
      senderName: currentUserName ?? 'Unknown',
      senderPhoto: currentUserPhoto,
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: now,
      replyToMessageId: replyToMessageId,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      metadata: metadata,
    );

    try {
      // Add message to Firestore
      await _messagesCollection(chatId).doc(messageId).set(message.toMap());

      // Update chat with last message info
      await _updateChatLastMessage(chatId, content, now);

      // Update message status to sent
      await _updateMessageStatus(chatId, messageId, MessageStatus.sent);
    } catch (e) {
      // Update message status to failed
      await _updateMessageStatus(chatId, messageId, MessageStatus.failed);
      rethrow;
    }
  }

  // Create a new chat
  Future<String> createChat({
    required String name,
    required List<String> participantIds,
    ChatType type = ChatType.individual,
    String? description,
    String? photoUrl,
    Map<String, dynamic>? settings,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final chatId = _chatsCollection.doc().id;
    final now = DateTime.now();

    // Get participant details
    final participantNames = <String, String>{};
    final participantPhotos = <String, String?>{};
    final unreadCount = <String, int>{};

    for (final participantId in participantIds) {
      final userDoc = await _usersCollection.doc(participantId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        participantNames[participantId] = userData['displayName'] ?? 'Unknown';
        participantPhotos[participantId] = userData['photoURL'];
      }
      unreadCount[participantId] = 0;
    }

    final chat = ChatModel(
      id: chatId,
      name: name,
      description: description,
      photoUrl: photoUrl,
      type: type,
      participants: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      unreadCount: unreadCount,
      createdAt: now,
      updatedAt: now,
      createdBy: currentUserId,
      settings: settings ?? {},
    );

    await _chatsCollection.doc(chatId).set(chat.toMap());
    return chatId;
  }

  // Update message status
  Future<void> _updateMessageStatus(
      String chatId, String messageId, MessageStatus status) async {
    await _messagesCollection(chatId).doc(messageId).update({
      'status': status.index,
    });
  }

  // Update chat with last message info
  Future<void> _updateChatLastMessage(
      String chatId, String lastMessage, DateTime timestamp) async {
    await _chatsCollection.doc(chatId).update({
      'lastMessage': lastMessage,
      'lastMessageSenderId': currentUserId,
      'lastMessageTime': timestamp,
      'updatedAt': timestamp,
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    // Get all messages in the chat and filter locally
    final allMessages = await _messagesCollection(chatId).get();

    // Mark each unread message as read
    for (final doc in allMessages.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final senderId = data?['senderId'] as String?;
      final readBy = List<String>.from(data?['readBy'] ?? []);
      
      // Skip messages sent by current user and already read messages
      if (senderId == currentUserId || readBy.contains(currentUserId!)) {
        continue;
      }
      
      readBy.add(currentUserId!);
      batch.update(doc.reference, {'readBy': readBy});
    }

    // Reset unread count for current user
    batch.update(_chatsCollection.doc(chatId), {
      'unreadCount.$currentUserId': 0,
    });

    await batch.commit();
  }

  // Upload media file
  Future<String> uploadMedia(File file, String chatId, String fileName) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final ref = _storage
        .ref()
        .child('chats')
        .child(chatId)
        .child('media')
        .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _messagesCollection(chatId).doc(messageId).update({
      'isDeleted': true,
      'deletedAt': DateTime.now(),
      'content': 'This message was deleted',
    });
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    final doc = await _chatsCollection.doc(chatId).get();
    if (doc.exists) {
      return ChatModel.fromFirestore(doc);
    }
    return null;
  }

  // Search users for creating new chats
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Simple query - get all users and filter locally for now
      // In production, you might want to use a search service like Algolia
      final snapshot = await _usersCollection.limit(50).get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => 
              user.uid != currentUserId &&
              (user.displayName.toLowerCase().contains(query.toLowerCase()) ||
               user.email.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Update chat settings
  Future<void> updateChatSettings(String chatId, Map<String, dynamic> settings) async {
    await _chatsCollection.doc(chatId).update({
      'settings': settings,
      'updatedAt': DateTime.now(),
    });
  }

  // Archive/Unarchive chat
  Future<void> toggleArchiveChat(String chatId, bool isArchived) async {
    await _chatsCollection.doc(chatId).update({
      'isArchived': isArchived,
      'updatedAt': DateTime.now(),
    });
  }

  // Mute/Unmute chat
  Future<void> toggleMuteChat(String chatId, bool isMuted, {DateTime? mutedUntil}) async {
    await _chatsCollection.doc(chatId).update({
      'isMuted': isMuted,
      'mutedUntil': mutedUntil,
      'updatedAt': DateTime.now(),
    });
  }

  // Get individual chat between two users
  Future<String?> getIndividualChatId(String otherUserId) async {
    if (currentUserId == null) return null;

    final snapshot = await _chatsCollection
        .where('type', isEqualTo: ChatType.individual.index)
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in snapshot.docs) {
      final chat = ChatModel.fromFirestore(doc);
      if (chat.participants.contains(otherUserId)) {
        return chat.id;
      }
    }
    return null;
  }

  // Create individual chat if doesn't exist
  Future<String> getOrCreateIndividualChat(String otherUserId) async {
    final existingChatId = await getIndividualChatId(otherUserId);
    if (existingChatId != null) {
      return existingChatId;
    }

    // Get other user's details
    final otherUserDoc = await _usersCollection.doc(otherUserId).get();
    final otherUserData = otherUserDoc.data() as Map<String, dynamic>?;
    final otherUserName = otherUserData?['displayName'] ?? 'Unknown User';

    return await createChat(
      name: otherUserName,
      participantIds: [currentUserId!, otherUserId],
      type: ChatType.individual,
    );
  }

  // Delete chat and all its messages
  Future<void> deleteChat(String chatId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Delete all messages in the chat
      final messagesQuery = await _messagesCollection(chatId).get();
      final batch = _firestore.batch();
      
      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the chat document
      batch.delete(_chatsCollection.doc(chatId));
      
      // Commit all deletions
      await batch.commit();
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}
