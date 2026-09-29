class AppConstants {
  // Swap this to your VPS IP in Phase 5
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL', 
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  // flutter_secure_storage keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String refreshTokenKey = 'refresh_token';
}