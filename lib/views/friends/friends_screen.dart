import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controllers/friend_controller.dart';
import '../../models/user_model.dart';
import '../../models/friend_request.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FriendController friendController = Get.find<FriendController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.friends),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Get.toNamed('/add-friends'),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Friends'),
                Tab(text: 'Requests'),
              ],
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primaryGreen,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFriendsTab(friendController),
                  _buildRequestsTab(friendController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab(FriendController friendController) {
    return Obx(() {
      if (friendController.friends.isEmpty) {
        return _buildEmptyFriendsState();
      }

      return RefreshIndicator(
        onRefresh: () => friendController.refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          itemCount: friendController.friends.length,
          itemBuilder: (context, index) {
            final friend = friendController.friends[index];
            return _buildFriendCard(friend, friendController);
          },
        ),
      );
    });
  }

  Widget _buildRequestsTab(FriendController friendController) {
    return Obx(() {
      if (friendController.pendingRequests.isEmpty) {
        return _buildEmptyRequestsState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: friendController.pendingRequests.length,
        itemBuilder: (context, index) {
          final request = friendController.pendingRequests[index];
          return _buildRequestCard(request, friendController);
        },
      );
    });
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No Friends Yet',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Add friends to start creating matches together!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/add-friends'),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friends'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_disabled,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No Friend Requests',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'When someone sends you a friend request, it will appear here.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(UserModel friend, FriendController friendController) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryGreen,
          backgroundImage: friend.profilePictureUrl != null
              ? NetworkImage(friend.profilePictureUrl!)
              : null,
          child: friend.profilePictureUrl == null
              ? Text(
                  friend.displayName.isNotEmpty 
                      ? friend.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(friend.displayName, style: AppTextStyles.bodyLarge),
        subtitle: Row(
          children: [
            Text('@${friend.username}', style: AppTextStyles.bodySmall),
            const SizedBox(width: AppDimensions.paddingSmall),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: friend.isActive ? Colors.green : AppColors.grey,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              friend.isActive ? 'Active' : 'Away',
              style: AppTextStyles.bodySmall.copyWith(
                color: friend.isActive ? Colors.green : AppColors.grey,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              _showRemoveFriendDialog(friend, friendController);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: AppColors.red),
                  SizedBox(width: AppDimensions.paddingSmall),
                  Text('Remove Friend'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request, FriendController friendController) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryGreen,
          backgroundImage: request.senderPhotoUrl != null
              ? NetworkImage(request.senderPhotoUrl!)
              : null,
          child: request.senderPhotoUrl == null
              ? Text(
                  request.senderName.isNotEmpty 
                      ? request.senderName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(request.senderName, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          'Wants to be your friend',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => friendController.acceptFriendRequest(request),
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'Accept',
            ),
            IconButton(
              onPressed: () => friendController.declineFriendRequest(request),
              icon: const Icon(Icons.close, color: AppColors.red),
              tooltip: 'Decline',
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFriendDialog(UserModel friend, FriendController friendController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.displayName} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              friendController.removeFriend(friend.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
