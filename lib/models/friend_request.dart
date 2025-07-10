enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String? senderPhotoUrl;
  final DateTime sentAt;
  final FriendRequestStatus status;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.sentAt,
    required this.status,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> data, String id) {
    return FriendRequest(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      sentAt: DateTime.fromMillisecondsSinceEpoch(data['sentAt'] ?? 0),
      status: FriendRequestStatus.values[data['status'] ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'status': status.index,
    };
  }
}
