import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setupProfile),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.paddingLarge),
                
                // Profile Picture Section
                _buildProfilePictureSection(),
                
                const SizedBox(height: AppDimensions.paddingXLarge),
                
                // Username Field
                CustomTextField(
                  controller: _usernameController,
                  label: AppStrings.chooseUsername,
                  hint: 'e.g. john_doe',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                // Display Name Field
                CustomTextField(
                  controller: _displayNameController,
                  label: AppStrings.displayName,
                  hint: 'e.g. John Doe',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    if (value.length < 2) {
                      return 'Display name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppDimensions.paddingXLarge),
                
                // Setup Button
                Obx(() => CustomButton(
                  text: 'Complete Setup',
                  onPressed: _authController.isLoading ? null : _setupProfile,
                  isLoading: _authController.isLoading,
                )),
                
                const SizedBox(height: AppDimensions.paddingMedium),
                
                // Skip Button
                TextButton(
                  onPressed: () => _setupProfile(skipPhoto: true),
                  child: const Text(AppStrings.skipForNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Text(
          AppStrings.uploadPhoto,
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        GestureDetector(
          onTap: _showImagePicker,
          child: Container(
            width: AppDimensions.avatarSizeXLarge,
            height: AppDimensions.avatarSizeXLarge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightGrey,
              border: Border.all(
                color: AppColors.primaryGreen,
                width: 3,
              ),
            ),
            child: _selectedImage != null
                ? ClipOval(
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: AppDimensions.avatarSizeXLarge,
                      height: AppDimensions.avatarSizeXLarge,
                    ),
                  )
                : const Icon(
                    Icons.add_a_photo,
                    size: AppDimensions.iconSizeLarge,
                    color: AppColors.grey,
                  ),
          ),
        ),
        
        const SizedBox(height: AppDimensions.paddingSmall),
        
        Text(
          'Tap to ${_selectedImage != null ? 'change' : 'add'} photo',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  void _showImagePicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Profile Picture',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            
            Row(
              children: [
                Expanded(
                  child: CustomOutlinedButton(
                    text: 'Camera',
                    icon: Icons.camera_alt,
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: CustomOutlinedButton(
                    text: 'Gallery',
                    icon: Icons.photo_library,
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            
            if (_selectedImage != null) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              CustomOutlinedButton(
                text: 'Remove Photo',
                icon: Icons.delete,
                borderColor: AppColors.red,
                textColor: AppColors.red,
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                  Get.back();
                },
              ),
            ],
            
            const SizedBox(height: AppDimensions.paddingMedium),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
      
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  void _setupProfile({bool skipPhoto = false}) {
    if (_formKey.currentState!.validate()) {
      String? profilePictureUrl;
      
      // In a real app, you would upload the image to Firebase Storage
      // and get the download URL here
      if (_selectedImage != null && !skipPhoto) {
        // TODO: Upload image to Firebase Storage
        // profilePictureUrl = await uploadImageToStorage(_selectedImage!);
      }
      
      _authController.setupUserProfile(
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        profilePictureUrl: profilePictureUrl,
      );
    }
  }
}
