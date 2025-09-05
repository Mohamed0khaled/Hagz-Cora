import 'package:flutter/material.dart';

/// App-wide constants and configuration
/// Updated to work with dynamic theming system
class AppConstants {
  // Legacy colors - kept for compatibility but consider using Theme.of(context) instead
  static const Color primaryColor = Color(0xFF2E7D32); // Football green
  static const Color primaryColorDark = Color(0xFF1B5E20);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFB00020);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color onSurfaceColor = Color(0xFF000000);
  static const Color onBackgroundColor = Color(0xFF000000);
  static const Color googleColor = Color(0xFF4285F4);

  // Theme-aware color getters
  static Color getPrimaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  
  static Color getSecondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
      
  static Color getBackgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.background;
      
  static Color getSurfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  // Dynamic text styles that respond to theme and font scaling
  static TextStyle headlineLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge ?? const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

  static TextStyle headlineMedium(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium ?? const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge ?? const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      );

  static TextStyle bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge ?? const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  static TextStyle bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle labelLarge(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge ?? const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  // Legacy text styles - kept for backward compatibility
  static const TextStyle headlineLargeStatic = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
  );

  static const TextStyle headlineMediumStatic = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );

  static const TextStyle titleLargeStatic = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );

  static const TextStyle bodyLargeStatic = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: onSurfaceColor,
  );

  static const TextStyle bodyMediumStatic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: onSurfaceColor,
  );

  static const TextStyle labelLargeStatic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusExtraLarge = 16.0;

  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 400);
  static const Duration animationDurationLong = Duration(milliseconds: 600);

  // File Upload
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // Network
  static const Duration networkTimeout = Duration(seconds: 30);

  // Football theme colors
  static const List<Color> footballColors = [
    Color(0xFF2E7D32), // Forest Green
    Color(0xFF4CAF50), // Green
    Color(0xFF388E3C), // Dark Green
    Color(0xFF66BB6A), // Light Green
    Color(0xFF1B5E20), // Very Dark Green
  ];

  // App theme colors for dynamic theming
  static const List<Color> appThemeColors = [
    Color(0xFF2E7D32), // Green (Football theme) - Default
    Color(0xFF1976D2), // Blue
    Color(0xFFD32F2F), // Red
    Color(0xFFFF6F00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF00796B), // Teal
    Color(0xFF5D4037), // Brown
    Color(0xFF455A64), // Blue Grey
  ];

  // Theme-aware border radius
  static BorderRadius getCardBorderRadius(BuildContext context) =>
      BorderRadius.circular(radiusLarge);

  static BorderRadius getButtonBorderRadius(BuildContext context) =>
      BorderRadius.circular(radiusMedium);

  static BorderRadius getInputBorderRadius(BuildContext context) =>
      BorderRadius.circular(radiusMedium);

  // Theme-aware shadows
  static List<BoxShadow> getCardShadow(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.black.withOpacity(0.1)
          : Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> getElevatedShadow(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.black.withOpacity(0.15)
          : Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Helper methods for responsive design
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 600;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1200;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Safe area helpers
  static EdgeInsets getSafeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  static double getStatusBarHeight(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  static double getBottomPadding(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String timeoutErrorMessage = 'Request timed out. Please try again.';
  static const String signInCancelledMessage = 'Sign in was cancelled.';

  // Theme-aware colors for common UI states
  static Color getPlayerHighlightColor(BuildContext context, bool isCurrentUser) =>
      isCurrentUser 
          ? Theme.of(context).colorScheme.tertiary
          : Theme.of(context).colorScheme.surface;

  static Color getFieldGrassColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  static Color getFieldDarkGrassColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}

/// UI Helper utilities
class UIUtils {
  /// Show snackbar with message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppConstants.errorColor : AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'Please wait...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show error dialog
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
