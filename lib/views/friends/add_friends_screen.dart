import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controllers/friend_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final FriendController _friendController = Get.find<FriendController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friends'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: CustomSearchField(
              controller: _searchController,
              hint: 'Search by username or ID',
              onChanged: (value) {
                if (value.length >= 2) {
                  _friendController.searchUsers(value);
                } else {
                  _friendController.clearSearchResults();
                }
              },
              onClear: () {
                _searchController.clear();
                _friendController.clearSearchResults();
              },
            ),
          ),
          
          // Search Results
          Expanded(
            child: Obx(() {
              if (_friendController.isSearching) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (_friendController.searchQuery.isEmpty) {
                return _buildSearchInstructions();
              }
              
              if (_friendController.searchResults.isEmpty) {
                return _buildNoResultsFound();
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
                itemCount: _friendController.searchResults.length,
                itemBuilder: (context, index) {
                  final user = _friendController.searchResults[index];
                  return _buildUserCard(user);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInstructions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Search for Friends',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Enter a username or user ID to find friends',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No Users Found',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Try searching with a different username or ID',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isFriend = _friendController.isFriend(user.id);
    final isRequestPending = _friendController.isFriendRequestPending(user.id);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryGreen,
          backgroundImage: user.profilePictureUrl != null
              ? NetworkImage(user.profilePictureUrl!)
              : null,
          child: user.profilePictureUrl == null
              ? Text(
                  user.displayName.isNotEmpty 
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(user.displayName, style: AppTextStyles.bodyLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}', style: AppTextStyles.bodySmall),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.isActive ? Colors.green : AppColors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  user.isActive ? 'Active' : 'Away',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: user.isActive ? Colors.green : AppColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildActionButton(user, isFriend, isRequestPending),
      ),
    );
  }

  Widget _buildActionButton(UserModel user, bool isFriend, bool isRequestPending) {
    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Text(
          'Friends',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isRequestPending) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Text(
          'Pending',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!user.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Text(
          'Away',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _friendController.sendFriendRequest(user.id),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        minimumSize: const Size(80, 32),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      ),
      child: const Text('Add'),
    );
  }
}
