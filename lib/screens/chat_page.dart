import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/database_service.dart';
import 'lineup_screen.dart';

// Helper function to create proper image widget based on image source
Widget _buildChatAvatarImage(String? imageUrl, String displayName, {double radius = 20}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  } else if (imageUrl.startsWith('assets/')) {
    // Asset image
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: Image.asset(
          imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  } else if (imageUrl.startsWith('http')) {
    // Network image
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: NetworkImage(imageUrl),
      child: null,
      onBackgroundImageError: (exception, stackTrace) {
        // This will show the backgroundColor if image fails
      },
    );
  } else {
    // File image (from gallery)
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: Image.file(
          File(imageUrl),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String? chatName;
  final String? chatPhoto;
  final ChatType chatType;

  const ChatPage({
    super.key,
    required this.chatId,
    this.chatName,
    this.chatPhoto,
    this.chatType = ChatType.individual,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  late final AudioPlayer _audioPlayer;
  final ValueNotifier<bool> _isTypingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<MessageModel?> _replyToMessageNotifier = ValueNotifier<MessageModel?>(null);
  
  // Track message statuses to detect when they change to 'sent'
  final Map<String, MessageStatus> _messageStatuses = {};
  
  ChatModel? _currentChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _loadChatData();
    _markMessagesAsRead();
    
    // Add listener to text controller to manage typing state more efficiently
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Use ValueNotifier to prevent rebuilds of the entire widget
    final hasText = _messageController.text.trim().isNotEmpty;
    _isTypingNotifier.value = hasText;
  }

  Future<void> _playSendSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/send.mp3');
      await _audioPlayer.play();
    } catch (e) {
      // Handle error silently - don't let sound issues affect messaging
      print('Error playing send sound: $e');
    }
  }

  void _checkForDeliveredMessages(List<MessageModel> messages) {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    for (final message in messages) {
      // Only check messages sent by current user
      if (message.senderId == currentUserId) {
        final previousStatus = _messageStatuses[message.id];
        final currentStatus = message.status;
        
        // If message status changed from sending to sent, play sound
        if (previousStatus == MessageStatus.sending && currentStatus == MessageStatus.sent) {
          _playSendSound();
        }
        
        // Update stored status
        _messageStatuses[message.id] = currentStatus;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _isTypingNotifier.dispose();
    _replyToMessageNotifier.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  Future<void> _loadChatData() async {
    final chat = await _chatService.getChatById(widget.chatId);
    if (chat != null) {
      setState(() {
        _currentChat = chat;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.chatId);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      chatId: widget.chatId,
      content: text,
      type: MessageType.text,
      replyToMessageId: _replyToMessageNotifier.value?.id,
    );

    _messageController.clear();
    _clearReply();
    _scrollToBottom();
  }

  void _sendMediaMessage(String mediaUrl, MessageType type, {String? thumbnailUrl}) {
    _chatService.sendMessage(
      chatId: widget.chatId,
      content: type == MessageType.image ? '📷 Photo' : 
               type == MessageType.video ? '🎥 Video' : 
               type == MessageType.audio ? '🎵 Audio' : '📎 File',
      type: type,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      replyToMessageId: _replyToMessageNotifier.value?.id,
    );

    _clearReply();
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final url = await _chatService.uploadMedia(
        File(image.path),
        widget.chatId,
        image.name,
      );
      _sendMediaMessage(url, MessageType.image);
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final url = await _chatService.uploadMedia(
        File(video.path),
        widget.chatId,
        video.name,
      );
      _sendMediaMessage(url, MessageType.video);
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final url = await _chatService.uploadMedia(
        File(image.path),
        widget.chatId,
        image.name,
      );
      _sendMediaMessage(url, MessageType.image);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setReplyMessage(MessageModel message) {
    _replyToMessageNotifier.value = message;
  }

  void _clearReply() {
    _replyToMessageNotifier.value = null;
  }

  void _deleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _chatService.deleteMessage(widget.chatId, message.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _MediaOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _MediaOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _MediaOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGroupMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Group Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<ChatModel?>(
                  future: _chatService.getChatById(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text('Error loading group information'),
                      );
                    }

                    final chat = snapshot.data!;
                    final members = chat.participants;
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final memberId = members[index];
                        final memberName = chat.participantNames[memberId] ?? 'Unknown User';
                        final memberPhoto = chat.participantPhotos[memberId];
                        
                        // Debug: Print the member data to understand what we're getting
                        print('Member $index: ID=$memberId, Name=$memberName, Photo=$memberPhoto');
                        
                        return FutureBuilder(
                          future: _getUserData(memberId),
                          builder: (context, userSnapshot) {
                            // Always show member name from chat data first
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return ListTile(
                                leading: _buildChatAvatarImage(memberPhoto, memberName),
                                title: Text(memberName),
                                subtitle: const Text('Loading user details...'),
                                trailing: memberId == _getCurrentUserId() 
                                  ? const Chip(
                                      label: Text('You', style: TextStyle(fontSize: 12)),
                                      backgroundColor: Color(0xFF075E54),
                                      labelStyle: TextStyle(color: Colors.white),
                                    )
                                  : null,
                              );
                            }
                            
                            // Check if we got user data successfully
                            if (userSnapshot.hasData && userSnapshot.data != null) {
                              final user = userSnapshot.data as UserModel;
                              return ListTile(
                                leading: _buildChatAvatarImage(user.photoURL ?? memberPhoto, user.displayName),
                                title: Text(user.displayName),
                                subtitle: Text(user.email),
                                trailing: _isCurrentUser(memberId, user.uid)
                                  ? const Chip(
                                      label: Text('You', style: TextStyle(fontSize: 12)),
                                      backgroundColor: Color(0xFF075E54),
                                      labelStyle: TextStyle(color: Colors.white),
                                    )
                                  : null,
                              );
                            }
                            
                            // Fallback to chat participant data if user profile fails
                            return ListTile(
                              leading: _buildChatAvatarImage(memberPhoto, memberName),
                              title: Text(memberName),
                              subtitle: Text(_isEmailFormat(memberId) 
                                ? memberId // Show email if it's an email format
                                : 'User ID: ${memberId.substring(0, 8)}...'),
                              trailing: memberId == _getCurrentUserId() 
                                ? const Chip(
                                    label: Text('You', style: TextStyle(fontSize: 12)),
                                    backgroundColor: Color(0xFF075E54),
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : null,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLineupView() {
    if (_currentChat == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LineupScreen(
          chatId: widget.chatId,
          chat: _currentChat!,
          currentUserId: _getCurrentUserId(),
        ),
      ),
    );
  }

  String _getCurrentUserId() {
    return _chatService.currentUserId ?? '';
  }

  /// Get user data by ID or email
  Future<UserModel?> _getUserData(String identifier) async {
    try {
      if (_isEmailFormat(identifier)) {
        // If it's an email, search for user by email
        final users = await _databaseService.searchUsers('');
        for (final user in users) {
          if (user.email == identifier) {
            return user;
          }
        }
        return null;
      } else {
        // If it's a UID, get user profile directly
        final result = await _databaseService.getUserProfile(identifier);
        if (result.success) {
          return result.data as UserModel;
        }
        return null;
      }
    } catch (e) {
      print('Error getting user data for $identifier: $e');
      return null;
    }
  }

  /// Check if a string is in email format
  bool _isEmailFormat(String text) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
  }

  /// Check if the member is the current user
  bool _isCurrentUser(String memberId, String userUid) {
    final currentUserId = _getCurrentUserId();
    return memberId == currentUserId || userUid == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _getCurrentUserId();
    final displayName = _currentChat?.getDisplayName(currentUserId) ?? widget.chatName ?? 'Chat';
    final displayPhoto = _currentChat?.getDisplayPhoto(currentUserId) ?? widget.chatPhoto;

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54), // WhatsApp green
        elevation: 0,
        titleSpacing: 0, // Reduce spacing between leading and title
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildChatAvatarImage(displayPhoto, displayName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.chatType == ChatType.individual)
                    const Text(
                      'Online', // You can implement real online status
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'view_members':
                  _showGroupMembers();
                  break;
                case 'lineup':
                  _showLineupView();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_members',
                child: Row(
                  children: [
                    Icon(Icons.group, color: Colors.black54),
                    SizedBox(width: 12),
                    Text('View members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'lineup',
                child: Row(
                  children: [
                    Icon(Icons.sports_soccer, color: Colors.black54),
                    SizedBox(width: 12),
                    Text('Lineup'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply preview
          ValueListenableBuilder<MessageModel?>(
            valueListenable: _replyToMessageNotifier,
            builder: (context, replyToMessage, child) {
              if (replyToMessage == null) return const SizedBox.shrink();
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCF8C6),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF075E54),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            replyToMessage.senderName,
                            style: const TextStyle(
                              color: Color(0xFF075E54),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyToMessage.content,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _clearReply,
                    ),
                  ],
                ),
              );
            },
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];
                
                // Check for delivered messages and play sound if needed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkForDeliveredMessages(messages);
                });

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSend a message to start the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showDateHeader = index == messages.length - 1 ||
                        (index < messages.length - 1 &&
                            !_isSameDay(message.timestamp, messages[index + 1].timestamp));

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(message.timestamp),
                        _MessageBubble(
                          message: message,
                          isMe: isMe,
                          showTime: _shouldShowTime(messages, index),
                          showAvatar: !isMe && (index == 0 || messages[index - 1].senderId != message.senderId),
                          senderPhoto: message.senderPhoto,
                          senderName: message.senderName,
                          onReply: () => _setReplyMessage(message),
                          onDelete: isMe ? () => _deleteMessage(message) : null,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: () {
                            // Implement emoji picker
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: _showMediaPicker,
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isTypingNotifier,
                          builder: (context, isTyping, child) {
                            return isTyping 
                                ? const SizedBox.shrink()
                                : IconButton(
                                    icon: const Icon(Icons.camera_alt),
                                    onPressed: _takePhoto,
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _isTypingNotifier,
                  builder: (context, isTyping, child) {
                    return FloatingActionButton(
                      onPressed: isTyping ? _sendMessage : () {
                        // Implement voice recording
                      },
                      backgroundColor: const Color(0xFF075E54),
                      mini: true,
                      child: Icon(
                        isTyping ? Icons.send : Icons.mic,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _shouldShowTime(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index - 1];
    
    return currentMessage.senderId != nextMessage.senderId ||
        currentMessage.timestamp.difference(nextMessage.timestamp).inMinutes > 5;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    String dateText;
    if (difference == 0) {
      dateText = 'Today';
    } else if (difference == 1) {
      dateText = 'Yesterday';
    } else if (difference < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      dateText = days[date.weekday - 1];
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTime;
  final bool showAvatar;
  final String? senderPhoto;
  final String senderName;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showTime,
    required this.showAvatar,
    required this.senderPhoto,
    required this.senderName,
    required this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          top: 2,
          bottom: 2,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for received messages
            if (!isMe) ...[
              if (showAvatar)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: _buildChatAvatarImage(senderPhoto, senderName, radius: 16),
                )
              else
                const SizedBox(width: 40), // Space to align with avatar
            ],
            
            // Message bubble
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : (showAvatar ? 4 : 18)),
                    bottomRight: Radius.circular(isMe ? (showAvatar ? 4 : 18) : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name for group chats (non-me messages)
                    if (!isMe && showAvatar)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          senderName,
                          style: const TextStyle(
                            color: Color(0xFF075E54),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    
                    if (message.replyToMessageId != null)
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border(
                              left: BorderSide(
                                color: isMe ? const Color(0xFF075E54) : Colors.grey,
                                width: 3,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Replied message', // You can fetch the actual replied message
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    
                    if (message.isMedia)
                      _buildMediaContent()
                    else
                      Text(
                        message.isDeleted ? 'This message was deleted' : message.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: message.isDeleted ? Colors.grey : Colors.black87,
                          fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showTime)
                          Text(
                            _formatTime(message.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.status == MessageStatus.read
                                ? Icons.done_all
                                : message.status == MessageStatus.delivered
                                    ? Icons.done_all
                                    : message.status == MessageStatus.sent
                                        ? Icons.done
                                        : message.status == MessageStatus.failed
                                            ? Icons.error_outline
                                            : Icons.schedule,
                            size: 14,
                            color: message.status == MessageStatus.read
                                ? Colors.blue
                                : message.status == MessageStatus.failed
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Avatar for sent messages (if needed for consistency)
            if (isMe) ...[
              const SizedBox(width: 8), // Small spacing from message
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (message.type) {
      case MessageType.image:
        return Container(
          constraints: const BoxConstraints(
            maxHeight: 200,
            maxWidth: 200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: message.mediaUrl != null
                ? Image.network(
                    message.mediaUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      );
                    },
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
          ),
        );
      case MessageType.video:
        return Container(
          constraints: const BoxConstraints(
            maxHeight: 200,
            maxWidth: 200,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: message.thumbnailUrl != null
                    ? Image.network(
                        message.thumbnailUrl!,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.video_library, color: Colors.white),
              ),
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 48,
              ),
            ],
          ),
        );
      default:
        return Text(message.content);
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}