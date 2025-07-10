import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_controller.dart';
import '../../models/formation.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_button.dart';

class FormationScreen extends StatefulWidget {
  final String groupId;

  const FormationScreen({super.key, required this.groupId});

  @override
  State<FormationScreen> createState() => _FormationScreenState();
}

class _FormationScreenState extends State<FormationScreen> {
  final BookingController _bookingController = Get.find();
  Formation? _currentFormation;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadFormation();
  }

  void _loadFormation() {
    final group = _bookingController.groups.firstWhereOrNull(
      (g) => g.id == widget.groupId,
    );
    if (group?.formation != null) {
      setState(() {
        _currentFormation = Formation.fromMap(group!.formation!);
      });
    } else {
      // Create default 4-4-2 formation
      setState(() {
        _currentFormation = Formation.createDefault();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formation'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.done : Icons.edit),
          ),
        ],
      ),
      body: _currentFormation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Formation selector
                if (_isEditing) _buildFormationSelector(),
                
                // Football pitch
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50), // Grass green
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Pitch markings
                        _buildPitchMarkings(),
                        
                        // Players
                        ..._buildPlayerPositions(),
                      ],
                    ),
                  ),
                ),
                
                // Save button
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomButton(
                      text: 'Save Formation',
                      onPressed: _saveFormation,
                      isLoading: _bookingController.isLoading.value,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFormationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formation Type',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: FormationType.values.map((type) {
              final isSelected = _currentFormation?.type == type;
              return FilterChip(
                label: Text(_getFormationName(type)),
                selected: isSelected,
                onSelected: (_) => _changeFormation(type),
                backgroundColor: Colors.grey[200],
                selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                checkmarkColor: AppColors.primaryGreen,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchMarkings() {
    return CustomPaint(
      size: Size.infinite,
      painter: PitchPainter(),
    );
  }

  List<Widget> _buildPlayerPositions() {
    if (_currentFormation == null) return [];

    return _currentFormation!.playerPositions.entries.map((entry) {
      final playerId = entry.key;
      final position = entry.value;
      
      return Positioned(
        left: position.x,
        top: position.y,
        child: _buildPlayerWidget(playerId, position),
      );
    }).toList();
  }

  Widget _buildPlayerWidget(String playerId, PlayerPosition position) {
    final group = _bookingController.groups.firstWhereOrNull(
      (g) => g.id == widget.groupId,
    );
    
    // Find player name
    String playerName = 'Player';
    if (group != null) {
      final member = group.members.firstWhereOrNull((m) => m.userId == playerId);
      if (member != null) {
        playerName = member.userName.split(' ').first; // First name only
      }
    }

    return GestureDetector(
      onPanUpdate: _isEditing ? (details) => _updatePlayerPosition(playerId, details) : null,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: position.team == TeamSide.home 
              ? AppColors.teamAColor 
              : AppColors.teamBColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            playerName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _changeFormation(FormationType type) {
    setState(() {
      _currentFormation = Formation.createByType(type);
    });
  }

  void _updatePlayerPosition(String playerId, DragUpdateDetails details) {
    if (_currentFormation == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _currentFormation!.playerPositions[playerId] = PlayerPosition(
        playerId: playerId,
        playerName: 'Player', // Default name
        x: localPosition.dx - 25, // Center the player
        y: localPosition.dy - 25,
        team: _currentFormation!.playerPositions[playerId]?.team ?? TeamSide.home,
        role: _currentFormation!.playerPositions[playerId]?.role ?? PlayerRole.midfielder,
      );
    });
  }

  Future<void> _saveFormation() async {
    if (_currentFormation == null) return;

    try {
      await _bookingController.updateFormation(
        widget.groupId,
        _currentFormation!,
      );
      
      Get.snackbar(
        'Success',
        'Formation saved successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save formation: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _getFormationName(FormationType type) {
    switch (type) {
      case FormationType.f442:
        return '4-4-2';
      case FormationType.f433:
        return '4-3-3';
      case FormationType.f352:
        return '3-5-2';
      case FormationType.f343:
        return '3-4-3';
      case FormationType.f541:
        return '5-4-1';
    }
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Outer boundary
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
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
      paint..style = PaintingStyle.fill,
    );

    paint.style = PaintingStyle.stroke;

    // Goal areas (top)
    final goalAreaWidth = size.width * 0.3;
    final goalAreaHeight = size.height * 0.1;
    
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        0,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );

    // Goal areas (bottom)
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        size.height - goalAreaHeight,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );

    // Penalty areas (top)
    final penaltyAreaWidth = size.width * 0.5;
    final penaltyAreaHeight = size.height * 0.2;
    
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyAreaWidth) / 2,
        0,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Penalty areas (bottom)
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyAreaWidth) / 2,
        size.height - penaltyAreaHeight,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Penalty spots
    canvas.drawCircle(
      Offset(size.width / 2, penaltyAreaHeight * 0.6),
      3,
      paint..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height - penaltyAreaHeight * 0.6),
      3,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
