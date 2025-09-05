import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/validators.dart' as format_utils;
import 'auth/login_screen.dart';

/// Profile Settings Screen
/// Allows users to update their display name and profile picture
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeProfile() {
    final authProvider = context.read<AuthProvider>();
    _displayNameController.text = authProvider.displayName;
    _displayNameController.addListener(_onDisplayNameChanged);
  }

  void _onDisplayNameChanged() {
    final authProvider = context.read<AuthProvider>();
    final hasDisplayNameChanged =
        _displayNameController.text != authProvider.displayName;
    final hasImageChanged = _selectedImage != null;

    setState(() {
      _hasChanges = hasDisplayNameChanged || hasImageChanged;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 28,
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'signOut') {
                    _showSignOutDialog();
                  } else if (value == 'deleteAccount') {
                    _showDeleteAccountDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'signOut',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'deleteAccount',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: AppConstants.errorColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Account',
                          style: TextStyle(color: AppConstants.errorColor),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppConstants.primaryColor.withOpacity(
                          0.1,
                        ),
                        backgroundImage: _getProfileImage(authProvider),
                        child: _getProfileImage(authProvider) == null
                            ? Text(
                                format_utils.FormatUtils.getInitials(
                                  authProvider.displayName,
                                ),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      // Camera Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: authProvider.isLoading
                                ? null
                                : _selectImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Display Name Field
                TextFormField(
                  controller: _displayNameController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  enabled: !authProvider.isLoading,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: AppConstants.surfaceColor,
                  ),
                  validator: Validators.validateDisplayName,
                  onFieldSubmitted: (_) => _saveProfile(),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Email Display (Read-only)
                TextFormField(
                  initialValue: authProvider.email,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (authProvider.isLoading || !_hasChanges)
                        ? null
                        : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: AppConstants.labelLarge(context),
                          ),
                  ),
                ),

                // Error message display
                if (authProvider.error != null) ...[
                  const SizedBox(height: AppConstants.paddingMedium),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppConstants.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppConstants.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(
                              color: AppConstants.errorColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Get profile image to display
  ImageProvider? _getProfileImage(AuthProvider authProvider) {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (authProvider.photoURL != null &&
        authProvider.photoURL!.isNotEmpty) {
      return NetworkImage(authProvider.photoURL!);
    }
    return null;
  }

  /// Select image from gallery
  Future<void> _selectImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Check file size
        final fileSize = await file.length();
        if (fileSize > AppConstants.maxImageSizeBytes) {
          if (mounted) {
            UIUtils.showSnackBar(
              context,
              'Image size must be less than ${format_utils.FormatUtils.formatFileSize(AppConstants.maxImageSizeBytes)}',
              isError: true,
            );
          }
          return;
        }

        setState(() {
          _selectedImage = file;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showSnackBar(
          context,
          'Failed to select image: $e',
          isError: true,
        );
      }
    }
  }

  /// Save profile changes
  void _saveProfile() {
    // Dismiss keyboard
    _focusNode.unfocus();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if there are changes to save
    if (!_hasChanges) {
      UIUtils.showSnackBar(context, 'No changes to save');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final displayName = _displayNameController.text.trim();

    // Save profile
    authProvider
        .updateUserProfile(
          displayName: displayName != authProvider.displayName
              ? displayName
              : null,
          profileImage: _selectedImage,
        )
        .then((_) {
          if (authProvider.error == null) {
            setState(() {
              _selectedImage = null;
              _hasChanges = false;
            });
            UIUtils.showSnackBar(context, 'Profile updated successfully');
          }
        });
  }

  /// Show sign out confirmation dialog
  void _showSignOutDialog() {
    UIUtils.showConfirmationDialog(
      context,
      'Sign Out',
      'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<AuthProvider>().signOut().then((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        });
      }
    });
  }

  /// Show delete account confirmation dialog
  void _showDeleteAccountDialog() {
    UIUtils.showConfirmationDialog(
      context,
      'Delete Account',
      'Are you sure you want to delete your account? This action cannot be undone.',
      confirmText: 'Delete',
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<AuthProvider>().deleteAccount().then((_) {
          final authProvider = context.read<AuthProvider>();
          if (authProvider.error == null) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
            UIUtils.showSnackBar(context, 'Account deleted successfully');
          }
        });
      }
    });
  }
}
