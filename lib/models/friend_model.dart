import 'package:cloud_firestore/cloud_firestore.dart';

/// Friend Model
/// Represents a friend relationship in the app
class FriendModel {
  final String id;
  final String userId; // The user who added this friend
  final String friendId; // The friend's user ID
  final String friendEmail;
  final String friendName;
  final String? friendPhotoUrl;
  final DateTime addedAt;
  final bool isAccepted; // For future friend request functionality

  FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendEmail,
    required this.friendName,
    this.friendPhotoUrl,
    required this.addedAt,
    this.isAccepted = true,
  });

  /// Create FriendModel from Firestore document
  factory FriendModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      friendEmail: data['friendEmail'] ?? '',
      friendName: data['friendName'] ?? '',
      friendPhotoUrl: data['friendPhotoUrl'],
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAccepted: data['isAccepted'] ?? true,
    );
  }

  /// Convert FriendModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'friendId': friendId,
      'friendEmail': friendEmail,
      'friendName': friendName,
      'friendPhotoUrl': friendPhotoUrl,
      'addedAt': Timestamp.fromDate(addedAt),
      'isAccepted': isAccepted,
    };
  }

  /// Create a copy of this friend with updated values
  FriendModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendEmail,
    String? friendName,
    String? friendPhotoUrl,
    DateTime? addedAt,
    bool? isAccepted,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendEmail: friendEmail ?? this.friendEmail,
      friendName: friendName ?? this.friendName,
      friendPhotoUrl: friendPhotoUrl ?? this.friendPhotoUrl,
      addedAt: addedAt ?? this.addedAt,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }

  @override
  String toString() {
    return 'FriendModel(id: $id, friendEmail: $friendEmail, friendName: $friendName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendModel &&
        other.id == id &&
        other.friendEmail == friendEmail;
  }

  @override
  int get hashCode => id.hashCode ^ friendEmail.hashCode;
}
