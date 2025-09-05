import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/chat_model.dart';
import '../models/friend_model.dart';
import '../services/chat_service.dart';
import '../services/friends_service.dart';
import 'chat_page.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FriendsService _friendsService = FriendsService();
  
  List<String> _memberEmails = [];
  List<String> _memberIds = []; // Firebase UIDs of selected members
  Map<String, String> _memberNames = {}; // Email -> Name mapping
  Map<String, String?> _memberPhotos = {}; // Email -> Photo URL mapping
  int _selectedHagzNumber = 5;
  String? _selectedGroupImage; // Selected group image path or URL
  final ImagePicker _imagePicker = ImagePicker();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  DateTime _selectedDate = DateTime.now(); // Selected hagz date
  bool _isCreating = false;

  final List<int> _hagzNumbers = [5, 7, 11];
  
  // Predefined group images (add more images to assets/images/ as needed)
  final List<String> _predefinedImages = [
    'assets/images/football-ball.png',
    'assets/images/football-ball_1.png',
    'assets/images/football-ball_2.png',
    'assets/images/football-ball_3.png',
    'assets/images/football-ball_4.png',
    'assets/images/football-ball_5.png',
    'assets/images/football-ball_6.png',
  ];

  @override
  void dispose() {
    _groupNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Add member by email
  Future<void> _addMemberByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (_memberEmails.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member already added')),
      );
      return;
    }

    // Try to get user name from email
    final users = await _chatService.searchUsers(email);
    String userName = email.split('@')[0]; // Default to email prefix
    String? userPhoto;
    
    for (final user in users) {
      if (user.email.toLowerCase() == email.toLowerCase()) {
        userName = user.displayName;
        userPhoto = user.photoURL;
        break;
      }
    }

    setState(() {
      _memberEmails.add(email);
      _memberNames[email] = userName;
      _memberPhotos[email] = userPhoto;
      _emailController.clear();
    });
  }

  // Remove member by email
  void _removeMemberEmail(String email) {
    setState(() {
      _memberEmails.remove(email);
      _memberNames.remove(email);
      _memberPhotos.remove(email);
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // Select date for hagz
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Show image selection dialog
  void _showImageSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Group Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Predefined images grid
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 1,
                  mainAxisSpacing: 8,
                ),
                itemCount: _predefinedImages.length,
                itemBuilder: (context, index) {
                  final imagePath = _predefinedImages[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGroupImage = imagePath;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedGroupImage == imagePath
                              ? Colors.green
                              : Colors.grey[300]!,
                          width: _selectedGroupImage == imagePath ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.sports_soccer,
                                color: Colors.green,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Gallery button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ),
            
            // Remove image button (if image is selected)
            if (_selectedGroupImage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedGroupImage = null;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Remove Image',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Uploading image...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }
        
        try {
          // Upload image to Firebase Storage
          final fileName = 'group_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final imageUrl = await _chatService.uploadMedia(
            File(image.path),
            'group_images', // Use a special folder for group images
            fileName,
          );
          
          setState(() {
            _selectedGroupImage = imageUrl; // Store the Firebase URL
          });
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $uploadError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _createHagzGroup() async {
    final groupName = _groupNameController.text.trim();
    
    if (groupName.isEmpty) {
      _showErrorSnackBar('Please enter a group name');
      return;
    }

    if (_memberEmails.isEmpty) {
      _showErrorSnackBar('Please add at least one member');
      return;
    }

    // Validate time range
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    if (endMinutes <= startMinutes) {
      _showErrorSnackBar('End time must be after start time');
      return;
    }

    // Validate date is not in the past (for today, allow any time)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    if (selectedDay == today) {
      // For today, check if the start time hasn't passed
      final nowMinutes = now.hour * 60 + now.minute;
      if (startMinutes <= nowMinutes) {
        _showErrorSnackBar('Start time cannot be in the past');
        return;
      }
    } else if (selectedDay.isBefore(today)) {
      _showErrorSnackBar('Cannot create hagz for past dates');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final currentUserId = _chatService.currentUserId!;
      
      // Resolve email addresses to Firebase User IDs
      final participantIds = <String>[currentUserId];
      final participantNames = <String, String>{
        currentUserId: _chatService.currentUserName ?? 'You',
      };
      final participantPhotos = <String, String?>{
        currentUserId: _chatService.currentUserPhoto,
      };

      // For each email, try to find the corresponding Firebase user
      for (int i = 0; i < _memberEmails.length; i++) {
        final email = _memberEmails[i];
        
        try {
          // Search for user by email in Firestore
          final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();
          
          if (userQuery.docs.isNotEmpty) {
            // User found in Firestore - use their Firebase UID
            final userDoc = userQuery.docs.first;
            final userId = userDoc.id;
            final userData = userDoc.data();
            
            participantIds.add(userId);
            participantNames[userId] = userData['displayName'] ?? email.split('@')[0];
            participantPhotos[userId] = userData['photoURL'];
            
            print('✅ Found user for email $email: $userId');
          } else {
            // User not found in Firestore - they may not have signed up yet
            // Create a placeholder entry with email as ID for now
            // When they sign up, the system can resolve this
            participantIds.add(email);
            participantNames[email] = _memberNames[email] ?? email.split('@')[0];
            participantPhotos[email] = _memberPhotos[email];
            
            print('⚠️ User not found for email $email - using email as placeholder');
            
            // Optionally show a warning
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$email hasn\'t signed up yet. They\'ll see the group when they join.'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          print('❌ Error resolving email $email: $e');
          // Fallback to using email as ID
          participantIds.add(email);
          participantNames[email] = _memberNames[email] ?? email.split('@')[0];
          participantPhotos[email] = _memberPhotos[email];
        }
      }

      // Create hagz-specific settings
      final hagzSettings = {
        'isHagzGroup': true,
        'hagzNumber': _selectedHagzNumber,
        'hagzDate': _selectedDate.toIso8601String(),
        'startTime': _formatTime(_startTime),
        'endTime': _formatTime(_endTime),
        'memberEmails': _memberEmails,
        'groupImage': _selectedGroupImage,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': currentUserId,
      };

      final chatId = await _chatService.createChat(
        name: groupName,
        participantIds: participantIds,
        type: ChatType.group,
        description: 'Hagz ${_selectedHagzNumber}v${_selectedHagzNumber} • ${_formatDate(_selectedDate)} • ${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
        photoUrl: _selectedGroupImage,
        settings: hagzSettings,
      );

      if (mounted) {
        Navigator.pop(context); // Close new chat screen
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: chatId,
              chatName: groupName,
              chatPhoto: _selectedGroupImage,
              chatType: ChatType.group,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating hagz group: $e');
      if (mounted) {
        _showErrorSnackBar('Error creating hagz group: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green, // Football green
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New Hagz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createHagzGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'CREATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Icon and Name
            Row(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageSelectionDialog,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: _selectedGroupImage != null
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: _selectedGroupImage != null
                            ? ClipOval(
                                child: _selectedGroupImage!.startsWith('assets/')
                                    ? Image.asset(
                                        _selectedGroupImage!,
                                        fit: BoxFit.cover,
                                        width: 60,
                                        height: 60,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.sports_soccer,
                                            size: 30,
                                            color: Colors.white,
                                          );
                                        },
                                      )
                                    : _selectedGroupImage!.startsWith('http')
                                        ? Image.network(
                                            _selectedGroupImage!,
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.sports_soccer,
                                                size: 30,
                                                color: Colors.white,
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(_selectedGroupImage!),
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.sports_soccer,
                                                size: 30,
                                                color: Colors.white,
                                              );
                                            },
                                          ),
                              )
                            : const Icon(
                                Icons.sports_soccer,
                                size: 30,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to change',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter hagz name (e.g., "Friday Night Football")',
                      border: UnderlineInputBorder(),
                      labelText: 'Hagz Name',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Hagz Number Selection
            const Text(
              'Select Hagz Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _hagzNumbers.map((number) {
                final isSelected = _selectedHagzNumber == number;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHagzNumber = number;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.groups,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${number}v$number',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '$number players',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Date & Time Selection
            const Text(
              'Hagz Date & Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            
            // Date Selection
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hagz Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_formatDate(_selectedDate) == 'Today' || _formatDate(_selectedDate) == 'Tomorrow')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatDate(_selectedDate) == 'Today' ? '⚡' : '📅',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            // Time Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_startTime),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_endTime),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Add Members Section
            const Text(
              'Add Members',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            
            // Quick add from friends button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showFriendsSelectionDialog,
                icon: const Icon(Icons.people),
                label: const Text('Select from Friends'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Divider with "OR"
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Add by Email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter email address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    onSubmitted: (_) async => await _addMemberByEmail(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addMemberByEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text('ADD'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Members List
            if (_memberEmails.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members (${_memberEmails.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._memberEmails.map((email) {
                      final userName = _memberNames[email] ?? email.split('@')[0];
                      final userPhoto = _memberPhotos[email];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green,
                              backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                                  ? NetworkImage(userPhoto)
                                  : null,
                              child: userPhoto == null || userPhoto.isEmpty
                                  ? Text(
                                      userName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeMemberEmail(email),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hagz Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Format', '${_selectedHagzNumber}v$_selectedHagzNumber'),
                  _buildSummaryRow('Date', _formatDate(_selectedDate)),
                  _buildSummaryRow('Time', '${_formatTime(_startTime)} - ${_formatTime(_endTime)}'),
                  _buildSummaryRow('Members', '${_memberEmails.length + 1} players'),
                  if (_groupNameController.text.isNotEmpty)
                    _buildSummaryRow('Name', _groupNameController.text),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createHagzGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Hagz Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E7D32),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Show friends selection dialog
  void _showFriendsSelectionDialog() async {
    try {
      final friends = await _friendsService.getUserFriends().first;
      
      if (friends.isEmpty) {
        _showErrorSnackBar('No friends found. Add friends first to select them quickly!');
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Friends'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final isSelected = _memberEmails.contains(friend.friendEmail);
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                      backgroundImage: friend.friendPhotoUrl != null && friend.friendPhotoUrl!.isNotEmpty
                          ? NetworkImage(friend.friendPhotoUrl!)
                          : null,
                      child: friend.friendPhotoUrl == null || friend.friendPhotoUrl!.isEmpty
                          ? Text(
                              friend.friendName.isNotEmpty 
                                  ? friend.friendName[0].toUpperCase()
                                  : 'F',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      friend.friendName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(friend.friendEmail),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                        : const Icon(Icons.add_circle_outline, color: Colors.grey),
                    onTap: () {
                      if (!isSelected) {
                        _addFriendToMembers(friend);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error loading friends: $e');
    }
  }

  // Add friend to members list
  void _addFriendToMembers(FriendModel friend) {
    if (!_memberEmails.contains(friend.friendEmail)) {
      setState(() {
        _memberEmails.add(friend.friendEmail);
        // Store the actual Firebase UID if available, otherwise use email
        if (friend.friendId.isNotEmpty && !friend.friendId.contains('@')) {
          // This is a proper Firebase UID
          _memberIds.add(friend.friendId);
        } else {
          // This might be an email, try to resolve it later
          _memberIds.add(friend.friendEmail);
        }
        _memberNames[friend.friendEmail] = friend.friendName;
        _memberPhotos[friend.friendEmail] = friend.friendPhotoUrl;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${friend.friendName} added to the hagz!'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
