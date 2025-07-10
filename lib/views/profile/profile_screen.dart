import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/friend_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find();
  final FriendController _friendController = Get.find();
  final BookingController _bookingController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/notification-settings'),
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: Obx(() {
        final user = _authController.userModel;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile header
              _buildProfileHeader(user),
              
              const SizedBox(height: 24),
              
              // Stats cards
              _buildStatsSection(),
              
              const SizedBox(height: 24),
              
              // Menu options
              _buildMenuSection(),
              
              const SizedBox(height: 32),
              
              // Sign out button
              CustomButton(
                text: 'Sign Out',
                onPressed: _showSignOutDialog,
                backgroundColor: AppColors.red,
              ),
              
              const SizedBox(height: 16),
              
              // Delete account button
              CustomOutlinedButton(
                text: 'Delete Account',
                onPressed: _showDeleteAccountDialog,
                borderColor: AppColors.red,
                textColor: AppColors.red,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.profilePictureUrl != null
                      ? NetworkImage(user.profilePictureUrl!)
                      : null,
                  backgroundColor: AppColors.lightGrey,
                  child: user.profilePictureUrl == null
                      ? Text(
                          user.displayName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      onPressed: _editProfilePicture,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Name and username
            Text(
              user.displayName,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Edit button
            CustomOutlinedButton(
              text: 'Edit Profile',
              onPressed: _editProfile,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Friends',
            '${_friendController.friends.length}',
            Icons.group,
            AppColors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Groups',
            '${_bookingController.userGroups.length}',
            Icons.sports_soccer,
            AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Matches',
            '${_bookingController.userGroups.where((g) => g.isActive).length}',
            Icons.event,
            AppColors.teamAColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(color: color),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.notifications,
          title: 'Notification Settings',
          subtitle: 'Manage your notification preferences',
          onTap: () => Get.toNamed('/notification-settings'),
        ),
        _buildMenuItem(
          icon: Icons.language,
          title: 'Language',
          subtitle: 'English',
          onTap: _showLanguageSelector,
        ),
        _buildMenuItem(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: _showHelpDialog,
        ),
        _buildMenuItem(
          icon: Icons.info,
          title: 'About',
          subtitle: 'App version and information',
          onTap: _showAboutDialog,
        ),
        _buildMenuItem(
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: _showPrivacyPolicy,
        ),
        _buildMenuItem(
          icon: Icons.description,
          title: 'Terms of Service',
          subtitle: 'Read our terms of service',
          onTap: _showTermsOfService,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(title, style: AppTextStyles.bodyMedium),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _editProfilePicture() {
    Get.snackbar(
      'Coming Soon',
      'Profile picture editing will be available soon',
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
    );
  }

  void _editProfile() {
    Get.snackbar(
      'Coming Soon',
      'Profile editing will be available soon',
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
    );
  }

  void _showLanguageSelector() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              trailing: const Icon(Icons.check, color: AppColors.primaryGreen),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Text('🇪🇬'),
              title: const Text('العربية'),
              onTap: () {
                Get.back();
                Get.snackbar('Coming Soon', 'Arabic language support coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For support, please contact us at:\n\n'
          'Email: support@hagzkora.com\n'
          'Phone: +20 123 456 7890\n\n'
          'We\'re here to help with any questions or issues you may have.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('About Hagz Kora'),
        content: const Text(
          'Hagz Kora v1.0.0\n\n'
          'The ultimate football booking app for organizing matches with friends.\n\n'
          'Built with ❤️ in Egypt\n'
          '© 2025 Hagz Kora Team',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Get.snackbar(
      'Coming Soon',
      'Privacy policy will be available soon',
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
    );
  }

  void _showTermsOfService() {
    Get.snackbar(
      'Coming Soon',
      'Terms of service will be available soon',
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
    );
  }

  void _showSignOutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _authController.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showDeleteConfirmationDialog();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final TextEditingController confirmController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type "DELETE" to confirm account deletion:'),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'Type DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (confirmController.text == 'DELETE') {
                Get.back();
                _authController.deleteAccount();
              } else {
                Get.snackbar(
                  'Error',
                  'Please type "DELETE" to confirm',
                  backgroundColor: AppColors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Delete Account', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
