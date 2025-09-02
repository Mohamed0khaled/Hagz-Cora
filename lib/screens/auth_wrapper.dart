import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'homescreen.dart';

/// Authentication Wrapper
/// Decides which screen to show based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Initialize auth provider on first build
        if (!authProvider.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.initialize();
          });
          // Show loading while initializing
          return const LoadingScreen();
        }

        // Show loading while authentication is being processed
        if (authProvider.isLoading) {
          return const LoadingScreen();
        }

        // Show error message if there's an error
        if (authProvider.error != null) {
          return const LoginScreen();
        }

        // Show appropriate screen based on authentication status
        if (authProvider.isAuthenticated) {
          return HomePage();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// Loading Screen
/// Shown while authentication state is being determined
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
