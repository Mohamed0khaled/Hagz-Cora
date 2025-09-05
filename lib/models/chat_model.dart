import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType {
  individual,
  group,
}

class ChatModel {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final ChatType type;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final Map<String, dynamic> settings;
  final bool isArchived;
  final bool isMuted;
  final DateTime? mutedUntil;

  const ChatModel({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    required this.type,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.settings = const {},
    this.isArchived = false,
    this.isMuted = false,
    this.mutedUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'type': type.index,
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'settings': settings,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'mutedUntil': mutedUntil,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      photoUrl: map['photoUrl'],
      type: ChatType.values[map['type'] ?? 0],
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(map['participantPhotos'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'],
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      isArchived: map['isArchived'] ?? false,
      isMuted: map['isMuted'] ?? false,
      mutedUntil: map['mutedUntil'] is Timestamp
          ? (map['mutedUntil'] as Timestamp).toDate()
          : null,
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel.fromMap({...data, 'id': doc.id});
  }

  ChatModel copyWith({
    String? id,
    String? name,
    String? description,
    String? photoUrl,
    ChatType? type,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? settings,
    bool? isArchived,
    bool? isMuted,
    DateTime? mutedUntil,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
    );
  }

  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return name;
    } else {
      // For individual chats, return the other participant's name
      final otherParticipant = participants.firstWhere(
        (p) => p != currentUserId,
        orElse: () => currentUserId,
      );
      return participantNames[otherParticipant] ?? 'Unknown User';
    }
  }

  String? getDisplayPhoto(String currentUserId) {
    if (type == ChatType.group) {
      return photoUrl;
    } else {
      // For individual chats, return the other participant's photo
      final otherParticipant = participants.firstWhere(
        (p) => p != currentUserId,
        orElse: () => currentUserId,
      );
      return participantPhotos[otherParticipant];
    }
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool get hasUnreadMessages {
    return unreadCount.values.any((count) => count > 0);
  }

  String get formattedLastMessageTime {
    if (lastMessageTime == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(lastMessageTime!);
    
    if (diff.inDays > 7) {
      return '${lastMessageTime!.day}/${lastMessageTime!.month}/${lastMessageTime!.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
