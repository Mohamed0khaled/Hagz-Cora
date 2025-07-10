import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/friend_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/booking_group.dart';
import '../../models/user_model.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_button.dart';

class InvitePlayersScreen extends StatefulWidget {
  final String groupId;

  const InvitePlayersScreen({super.key, required this.groupId});

  @override
  State<InvitePlayersScreen> createState() => _InvitePlayersScreenState();
}

class _InvitePlayersScreenState extends State<InvitePlayersScreen> {
  final BookingController _bookingController = Get.find();
  final FriendController _friendController = Get.find();
  final AuthController _authController = Get.find();
  
  BookingGroup? _group;
  List<UserModel> _availableFriends = [];
  List<String> _selectedPlayerIds = [];
  String _selectedTeam = 'A'; // Default team A

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _group = _bookingController.getGroupById(widget.groupId);
    if (_group != null) {
      // For now, get friends from FriendController since getInvitableFriends doesn't exist yet
      final allFriends = _friendController.friends;
      _availableFriends = allFriends.where((friend) => 
        !_group!.playerIds.contains(friend.id) && 
        !_group!.invitedPlayerIds.contains(friend.id)
      ).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Players'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPlayerIds.isNotEmpty)
            TextButton(
              onPressed: _inviteSelectedPlayers,
              child: const Text(
                'INVITE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _group == null
          ? const Center(child: Text('Group not found'))
          : Column(
              children: [
                // Team selection (for dual admin groups)
                if (_group!.isDuelAdmins) _buildTeamSelector(),
                
                // Group info
                _buildGroupInfo(),
                
                // Available friends list
                Expanded(
                  child: _buildFriendsList(),
                ),
                
                // Invite button
                if (_selectedPlayerIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: CustomButton(
                      text: 'Invite ${_selectedPlayerIds.length} Player${_selectedPlayerIds.length > 1 ? 's' : ''}',
                      onPressed: _inviteSelectedPlayers,
                      isLoading: _bookingController.isLoading.value,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTeamSelector() {
    final currentUserId = _authController.userModel?.id ?? '';
    final isAdmin = _group!.adminId == currentUserId;
    final isOpponentAdmin = _group!.opponentAdminId == currentUserId;
    
    if (!isAdmin && !isOpponentAdmin) {
      return const SizedBox(); // Not an admin, no team selection
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Team',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTeamOption(
                  'Team A',
                  'A',
                  AppColors.teamAColor,
                  isAdmin,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTeamOption(
                  'Team B',
                  'B',
                  AppColors.teamBColor,
                  isOpponentAdmin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOption(String title, String teamId, Color color, bool isUserTeam) {
    final isSelected = _selectedTeam == teamId;
    final canSelect = isUserTeam; // Can only select their own team
    
    return GestureDetector(
      onTap: canSelect ? () => setState(() => _selectedTeam = teamId) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppColors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: canSelect ? color : AppColors.grey,
              ),
            ),
            Text(
              isUserTeam ? 'Your Team' : 'Opponent Team',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.lightGrey,
      child: Row(
        children: [
          Icon(Icons.group, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _group!.name,
                  style: AppTextStyles.heading3,
                ),
                Text(
                  '${_group!.playerIds.length}/${_group!.maxPlayersPerTeam * 2} players',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _group!.matchType.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_availableFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No friends available to invite',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Add more friends to invite them to your games',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableFriends.length,
      itemBuilder: (context, index) {
        final friend = _availableFriends[index];
        final isSelected = _selectedPlayerIds.contains(friend.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: friend.profilePictureUrl != null
                  ? NetworkImage(friend.profilePictureUrl!)
                  : null,
              backgroundColor: AppColors.lightGrey,
              child: friend.profilePictureUrl == null
                  ? Text(
                      friend.displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : null,
            ),
            title: Text(
              friend.displayName,
              style: AppTextStyles.bodyMedium,
            ),
            subtitle: Text(
              '@${friend.username}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedPlayerIds.add(friend.id);
                  } else {
                    _selectedPlayerIds.remove(friend.id);
                  }
                });
              },
              activeColor: AppColors.primaryGreen,
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedPlayerIds.remove(friend.id);
                } else {
                  _selectedPlayerIds.add(friend.id);
                }
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _inviteSelectedPlayers() async {
    if (_selectedPlayerIds.isEmpty) return;

    try {
      for (final playerId in _selectedPlayerIds) {
        await _bookingController.invitePlayer(
          widget.groupId,
          playerId,
          _selectedTeam,
        );
      }

      Get.back();
      Get.snackbar(
        'Success',
        'Invited ${_selectedPlayerIds.length} player${_selectedPlayerIds.length > 1 ? 's' : ''}',
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to invite players: $e',
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    }
  }
}
