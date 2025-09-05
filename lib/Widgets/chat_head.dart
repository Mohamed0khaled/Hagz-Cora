import 'package:flutter/material.dart';
import 'dart:io';

// Helper function to create proper image widget based on image source
Widget _buildChatImage(String imageUrl, {double radius = 28}) {
  if (imageUrl.isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Image.asset("assets/images/football-ball.png"),
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
            return Image.asset("assets/images/football-ball.png");
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
            return Image.asset("assets/images/football-ball.png");
          },
        ),
      ),
    );
  }
}

Widget chatHead({
  required String name,
  required String imageUrl,
  required String message,
  required String time,
  bool isOnline = false,
  bool hasUnreadMessage = false,
  int unreadCount = 0,
  bool isTyping = false,
  bool isRecording = false,
  bool isDelivered = false,
  bool isRead = false,
  bool isSent = false,
  bool isGroup = false,
  bool isMuted = false,
  bool isPinned = false,
  MessageType messageType = MessageType.text,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  VoidCallback? onProfileTap,
  VoidCallback? onMute,
  VoidCallback? onDelete,
  Function(String)? onMessageSend,
  Function(bool)? onMuteToggle,
}) {
  return Container(
    color: Colors.white,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Profile Picture with Online Status
            Stack(
              children: [
                GestureDetector(
                  onTap: onProfileTap,
                  child: _buildChatImage(imageUrl),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366), // WhatsApp green
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Chat Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Pin Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPinned)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Message with Status
                  Row(
                    children: [
                      // Message Status Icons (for sent messages)
                      if (isSent || isDelivered || isRead)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            isRead 
                              ? Icons.done_all
                              : isDelivered 
                                ? Icons.done_all
                                : Icons.done,
                            size: 16,
                            color: isRead 
                              ? const Color(0xFF25D366)
                              : Colors.grey,
                          ),
                        ),
                      
                      // Message Type Icon
                      if (messageType != MessageType.text)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            _getMessageTypeIcon(messageType),
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      
                      // Message Text
                      Expanded(
                        child: Text(
                          isTyping 
                            ? "typing..."
                            : isRecording 
                              ? "recording..."
                              : message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isTyping || isRecording 
                              ? const Color(0xFF25D366)
                              : hasUnreadMessage 
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: hasUnreadMessage 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                            fontStyle: isTyping || isRecording 
                              ? FontStyle.italic 
                              : FontStyle.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Time and Notification Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Time
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnreadMessage 
                      ? const Color(0xFF25D366)
                      : Colors.grey[600],
                    fontWeight: hasUnreadMessage 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Unread Badge and Mute Icon Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mute Icon
                    if (isMuted)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.volume_off,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    
                    // Unread Count Badge
                    if (hasUnreadMessage && unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isMuted 
                            ? Colors.grey[400]
                            : const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 999 ? "999+" : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            // Action Buttons (visible on long press or when needed)
            if (onMute != null || onDelete != null)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.grey[600],
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'mute':
                      if (onMuteToggle != null) {
                        onMuteToggle(!isMuted);
                      } else if (onMute != null) {
                        onMute();
                      }
                      break;
                    case 'delete':
                      if (onDelete != null) onDelete();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  List<PopupMenuEntry<String>> items = [];
                  
                  if (onMuteToggle != null || onMute != null) {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'mute',
                        child: Row(
                          children: [
                            Icon(
                              isMuted ? Icons.volume_up : Icons.volume_off,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(isMuted ? 'Unmute' : 'Mute'),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  if (onDelete != null) {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return items;
                },
              ),
          ],
        ),
      ),
    ),
  );
}

// Enum for different message types
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  contact,
  sticker,
  gif
}

// Helper function to get icon for message type
IconData _getMessageTypeIcon(MessageType type) {
  switch (type) {
    case MessageType.image:
      return Icons.photo_camera;
    case MessageType.video:
      return Icons.videocam;
    case MessageType.audio:
      return Icons.mic;
    case MessageType.document:
      return Icons.description;
    case MessageType.location:
      return Icons.location_on;
    case MessageType.contact:
      return Icons.person;
    case MessageType.sticker:
      return Icons.emoji_emotions;
    case MessageType.gif:
      return Icons.gif;
    default:
      return Icons.message;
  }
}