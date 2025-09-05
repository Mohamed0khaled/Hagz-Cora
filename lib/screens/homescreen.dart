import 'package:flutter/material.dart';
import 'package:hagzcoora/Widgets/chat_head.dart';
import 'package:hagzcoora/screens/chat_page.dart';
import 'package:hagzcoora/screens/new_chat_screen.dart';
import 'package:hagzcoora/models/chat_model.dart';
import 'package:hagzcoora/services/chat_service.dart';
import 'profile_settings_screen.dart';
import 'settings.dart';
import 'friends_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ChatService _chatService = ChatService();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeChatService();
  }

  Future<void> _initializeChatService() async {
    try {
      await _chatService.initializeUser();
    } catch (e) {
      print('Error initializing chat service: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.green, // Solid green
        title: const Text(
          ' HagzKora',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 28,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.green,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              } else if (value == 'friends') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FriendsScreen(),
                  ),
                );
              }
              // Handle other menu selections
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 25,)
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'friends',
                  child: Row(
                    children: [
                      Text(
                        'Friends',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 25,)
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 25,)
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Unfocus search when tapping outside
          _searchFocusNode.unfocus();
        },
        child: _buildChatsTab(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50), // Solid light green
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewChatScreen()),
          );
        },
        child: Image.asset(
          "assets/images/ticket.png",
          color: Colors.white,
          scale: 15.5,
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        // Search Bar - Recreated from scratch
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search teams, players, matches...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),

        // Chat List
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildChatList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<ChatModel>>(
      stream: _chatService.getAllUserChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline, 
                  size: 64, 
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading chats',
                  style: TextStyle(
                    color: Colors.grey, 
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final allChats = snapshot.data ?? [];
        final currentUserId = _chatService.currentUserId ?? '';
        final searchQuery = _searchController.text.toLowerCase();

        // Filter chats based on search query
        final filteredChats = allChats.where((chat) {
          final displayName = chat.getDisplayName(currentUserId).toLowerCase();
          final lastMessage = (chat.lastMessage ?? '').toLowerCase();

          // Search in chat name and last message content
          return displayName.contains(searchQuery) ||
              lastMessage.contains(searchQuery);
        }).toList();

        if (filteredChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No results found for "${_searchController.text}"',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try searching for team names or messages',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            final displayName = chat.getDisplayName(currentUserId);
            final displayPhoto = chat.getDisplayPhoto(currentUserId);
            final unreadCount = chat.getUnreadCount(currentUserId);

            return chatHead(
              name: displayName,
              imageUrl: displayPhoto ?? '',
              message: chat.lastMessage ?? 'No messages yet',
              time: chat.formattedLastMessageTime,
              isOnline: false,
              hasUnreadMessage: unreadCount > 0,
              unreadCount: unreadCount,
              isTyping: false,
              isRecording: false,
              isRead: false,
              isDelivered: false,
              isSent: false,
              isGroup: chat.type == ChatType.group,
              isMuted: chat.isMuted,
              isPinned: false,
              messageType: MessageType.text,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      chatId: chat.id,
                      chatName: displayName,
                      chatPhoto: displayPhoto,
                      chatType: chat.type,
                    ),
                  ),
                );
              },
              onProfileTap: () {
                // Navigate to chat info/profile
              },
              onMute: () {
                _chatService.toggleMuteChat(chat.id, !chat.isMuted);
              },
              onDelete: () {
                _showDeleteChatDialog(chat);
              },
              onMessageSend: (name) {
                _chatService.sendMessage(
                  chatId: chat.id,
                  content: 'Quick reply message',
                );
              },
              onMuteToggle: (isMuted) {
                _chatService.toggleMuteChat(chat.id, isMuted);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<ChatModel>>(
      stream: _chatService.getAllUserChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Error loading chats',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final chats = snapshot.data ?? [];
        final currentUserId = _chatService.currentUserId ?? '';

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No chats yet',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a conversation by tapping the + button',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewChatScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Start New Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // Solid light green
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final displayName = chat.getDisplayName(currentUserId);
            final displayPhoto = chat.getDisplayPhoto(currentUserId);
            final unreadCount = chat.getUnreadCount(currentUserId);

            return chatHead(
              name: displayName,
              imageUrl: displayPhoto ?? '',
              message: chat.lastMessage ?? 'No messages yet',
              time: chat.formattedLastMessageTime,
              isOnline: false, // You can implement online status
              hasUnreadMessage: unreadCount > 0,
              unreadCount: unreadCount,
              isTyping: false, // You can implement typing indicator
              isRecording: false,
              isRead: false, // You can implement read status
              isDelivered: false,
              isSent: false,
              isGroup: chat.type == ChatType.group,
              isMuted: chat.isMuted,
              isPinned: false, // You can implement pinned chats
              messageType: MessageType.text,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      chatId: chat.id,
                      chatName: displayName,
                      chatPhoto: displayPhoto,
                      chatType: chat.type,
                    ),
                  ),
                );
              },
              onProfileTap: () {
                // Navigate to chat info/profile
              },
              onMute: () {
                _chatService.toggleMuteChat(chat.id, !chat.isMuted);
              },
              onDelete: () {
                _showDeleteChatDialog(chat);
              },
              onMessageSend: (name) {
                // Quick reply functionality - simplified signature
                _chatService.sendMessage(
                  chatId: chat.id,
                  content: 'Quick reply message',
                );
              },
              onMuteToggle: (isMuted) {
                _chatService.toggleMuteChat(chat.id, isMuted);
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteChatDialog(ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete the chat "${chat.name}"?\n\nThis action cannot be undone and will delete all messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store ScaffoldMessenger reference before any async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              // Show loading indicator
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Deleting chat...'),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                // Delete the chat
                await _chatService.deleteChat(chat.id);

                // Hide loading and show success message
                if (mounted) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Chat "${chat.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                // Hide loading and show error message
                if (mounted) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete chat: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
