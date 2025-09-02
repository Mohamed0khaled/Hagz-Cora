/// Validation utility class for input validation
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Display name is required';
    }

    // Trim whitespace
    final trimmedValue = value.trim();

    // Check minimum length
    if (trimmedValue.length < 2) {
      return 'Display name must be at least 2 characters';
    }

    // Check maximum length
    if (trimmedValue.length > 50) {
      return 'Display name must be less than 50 characters';
    }

    // Check for valid characters (letters, numbers, spaces, hyphens, apostrophes, dots)
    if (!RegExp(r"^[a-zA-Z0-9\s\-'.]+$").hasMatch(trimmedValue)) {
      return 'Display name contains invalid characters';
    }

    return null;
  }

  /// Validate image file
  static String? validateImageFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return null; // Image is optional
    }

    final extension = filePath.split('.').last.toLowerCase();
    const supportedFormats = ['jpg', 'jpeg', 'png'];

    if (!supportedFormats.contains(extension)) {
      return 'Supported formats: ${supportedFormats.join(', ')}';
    }

    return null;
  }
}

/// Utility class for formatting data
class FormatUtils {
  /// Format file size in bytes to human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get initials from display name
  static String getInitials(String displayName) {
    if (displayName.isEmpty) return '';
    
    final words = displayName.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
