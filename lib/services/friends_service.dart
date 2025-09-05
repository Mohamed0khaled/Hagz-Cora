import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';

/// Friends Service
/// Handles all friend-related operations with Firebase
/// Uses private subcollections for better security
class FriendsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get the user's private friends collection reference
  CollectionReference? get _userFriendsCollection {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('friends');
  }

  /// Initialize the friends service (ensure user is authenticated)
  Future<bool> initialize() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ FriendsService: No authenticated user');
        return false;
      }
      
      print('✅ FriendsService: Initialized for user ${user.uid}');
      
      // Run migration to move friends to private collection
      await migrateFriendsToPrivateCollection();
      
      return true;
    } catch (e) {
      print('❌ FriendsService initialization error: $e');
      return false;
    }
  }

  /// Add a friend by email
  Future<bool> addFriendByEmail(String email) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userFriendsCollection = _userFriendsCollection;
      if (userFriendsCollection == null) {
        throw Exception('Cannot access user friends collection');
      }

      // Check if user is trying to add themselves
      if (email.toLowerCase() == currentUser.email?.toLowerCase()) {
        throw Exception('You cannot add yourself as a friend');
      }

      // Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found with email: $email');
      }

      final friendDoc = userQuery.docs.first;
      final friendData = friendDoc.data();
      final friendId = friendDoc.id;

      // Check if friend relationship already exists in user's private collection
      final existingFriend = await userFriendsCollection
          .where('friendId', isEqualTo: friendId)
          .get();

      if (existingFriend.docs.isNotEmpty) {
        throw Exception('User is already in your friends list');
      }

      // Add friend relationship to user's private collection
      final friendModel = FriendModel(
        id: '', // Will be set by Firestore
        userId: currentUser.uid,
        friendId: friendId,
        friendEmail: email.toLowerCase(),
        friendName: friendData['displayName'] ?? friendData['name'] ?? 'Unknown User',
        friendPhotoUrl: friendData['photoURL'],
        addedAt: DateTime.now(),
        isAccepted: true,
      );

      await userFriendsCollection.add(friendModel.toMap());

      print('✅ Friend added to private collection for user ${currentUser.uid}');
      return true;
    } catch (e) {
      print('❌ Error adding friend: $e');
      rethrow;
    }
  }

  /// Get all friends for current user
  Stream<List<FriendModel>> getUserFriends() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('⚠️ Warning: No authenticated user for getUserFriends');
      return Stream.value([]);
    }

    final userFriendsCollection = _userFriendsCollection;
    if (userFriendsCollection == null) {
      print('⚠️ Warning: Cannot access user friends collection');
      return Stream.value([]);
    }

    // Simplified query - only filter by isAccepted, sort on client side
    return userFriendsCollection
        .where('isAccepted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      try {
        final friends = snapshot.docs
            .map((doc) => FriendModel.fromDocument(doc))
            .toList();
        
        // Sort by addedAt on client side (most recent first)
        friends.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        
        return friends;
      } catch (e) {
        print('❌ Error parsing friends documents: $e');
        return <FriendModel>[];
      }
    }).handleError((error) {
      print('❌ Error in getUserFriends stream: $error');
      return <FriendModel>[];
    });
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userFriendsCollection = _userFriendsCollection;
      if (userFriendsCollection == null) {
        throw Exception('Cannot access user friends collection');
      }

      final friendQuery = await userFriendsCollection
          .where('friendId', isEqualTo: friendId)
          .get();

      for (final doc in friendQuery.docs) {
        await doc.reference.delete();
      }

      print('✅ Friend removed from private collection for user ${currentUser.uid}');
    } catch (e) {
      print('❌ Error removing friend: $e');
      rethrow;
    }
  }

  /// Search friends by name or email
  Future<List<FriendModel>> searchFriends(String query) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final userFriendsCollection = _userFriendsCollection;
      if (userFriendsCollection == null) {
        return [];
      }

      // Get all accepted friends and filter on client side
      final friends = await userFriendsCollection
          .where('isAccepted', isEqualTo: true)
          .get();

      final filteredFriends = friends.docs
          .map((doc) => FriendModel.fromDocument(doc))
          .where((friend) {
        final searchQuery = query.toLowerCase();
        return friend.friendName.toLowerCase().contains(searchQuery) ||
               friend.friendEmail.toLowerCase().contains(searchQuery);
      }).toList();

      return filteredFriends;
    } catch (e) {
      print('❌ Error searching friends: $e');
      return [];
    }
  }

  /// Get friend by email
  Future<FriendModel?> getFriendByEmail(String email) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final userFriendsCollection = _userFriendsCollection;
      if (userFriendsCollection == null) {
        return null;
      }

      final friendQuery = await userFriendsCollection
          .where('friendEmail', isEqualTo: email.toLowerCase())
          .where('isAccepted', isEqualTo: true)
          .get();

      if (friendQuery.docs.isNotEmpty) {
        return FriendModel.fromDocument(friendQuery.docs.first);
      }

      return null;
    } catch (e) {
      print('❌ Error getting friend by email: $e');
      return null;
    }
  }

  /// Get friends count
  Future<int> getFriendsCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final userFriendsCollection = _userFriendsCollection;
      if (userFriendsCollection == null) {
        return 0;
      }

      final friendsQuery = await userFriendsCollection
          .where('isAccepted', isEqualTo: true)
          .get();

      return friendsQuery.docs.length;
    } catch (e) {
      print('❌ Error getting friends count: $e');
      return 0;
    }
  }

  /// Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      return userQuery.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if user exists: $e');
      return false;
    }
  }

  /// Migrate friends from global collection to user subcollections
  /// This should be called once to fix the privacy issue
  Future<void> migrateFriendsToPrivateCollection() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ No authenticated user for migration');
        return;
      }

      final userFriendsCollection = _userFriendsCollection;
      if (userFriendsCollection == null) {
        print('⚠️ Cannot access user friends collection');
        return;
      }

      // Check if migration is needed by looking for friends in the old global collection
      final oldFriends = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (oldFriends.docs.isEmpty) {
        print('✅ No friends to migrate for user ${currentUser.uid}');
        return;
      }

      print('🔄 Migrating ${oldFriends.docs.length} friends to private collection...');

      // Check if friends already exist in the new collection
      final existingPrivateFriends = await userFriendsCollection.get();
      final existingFriendIds = existingPrivateFriends.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['friendId'] as String?;
          })
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      int migratedCount = 0;
      for (final doc in oldFriends.docs) {
        final friendData = doc.data();
        final friendId = friendData['friendId'] as String?;
        
        // Skip if friend already exists in private collection
        if (friendId != null && existingFriendIds.contains(friendId)) {
          continue;
        }

        // Add to private collection
        await userFriendsCollection.add(friendData);
        migratedCount++;

        // Delete from global collection
        await doc.reference.delete();
      }

      print('✅ Successfully migrated $migratedCount friends to private collection');
    } catch (e) {
      print('❌ Error migrating friends: $e');
    }
  }
}
