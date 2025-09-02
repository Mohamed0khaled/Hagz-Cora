import 'package:flutter/material.dart';
import 'package:hagzcoora/Widgets/chat_head.dart';
import 'profile_settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: const Color(0xFF2E7D32), // Football green
        title: const Text(
          ' HagzKora',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 28,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Toggle search functionality
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
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
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'new_group',
                  child: Text('New group'),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('Settings'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _buildChatsTab(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50), // Football green
        onPressed: () {
          // Start new chat
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          color: const Color(0xFF2E7D32),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
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
                  size: 22,
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search suggestions
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4CAF50),
              child: Icon(Icons.search, color: Colors.white, size: 20),
            ),
            title: Text(
              'Search for "${_searchController.text}"',
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: const Text('Search messages'),
            onTap: () {},
          ),
          const Divider(height: 1),
          
          // Quick Actions
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[300],
              child: Icon(Icons.group_add, color: Colors.white, size: 20),
            ),
            title: const Text('New team group'),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[300],
              child: Icon(Icons.sports_soccer, color: Colors.white, size: 20),
            ),
            title: const Text('Join match discussion'),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[300],
              child: Icon(Icons.campaign, color: Colors.white, size: 20),
            ),
            title: const Text('New match broadcast'),
            onTap: () {},
          ),
          
          const SizedBox(height: 20),
          
          // No results
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results found for "${_searchController.text}"',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView(
      children: [
        SizedBox(height: 10,),
        
        // Football-themed chat heads
        chatHead(
          name: "Manchester United FC",
          imageUrl: "https://yt3.ggpht.com/ytc/AIdro_kkTWbv9dhD9ou6ii8dpBFM4zzI7V6ZTH0GAxF_ikbMUcc=s88-c-k-c0x00ffffff-no-rj",
          message: "Match tonight! Everyone ready?",
          time: "3:45 PM",
          isOnline: false,
          hasUnreadMessage: true,
          unreadCount: 12,
          isTyping: false,
          isRecording: false,
          isRead: false,
          isDelivered: false,
          isSent: false,
          isGroup: true,
          isMuted: false,
          isPinned: false,
          messageType: MessageType.text,
          onTap: () {
            // Navigate to chat
          },
        ),
        
      ],
    );
  }
}
