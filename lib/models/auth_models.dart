/// Authentication state enumeration
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication result model
class AuthResult {
  final bool success;
  final String? errorMessage;
  final dynamic data;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory AuthResult.success({dynamic data}) {
    return AuthResult(
      success: true,
      data: data,
    );
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Sign-in method enumeration
enum SignInMethod {
  google,
  apple,
  email,
  phone,
}
