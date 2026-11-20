import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/app.dart';
import 'package:xe_truong_admin/auth/auth_service.dart';
import 'package:xe_truong_admin/fleet/quan_ly_service.dart';
import 'package:xe_truong_admin/operations/quan_ly_operations_service.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';

import 'support/fake_token_storage.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, Object?> nguoiDungJson({
  required String vaiTro,
  required String hoTen,
  required String email,
}) =>
    {
      'id': 1,
      'email': email,
      'hoTen': hoTen,
      'sdt': '0901234567',
      'vaiTro': vaiTro,
    };

Future<void> pumpTestApp(
  WidgetTester tester, {
  required FakeTokenStorage storage,
  required http.Client client,
}) async {
  final authService = AuthService(
    client: client,
    storage: storage,
    baseUrl: 'http://api.test',
  );

  await tester.pumpWidget(
    AdminApp(
      authService: authService,
      quanLyService: QuanLyService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      ),
      operationsService: QuanLyOperationsService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      ),
      vanHanhService: VanHanhService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> thucHienDangNhap(
  WidgetTester tester, {
  required String email,
  required String matKhau,
}) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), matKhau);
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Đăng nhập QUAN_LY điều hướng vào AdminShell', (tester) async {
    final storage = FakeTokenStorage();
    final client = MockClient((req) async {
      return jsonResponse({
        'token': 'jwt-admin',
        'nguoiDung': nguoiDungJson(
          vaiTro: 'QUAN_LY',
          hoTen: 'Nguyễn Văn Quản Lý',
          email: 'admin@xetruong.vn',
        ),
      });
    });

    await pumpTestApp(tester, storage: storage, client: client);
    await thucHienDangNhap(tester, email: 'admin@xetruong.vn', matKhau: '123456');

    expect(find.byKey(const Key('admin-shell')), findsOneWidget);
    expect(find.byKey(const Key('van-hanh-shell')), findsNothing);
  });

  testWidgets('Đăng nhập TAI_XE điều hướng vào VanHanhShell với nhãn TÀI XẾ', (tester) async {
    final storage = FakeTokenStorage();
    final client = MockClient((req) async {
      return jsonResponse({
        'token': 'jwt-driver',
        'nguoiDung': nguoiDungJson(
          vaiTro: 'TAI_XE',
          hoTen: 'Trần Văn Lái Xe',
          email: 'taixe@xetruong.vn',
        ),
      });
    });

    await pumpTestApp(tester, storage: storage, client: client);
    await thucHienDangNhap(tester, email: 'taixe@xetruong.vn', matKhau: '123456');

    expect(find.byKey(const Key('van-hanh-shell')), findsOneWidget);
    expect(find.byKey(const Key('admin-shell')), findsNothing);
    expect(find.text('TÀI XẾ'), findsOneWidget);
    expect(find.text('Trần Văn Lái Xe'), findsOneWidget);
  });

  testWidgets('Đăng nhập BAO_MAU điều hướng vào VanHanhShell với nhãn BẢO MẪU', (tester) async {
    final storage = FakeTokenStorage();
    final client = MockClient((req) async {
      return jsonResponse({
        'token': 'jwt-monitor',
        'nguoiDung': nguoiDungJson(
          vaiTro: 'BAO_MAU',
          hoTen: 'Lê Thị Bảo Mẫu',
          email: 'baomau@xetruong.vn',
        ),
      });
    });

    await pumpTestApp(tester, storage: storage, client: client);
    await thucHienDangNhap(tester, email: 'baomau@xetruong.vn', matKhau: '123456');

    expect(find.byKey(const Key('van-hanh-shell')), findsOneWidget);
    expect(find.byKey(const Key('admin-shell')), findsNothing);
    expect(find.text('BẢO MẪU'), findsOneWidget);
    expect(find.text('Lê Thị Bảo Mẫu'), findsOneWidget);
  });

  testWidgets('Đăng xuất từ VanHanhShell quay về LoginScreen', (tester) async {
    final storage = FakeTokenStorage();
    final client = MockClient((req) async {
      return jsonResponse({
        'token': 'jwt-driver',
        'nguoiDung': nguoiDungJson(
          vaiTro: 'TAI_XE',
          hoTen: 'Trần Văn Lái Xe',
          email: 'taixe@xetruong.vn',
        ),
      });
    });

    await pumpTestApp(tester, storage: storage, client: client);
    await thucHienDangNhap(tester, email: 'taixe@xetruong.vn', matKhau: '123456');

    expect(find.byKey(const Key('van-hanh-shell')), findsOneWidget);

    // Bấm nút đăng xuất trên AppBar của VanHanhShell
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('van-hanh-shell')), findsNothing);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(storage.token, isNull);
  });
}
