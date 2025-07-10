import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _friendRequestsEnabled = true;
  bool _groupInvitesEnabled = true;
  bool _matchRemindersEnabled = true;
  bool _chatMessagesEnabled = true;
  bool _formationUpdatesEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);
  bool _quietHoursEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Load from shared preferences or user settings
    // Implementation would load saved settings
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Push Notifications'),
          _buildNotificationToggle(
            'Friend Requests',
            'Get notified when someone sends you a friend request',
            _friendRequestsEnabled,
            (value) => setState(() => _friendRequestsEnabled = value),
            Icons.person_add,
          ),
          _buildNotificationToggle(
            'Group Invites',
            'Get notified when you\'re invited to a football match',
            _groupInvitesEnabled,
            (value) => setState(() => _groupInvitesEnabled = value),
            Icons.group_add,
          ),
          _buildNotificationToggle(
            'Match Reminders',
            'Get reminders before your scheduled matches',
            _matchRemindersEnabled,
            (value) => setState(() => _matchRemindersEnabled = value),
            Icons.schedule,
          ),
          _buildNotificationToggle(
            'Chat Messages',
            'Get notified for new messages in group chats',
            _chatMessagesEnabled,
            (value) => setState(() => _chatMessagesEnabled = value),
            Icons.chat,
          ),
          _buildNotificationToggle(
            'Formation Updates',
            'Get notified when team formations are updated',
            _formationUpdatesEnabled,
            (value) => setState(() => _formationUpdatesEnabled = value),
            Icons.sports_soccer,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Sound & Vibration'),
          _buildNotificationToggle(
            'Sound',
            'Play sound for notifications',
            _soundEnabled,
            (value) => setState(() => _soundEnabled = value),
            Icons.volume_up,
          ),
          _buildNotificationToggle(
            'Vibration',
            'Vibrate for notifications',
            _vibrationEnabled,
            (value) => setState(() => _vibrationEnabled = value),
            Icons.vibration,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Quiet Hours'),
          _buildNotificationToggle(
            'Enable Quiet Hours',
            'Silence notifications during specified hours',
            _quietHoursEnabled,
            (value) => setState(() => _quietHoursEnabled = value),
            Icons.bedtime,
          ),
          
          if (_quietHoursEnabled) ...[
            const SizedBox(height: 16),
            _buildTimeSelector(
              'Start Time',
              _quietHoursStart,
              (time) => setState(() => _quietHoursStart = time),
            ),
            const SizedBox(height: 12),
            _buildTimeSelector(
              'End Time',
              _quietHoursEnd,
              (time) => setState(() => _quietHoursEnd = time),
            ),
          ],

          const SizedBox(height: 32),
          CustomButton(
            text: 'Save Settings',
            onPressed: _saveSettings,
          ),
          
          const SizedBox(height: 16),
          CustomOutlinedButton(
            text: 'Test Notification',
            onPressed: _testNotification,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
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
        title: Text(
          title,
          style: AppTextStyles.bodyMedium,
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryGreen,
        ),
        onTap: () => onChanged(!value),
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.access_time,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium,
        ),
        trailing: Text(
          time.format(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primaryGreen,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      // Save settings to shared preferences and/or Firebase
      // Update notification service settings
      await _notificationService.updateNotificationSettings({
        'friendRequests': _friendRequestsEnabled,
        'groupInvites': _groupInvitesEnabled,
        'matchReminders': _matchRemindersEnabled,
        'chatMessages': _chatMessagesEnabled,
        'formationUpdates': _formationUpdatesEnabled,
        'sound': _soundEnabled,
        'vibration': _vibrationEnabled,
        'quietHours': _quietHoursEnabled,
        'quietHoursStart': '${_quietHoursStart.hour}:${_quietHoursStart.minute}',
        'quietHoursEnd': '${_quietHoursEnd.hour}:${_quietHoursEnd.minute}',
      });

      Get.snackbar(
        'Success',
        'Notification settings saved',
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save settings: $e',
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showNotification(
        title: 'Test Notification',
        body: 'This is a test notification from Hagz Kora!',
        payload: 'test',
      );
      
      Get.snackbar(
        'Test Sent',
        'Check your notification panel',
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send test notification: $e',
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    }
  }
}
