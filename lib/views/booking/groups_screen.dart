import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/booking_group.dart';
import '../../utils/date_time_utils.dart';
import '../../widgets/custom_button.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingController bookingController = Get.find<BookingController>();
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (bookingController.userGroups.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => bookingController.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            itemCount: bookingController.userGroups.length,
            itemBuilder: (context, index) {
              final group = bookingController.userGroups[index];
              return _buildGroupCard(group, authController.userModel?.id);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No Matches Yet',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Create your first match to get started!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: 'Create Match',
            onPressed: () => Get.toNamed('/create-booking'),
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BookingGroup group, String? currentUserId) {
    final isAdmin = group.adminId == currentUserId;
    final isOpponentAdmin = group.opponentAdminId == currentUserId;
    final timeUntilMatch = DateTimeUtils.getTimeUntil(group.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: InkWell(
        onTap: () => Get.toNamed('/group-chat', arguments: group.id),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: AppDimensions.paddingSmall),
                        Text(
                          _getMatchTypeText(group.matchType),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Text(
                        'Admin',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (isOpponentAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Text(
                        'Captain',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: AppDimensions.iconSizeSmall,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Text(
                    DateTimeUtils.formatDate(group.matchDate),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Icon(
                    Icons.access_time,
                    size: AppDimensions.iconSizeSmall,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Text(
                    '${DateTimeUtils.formatTime(group.startTime)} - ${DateTimeUtils.formatTime(group.endTime)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              
              if (group.stadiumName != null) ...[
                const SizedBox(height: AppDimensions.paddingSmall),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: AppDimensions.iconSizeSmall,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Text(
                      group.stadiumName!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: AppDimensions.iconSizeSmall,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: AppDimensions.paddingSmall),
                        Text(
                          '${group.playerIds.length}/${group.isDuelAdmins ? group.maxPlayersPerTeam * 2 : group.maxPlayersPerTeam} players',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeUntilMatch,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: timeUntilMatch == 'Past' ? AppColors.red : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Chat',
                      onPressed: () => Get.toNamed('/group-chat', arguments: group.id),
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: CustomButton(
                      text: 'Formation',
                      onPressed: () => Get.toNamed('/formation', arguments: group.id),
                      backgroundColor: AppColors.blue,
                      height: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMatchTypeText(MatchType matchType) {
    switch (matchType) {
      case MatchType.fiveAside:
        return '5-a-side';
      case MatchType.sevenAside:
        return '7-a-side';
      case MatchType.tenAside:
        return '10-a-side';
    }
  }
}
