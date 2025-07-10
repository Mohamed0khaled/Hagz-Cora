import 'package:cloud_firestore/cloud_firestore.dart';

enum FormationType {
  f442,
  f433,
  f352,
  f343,
  f541,
}

enum TeamSide {
  home,
  away,
}

enum PlayerRole {
  goalkeeper,
  defender,
  midfielder,
  striker,
}

class PlayerPosition {
  final String playerId;
  final double x; // Position on pitch (0.0 to 1.0)
  final double y; // Position on pitch (0.0 to 1.0)
  final String playerName;
  final String? playerPhotoUrl;
  final bool isGoalkeeper;
  final TeamSide team;
  final PlayerRole role;

  PlayerPosition({
    required this.playerId,
    required this.x,
    required this.y,
    required this.playerName,
    this.playerPhotoUrl,
    this.isGoalkeeper = false,
    this.team = TeamSide.home,
    this.role = PlayerRole.midfielder,
  });

  factory PlayerPosition.fromMap(Map<String, dynamic> data) {
    return PlayerPosition(
      playerId: data['playerId'] ?? '',
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      playerName: data['playerName'] ?? '',
      playerPhotoUrl: data['playerPhotoUrl'],
      isGoalkeeper: data['isGoalkeeper'] ?? false,
      team: TeamSide.values.firstWhere(
        (t) => t.name == (data['team'] ?? 'home'),
        orElse: () => TeamSide.home,
      ),
      role: PlayerRole.values.firstWhere(
        (r) => r.name == (data['role'] ?? 'midfielder'),
        orElse: () => PlayerRole.midfielder,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'x': x,
      'y': y,
      'playerName': playerName,
      'playerPhotoUrl': playerPhotoUrl,
      'isGoalkeeper': isGoalkeeper,
      'team': team.name,
      'role': role.name,
    };
  }

  PlayerPosition copyWith({
    String? playerId,
    double? x,
    double? y,
    String? playerName,
    String? playerPhotoUrl,
    bool? isGoalkeeper,
    TeamSide? team,
    PlayerRole? role,
  }) {
    return PlayerPosition(
      playerId: playerId ?? this.playerId,
      x: x ?? this.x,
      y: y ?? this.y,
      playerName: playerName ?? this.playerName,
      playerPhotoUrl: playerPhotoUrl ?? this.playerPhotoUrl,
      isGoalkeeper: isGoalkeeper ?? this.isGoalkeeper,
      team: team ?? this.team,
      role: role ?? this.role,
    );
  }
}

class Formation {
  final String id;
  final String groupId;
  final FormationType type;
  final Map<String, PlayerPosition> playerPositions;
  final DateTime lastUpdated;
  final String lastUpdatedBy;

  Formation({
    required this.id,
    required this.groupId,
    this.type = FormationType.f442,
    Map<String, PlayerPosition>? playerPositions,
    required this.lastUpdated,
    required this.lastUpdatedBy,
  }) : playerPositions = playerPositions ?? {};

  factory Formation.fromMap(Map<String, dynamic> data) {
    final positions = <String, PlayerPosition>{};
    if (data['playerPositions'] != null) {
      (data['playerPositions'] as Map<String, dynamic>).forEach((key, value) {
        positions[key] = PlayerPosition.fromMap(value as Map<String, dynamic>);
      });
    }

    return Formation(
      id: data['id'] ?? '',
      groupId: data['groupId'] ?? '',
      type: FormationType.values.firstWhere(
        (t) => t.name == (data['type'] ?? 'f442'),
        orElse: () => FormationType.f442,
      ),
      playerPositions: positions,
      lastUpdated: data['lastUpdated'] is DateTime
          ? data['lastUpdated']
          : DateTime.now(),
      lastUpdatedBy: data['lastUpdatedBy'] ?? '',
    );
  }

  static Formation createDefault() {
    return Formation(
      id: '',
      groupId: '',
      type: FormationType.f442,
      playerPositions: _getDefaultPositions(FormationType.f442),
      lastUpdated: DateTime.now(),
      lastUpdatedBy: '',
    );
  }

  static Formation createByType(FormationType type) {
    return Formation(
      id: '',
      groupId: '',
      type: type,
      playerPositions: _getDefaultPositions(type),
      lastUpdated: DateTime.now(),
      lastUpdatedBy: '',
    );
  }

  static Map<String, PlayerPosition> _getDefaultPositions(FormationType type) {
    final positions = <String, PlayerPosition>{};
    
    switch (type) {
      case FormationType.f442:
        // Default 4-4-2 formation positions
        positions['player1'] = PlayerPosition(
          playerId: 'player1',
          x: 0.5,
          y: 0.9,
          playerName: 'GK',
          team: TeamSide.home,
          role: PlayerRole.goalkeeper,
          isGoalkeeper: true,
        );
        // Add more default positions as needed
        break;
      case FormationType.f433:
        // 4-3-3 formation
        break;
      case FormationType.f352:
        // 3-5-2 formation
        break;
      case FormationType.f343:
        // 3-4-3 formation
        break;
      case FormationType.f541:
        // 5-4-1 formation
        break;
    }
    
    return positions;
  }

  factory Formation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Formation.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toFirestore() {
    final playerPositionsMap = <String, dynamic>{};
    playerPositions.forEach((key, value) {
      playerPositionsMap[key] = value.toMap();
    });

    return {
      'groupId': groupId,
      'type': type.name,
      'playerPositions': playerPositionsMap,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastUpdatedBy': lastUpdatedBy,
    };
  }

  Formation copyWith({
    String? id,
    String? groupId,
    FormationType? type,
    Map<String, PlayerPosition>? playerPositions,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
  }) {
    return Formation(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      playerPositions: playerPositions ?? this.playerPositions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
    );
  }
}
