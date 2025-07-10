import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/friend_controller.dart';
import 'controllers/booking_controller.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'views/splash_screen.dart';
import 'views/auth/auth_screen.dart';
import 'views/auth/profile_setup_screen.dart';
import 'views/main/main_screen.dart';
import 'views/booking/create_booking_screen.dart';
import 'views/booking/group_chat_screen.dart';
import 'views/formation/formation_screen.dart';
import 'views/booking/invite_players_screen.dart';
import 'views/friends/add_friends_screen.dart';
import 'views/settings/notification_settings_screen.dart';
import 'views/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  // Initialize controllers
  Get.put(AuthController());
  Get.put(FriendController());
  Get.put(BookingController());
  
  runApp(const HagzKoraApp());
}

class HagzKoraApp extends StatelessWidget {
  const HagzKoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hagz Kora',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/auth', page: () => const AuthScreen()),
        GetPage(name: '/profile-setup', page: () => const ProfileSetupScreen()),
        GetPage(name: '/main', page: () => const MainScreen()),
        GetPage(name: '/create-booking', page: () => const CreateBookingScreen()),
        GetPage(name: '/group-chat', page: () => const GroupChatScreen()),
        GetPage(
          name: '/formation', 
          page: () {
            final groupId = Get.parameters['groupId'] ?? '';
            return FormationScreen(groupId: groupId);
          },
        ),
        GetPage(
          name: '/invite-players', 
          page: () {
            final groupId = Get.parameters['groupId'] ?? '';
            return InvitePlayersScreen(groupId: groupId);
          },
        ),
        GetPage(name: '/add-friends', page: () => const AddFriendsScreen()),
        GetPage(name: '/notification-settings', page: () => const NotificationSettingsScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
