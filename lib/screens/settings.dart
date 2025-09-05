import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'profile_settings_screen.dart';
import 'auth/login_screen.dart';

/// Settings Screen
/// Comprehensive settings page for theme, appearance, and app preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        elevation: 1,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              // Profile Section
              _buildProfileSection(),
              
              // Theme Section
              _buildSectionHeader('Appearance'),
              _buildThemeModeTile(themeProvider),
              _buildPrimaryColorTile(themeProvider),
              _buildFontSizeTile(themeProvider),
              
              const SizedBox(height: 16),
              
              // App Settings Section
              _buildSectionHeader('App Settings'),
              _buildNotificationsTile(themeProvider),
              _buildSoundTile(themeProvider),
              _buildVibrationTile(themeProvider),
              _buildLanguageTile(themeProvider),
              
              const SizedBox(height: 16),
              
              // Football Settings
              _buildSectionHeader('Football Preferences'),
              _buildFootballSettings(),
              
              const SizedBox(height: 16),
              
              // Privacy & About
              _buildSectionHeader('Privacy & About'),
              _buildPrivacySettings(),
              
              const SizedBox(height: 16),
              
              // Actions Section
              _buildSectionHeader('Actions'),
              _buildResetTile(themeProvider),
              _buildAccountActions(),
              
              const SizedBox(height: 32),
              
              // App Info
              _buildAppInfo(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              backgroundImage: authProvider.photoURL != null && authProvider.photoURL!.isNotEmpty
                  ? NetworkImage(authProvider.photoURL!)
                  : null,
              child: authProvider.photoURL == null || authProvider.photoURL!.isEmpty
                  ? Text(
                      authProvider.displayName.isNotEmpty 
                          ? authProvider.displayName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            title: Text(
              authProvider.displayName.isNotEmpty 
                  ? authProvider.displayName 
                  : 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(authProvider.email),
            trailing: const Icon(Icons.edit),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeModeTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          themeProvider.isDarkMode 
              ? Icons.dark_mode 
              : themeProvider.isLightMode 
                  ? Icons.light_mode 
                  : Icons.auto_mode,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Theme Mode'),
        subtitle: Text(themeProvider.getThemeDescription()),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showThemeModeDialog(themeProvider),
      ),
    );
  }

  Widget _buildPrimaryColorTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        title: const Text('Primary Color'),
        subtitle: const Text('Choose your app theme color'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showColorPicker(themeProvider),
      ),
    );
  }

  Widget _buildFontSizeTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.text_fields,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Font Size'),
        subtitle: Text(themeProvider.getFontSizeDescription()),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showFontSizeDialog(themeProvider),
      ),
    );
  }

  Widget _buildNotificationsTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(
          Icons.notifications,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Notifications'),
        subtitle: const Text('Receive push notifications'),
        value: themeProvider.notificationsEnabled,
        onChanged: (value) => themeProvider.setNotificationsEnabled(value),
      ),
    );
  }

  Widget _buildSoundTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(
          themeProvider.soundEnabled ? Icons.volume_up : Icons.volume_off,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Sound'),
        subtitle: const Text('Play notification sounds'),
        value: themeProvider.soundEnabled,
        onChanged: (value) => themeProvider.setSoundEnabled(value),
      ),
    );
  }

  Widget _buildVibrationTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(
          Icons.vibration,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Vibration'),
        subtitle: const Text('Vibrate on notifications'),
        value: themeProvider.vibrationEnabled,
        onChanged: (value) => themeProvider.setVibrationEnabled(value),
      ),
    );
  }

  Widget _buildLanguageTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.language,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Language'),
        subtitle: Text(_getLanguageName(themeProvider.languageCode)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLanguageDialog(themeProvider),
      ),
    );
  }

  Widget _buildFootballSettings() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.person_pin,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Preferred Position'),
            subtitle: const Text('Set your favorite playing position'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPositionDialog(),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.trending_up,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Playing Level'),
            subtitle: const Text('Set your skill level'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSkillLevelDialog(),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.schedule,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Preferred Match Time'),
            subtitle: const Text('Set your preferred playing hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimePreferenceDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Read our privacy policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Terms of Service'),
            subtitle: const Text('Read our terms of service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.help,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildResetTile(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(
          Icons.restore,
          color: Colors.orange,
        ),
        title: const Text('Reset to Default'),
        subtitle: const Text('Reset all settings to default values'),
        onTap: () => _showResetDialog(themeProvider),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.orange,
            ),
            title: const Text('Sign Out'),
            subtitle: const Text('Sign out of your account'),
            onTap: () => _showSignOutDialog(),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account'),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'HagzCoora',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ultimate football companion app',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showThemeModeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Primary Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: ThemeProvider.predefinedColors.length,
            itemBuilder: (context, index) {
              final color = ThemeProvider.predefinedColors[index];
              final isSelected = color == themeProvider.primaryColor;
              
              return GestureDetector(
                onTap: () {
                  themeProvider.setPrimaryColor(color);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected 
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFontSizeOption(themeProvider, 'Small', 0.85),
            _buildFontSizeOption(themeProvider, 'Medium', 1.0),
            _buildFontSizeOption(themeProvider, 'Large', 1.15),
            _buildFontSizeOption(themeProvider, 'Extra Large', 1.3),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(ThemeProvider themeProvider, String label, double scale) {
    final isSelected = (themeProvider.fontSizeScale - scale).abs() < 0.1;
    
    return RadioListTile<double>(
      title: Text(
        label,
        style: TextStyle(fontSize: 16 * scale),
      ),
      subtitle: Text(
        'Sample text preview',
        style: TextStyle(fontSize: 14 * scale),
      ),
      value: scale,
      groupValue: themeProvider.fontSizeScale,
      selected: isSelected,
      onChanged: (value) {
        if (value != null) {
          themeProvider.setFontSizeScale(value);
          Navigator.pop(context);
        }
      },
    );
  }

  void _showLanguageDialog(ThemeProvider themeProvider) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'de', 'name': 'Deutsch'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang['name']!),
              value: lang['code']!,
              groupValue: themeProvider.languageCode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              themeProvider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to default'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut().then((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              });
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().deleteAccount().then((_) {
                final authProvider = context.read<AuthProvider>();
                if (authProvider.error == null) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showPositionDialog() {
    final positions = [
      'Goalkeeper',
      'Defender', 
      'Midfielder',
      'Forward',
      'Any Position'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Preferred Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: positions.map((position) {
            return ListTile(
              leading: Icon(_getPositionIcon(position)),
              title: Text(position),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preferred position set to $position'),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSkillLevelDialog() {
    final levels = [
      'Beginner',
      'Intermediate', 
      'Advanced',
      'Professional'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Skill Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) {
            return ListTile(
              leading: Icon(_getSkillIcon(level)),
              title: Text(level),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Skill level set to $level'),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTimePreferenceDialog() {
    final times = [
      'Morning (6AM - 12PM)',
      'Afternoon (12PM - 6PM)',
      'Evening (6PM - 10PM)', 
      'Night (10PM - 12AM)',
      'Any Time'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Preferred Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: times.map((time) {
            return ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(time),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preferred time set to $time'),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }

  IconData _getPositionIcon(String position) {
    switch (position) {
      case 'Goalkeeper':
        return Icons.sports_volleyball;
      case 'Defender':
        return Icons.shield;
      case 'Midfielder':
        return Icons.swap_horiz;
      case 'Forward':
        return Icons.arrow_upward;
      default:
        return Icons.sports_soccer;
    }
  }

  IconData _getSkillIcon(String level) {
    switch (level) {
      case 'Beginner':
        return Icons.star_border;
      case 'Intermediate':
        return Icons.star_half;
      case 'Advanced':
        return Icons.star;
      case 'Professional':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }
}
