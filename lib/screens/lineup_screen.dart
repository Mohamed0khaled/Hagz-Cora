import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class LineupScreen extends StatefulWidget {
  final String chatId;
  final ChatModel chat;
  final String currentUserId;

  const LineupScreen({
    super.key,
    required this.chatId,
    required this.chat,
    required this.currentUserId,
  });

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isEditingLineup = false;

  /// Get Hagz number from chat settings
  Future<String> _getHagzNumber() async {
    if (widget.chat.settings['hagzNumber'] != null) {
      return widget.chat.settings['hagzNumber'].toString();
    }
    return '11'; // Default
  }

  /// Get formation based on Hagz number
  String _getFormationForHagz(String hagzNumber) {
    switch (hagzNumber) {
      case '5':
        return '1-2-1'; // Goalkeeper, 2 defenders, 1 attacker
      case '7':
        return '1-3-2'; // Goalkeeper, 3 midfielders, 2 attackers
      case '11':
        return '4-4-2'; // Classic formation
      default:
        return '4-4-2';
    }
  }

  /// Get formation description
  String _getFormationDescription(String hagzNumber) {
    switch (hagzNumber) {
      case '5':
        return 'Compact 5v5 formation perfect for small-sided games. Fast-paced with high intensity and quick transitions.';
      case '7':
        return 'Balanced 7v7 setup allowing for tactical flexibility. Great for developing technical skills and teamwork.';
      case '11':
        return 'Classic 11v11 formation with strong midfield control. Perfect balance between defense and attack.';
      default:
        return 'Standard football formation optimized for team coordination and strategic play.';
    }
  }

  /// Check if current user is admin
  bool _isCurrentUserAdmin() {
    return widget.chat.createdBy == widget.currentUserId;
  }

  /// Toggle edit mode for lineup
  void _toggleEditMode() {
    setState(() {
      _isEditingLineup = !_isEditingLineup;
    });
    if (!_isEditingLineup) {
      _saveLineup();
    }
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

  /// Get players for lineup display
  Future<List<Map<String, dynamic>>> _getPlayersForLineup() async {
    final players = <Map<String, dynamic>>[];
    
    for (final memberId in widget.chat.participants) {
      final memberName = widget.chat.participantNames[memberId] ?? 'Player';
      final memberPhoto = widget.chat.participantPhotos[memberId];
      
      // Try to get full user data
      final userData = await _getUserData(memberId);
      
      players.add({
        'id': memberId,
        'name': userData?.displayName ?? memberName,
        'photo': userData?.photoURL ?? memberPhoto,
        'isCurrentUser': memberId == widget.currentUserId,
      });
    }
    
    return players;
  }

  /// Build football field background
  Widget _buildFootballField() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Grass texture
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.primary,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          
          // Field lines
          CustomPaint(
            painter: FieldPainter(),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }

  /// Build players positioned on field
  Widget _buildPlayersOnField(List<Map<String, dynamic>> players, String hagzNumber) {
    final positions = _getPositionsForFormation(hagzNumber, players.length);
    
    return Stack(
      children: [
        for (int i = 0; i < positions.length && i < players.length; i++)
          _buildPlayerWidget(
            players[i],
            positions[i]['x'],
            positions[i]['y'],
            positions[i]['position'],
          ),
      ],
    );
  }

  /// Get positions for formation
  List<Map<String, dynamic>> _getPositionsForFormation(String hagzNumber, int playerCount) {
    switch (hagzNumber) {
      case '5':
        return _get5v5Positions(playerCount);
      case '7':
        return _get7v7Positions(playerCount);
      case '11':
        return _get11v11Positions(playerCount);
      default:
        return _get11v11Positions(playerCount);
    }
  }

  /// 5v5 Formation positions
  List<Map<String, dynamic>> _get5v5Positions(int playerCount) {
    final positions = [
      {'x': 0.5, 'y': 0.85, 'position': 'GK'},   // Goalkeeper
      {'x': 0.25, 'y': 0.6, 'position': 'DEF'},  // Left Defender
      {'x': 0.75, 'y': 0.6, 'position': 'DEF'},  // Right Defender
      {'x': 0.5, 'y': 0.4, 'position': 'MID'},   // Midfielder
      {'x': 0.5, 'y': 0.2, 'position': 'ATT'},   // Attacker
    ];
    
    return positions.take(playerCount).toList();
  }

  /// 7v7 Formation positions
  List<Map<String, dynamic>> _get7v7Positions(int playerCount) {
    final positions = [
      {'x': 0.5, 'y': 0.85, 'position': 'GK'},   // Goalkeeper
      {'x': 0.2, 'y': 0.65, 'position': 'DEF'},  // Left Defender
      {'x': 0.5, 'y': 0.65, 'position': 'DEF'},  // Center Defender
      {'x': 0.8, 'y': 0.65, 'position': 'DEF'},  // Right Defender
      {'x': 0.3, 'y': 0.4, 'position': 'MID'},   // Left Midfielder
      {'x': 0.7, 'y': 0.4, 'position': 'MID'},   // Right Midfielder
      {'x': 0.5, 'y': 0.2, 'position': 'ATT'},   // Attacker
    ];
    
    return positions.take(playerCount).toList();
  }

  /// 11v11 Formation positions (4-4-2)
  List<Map<String, dynamic>> _get11v11Positions(int playerCount) {
    final positions = [
      {'x': 0.5, 'y': 0.9, 'position': 'GK'},    // Goalkeeper
      {'x': 0.15, 'y': 0.7, 'position': 'LB'},   // Left Back
      {'x': 0.38, 'y': 0.7, 'position': 'CB'},   // Center Back
      {'x': 0.62, 'y': 0.7, 'position': 'CB'},   // Center Back
      {'x': 0.85, 'y': 0.7, 'position': 'RB'},   // Right Back
      {'x': 0.15, 'y': 0.45, 'position': 'LM'},  // Left Midfielder
      {'x': 0.38, 'y': 0.45, 'position': 'CM'},  // Center Midfielder
      {'x': 0.62, 'y': 0.45, 'position': 'CM'},  // Center Midfielder
      {'x': 0.85, 'y': 0.45, 'position': 'RM'},  // Right Midfielder
      {'x': 0.35, 'y': 0.2, 'position': 'ST'},   // Striker
      {'x': 0.65, 'y': 0.2, 'position': 'ST'},   // Striker
    ];
    
    return positions.take(playerCount).toList();
  }

  /// Build individual player widget
  Widget _buildPlayerWidget(Map<String, dynamic> player, double x, double y, String position) {
    return Positioned(
      left: (x * 300) - 30, // Adjust based on container width
      top: (y * 400) - 30,  // Adjust based on container height
      child: GestureDetector(
        onTap: _isEditingLineup ? () => _onPlayerTap(player, position) : null,
        child: Column(
          children: [
            // Player avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.getPlayerHighlightColor(context, player['isCurrentUser']),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildChatAvatarImage(
                  player['photo'], 
                  player['name'],
                  radius: 28,
                ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Player name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player['name'].toString().split(' ').first, // First name only
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Position badge
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPositionColor(position),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                position,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function to create proper image widget based on image source
  Widget _buildChatAvatarImage(String? imageUrl, String displayName, {double radius = 20}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (imageUrl.startsWith('assets/')) {
      // Asset image
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: ClipOval(
          child: Image.asset(
            imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
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
          child: Image.network(
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
    }
  }

  /// Get color for position
  Color _getPositionColor(String position) {
    switch (position) {
      case 'GK':
        return Colors.orange;
      case 'DEF':
      case 'LB':
      case 'CB':
      case 'RB':
        return Colors.blue;
      case 'MID':
      case 'LM':
      case 'CM':
      case 'RM':
        return Colors.green;
      case 'ATT':
      case 'ST':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Handle player tap for editing
  void _onPlayerTap(Map<String, dynamic> player, String position) {
    if (!_isEditingLineup) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${player['name']}'),
        content: Text('Change position for ${player['name']}?\nCurrent: $position'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement position change logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Position updated for ${player['name']}')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _saveLineup() {
    // Implement save lineup logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formation saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Team Lineup',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isCurrentUserAdmin())
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: IconButton(
                onPressed: _toggleEditMode,
                icon: Icon(
                  _isEditingLineup ? Icons.check : Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: _isEditingLineup ? 'Save Formation' : 'Edit Formation',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with formation info
          Container(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<String>(
              future: _getHagzNumber(),
              builder: (context, snapshot) {
                final hagzNumber = snapshot.data ?? '11';
                final formation = _getFormationForHagz(hagzNumber);
                return Column(
                  children: [
                    Text(
                      'Formation: $formation',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${hagzNumber}v$hagzNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Football Field
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Field background with lines
                  _buildFootballField(),
                  
                  // Players
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getPlayersForLineup(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      
                      final players = snapshot.data ?? [];
                      return FutureBuilder<String>(
                        future: _getHagzNumber(),
                        builder: (context, hagzSnapshot) {
                          final hagzNumber = hagzSnapshot.data ?? '11';
                          return _buildPlayersOnField(players, hagzNumber);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Formation Info Panel
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FutureBuilder<String>(
              future: _getHagzNumber(),
              builder: (context, snapshot) {
                final hagzNumber = snapshot.data ?? '11';
                final formation = _getFormationForHagz(hagzNumber);
                final description = _getFormationDescription(hagzNumber);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${hagzNumber}v$hagzNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formation,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for football field lines
class FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Field border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ),
      paint,
    );

    // Center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      paint,
    );

    // Center spot
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );

    // Goal areas
    final goalWidth = size.width * 0.3;
    final goalHeight = size.height * 0.12;
    
    // Top goal area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalWidth) / 2,
        0,
        goalWidth,
        goalHeight,
      ),
      paint,
    );

    // Bottom goal area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalWidth) / 2,
        size.height - goalHeight,
        goalWidth,
        goalHeight,
      ),
      paint,
    );

    // Penalty areas
    final penaltyWidth = size.width * 0.5;
    final penaltyHeight = size.height * 0.2;
    
    // Top penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        0,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Bottom penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        size.height - penaltyHeight,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Penalty spots
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.15),
      3,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.85),
      3,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
