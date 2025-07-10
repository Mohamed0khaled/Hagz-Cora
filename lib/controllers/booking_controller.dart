import 'package:get/get.dart';
import '../models/booking_group.dart';
import '../models/chat_message.dart';
import '../models/formation.dart';
import '../models/user_model.dart';
import '../services/booking_service.dart';
import 'auth_controller.dart';
import 'friend_controller.dart';

class BookingController extends GetxController {
  final BookingService _bookingService = BookingService();
  final AuthController _authController = Get.find<AuthController>();
  final FriendController _friendController = Get.find<FriendController>();

  // Observables
  final RxList<BookingGroup> _userGroups = <BookingGroup>[].obs;
  final RxList<ChatMessage> _chatMessages = <ChatMessage>[].obs;
  final Rx<Formation?> _currentFormation = Rx<Formation?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _currentGroupId = ''.obs;

  // Getters
  List<BookingGroup> get userGroups => _userGroups;
  List<BookingGroup> get groups => _userGroups; // Alias for compatibility
  List<ChatMessage> get chatMessages => _chatMessages;
  Formation? get currentFormation => _currentFormation.value;
  RxBool get isLoading => _isLoading;
  String get errorMessage => _errorMessage.value;
  String get currentGroupId => _currentGroupId.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserGroups();
  }

  // Load user's booking groups
  void _loadUserGroups() {
    String currentUserId = _authController.userModel?.id ?? '';
    if (currentUserId.isEmpty) return;

    _bookingService.getUserBookingGroups(currentUserId).listen(
      (groups) {
        _userGroups.value = groups;
      },
      onError: (error) {
        _errorMessage.value = error.toString();
      },
    );
  }

  // Create booking group
  Future<String?> createBookingGroup({
    required String name,
    required MatchType matchType,
    required BookingType bookingType,
    required DateTime matchDate,
    required DateTime startTime,
    required DateTime endTime,
    String? stadiumName,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      String currentUserId = _authController.userModel?.id ?? '';
      if (currentUserId.isEmpty) throw Exception('User not found');

      BookingGroup group = BookingGroup(
        id: '',
        name: name,
        adminId: currentUserId,
        matchType: matchType,
        bookingType: bookingType,
        matchDate: matchDate,
        startTime: startTime,
        endTime: endTime,
        stadiumName: stadiumName,
        createdAt: DateTime.now(),
      );

      String groupId = await _bookingService.createBookingGroup(group);
      Get.snackbar('Success', 'Booking created successfully!');
      return groupId;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Invite player to group
  Future<void> invitePlayerToGroup(String groupId, String playerId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      String inviterName = _authController.userModel?.displayName ?? 'Someone';
      await _bookingService.invitePlayerToGroup(groupId, playerId, inviterName);
      
      Get.snackbar('Success', 'Player invited successfully!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Invite player to group
  Future<void> invitePlayer(String groupId, String playerId, String team) async {
    try {
      _isLoading.value = true;
      final inviterName = _authController.userModel?.displayName ?? 'Someone';
      await _bookingService.invitePlayerToGroup(groupId, playerId, inviterName);
      
      // Update local group data
      final groupIndex = _userGroups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        final group = _userGroups[groupIndex];
        final updatedInvitedIds = [...group.invitedPlayerIds, playerId];
        
        _userGroups[groupIndex] = group.copyWith(
          invitedPlayerIds: updatedInvitedIds,
        );
      }
      
    } catch (e) {
      _errorMessage.value = e.toString();
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  // Accept group invitation
  Future<void> acceptGroupInvitation(String groupId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      String playerId = _authController.userModel?.id ?? '';
      await _bookingService.acceptGroupInvitation(groupId, playerId);
      
      Get.snackbar('Success', 'Invitation accepted!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Decline group invitation
  Future<void> declineGroupInvitation(String groupId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      String playerId = _authController.userModel?.id ?? '';
      await _bookingService.declineGroupInvitation(groupId, playerId);
      
      Get.snackbar('Success', 'Invitation declined');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Set opponent admin
  Future<void> setOpponentAdmin(String groupId, String opponentAdminId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      String inviterName = _authController.userModel?.displayName ?? 'Someone';
      await _bookingService.setOpponentAdmin(groupId, opponentAdminId, inviterName);
      
      Get.snackbar('Success', 'Opponent admin set successfully!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Assign player to team
  Future<void> assignPlayerToTeam(String groupId, String playerId, bool isTeamA) async {
    try {
      String adminId = _authController.userModel?.id ?? '';
      await _bookingService.assignPlayerToTeam(groupId, playerId, isTeamA, adminId);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Send chat message
  Future<void> sendMessage(String content) async {
    try {
      UserModel? currentUser = _authController.userModel;
      if (currentUser == null || _currentGroupId.value.isEmpty) return;

      ChatMessage message = ChatMessage(
        id: '',
        groupId: _currentGroupId.value,
        senderId: currentUser.id,
        senderName: currentUser.displayName,
        senderPhotoUrl: currentUser.profilePictureUrl,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      await _bookingService.sendMessage(message);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
    }
  }

  // Load chat messages for a group
  void loadChatMessages(String groupId) {
    _currentGroupId.value = groupId;
    
    _bookingService.getChatMessages(groupId).listen(
      (messages) {
        _chatMessages.value = messages;
      },
      onError: (error) {
        _errorMessage.value = error.toString();
      },
    );
  }

  // Load formation for a group
  void loadFormation(String groupId) {
    _bookingService.getFormation(groupId).listen(
      (formation) {
        _currentFormation.value = formation;
      },
      onError: (error) {
        _errorMessage.value = error.toString();
      },
    );
  }

  // Update formation
  Future<void> updateFormation(String groupId, Formation formation) async {
    try {
      _isLoading.value = true;
      
      // Create formation with correct groupId
      final updatedFormation = formation.copyWith(
        groupId: groupId,
        lastUpdatedBy: _authController.userModel?.id ?? '',
        lastUpdated: DateTime.now(),
      );
      
      await _bookingService.updateFormation(updatedFormation);
      
      // Update local formation
      _currentFormation.value = updatedFormation;
      
    } catch (e) {
      _errorMessage.value = e.toString();
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  // Leave group
  Future<void> leaveGroup(String groupId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      String playerId = _authController.userModel?.id ?? '';
      await _bookingService.leaveGroup(groupId, playerId);
      
      Get.back(); // Go back to groups list
      Get.snackbar('Success', 'Left the group');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Get group by ID
  BookingGroup? getGroupById(String groupId) {
    try {
      return _userGroups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is admin of group
  bool isGroupAdmin(String groupId) {
    BookingGroup? group = getGroupById(groupId);
    if (group == null) return false;
    
    String currentUserId = _authController.userModel?.id ?? '';
    return group.adminId == currentUserId || group.opponentAdminId == currentUserId;
  }

  // Check if user is main admin of group
  bool isMainAdmin(String groupId) {
    BookingGroup? group = getGroupById(groupId);
    if (group == null) return false;
    
    String currentUserId = _authController.userModel?.id ?? '';
    return group.adminId == currentUserId;
  }

  // Check if user is opponent admin of group
  bool isOpponentAdmin(String groupId) {
    BookingGroup? group = getGroupById(groupId);
    if (group == null) return false;
    
    String currentUserId = _authController.userModel?.id ?? '';
    return group.opponentAdminId == currentUserId;
  }

  // Get available friends for invitation
  List<UserModel> getAvailableFriendsForInvitation(String groupId) {
    BookingGroup? group = getGroupById(groupId);
    if (group == null) return [];

    List<UserModel> friends = _friendController.friends;
    List<String> excludedIds = [
      ...group.playerIds,
      ...group.invitedPlayerIds,
      group.adminId,
      if (group.opponentAdminId != null) group.opponentAdminId!,
    ];

    return friends.where((friend) => 
      friend.isActive && !excludedIds.contains(friend.id)
    ).toList();
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // Refresh data
  @override
  Future<void> refresh() async {
    // Groups are automatically refreshed via stream
    // This method can be used for manual refresh if needed
  }
}
