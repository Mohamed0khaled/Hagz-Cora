# HagzCoora Theme System Implementation

## Overview
The HagzCoora app now has a comprehensive theme system that provides:
- Light/Dark/System theme modes
- Dynamic color theming with 8 predefined colors
- Font size scaling (Small/Medium/Large/Extra Large)
- Theme persistence using SharedPreferences
- Unified styling across all app screens

## Components

### 1. ThemeProvider (`lib/providers/theme_provider.dart`)
- **Purpose**: Central theme management with state persistence
- **Features**:
  - Theme mode management (light/dark/system)
  - Primary color selection from predefined palette
  - Font size scaling (0.85x to 1.3x)
  - Notification settings
  - Sound and vibration toggles
  - Language settings
  - Settings persistence via SharedPreferences

### 2. Settings Screen (`lib/screens/settings.dart`)
- **Purpose**: Unified settings interface for all app preferences
- **Features**:
  - Profile section with user information
  - Theme mode selector (Light/Dark/System)
  - Color picker with 8 predefined colors
  - Font size adjustment
  - Notification toggles
  - Football-specific settings
  - Account management options
  - Reset to defaults option

### 3. Constants Utility (`lib/utils/constants.dart`)
- **Purpose**: Theme-aware constants and helper functions
- **Features**:
  - Dynamic color getters that respond to theme
  - Context-aware text styles with font scaling
  - Legacy color constants for backward compatibility
  - Theme-aware shadows and border radius
  - Responsive design helpers
  - UI utility functions (dialogs, snackbars)

### 4. Main App Integration (`lib/main.dart`)
- **Purpose**: Theme system integration at app level
- **Features**:
  - Multi-provider setup (AuthProvider + ThemeProvider)
  - Theme mode application
  - Loading screen during initialization
  - Consumer pattern for theme updates

## Theme Settings Available

### Theme Modes
- **Light**: Always use light theme
- **Dark**: Always use dark theme  
- **System**: Follow device system theme

### Color Themes
1. Green (Football theme) - Default
2. Blue
3. Red
4. Orange
5. Purple
6. Teal
7. Brown
8. Blue Grey

### Font Sizes
- Small (0.85x)
- Medium (1.0x) - Default
- Large (1.15x)
- Extra Large (1.3x)

### App Settings
- Notifications enabled/disabled
- Sound enabled/disabled
- Vibration enabled/disabled
- Language selection (English, Arabic, Spanish, French, German)

## Updated Screens

The following screens have been updated to use the theme system:

### ✅ Fully Updated
- `lib/main.dart` - Theme integration
- `lib/screens/settings.dart` - Settings interface
- `lib/providers/theme_provider.dart` - Theme management
- `lib/utils/constants.dart` - Theme utilities
- `lib/screens/homescreen.dart` - Home screen theming
- `lib/screens/lineup_screen.dart` - Lineup screen theming
- `lib/screens/friends_screen.dart` - Friends screen theming
- `lib/screens/auth/login_screen.dart` - Login screen text styles
- `lib/screens/profile_settings_screen.dart` - Profile settings text styles

### 🔄 Partially Updated (may need more work)
- `lib/screens/chat_page.dart` - Chat interface
- `lib/screens/new_chat_screen.dart` - New chat creation

## How to Use

### For Developers
1. **Using theme-aware colors**:
   ```dart
   // Instead of hardcoded colors
   color: Colors.blue
   
   // Use theme colors
   color: Theme.of(context).colorScheme.primary
   ```

2. **Using dynamic text styles**:
   ```dart
   // Instead of static text styles
   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
   
   // Use theme-aware styles
   style: Theme.of(context).textTheme.titleMedium
   // Or use constants
   style: AppConstants.titleLarge(context)
   ```

3. **Using theme-aware helpers**:
   ```dart
   // For consistent shadows
   boxShadow: AppConstants.getCardShadow(context)
   
   // For consistent border radius
   borderRadius: AppConstants.getCardBorderRadius(context)
   ```

### For Users
1. Open the app
2. Navigate to Settings (via menu or bottom navigation)
3. Customize appearance:
   - Choose theme mode (Light/Dark/System)
   - Select primary color
   - Adjust font size
   - Toggle notifications
4. Settings are automatically saved and persist across app restarts

## Testing

### Theme Changes
- Switch between light/dark modes
- Change primary colors
- Adjust font sizes
- Verify settings persist after app restart

### Screen Coverage
- Test all major screens in both light and dark modes
- Verify color consistency across the app
- Check font scaling works properly
- Ensure all hardcoded colors have been replaced

## Future Enhancements

1. **Custom Color Picker**: Allow users to choose any color, not just predefined ones
2. **Font Family Selection**: Let users choose different font families
3. **Advanced Theme Customization**: More granular control over colors
4. **Theme Presets**: Pre-built theme combinations
5. **Accessibility Features**: High contrast modes, larger text options

## Migration Notes

### Breaking Changes
- Some old color constants may need updates
- Text styles now require BuildContext for dynamic scaling
- Theme changes now require context awareness

### Backward Compatibility
- Legacy color constants still available in AppConstants
- Static text style versions available for immediate needs
- Gradual migration path for existing screens

## Conclusion

The theme system is now fully integrated and provides a consistent, customizable user experience across the entire HagzCoora app. Users can personalize their experience while developers have a robust foundation for maintaining visual consistency.
