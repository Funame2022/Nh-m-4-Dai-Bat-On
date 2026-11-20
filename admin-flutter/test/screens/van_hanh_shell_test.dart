import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/auth/auth_service.dart';
import 'package:xe_truong_admin/models/nguoi_dung.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';
import 'package:xe_truong_admin/screens/van_hanh_shell.dart';

import '../support/fake_token_storage.dart';

void main() {
  const driverUser = NguoiDung(
    id: 10,
    email: 'taixe@xetruong.vn',
    hoTen: 'Trần Văn Lái Xe',
    vaiTro: 'TAI_XE',
    sdt: '0988776655',
  );

  Widget createTestWidget({
    NguoiDung nguoiDung = driverUser,
    http.Client? client,
    Future<void> Function()? onLogout,
    Future<void> Function()? onToggleTheme,
  }) {
    final storage = FakeTokenStorage('test-token');
    final httpClient = client ??
        MockClient(
          (_) async => http.Response(
            jsonEncode([]),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

    final authService = AuthService(
      client: httpClient,
      storage: storage,
      baseUrl: 'http://api.test',
    );
    final vanHanhService = VanHanhService(
      client: httpClient,
      storage: storage,
      baseUrl: 'http://api.test',
    );

    return MaterialApp(
      home: VanHanhShell(
        nguoiDung: nguoiDung,
        authService: authService,
        vanHanhService: vanHanhService,
        onLogout: onLogout ?? () async {},
        onSwitchAccount: () async {},
        onUserUpdated: (_) {},
        isDark: false,
        onToggleTheme: onToggleTheme ?? () async {},
      ),
    );
  }

  testWidgets('Hiển thị đầy đủ thông tin ca trực và nhãn TÀI XẾ', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('van-hanh-shell')), findsOneWidget);
    expect(find.text('TÀI XẾ'), findsOneWidget);
    expect(find.text('Trần Văn Lái Xe'), findsNWidgets(2)); // AppBar and Card
    expect(find.byKey(const Key('card-ca-truc-header')), findsOneWidget);
    expect(find.text('Sẵn sàng'), findsOneWidget);
  });

  testWidgets('Chuyển tab sang Hồ sơ hiển thị màn hình cài đặt', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Bấm vào tab 'Hồ sơ' trên bottom nav
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt & Hồ sơ'), findsOneWidget);
    expect(find.byKey(const Key('card-ca-truc-header')), findsNothing);
  });

  testWidgets('Bấm nút đăng xuất hiển thị Dialog xác nhận; chọn Hủy giữ nguyên màn hình', (tester) async {
    bool loggedOut = false;
    await tester.pumpWidget(createTestWidget(onLogout: () async {
      loggedOut = true;
    }));
    await tester.pumpAndSettle();

    // Bấm nút đăng xuất trên AppBar
    await tester.tap(find.byKey(const Key('btn-logout')));
    await tester.pumpAndSettle();

    // Thấy dialog xác nhận
    expect(find.byKey(const Key('dialog-logout-confirm')), findsOneWidget);
    expect(find.text('Bạn có chắc chắn muốn kết thúc ca làm việc và đăng xuất không?'), findsOneWidget);

    // Bấm Hủy
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dialog-logout-confirm')), findsNothing);
    expect(loggedOut, isFalse);
  });

  testWidgets('Xác nhận đăng xuất trong Dialog gọi onLogout', (tester) async {
    bool loggedOut = false;
    await tester.pumpWidget(createTestWidget(onLogout: () async {
      loggedOut = true;
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-logout')));
    await tester.pumpAndSettle();

    // Bấm nút Đăng xuất trong dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
  });

  testWidgets('Bấm nút đổi theme gọi onToggleTheme', (tester) async {
    bool themeToggled = false;
    await tester.pumpWidget(createTestWidget(onToggleTheme: () async {
      themeToggled = true;
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-toggle-theme')));
    await tester.pumpAndSettle();

    expect(themeToggled, isTrue);
  });
}
