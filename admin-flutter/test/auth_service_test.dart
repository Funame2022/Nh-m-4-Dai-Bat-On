import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/auth/auth_service.dart';

import 'support/fake_token_storage.dart';

http.Response jsonResponse(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

Map<String, Object?> nguoiDungJson(String vaiTro) => {
  'id': 1,
  'email': 'admin@xetruong.vn',
  'hoTen': 'Nguyễn Văn Quản Lý',
  'sdt': '0901000001',
  'vaiTro': vaiTro,
};

AuthService taoAuthService(http.Client client, FakeTokenStorage storage) =>
    AuthService(client: client, storage: storage, baseUrl: 'http://api.test');

void main() {
  group('login', () {
    test('gửi đúng body và lưu token cho QUAN_LY', () async {
      final storage = FakeTokenStorage();
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({
          'token': 'jwt-admin',
          'nguoiDung': nguoiDungJson('QUAN_LY'),
        }, 200);
      });

      final nguoiDung = await taoAuthService(
        client,
        storage,
      ).login(email: 'admin@xetruong.vn', matKhau: '123456');

      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://api.test/api/auth/dang-nhap');
      expect(jsonDecode(request.body), {
        'email': 'admin@xetruong.vn',
        'matKhau': '123456',
      });
      expect(nguoiDung.vaiTro, 'QUAN_LY');
      expect(nguoiDung.hoTen, 'Nguyễn Văn Quản Lý');
      expect(storage.token, 'jwt-admin');
      expect(storage.saveCount, 1);
    });

    for (final vaiTro in ['TAI_XE', 'BAO_MAU']) {
      test('cho phép vai trò $vaiTro đăng nhập và lưu token', () async {
        final storage = FakeTokenStorage();
        final client = MockClient(
          (_) async => jsonResponse({
            'token': 'jwt-$vaiTro',
            'nguoiDung': nguoiDungJson(vaiTro),
          }, 200),
        );

        final nguoiDung = await taoAuthService(
          client,
          storage,
        ).login(email: 'test@xetruong.vn', matKhau: '123456');

        expect(nguoiDung.vaiTro, vaiTro);
        expect(storage.token, 'jwt-$vaiTro');
        expect(storage.saveCount, 1);
      });
    }

    for (final vaiTro in ['PHU_HUYNH', 'UNKNOWN']) {
      test('từ chối vai trò $vaiTro và không lưu token', () async {
        final storage = FakeTokenStorage();
        final client = MockClient(
          (_) async => jsonResponse({
            'token': 'jwt-sai-quyen',
            'nguoiDung': nguoiDungJson(vaiTro),
          }, 200),
        );

        await expectLater(
          taoAuthService(
            client,
            storage,
          ).login(email: 'user@xetruong.vn', matKhau: '123456'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('quyền truy cập'),
            ),
          ),
        );

        expect(storage.token, isNull);
        expect(storage.saveCount, 0);
      });
    }

    test('401 báo lỗi và không lưu token', () async {
      final storage = FakeTokenStorage();
      final client = MockClient((_) async => http.Response('', 401));

      await expectLater(
        taoAuthService(
          client,
          storage,
        ).login(email: 'admin@xetruong.vn', matKhau: 'sai'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('Sai email')),
        ),
      );

      expect(storage.token, isNull);
      expect(storage.saveCount, 0);
    });

    test('lỗi mạng là retryable và không lưu token', () async {
      final storage = FakeTokenStorage();
      final client = MockClient((_) async {
        throw http.ClientException('offline');
      });

      await expectLater(
        taoAuthService(
          client,
          storage,
        ).login(email: 'admin@xetruong.vn', matKhau: '123456'),
        throwsA(
          isA<AuthException>().having((e) => e.retryable, 'retryable', true),
        ),
      );

      expect(storage.token, isNull);
      expect(storage.saveCount, 0);
    });
  });

  group('restoreSession', () {
    test('khôi phục QUAN_LY từ /toi với dữ liệu snake_case', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({
          'id': 7,
          'email': 'admin@xetruong.vn',
          'ho_ten': 'Nguyễn Văn Quản Lý',
          'sdt': '0901000001',
          'vai_tro': 'QUAN_LY',
        }, 200);
      });

      final nguoiDung = await taoAuthService(client, storage).restoreSession();

      expect(request.url.toString(), 'http://api.test/api/auth/toi');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(nguoiDung, isNotNull);
      expect(nguoiDung!.id, 7);
      expect(nguoiDung.hoTen, 'Nguyễn Văn Quản Lý');
      expect(nguoiDung.vaiTro, 'QUAN_LY');
      expect(storage.token, 'saved-token');
      expect(storage.clearCount, 0);
    });

    test('401 xóa token đã lưu và trở về đăng nhập', () async {
      final storage = FakeTokenStorage('saved-token');
      final client = MockClient((_) async => http.Response('', 401));

      final nguoiDung = await taoAuthService(client, storage).restoreSession();

      expect(nguoiDung, isNull);
      expect(storage.token, isNull);
      expect(storage.clearCount, 1);
    });

    test('403 không được coi là thành công và xóa token', () async {
      final storage = FakeTokenStorage('saved-token');
      final client = MockClient((_) async => http.Response('', 403));

      final nguoiDung = await taoAuthService(client, storage).restoreSession();

      expect(nguoiDung, isNull);
      expect(storage.token, isNull);
      expect(storage.clearCount, 1);
    });

    test('vai trò không phải QUAN_LY bị xóa phiên', () async {
      final storage = FakeTokenStorage('saved-token');
      final client = MockClient(
        (_) async => jsonResponse({
          'id': 2,
          'email': 'taixe@xetruong.vn',
          'ho_ten': 'Trần Văn Tài Xế',
          'sdt': '0901000002',
          'vai_tro': 'TAI_XE',
        }, 200),
      );

      final nguoiDung = await taoAuthService(client, storage).restoreSession();

      expect(nguoiDung, isNull);
      expect(storage.token, isNull);
      expect(storage.clearCount, 1);
    });

    test('lỗi mạng là retryable và giữ token để thử lại', () async {
      final storage = FakeTokenStorage('saved-token');
      final client = MockClient((_) async {
        throw http.ClientException('offline');
      });

      await expectLater(
        taoAuthService(client, storage).restoreSession(),
        throwsA(
          isA<AuthException>().having((e) => e.retryable, 'retryable', true),
        ),
      );

      expect(storage.token, 'saved-token');
      expect(storage.clearCount, 0);
    });
  });

  group('cài đặt tài khoản', () {
    test('đổi tên gửi PATCH có xác thực và đọc hồ sơ mới', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({
          'id': 1,
          'email': 'admin@xetruong.vn',
          'ho_ten': 'Quản trị viên mới',
          'vai_tro': 'QUAN_LY',
        }, 200);
      });

      final user = await taoAuthService(
        client,
        storage,
      ).doiTen('Quản trị viên mới');

      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/auth/toi');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(jsonDecode(request.body), {'hoTen': 'Quản trị viên mới'});
      expect(user.hoTen, 'Quản trị viên mới');
    });

    test('đổi mật khẩu chỉ gửi dữ liệu trong phiên đã xác thực', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({'thongBao': 'Đã đổi mật khẩu'}, 200);
      });

      await taoAuthService(client, storage).doiMatKhau(
        matKhauHienTai: 'MatKhauCu123!',
        matKhauMoi: 'MatKhauMoi123!',
      );

      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/auth/mat-khau');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(jsonDecode(request.body), {
        'matKhauHienTai': 'MatKhauCu123!',
        'matKhauMoi': 'MatKhauMoi123!',
      });
    });
  });

  test('logout xóa token', () async {
    final storage = FakeTokenStorage('saved-token');
    final client = MockClient((_) async => http.Response('', 500));

    await taoAuthService(client, storage).logout();

    expect(storage.token, isNull);
    expect(storage.clearCount, 1);
  });
}
