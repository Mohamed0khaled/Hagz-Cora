import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Provider for managing app-wide theme settings
/// Handles light/dark mode, theme persistence, and theme-related state
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _fontSizeKey = 'font_size_scale';
  static const String _languageKey = 'app_language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';

  // Theme State
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(0xFF2E7D32); // Football green default
  double _fontSizeScale = 1.0;
  String _languageCode = 'en';
  
  // App Settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Loading state
  bool _isInitialized = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  double get fontSizeScale => _fontSizeScale;
  String get languageCode => _languageCode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  // Legacy compatibility
  String get fontSize => getFontSizeDescription();
  String get language => _languageCode;

  /// Initialize theme provider and load saved preferences
  Future<void> initializeTheme() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }
      
      // Load primary color
      final colorValue = prefs.getInt(_primaryColorKey);
      if (colorValue != null) {
        _primaryColor = Color(colorValue);
      }
      
      // Load font size scale
      _fontSizeScale = prefs.getDouble(_fontSizeKey) ?? 1.0;
      
      // Load language
      _languageCode = prefs.getString(_languageKey) ?? 'en';
      
      // Load app settings
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing theme provider: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set theme mode (light, dark, system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Set primary color theme
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor == color) return;
    
    _primaryColor = color;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_primaryColorKey, color.value);
    } catch (e) {
      debugPrint('Error saving primary color: $e');
    }
  }

  /// Set font size scale
  Future<void> setFontSizeScale(double scale) async {
    if (_fontSizeScale == scale) return;
    
    _fontSizeScale = scale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, scale);
    } catch (e) {
      debugPrint('Error saving font size scale: $e');
    }
  }

  /// Set app language
  Future<void> setLanguage(String languageCode) async {
    if (_languageCode == languageCode) return;
    
    _languageCode = languageCode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  /// Set font size (legacy method for compatibility)
  Future<void> setFontSize(String fontSize) async {
    double scale;
    switch (fontSize) {
      case 'Small':
        scale = 0.85;
        break;
      case 'Large':
        scale = 1.15;
        break;
      case 'Extra Large':
        scale = 1.3;
        break;
      case 'Medium':
      default:
        scale = 1.0;
        break;
    }
    await setFontSizeScale(scale);
  }

  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    
    _notificationsEnabled = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, enabled);
    } catch (e) {
      debugPrint('Error saving notifications setting: $e');
    }
  }

  /// Toggle sound
  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled) return;
    
    _soundEnabled = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error saving sound setting: $e');
    }
  }

  /// Toggle vibration
  Future<void> setVibrationEnabled(bool enabled) async {
    if (_vibrationEnabled == enabled) return;
    
    _vibrationEnabled = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error saving vibration setting: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Reset all theme settings to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _primaryColor = const Color(0xFF2E7D32);
    _fontSizeScale = 1.0;
    _languageCode = 'en';
    _notificationsEnabled = true;
    _soundEnabled = true;
    _vibrationEnabled = true;
    
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      await prefs.remove(_primaryColorKey);
      await prefs.remove(_fontSizeKey);
      await prefs.remove(_languageKey);
      await prefs.remove(_notificationsKey);
      await prefs.remove(_soundEnabledKey);
      await prefs.remove(_vibrationEnabledKey);
    } catch (e) {
      debugPrint('Error resetting theme settings: $e');
    }
  }

  /// Get predefined theme colors
  static List<Color> get predefinedColors => [
    const Color(0xFF2E7D32), // Green (Football theme)
    const Color(0xFF1976D2), // Blue  
    const Color(0xFFD32F2F), // Red
    const Color(0xFFFF6F00), // Orange
    const Color(0xFF7B1FA2), // Purple
    const Color(0xFF00796B), // Teal
    const Color(0xFF5D4037), // Brown
    const Color(0xFF455A64), // Blue Grey
  ];

  /// Get theme description
  String getThemeDescription() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'System default';
    }
  }

  /// Get font size description
  String getFontSizeDescription() {
    if (_fontSizeScale <= 0.9) return 'Small';
    if (_fontSizeScale <= 1.1) return 'Medium';
    if (_fontSizeScale <= 1.2) return 'Large';
    return 'Extra Large';
  }

  /// Get light theme data
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: _getTextTheme(Brightness.light),
  );

  /// Get dark theme data
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: _getTextTheme(Brightness.dark),
  );

  /// Get text theme based on font size setting
  TextTheme _getTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light 
        ? Colors.black87 
        : Colors.white;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32 * _fontSizeScale,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28 * _fontSizeScale,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 24 * _fontSizeScale,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20 * _fontSizeScale,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18 * _fontSizeScale,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16 * _fontSizeScale,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * _fontSizeScale,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * _fontSizeScale,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * _fontSizeScale,
        color: textColor.withOpacity(0.7),
      ),
    );
  }
}
