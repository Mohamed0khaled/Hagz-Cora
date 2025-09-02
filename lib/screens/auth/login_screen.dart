import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/google_logo.dart';
import '../homescreen.dart';

/// Login Screen with Google Sign-In
/// First screen shown to unauthenticated users
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Listen to auth state changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAuthStateChange(authProvider);
            });

            return Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon/Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(AppConstants.radiusExtraLarge),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                        const Text(
                          'Welcome to HagzCoora',
                          style: AppConstants.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        Text(
                          'Your ultimate football companion app',
                          style: AppConstants.bodyLarge.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Sign-in section
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: authProvider.isLoading ? null : _signInWithGoogle,
                            icon: authProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const GoogleLogoWidget(size: 24),
                            label: Text(
                              authProvider.isLoading 
                                  ? 'Signing in...' 
                                  : 'Sign in with Google',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.googleColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                              ),
                              elevation: 2,
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
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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

                        const Spacer(),

                        // Terms and privacy policy
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                          child: Text(
                            'By signing in, you agree to our Terms of Service and Privacy Policy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Sign in with Google
  void _signInWithGoogle() {
    context.read<AuthProvider>().signInWithGoogle();
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
    // Error is handled in the UI through error property
  }
}
