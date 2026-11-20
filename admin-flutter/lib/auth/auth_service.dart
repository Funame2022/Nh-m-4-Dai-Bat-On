import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/nguoi_dung.dart';
import 'token_storage.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode, this.retryable = false});

  final String message;
  final int? statusCode;
  final bool retryable;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    required http.Client client,
    required TokenStorage storage,
    required String baseUrl,
  }) : this._(client, storage, baseUrl.trim());

  AuthService._(this._client, this._storage, this.baseUrl);

  final http.Client _client;
  final TokenStorage _storage;
  final String baseUrl;
  final _sessionExpiredController = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  void notifySessionExpired() {
    _storage.clearToken();
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  void dispose() {
    _sessionExpiredController.close();
  }

  static const Duration _timeout = Duration(seconds: 20);

  bool get daCauHinh => baseUrl.isNotEmpty;

  Future<String?> readRememberedEmail() => _storage.readRememberedEmail();

  Future<void> rememberEmail(String email) =>
      _storage.saveRememberedEmail(email);

  Future<void> clearRememberedEmail() => _storage.clearRememberedEmail();

  Future<String?> readThemeMode() => _storage.readThemeMode();

  Future<void> saveThemeMode(String themeMode) =>
      _storage.saveThemeMode(themeMode);

  Future<bool> readNotificationsEnabled() async =>
      await _storage.readNotificationsEnabled() == 'true';

  Future<void> saveNotificationsEnabled(bool enabled) =>
      _storage.saveNotificationsEnabled(enabled);

  Uri _uri(String path) {
    final goc = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$goc$path');
  }

  Future<NguoiDung> login({
    required String email,
    required String matKhau,
  }) async {
    if (!daCauHinh) {
      throw const AuthException(ApiConfig.thongDiepChuaCauHinh);
    }

    http.Response response;
    try {
      response = await _client
          .post(
            _uri('/api/auth/dang-nhap'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'matKhau': matKhau}),
          )
          .timeout(_timeout);
    } on Exception {
      throw const AuthException(
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
        retryable: true,
      );
    }

    if (response.statusCode == 401) {
      throw const AuthException('Sai email hoặc mật khẩu.', statusCode: 401);
    }

    if (response.statusCode != 200) {
      throw AuthException(
        'Đăng nhập thất bại (mã ${response.statusCode}).',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500,
      );
    }

    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi không phải JSON object');
      }

      final token = json['token'];
      final nguoiDungJson = json['nguoiDung'];
      if (token is! String ||
          token.isEmpty ||
          nguoiDungJson is! Map<String, dynamic>) {
        throw const FormatException('Thiếu token hoặc người dùng');
      }

      final nguoiDung = NguoiDung.fromJson(nguoiDungJson);
      if (!nguoiDung.coQuyenAdminApp) {
        throw const AuthException(
          'Tài khoản không có quyền truy cập ứng dụng (chỉ dành cho Quản lý, Tài xế hoặc Bảo mẫu).',
          statusCode: 403,
        );
      }

      await _storage.saveToken(token);
      return nguoiDung;
    } on AuthException {
      rethrow;
    } on FormatException {
      throw const AuthException('Phản hồi đăng nhập không hợp lệ.');
    } catch (_) {
      throw const AuthException('Không thể đọc phản hồi đăng nhập.');
    }
  }

  Future<NguoiDung?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    http.Response response;
    try {
      response = await _client
          .get(
            _uri('/api/auth/toi'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);
    } on Exception {
      throw const AuthException(
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
        retryable: true,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await _storage.clearToken();
      return null;
    }

    if (response.statusCode != 200) {
      throw AuthException(
        'Không thể kiểm tra phiên đăng nhập (mã ${response.statusCode}).',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500,
      );
    }

    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi không phải JSON object');
      }

      final nguoiDung = NguoiDung.fromJson(json);
      if (!nguoiDung.coQuyenAdminApp) {
        await _storage.clearToken();
        return null;
      }
      return nguoiDung;
    } catch (_) {
      await _storage.clearToken();
      return null;
    }
  }

  Future<void> logout() => _storage.clearToken();

  Future<NguoiDung> doiTen(String hoTen) async {
    final json = await _authenticatedPatch('/api/auth/toi', {'hoTen': hoTen});
    return NguoiDung.fromJson(json);
  }

  Future<void> doiMatKhau({
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    await _authenticatedPatch('/api/auth/mat-khau', {
      'matKhauHienTai': matKhauHienTai,
      'matKhauMoi': matKhauMoi,
    });
  }

  Future<Map<String, dynamic>> _authenticatedPatch(
    String path,
    Map<String, Object?> body,
  ) async {
    if (!daCauHinh) {
      throw const AuthException(ApiConfig.thongDiepChuaCauHinh);
    }

    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.',
      );
    }

    http.Response response;
    try {
      response = await _client
          .patch(
            _uri(path),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on Exception {
      throw const AuthException(
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
        retryable: true,
      );
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi không hợp lệ');
      }
      json = decoded;
    } on FormatException {
      throw const AuthException('Phản hồi máy chủ không hợp lệ.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = json['loi'];
      throw AuthException(
        message is String ? message : 'Không thể cập nhật tài khoản.',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500,
      );
    }
    return json;
  }
}
