import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
  Future<String?> readRememberedEmail();
  Future<void> saveRememberedEmail(String email);
  Future<void> clearRememberedEmail();
  Future<String?> readThemeMode();
  Future<void> saveThemeMode(String themeMode);
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const String _key = 'xe_truong_admin_jwt';
  static const String _rememberedEmailKey = 'xe_truong_admin_remembered_email';
  static const String _themeModeKey = 'xe_truong_admin_theme_mode';

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _key);

  @override
  Future<String?> readRememberedEmail() =>
      _storage.read(key: _rememberedEmailKey);

  @override
  Future<void> saveRememberedEmail(String email) =>
      _storage.write(key: _rememberedEmailKey, value: email);

  @override
  Future<void> clearRememberedEmail() =>
      _storage.delete(key: _rememberedEmailKey);

  @override
  Future<String?> readThemeMode() => _storage.read(key: _themeModeKey);

  @override
  Future<void> saveThemeMode(String themeMode) =>
      _storage.write(key: _themeModeKey, value: themeMode);
}
