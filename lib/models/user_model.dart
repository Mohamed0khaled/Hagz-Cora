import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? profilePictureUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastSeen;
  final List<String> friendIds;
  final List<String> pendingFriendRequests;
  final List<String> sentFriendRequests;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
    required this.isActive,
    required this.createdAt,
    required this.lastSeen,
    this.friendIds = const [],
    this.pendingFriendRequests = const [],
    this.sentFriendRequests = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      friendIds: List<String>.from(data['friendIds'] ?? []),
      pendingFriendRequests: List<String>.from(data['pendingFriendRequests'] ?? []),
      sentFriendRequests: List<String>.from(data['sentFriendRequests'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'friendIds': friendIds,
      'pendingFriendRequests': pendingFriendRequests,
      'sentFriendRequests': sentFriendRequests,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? profilePictureUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastSeen,
    List<String>? friendIds,
    List<String>? pendingFriendRequests,
    List<String>? sentFriendRequests,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      friendIds: friendIds ?? this.friendIds,
      pendingFriendRequests: pendingFriendRequests ?? this.pendingFriendRequests,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
    );
  }
}
