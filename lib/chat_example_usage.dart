import 'package:flutter/material.dart';
import 'models/chat_model.dart';
import 'models/message_model.dart';
import 'services/chat_service.dart';
import 'screens/chat_page.dart';

/// Example usage of the WhatsApp-like chat system
/// 
/// This file demonstrates how to:
/// 1. Create and manage chats
/// 2. Send different types of messages
/// 3. Navigate to chat pages
/// 4. Stream real-time updates
class ChatSystemExample {
  final ChatService _chatService = ChatService();

  /// Example 1: Create a new individual chat
  Future<void> createIndividualChat() async {
    try {
      final otherUserId = 'other_user_id'; // Replace with actual user ID
      final chatId = await _chatService.getOrCreateIndividualChat(otherUserId);
      print('Individual chat created/found: $chatId');
    } catch (e) {
      print('Error creating individual chat: $e');
    }
  }

  /// Example 2: Create a new group chat
  Future<void> createGroupChat() async {
    try {
      final chatId = await _chatService.createChat(
        name: 'Football Team Chat',
        participantIds: ['user1', 'user2', 'user3'], // Replace with actual user IDs
        type: ChatType.group,
        description: 'Discuss matches and team strategies',
        photoUrl: 'https://example.com/team_photo.jpg',
      );
      print('Group chat created: $chatId');
    } catch (e) {
      print('Error creating group chat: $e');
    }
  }

  /// Example 3: Send different types of messages
  Future<void> sendMessages(String chatId) async {
    try {
      // Send text message
      await _chatService.sendMessage(
        chatId: chatId,
        content: 'Hello! Ready for tonight\'s match?',
        type: MessageType.text,
      );

      // Send image message (after uploading)
      // File imageFile = File('path/to/image.jpg');
      // String imageUrl = await _chatService.uploadMedia(imageFile, chatId, 'team_photo.jpg');
      // await _chatService.sendMessage(
      //   chatId: chatId,
      //   content: '📷 Team Photo',
      //   type: MessageType.image,
      //   mediaUrl: imageUrl,
      // );

      // Send reply message
      await _chatService.sendMessage(
        chatId: chatId,
        content: 'Absolutely! Can\'t wait!',
        type: MessageType.text,
        replyToMessageId: 'original_message_id', // Replace with actual message ID
      );

      print('Messages sent successfully');
    } catch (e) {
      print('Error sending messages: $e');
    }
  }

  /// Example 4: Navigate to chat page
  void navigateToChatPage(BuildContext context, String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chatId,
          chatName: 'Football Team Chat',
          chatPhoto: 'https://example.com/team_photo.jpg',
          chatType: ChatType.group,
        ),
      ),
    );
  }

  /// Example 5: Stream user's chats
  Widget buildChatsList() {
    return StreamBuilder<List<ChatModel>>(
      stream: _chatService.getUserChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Start a conversation!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final currentUserId = _chatService.currentUserId ?? '';
            
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: chat.getDisplayPhoto(currentUserId) != null
                    ? NetworkImage(chat.getDisplayPhoto(currentUserId)!)
                    : null,
                child: chat.getDisplayPhoto(currentUserId) == null
                    ? Text(chat.getDisplayName(currentUserId)[0].toUpperCase())
                    : null,
              ),
              title: Text(
                chat.getDisplayName(currentUserId),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                chat.lastMessage ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chat.formattedLastMessageTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (chat.getUnreadCount(currentUserId) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat.getUnreadCount(currentUserId).toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () => navigateToChatPage(context, chat.id),
            );
          },
        );
      },
    );
  }

  /// Example 6: Search users to start new chats
  Widget buildUserSearch() {
    return _UserSearchWidget();
  }
}

class _UserSearchWidget extends StatefulWidget {
  @override
  _UserSearchWidgetState createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<_UserSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  List<dynamic> _searchResults = []; // Replace with UserModel
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await _chatService.searchUsers(query);
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      print('Error searching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _searchUsers,
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    // final user = _searchResults[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Text('U'), // user.displayName[0].toUpperCase()
                      ),
                      title: const Text('User Name'), // user.displayName
                      subtitle: const Text('user@email.com'), // user.email
                      onTap: () async {
                        // Start individual chat with this user
                        try {
                          await _chatService.getOrCreateIndividualChat('user.uid');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatPage(
                                chatId: 'demo_chat_id', // Use actual chatId in real app
                                chatName: 'User Name', // user.displayName
                                chatPhoto: null, // user.photoURL
                                chatType: ChatType.individual,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error starting chat: $e')),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Example Firebase Security Rules for Firestore
/// 
/// Add these to your Firestore security rules:
/// 
/// ```
/// rules_version = '2';
/// service cloud.firestore {
///   match /databases/{database}/documents {
///     // Users can read/write their own user document
///     match /users/{userId} {
///       allow read, write: if request.auth != null && request.auth.uid == userId;
///     }
///     
///     // Chat rules
///     match /chats/{chatId} {
///       allow read, write: if request.auth != null && 
///         request.auth.uid in resource.data.participants;
///     }
///     
///     // Message rules
///     match /chats/{chatId}/messages/{messageId} {
///       allow read: if request.auth != null && 
///         request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
///       allow write: if request.auth != null && 
///         request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants &&
///         request.auth.uid == request.resource.data.senderId;
///     }
///   }
/// }
/// ```

/// Example Cloud Functions for enhanced features:
/// 
/// ```javascript
/// const functions = require('firebase-functions');
/// const admin = require('firebase-admin');
/// admin.initializeApp();
/// 
/// // Update unread count when new message is sent
/// exports.updateUnreadCount = functions.firestore
///   .document('chats/{chatId}/messages/{messageId}')
///   .onCreate(async (snap, context) => {
///     const message = snap.data();
///     const chatId = context.params.chatId;
///     
///     const chatRef = admin.firestore().collection('chats').doc(chatId);
///     const chatDoc = await chatRef.get();
///     const chatData = chatDoc.data();
///     
///     const unreadCount = { ...chatData.unreadCount };
///     
///     // Increment unread count for all participants except sender
///     chatData.participants.forEach(participantId => {
///       if (participantId !== message.senderId) {
///         unreadCount[participantId] = (unreadCount[participantId] || 0) + 1;
///       }
///     });
///     
///     await chatRef.update({ unreadCount });
///   });
/// 
/// // Send push notifications for new messages
/// exports.sendMessageNotification = functions.firestore
///   .document('chats/{chatId}/messages/{messageId}')
///   .onCreate(async (snap, context) => {
///     const message = snap.data();
///     const chatId = context.params.chatId;
///     
///     // Get chat participants and send notifications
///     // Implementation depends on your notification system
///   });
/// ```
