import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _authController = Get.find<AuthController>();

  // Form controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  // Form keys
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.paddingXLarge),
              
              // App Logo and Title
              _buildHeader(),
              
              const SizedBox(height: AppDimensions.paddingXLarge),
              
              // Tab Bar
              _buildTabBar(),
              
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Tab Bar View
              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSignInForm(),
                    _buildSignUpForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sports_soccer,
            size: 40,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Text(
          AppStrings.welcome,
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.grey,
        tabs: const [
          Tab(text: AppStrings.signIn),
          Tab(text: AppStrings.signUp),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _signInEmailController,
            label: AppStrings.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!GetUtils.isEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          CustomTextField(
            controller: _signInPasswordController,
            label: AppStrings.password,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text(AppStrings.forgotPassword),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          
          Obx(() => CustomButton(
            text: AppStrings.signIn,
            onPressed: _authController.isLoading ? null : _signIn,
            isLoading: _authController.isLoading,
          )),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          const Text('OR', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          Obx(() => CustomButton(
            text: AppStrings.signInWithGoogle,
            onPressed: _authController.isLoading ? null : _signInWithGoogle,
            isLoading: _authController.isLoading,
            backgroundColor: AppColors.white,
            textColor: AppColors.black,
            icon: Icons.login,
          )),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _signUpEmailController,
            label: AppStrings.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!GetUtils.isEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          CustomTextField(
            controller: _signUpPasswordController,
            label: AppStrings.password,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          CustomTextField(
            controller: _signUpConfirmPasswordController,
            label: AppStrings.confirmPassword,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _signUpPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          
          Obx(() => CustomButton(
            text: AppStrings.signUp,
            onPressed: _authController.isLoading ? null : _signUp,
            isLoading: _authController.isLoading,
          )),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          const Text('OR', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          Obx(() => CustomButton(
            text: AppStrings.signInWithGoogle,
            onPressed: _authController.isLoading ? null : _signInWithGoogle,
            isLoading: _authController.isLoading,
            backgroundColor: AppColors.white,
            textColor: AppColors.black,
            icon: Icons.login,
          )),
        ],
      ),
    );
  }

  void _signIn() {
    if (_signInFormKey.currentState!.validate()) {
      _authController.signInWithEmailAndPassword(
        _signInEmailController.text.trim(),
        _signInPasswordController.text,
      );
    }
  }

  void _signUp() {
    if (_signUpFormKey.currentState!.validate()) {
      _authController.createUserWithEmailAndPassword(
        _signUpEmailController.text.trim(),
        _signUpPasswordController.text,
      );
    }
  }

  void _signInWithGoogle() {
    _authController.signInWithGoogle();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link'),
            const SizedBox(height: AppDimensions.paddingMedium),
            CustomTextField(
              controller: emailController,
              label: AppStrings.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _authController.sendPasswordResetEmail(emailController.text.trim());
                Get.back();
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
