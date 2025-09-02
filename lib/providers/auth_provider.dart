import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../models/user_model.dart';
import '../services/auth_service_alternative.dart';
import '../services/database_service.dart';

/// Authentication Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthServiceAlternative _authService = AuthServiceAlternative();
  final DatabaseService _databaseService = DatabaseService();
  
  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  /// Initialize auth provider and listen to auth state changes
  void initialize() {
    if (_isInitialized) return; // Prevent multiple initializations
    
    // Check current auth state immediately
    _user = _authService.currentUser;
    if (_user != null) {
      // Start loading user profile but don't wait for it
      _ensureUserProfile(_user!);
    }
    _isInitialized = true;
    notifyListeners();
    
    // Listen for auth state changes
    _authService.authStateChanges.listen((User? user) async {
      if (_user?.uid != user?.uid) { // Only update if user actually changed
        _user = user;
        if (user != null) {
          await _ensureUserProfile(user);
        } else {
          _userProfile = null;
        }
        notifyListeners();
      }
    });
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.success) {
        _user = result.data as User;
        
        // Ensure user profile exists in Firestore
        await _ensureUserProfile(_user!);
      } else {
        _setError(result.errorMessage!);
      }
    } catch (e) {
      _setError('Failed to sign in: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    _setLoading(true);
    try {
      final result = await _authService.signOut();
      if (result.success) {
        _user = null;
        _userProfile = null;
        _clearError();
      } else {
        _setError(result.errorMessage!);
      }
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    File? profileImage,
  }) async {
    if (_user == null) {
      _setError('No authenticated user');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // First check if user profile exists, create if not
      final profileExists = await _databaseService.userProfileExists(_user!.uid);
      
      if (!profileExists) {
        // Create user profile if it doesn't exist
        await _createUserProfileFromGoogle(_user!);
      }

      final result = await _databaseService.updateUserProfile(
        uid: _user!.uid,
        displayName: displayName,
        profileImage: profileImage,
      );

      if (result.success) {
        _userProfile = result.data as UserModel;
      } else {
        _setError(result.errorMessage!);
      }
    } catch (e) {
      _setError('Failed to update profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    if (_user == null) {
      _setError('No authenticated user');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Delete user profile from Firestore
      final deleteProfileResult = await _databaseService.deleteUserProfile(_user!.uid);
      if (!deleteProfileResult.success) {
        _setError(deleteProfileResult.errorMessage!);
        return;
      }

      // Delete Firebase Auth account
      final deleteAuthResult = await _authService.deleteAccount();
      if (deleteAuthResult.success) {
        _user = null;
        _userProfile = null;
        _clearError();
      } else {
        _setError(deleteAuthResult.errorMessage!);
      }
    } catch (e) {
      _setError('Failed to delete account: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create user profile from Google account data
  Future<void> _createUserProfileFromGoogle(User user) async {
    try {
      final userModel = UserModel.fromFirebaseUser(
        user.uid,
        user.email ?? '',
        user.displayName ?? 'User',
        user.photoURL,
      );

      final result = await _databaseService.createUserProfile(userModel);
      if (result.success) {
        _userProfile = result.data as UserModel;
      }
    } catch (e) {
      debugPrint('Failed to create user profile from Google: $e');
    }
  }

  /// Ensure user profile exists, create if necessary
  Future<void> _ensureUserProfile(User user) async {
    try {
      // Try to load existing profile
      final result = await _databaseService.getUserProfile(user.uid);
      if (result.success) {
        _userProfile = result.data as UserModel;
        notifyListeners(); // Notify when profile is loaded
      } else {
        // Profile doesn't exist, create it
        debugPrint('User profile not found, creating new profile');
        await _createUserProfileFromGoogle(user);
        notifyListeners(); // Notify when profile is created
      }
    } catch (e) {
      debugPrint('Failed to ensure user profile: $e');
      // Try to create profile as fallback
      await _createUserProfileFromGoogle(user);
      notifyListeners(); // Notify even if there was an error
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get user's display name with fallback
  String get displayName {
    return _userProfile?.displayName ?? 
           _user?.displayName ?? 
           _user?.email?.split('@').first ?? 
           'User';
  }

  /// Get user's photo URL
  String? get photoURL => _userProfile?.photoURL ?? _user?.photoURL;

  /// Get user's email
  String get email => _userProfile?.email ?? _user?.email ?? '';
}
