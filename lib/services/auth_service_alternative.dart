import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';

/// Alternative Firebase Authentication Service
/// This version handles the PigeonUserDetails type casting issue
class AuthServiceAlternative {
  static final AuthServiceAlternative _instance = AuthServiceAlternative._internal();
  factory AuthServiceAlternative() => _instance;
  AuthServiceAlternative._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  
  /// Get or create Google Sign-In instance
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
      signInOption: SignInOption.standard,
    );
    return _googleSignIn!;
  }
  
  /// Initialize Google Sign-In with proper configuration
  void initialize() {
    // Just access googleSignIn to ensure it's created
    googleSignIn;
  }
  
  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google - Alternative implementation
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Start the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.failure('Sign in was cancelled');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Validate tokens
      if (googleAuth.accessToken == null) {
        return AuthResult.failure('Failed to get access token');
      }
      
      if (googleAuth.idToken == null) {
        return AuthResult.failure('Failed to get ID token');
      }

      // Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        return AuthResult.failure('Authentication failed');
      }

      return AuthResult.success(data: userCredential.user);
      
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      return AuthResult.failure(_getAuthErrorMessage(e));
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Exception during Google Sign-In: $e');
      }
      
      // Handle specific known issues
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('pigeonuserdetails') || 
          errorString.contains('type cast') ||
          errorString.contains('subtype')) {
        return AuthResult.failure('Google Sign-In service error. Please try restarting the app.');
      }
      
      return AuthResult.failure('Sign-in failed: Please try again');
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error: $e');
      }
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign out
  Future<AuthResult> signOut() async {
    try {
      await Future.wait([
        googleSignIn.signOut(),
        _auth.signOut(),
      ]);
      return AuthResult.success();
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      return AuthResult.failure('Failed to sign out');
    }
  }

  /// Delete user account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user is currently signed in');
      }

      // Re-authenticate before deletion
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Re-authentication cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      await user.delete();
      await googleSignIn.signOut();

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      if (kDebugMode) {
        print('Delete account error: $e');
      }
      return AuthResult.failure('Failed to delete account');
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Get user-friendly error messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
