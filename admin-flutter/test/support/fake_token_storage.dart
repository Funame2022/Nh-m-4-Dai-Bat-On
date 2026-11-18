import 'package:xe_truong_admin/auth/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this.token, this.themeMode]);

  FakeTokenStorage.withRememberedEmail({
    this.token,
    this.rememberedEmail,
    this.themeMode,
  });

  String? token;
  String? rememberedEmail;
  String? themeMode;
  String? notificationsEnabled;
  int saveCount = 0;
  int clearCount = 0;
  int rememberedEmailSaveCount = 0;
  int rememberedEmailClearCount = 0;
  int themeModeSaveCount = 0;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async {
    token = value;
    saveCount += 1;
  }

  @override
  Future<void> clearToken() async {
    token = null;
    clearCount += 1;
  }

  @override
  Future<String?> readRememberedEmail() async => rememberedEmail;

  @override
  Future<void> saveRememberedEmail(String email) async {
    rememberedEmail = email;
    rememberedEmailSaveCount += 1;
  }

  @override
  Future<void> clearRememberedEmail() async {
    rememberedEmail = null;
    rememberedEmailClearCount += 1;
  }

  @override
  Future<String?> readThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(String value) async {
    themeMode = value;
    themeModeSaveCount += 1;
  }

  @override
  Future<String?> readNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    notificationsEnabled = '$enabled';
  }
}
