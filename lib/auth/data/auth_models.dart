enum UserRole {
  patient,
  doctor,
  companion,
  facility;

  String get value => name;
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'] ?? 'bearer',
    );
  }
}
