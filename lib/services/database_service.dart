import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/auth_models.dart';

/// Firestore Database Service
/// Handles user data storage and retrieval
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Create user profile in Firestore
  Future<AuthResult> createUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
      return AuthResult.success(data: user);
    } catch (e) {
      if (kDebugMode) {
        print('Create user profile error: $e');
      }
      return AuthResult.failure('Failed to create user profile: $e');
    }
  }

  /// Get user profile from Firestore
  Future<AuthResult> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        return AuthResult.failure('User profile not found');
      }

      final userData = doc.data() as Map<String, dynamic>;
      final userModel = UserModel.fromMap(userData);

      return AuthResult.success(data: userModel);
    } catch (e) {
      if (kDebugMode) {
        print('Get user profile error: $e');
      }
      return AuthResult.failure('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<AuthResult> updateUserProfile({
    required String uid,
    String? displayName,
    File? profileImage,
  }) async {
    try {
      // First check if user profile exists
      final profileExists = await userProfileExists(uid);
      if (!profileExists) {
        return AuthResult.failure('User profile not found. Please try signing in again.');
      }

      Map<String, dynamic> updateData = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add display name if provided
      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      // Upload new profile image if provided
      if (profileImage != null) {
        final uploadResult = await _uploadProfileImage(uid, profileImage);
        if (!uploadResult.success) {
          return uploadResult;
        }
        updateData['photoURL'] = uploadResult.data as String;
      }

      // Update in Firestore
      await _usersCollection.doc(uid).update(updateData);

      // Get updated user profile
      return await getUserProfile(uid);
    } catch (e) {
      if (kDebugMode) {
        print('Update user profile error: $e');
      }
      return AuthResult.failure('Failed to update user profile: $e');
    }
  }

  /// Delete user profile and associated data
  Future<AuthResult> deleteUserProfile(String uid) async {
    try {
      // Delete profile image from storage
      try {
        await _storage.ref().child('profile_images/$uid').delete();
      } catch (e) {
        // Image might not exist, continue with profile deletion
        if (kDebugMode) {
          print('Profile image deletion error: $e');
        }
      }

      // Delete user document from Firestore
      await _usersCollection.doc(uid).delete();

      return AuthResult.success();
    } catch (e) {
      if (kDebugMode) {
        print('Delete user profile error: $e');
      }
      return AuthResult.failure('Failed to delete user profile: $e');
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user profile existence: $e');
      }
      return false;
    }
  }

  /// Upload profile image to Firebase Storage
  Future<AuthResult> _uploadProfileImage(String uid, File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        return AuthResult.failure('Image size must be less than 5MB');
      }

      // Create reference to storage location
      final ref = _storage.ref().child('profile_images/$uid');

      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return AuthResult.success(data: downloadUrl);
    } catch (e) {
      if (kDebugMode) {
        print('Upload profile image error: $e');
      }
      return AuthResult.failure('Failed to upload profile image: $e');
    }
  }

  /// Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      try {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing user data: $e');
        }
        return null;
      }
    });
  }

  /// Get users collection stream (for admin purposes)
  Stream<List<UserModel>> getUsersStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return UserModel.fromMap(data);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing user data: $e');
          }
          return null;
        }
      }).where((user) => user != null).cast<UserModel>().toList();
    });
  }

  /// Search users by display name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await _usersCollection
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + '\uf8ff')
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Search users error: $e');
      }
      return [];
    }
  }
}
