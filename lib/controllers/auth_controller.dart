import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Observables
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  User? get firebaseUser => _firebaseUser.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isLoggedIn => _firebaseUser.value != null && _userModel.value != null;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _firebaseUser.bindStream(_authService.authStateChanges);
    
    // Listen to user changes and update user model
    ever(_firebaseUser, _handleAuthChanged);
    
    // Initialize notifications
    _notificationService.initialize();
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (user != null) {
      // User signed in, get user profile
      try {
        UserModel? userProfile = await _authService.getUserProfile(user.uid);
        _userModel.value = userProfile;
        
        if (userProfile != null) {
          // Update last seen
          await _authService.updateActiveStatus(true);
          Get.offAllNamed('/main');
        } else {
          // User exists but no profile, redirect to profile setup
          Get.offAllNamed('/profile-setup');
        }
      } catch (e) {
        _errorMessage.value = e.toString();
      }
    } else {
      // User signed out
      _userModel.value = null;
      Get.offAllNamed('/auth');
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Create user with email and password
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      
      await _authService.createUserWithEmailAndPassword(email, password);
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      
      await _authService.signInWithGoogle();
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Setup user profile
  Future<void> setupUserProfile({
    required String username,
    required String displayName,
    String? profilePictureUrl,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      User? user = _authService.currentUser;
      if (user == null) throw Exception('No user found');

      // Check if username is available
      bool isAvailable = await _authService.isUsernameAvailable(username);
      if (!isAvailable) {
        throw Exception('Username is already taken');
      }

      // Create user model
      UserModel userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        username: username.toLowerCase(),
        displayName: displayName,
        profilePictureUrl: profilePictureUrl,
        isActive: true,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      // Save to Firestore
      await _authService.createUserProfile(userModel);
      
      _userModel.value = userModel;
      Get.offAllNamed('/main');
      Get.snackbar('Success', 'Profile created successfully!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading.value = true;
      
      await _authService.updateUserProfile(updatedUser);
      _userModel.value = updatedUser;
      
      Get.snackbar('Success', 'Profile updated successfully!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Update active status
  Future<void> updateActiveStatus(bool isActive) async {
    try {
      await _authService.updateActiveStatus(isActive);
      if (_userModel.value != null) {
        _userModel.value = _userModel.value!.copyWith(
          isActive: isActive,
          lastSeen: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      
      await _authService.sendPasswordResetEmail(email);
      Get.snackbar('Success', 'Password reset email sent!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      
      // Update active status before signing out
      await _authService.updateActiveStatus(false);
      await _authService.signOut();
    } catch (e) {
      Get.snackbar('Error', 'Sign out failed');
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      
      await _authService.deleteAccount();
      Get.snackbar('Success', 'Account deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete account');
    } finally {
      _isLoading.value = false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }
}
