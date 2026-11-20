import 'dart:async';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

/// Interceptor cho HTTP Client tự động phát hiện mã 401 (hết hạn token)
/// trên các yêu cầu được xác thực, tự động dọn dẹp token và thông báo hết hạn phiên.
class AuthHttpInterceptor extends http.BaseClient {
  AuthHttpInterceptor({
    required http.Client inner,
    required TokenStorage storage,
    required void Function() onSessionExpired,
  })  : _inner = inner,
        _storage = storage,
        _onSessionExpired = onSessionExpired;

  final http.Client _inner;
  final TokenStorage _storage;
  final void Function() _onSessionExpired;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);

    // Không xử lý hết hạn cho endpoint đăng nhập (401 tại dang-nhap là sai tài khoản/mật khẩu)
    final laYeuCauDangNhap = request.url.path.endsWith('/dang-nhap');
    if (response.statusCode == 401 && !laYeuCauDangNhap) {
      unawaited(_storage.clearToken());
      _onSessionExpired();
    }

    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
