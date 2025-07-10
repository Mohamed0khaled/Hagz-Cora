import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/friend_request.dart';
import '../services/friend_service.dart';
import 'auth_controller.dart';

class FriendController extends GetxController {
  final FriendService _friendService = FriendService();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  final RxList<UserModel> _searchResults = <UserModel>[].obs;
  final RxList<UserModel> _friends = <UserModel>[].obs;
  final RxList<FriendRequest> _pendingRequests = <FriendRequest>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSearching = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading.value;
  bool get isSearching => _isSearching.value;
  String get errorMessage => _errorMessage.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    _loadFriends();
    _loadPendingRequests();
  }

  // Search users
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      return;
    }

    try {
      _isSearching.value = true;
      _searchQuery.value = query;
      _errorMessage.value = '';

      List<UserModel> results = await _friendService.searchUsers(query);
      
      // Filter out current user and existing friends
      String currentUserId = _authController.userModel?.id ?? '';
      List<String> friendIds = _authController.userModel?.friendIds ?? [];
      
      _searchResults.value = results.where((user) => 
        user.id != currentUserId && !friendIds.contains(user.id)
      ).toList();
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isSearching.value = false;
    }
  }

  // Send friend request
  Future<void> sendFriendRequest(String targetUserId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      UserModel? currentUser = _authController.userModel;
      if (currentUser == null) throw Exception('User not found');

      await _friendService.sendFriendRequest(
        currentUser.id,
        targetUserId,
        currentUser.displayName,
        currentUser.profilePictureUrl,
      );

      // Remove from search results
      _searchResults.removeWhere((user) => user.id == targetUserId);
      
      Get.snackbar('Success', 'Friend request sent!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(FriendRequest request) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _friendService.acceptFriendRequest(
        request.id,
        request.senderId,
        request.receiverId,
      );

      // Remove from pending requests
      _pendingRequests.removeWhere((req) => req.id == request.id);
      
      // Reload friends list
      await _loadFriends();
      
      Get.snackbar('Success', 'Friend request accepted!');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Decline friend request
  Future<void> declineFriendRequest(FriendRequest request) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _friendService.declineFriendRequest(
        request.id,
        request.senderId,
        request.receiverId,
      );

      // Remove from pending requests
      _pendingRequests.removeWhere((req) => req.id == request.id);
      
      Get.snackbar('Success', 'Friend request declined');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Remove friend
  Future<void> removeFriend(String friendId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      String currentUserId = _authController.userModel?.id ?? '';
      await _friendService.removeFriend(currentUserId, friendId);

      // Remove from friends list
      _friends.removeWhere((friend) => friend.id == friendId);
      
      Get.snackbar('Success', 'Friend removed');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Load friends list
  Future<void> _loadFriends() async {
    try {
      List<String> friendIds = _authController.userModel?.friendIds ?? [];
      if (friendIds.isEmpty) {
        _friends.clear();
        return;
      }

      List<UserModel> friendsList = await _friendService.getFriends(friendIds);
      _friends.value = friendsList;
    } catch (e) {
      _errorMessage.value = e.toString();
    }
  }

  // Load pending friend requests
  void _loadPendingRequests() {
    String currentUserId = _authController.userModel?.id ?? '';
    if (currentUserId.isEmpty) return;

    _friendService.getPendingFriendRequests(currentUserId).listen(
      (requests) {
        _pendingRequests.value = requests;
      },
      onError: (error) {
        _errorMessage.value = error.toString();
      },
    );
  }

  // Refresh data
  @override
  Future<void> refresh() async {
    await Future.wait([
      _loadFriends(),
    ]);
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults.clear();
    _searchQuery.value = '';
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // Check if user is a friend
  bool isFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  // Check if friend request is pending
  bool isFriendRequestPending(String userId) {
    List<String> sentRequests = _authController.userModel?.sentFriendRequests ?? [];
    return sentRequests.contains(userId);
  }

  // Get friend by ID
  UserModel? getFriendById(String friendId) {
    try {
      return _friends.firstWhere((friend) => friend.id == friendId);
    } catch (e) {
      return null;
    }
  }
}
