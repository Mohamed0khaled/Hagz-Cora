import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF25D366);
  static const Color darkGreen = Color(0xFF128C7E);
  static const Color lightGreen = Color(0xFFDCF8C6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF8696A0);
  static const Color lightGrey = Color(0xFFF7F8FA);
  static const Color darkGrey = Color(0xFF3C4043);
  static const Color red = Color(0xFFE53E3E);
  static const Color blue = Color(0xFF007AFF);
  
  // Football specific colors
  static const Color pitchGreen = Color(0xFF4A7C59);
  static const Color pitchLineWhite = Color(0xFFFFFFFF);
  static const Color teamAColor = Color(0xFF007AFF);
  static const Color teamBColor = Color(0xFFFF3B30);
}

class AppStrings {
  static const String appName = 'Hagz Kora';
  static const String tagline = 'Football Booking Made Easy';
  
  // Auth
  static const String welcome = 'Welcome to Hagz Kora';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String signInWithGoogle = 'Sign In with Google';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  
  // Profile Setup
  static const String setupProfile = 'Setup Your Profile';
  static const String chooseUsername = 'Choose Username';
  static const String displayName = 'Display Name';
  static const String uploadPhoto = 'Upload Photo';
  static const String skipForNow = 'Skip for now';
  
  // Main Navigation
  static const String chats = 'Chats';
  static const String friends = 'Friends';
  static const String profile = 'Profile';
  
  // Booking
  static const String createBooking = 'Create Booking';
  static const String matchType = 'Match Type';
  static const String bookingType = 'Booking Type';
  static const String singleAdmin = 'Single Admin';
  static const String duelAdmins = 'Duel Admins';
  static const String selectDate = 'Select Date';
  static const String startTime = 'Start Time';
  static const String endTime = 'End Time';
  static const String stadiumName = 'Stadium Name (Optional)';
  static const String invitePlayers = 'Invite Players';
  
  // Formation
  static const String formation = 'Formation';
  static const String teamA = 'Team A';
  static const String teamB = 'Team B';
  static const String dragToPosition = 'Drag players to position them on the pitch';
  
  // Error Messages
  static const String errorOccurred = 'An error occurred';
  static const String noInternetConnection = 'No internet connection';
  static const String userNotFound = 'User not found';
  static const String invalidCredentials = 'Invalid credentials';
  static const String weakPassword = 'Password is too weak';
  static const String emailAlreadyInUse = 'Email is already in use';
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 80.0;
  static const double avatarSizeXLarge = 120.0;
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  static const TextStyle captionText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
  );
}
