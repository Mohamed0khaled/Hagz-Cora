import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  sticker,
  location,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToMessageId;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.replyToMessageId,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    this.isDeleted = false,
    this.deletedAt,
    this.readBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp,
      'replyToMessageId': replyToMessageId,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'readBy': readBy,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhoto: map['senderPhoto'],
      content: map['content'] ?? '',
      type: MessageType.values[map['type'] ?? 0],
      status: MessageStatus.values[map['status'] ?? 0],
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      replyToMessageId: map['replyToMessageId'],
      mediaUrl: map['mediaUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      metadata: map['metadata'],
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: map['deletedAt'] is Timestamp
          ? (map['deletedAt'] as Timestamp).toDate()
          : null,
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap({...data, 'id': doc.id});
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhoto,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyToMessageId,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    DateTime? deletedAt,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      readBy: readBy ?? this.readBy,
    );
  }

  bool get isMedia => type == MessageType.image || 
                     type == MessageType.video || 
                     type == MessageType.audio || 
                     type == MessageType.file;

  bool get isSent => status != MessageStatus.sending && status != MessageStatus.failed;
  
  bool get isDelivered => status == MessageStatus.delivered || status == MessageStatus.read;
  
  bool get isRead => status == MessageStatus.read;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
