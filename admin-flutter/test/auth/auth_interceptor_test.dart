import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/auth/auth_interceptor.dart';
import 'package:xe_truong_admin/auth/auth_service.dart';

import '../support/fake_token_storage.dart';

void main() {
  group('AuthHttpInterceptor', () {
    test('401 trên API thông thường tự động xóa token và gọi onSessionExpired', () async {
      final storage = FakeTokenStorage('existing-token');
      bool sessionExpiredCalled = false;

      final inner = MockClient((req) async {
        return http.Response(jsonEncode({'loi': 'Token het han'}), 401);
      });

      final interceptor = AuthHttpInterceptor(
        inner: inner,
        storage: storage,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      final response = await interceptor.get(Uri.parse('http://api.test/api/van-hanh/chuyen-hom-nay'));

      expect(response.statusCode, 401);
      expect(sessionExpiredCalled, isTrue);
      // Đợi microtask clearToken
      await Future<void>.delayed(Duration.zero);
      expect(storage.token, isNull);
    });

    test('401 trên API /dang-nhap KHÔNG gọi onSessionExpired (sai mật khẩu)', () async {
      final storage = FakeTokenStorage();
      bool sessionExpiredCalled = false;

      final inner = MockClient((req) async {
        return http.Response(jsonEncode({'loi': 'Sai email hoac mat khau'}), 401);
      });

      final interceptor = AuthHttpInterceptor(
        inner: inner,
        storage: storage,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      final response = await interceptor.post(Uri.parse('http://api.test/api/auth/dang-nhap'));

      expect(response.statusCode, 401);
      expect(sessionExpiredCalled, isFalse);
    });

    test('200 thành công không xóa token và không gọi onSessionExpired', () async {
      final storage = FakeTokenStorage('valid-token');
      bool sessionExpiredCalled = false;

      final inner = MockClient((req) async {
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final interceptor = AuthHttpInterceptor(
        inner: inner,
        storage: storage,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      final response = await interceptor.get(Uri.parse('http://api.test/api/van-hanh/chuyen-hom-nay'));

      expect(response.statusCode, 200);
      expect(sessionExpiredCalled, isFalse);
      expect(storage.token, 'valid-token');
    });
  });

  group('AuthService notifySessionExpired', () {
    test('phát sự kiện onSessionExpired và xóa token', () async {
      final storage = FakeTokenStorage('my-token');
      final authService = AuthService(
        client: http.Client(),
        storage: storage,
        baseUrl: 'http://api.test',
      );

      bool notified = false;
      final sub = authService.onSessionExpired.listen((_) {
        notified = true;
      });

      authService.notifySessionExpired();

      await Future<void>.delayed(Duration.zero);
      expect(notified, isTrue);
      expect(storage.token, isNull);

      await sub.cancel();
      authService.dispose();
    });
  });
}
