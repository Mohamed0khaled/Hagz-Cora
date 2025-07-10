import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchType {
  fiveAside,
  sevenAside,
  tenAside,
}

enum BookingType {
  singleAdmin,
  duelAdmins,
}

class GroupMember {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime joinedAt;
  final bool isAdmin;

  GroupMember({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.joinedAt,
    this.isAdmin = false,
  });

  factory GroupMember.fromMap(Map<String, dynamic> data) {
    return GroupMember(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      joinedAt: data['joinedAt'] is DateTime 
          ? data['joinedAt'] 
          : (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isAdmin': isAdmin,
    };
  }
}

class BookingGroup {
  final String id;
  final String name;
  final String adminId;
  final String? opponentAdminId; // For duel admins only
  final MatchType matchType;
  final BookingType bookingType;
  final DateTime matchDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? stadiumName;
  final List<String> playerIds;
  final List<String> teamAPlayerIds; // Admin's team
  final List<String> teamBPlayerIds; // Opponent admin's team
  final List<String> invitedPlayerIds;
  final Map<String, dynamic>? formation; // Formation data
  final List<GroupMember> members; // Group members with details
  final DateTime createdAt;
  final bool isActive;

  BookingGroup({
    required this.id,
    required this.name,
    required this.adminId,
    this.opponentAdminId,
    required this.matchType,
    required this.bookingType,
    required this.matchDate,
    required this.startTime,
    required this.endTime,
    this.stadiumName,
    this.playerIds = const [],
    this.teamAPlayerIds = const [],
    this.teamBPlayerIds = const [],
    this.invitedPlayerIds = const [],
    this.formation,
    this.members = const [],
    required this.createdAt,
    this.isActive = true,
  });

  factory BookingGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse members from data
    final membersList = <GroupMember>[];
    if (data['members'] != null) {
      (data['members'] as List<dynamic>).forEach((memberData) {
        membersList.add(GroupMember.fromMap(memberData as Map<String, dynamic>));
      });
    }
    
    return BookingGroup(
      id: doc.id,
      name: data['name'] ?? '',
      adminId: data['adminId'] ?? '',
      opponentAdminId: data['opponentAdminId'],
      matchType: MatchType.values[data['matchType'] ?? 0],
      bookingType: BookingType.values[data['bookingType'] ?? 0],
      matchDate: (data['matchDate'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      stadiumName: data['stadiumName'],
      playerIds: List<String>.from(data['playerIds'] ?? []),
      teamAPlayerIds: List<String>.from(data['teamAPlayerIds'] ?? []),
      teamBPlayerIds: List<String>.from(data['teamBPlayerIds'] ?? []),
      invitedPlayerIds: List<String>.from(data['invitedPlayerIds'] ?? []),
      formation: data['formation'] as Map<String, dynamic>?,
      members: membersList,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'adminId': adminId,
      'opponentAdminId': opponentAdminId,
      'matchType': matchType.index,
      'bookingType': bookingType.index,
      'matchDate': Timestamp.fromDate(matchDate),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'stadiumName': stadiumName,
      'playerIds': playerIds,
      'teamAPlayerIds': teamAPlayerIds,
      'teamBPlayerIds': teamBPlayerIds,
      'invitedPlayerIds': invitedPlayerIds,
      'formation': formation,
      'members': members.map((member) => member.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  int get maxPlayersPerTeam {
    switch (matchType) {
      case MatchType.fiveAside:
        return 5;
      case MatchType.sevenAside:
        return 7;
      case MatchType.tenAside:
        return 10;
    }
  }

  bool get isDuelAdmins => bookingType == BookingType.duelAdmins;

  BookingGroup copyWith({
    String? id,
    String? name,
    String? adminId,
    String? opponentAdminId,
    MatchType? matchType,
    BookingType? bookingType,
    DateTime? matchDate,
    DateTime? startTime,
    DateTime? endTime,
    String? stadiumName,
    List<String>? playerIds,
    List<String>? teamAPlayerIds,
    List<String>? teamBPlayerIds,
    List<String>? invitedPlayerIds,
    Map<String, dynamic>? formation,
    List<GroupMember>? members,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return BookingGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      opponentAdminId: opponentAdminId ?? this.opponentAdminId,
      matchType: matchType ?? this.matchType,
      bookingType: bookingType ?? this.bookingType,
      matchDate: matchDate ?? this.matchDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      stadiumName: stadiumName ?? this.stadiumName,
      playerIds: playerIds ?? this.playerIds,
      teamAPlayerIds: teamAPlayerIds ?? this.teamAPlayerIds,
      teamBPlayerIds: teamBPlayerIds ?? this.teamBPlayerIds,
      invitedPlayerIds: invitedPlayerIds ?? this.invitedPlayerIds,
      formation: formation ?? this.formation,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
