import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/app.dart';
import 'package:xe_truong_admin/auth/auth_service.dart';
import 'package:xe_truong_admin/fleet/quan_ly_service.dart';
import 'package:xe_truong_admin/operations/quan_ly_operations_service.dart';
import 'package:xe_truong_admin/widgets/brand_background.dart';

import 'support/fake_fleet_backend.dart';
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

Future<void> pumpAdminApp(
  WidgetTester tester, {
  required FakeTokenStorage storage,
  required http.Client client,
  QuanLyOperationsService? operationsService,
}) async {
  await tester.pumpWidget(
    AdminApp(
      authService: AuthService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      ),
      quanLyService: QuanLyService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      ),
      operationsService:
          operationsService ??
          QuanLyOperationsService(
            client: client,
            storage: storage,
            baseUrl: 'http://api.test',
            giamSatConnector: (_, _) =>
                Future<GiamSatConnection>.error(StateError('offline')),
          ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> dangNhap(
  WidgetTester tester, {
  String email = 'admin@xetruong.vn',
  String matKhau = '123456',
}) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), matKhau);
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('đăng nhập QUAN_LY lưu token và mở Admin shell', (tester) async {
    final storage = FakeTokenStorage();
    final client = MockClient(
      (_) async => jsonResponse({
        'token': 'jwt-admin',
        'nguoiDung': nguoiDungJson('QUAN_LY'),
      }, 200),
    );

    await pumpAdminApp(tester, storage: storage, client: client);

    expect(find.text('Đăng nhập dành cho quản lý'), findsOneWidget);
    await dangNhap(tester);

    expect(find.byKey(const Key('admin-shell')), findsOneWidget);
    expect(find.byKey(const Key('overview-greeting')), findsOneWidget);
    expect(storage.token, 'jwt-admin');
    expect(storage.saveCount, 1);
  });

  testWidgets('màn đăng nhập gọn trên điện thoại và cho phép hiện mật khẩu', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await pumpAdminApp(
      tester,
      storage: FakeTokenStorage(),
      client: MockClient((_) async => http.Response('', 401)),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('login-background-art')), findsOneWidget);
    expect(find.byKey(const Key('login-brand-logo')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == BrandAssets.background,
      ),
      findsOneWidget,
    );
    expect(find.text('Xe Trường Admin'), findsOneWidget);
    expect(find.text('Đăng nhập dành cho quản lý'), findsOneWidget);
    final editablePassword = find.descendant(
      of: find.byKey(const Key('login-password')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editablePassword).obscureText, isTrue);

    await tester.tap(find.byKey(const Key('login-password-visibility')));
    await tester.pump();

    expect(tester.widget<EditableText>(editablePassword).obscureText, isFalse);
  });

  testWidgets('khôi phục email đã ghi nhớ nhưng không khôi phục mật khẩu', (
    tester,
  ) async {
    final storage = FakeTokenStorage.withRememberedEmail(
      rememberedEmail: 'da-nho@xetruong.vn',
    );
    await pumpAdminApp(
      tester,
      storage: storage,
      client: MockClient((_) async => http.Response('', 401)),
    );

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('login-email')))
          .controller
          ?.text,
      'da-nho@xetruong.vn',
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('login-remember-account')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('login-password')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('ghi nhớ email chỉ sau khi QUAN_LY đăng nhập thành công', (
    tester,
  ) async {
    final storage = FakeTokenStorage();
    final client = MockClient(
      (_) async => jsonResponse({
        'token': 'jwt-admin',
        'nguoiDung': nguoiDungJson('QUAN_LY'),
      }, 200),
    );
    await pumpAdminApp(tester, storage: storage, client: client);
    await tester.tap(find.byKey(const Key('login-remember-account')));
    await tester.pump();
    await dangNhap(tester, email: 'moi@xetruong.vn');

    expect(storage.rememberedEmail, 'moi@xetruong.vn');
    expect(storage.rememberedEmailSaveCount, 1);
    expect(find.byKey(const Key('admin-shell')), findsOneWidget);
  });

  testWidgets('bỏ chọn ghi nhớ sẽ xóa email cũ sau khi đăng nhập', (
    tester,
  ) async {
    final storage = FakeTokenStorage.withRememberedEmail(
      rememberedEmail: 'cu@xetruong.vn',
    );
    final client = MockClient(
      (_) async => jsonResponse({
        'token': 'jwt-admin',
        'nguoiDung': nguoiDungJson('QUAN_LY'),
      }, 200),
    );
    await pumpAdminApp(tester, storage: storage, client: client);
    await tester.tap(find.byKey(const Key('login-remember-account')));
    await tester.pump();
    await dangNhap(tester, email: 'khac@xetruong.vn');

    expect(storage.rememberedEmail, isNull);
    expect(storage.rememberedEmailClearCount, 1);
  });

  testWidgets('vai trò không phải QUAN_LY bị từ chối, không lưu token', (
    tester,
  ) async {
    final storage = FakeTokenStorage();
    final client = MockClient(
      (_) async => jsonResponse({
        'token': 'jwt-sai-quyen',
        'nguoiDung': nguoiDungJson('TAI_XE'),
      }, 200),
    );

    await pumpAdminApp(tester, storage: storage, client: client);
    await dangNhap(tester);

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.textContaining('không có quyền quản lý'), findsOneWidget);
    expect(find.byKey(const Key('admin-shell')), findsNothing);
    expect(storage.token, isNull);
    expect(storage.saveCount, 0);
  });

  testWidgets('401 hiển thị lỗi và không lưu token', (tester) async {
    final storage = FakeTokenStorage();
    final client = MockClient((_) async => http.Response('', 401));

    await pumpAdminApp(tester, storage: storage, client: client);
    await dangNhap(tester, matKhau: 'sai');

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.textContaining('Sai email'), findsOneWidget);
    expect(find.byKey(const Key('admin-shell')), findsNothing);
    expect(storage.token, isNull);
    expect(storage.saveCount, 0);
  });

  testWidgets('khôi phục phiên QUAN_LY từ /toi vào thẳng shell', (
    tester,
  ) async {
    final storage = FakeTokenStorage('saved-token');
    final client = MockClient((request) async {
      expect(request.url.path, '/api/auth/toi');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      return jsonResponse({
        'id': 7,
        'email': 'admin@xetruong.vn',
        'ho_ten': 'Nguyễn Văn Quản Lý',
        'sdt': '0901000001',
        'vai_tro': 'QUAN_LY',
      }, 200);
    });

    await pumpAdminApp(tester, storage: storage, client: client);

    expect(find.byKey(const Key('admin-shell')), findsOneWidget);
    expect(find.byKey(const Key('overview-greeting')), findsOneWidget);
    expect(storage.token, 'saved-token');
  });

  testWidgets('restore 401 xóa token và trở về đăng nhập', (tester) async {
    final storage = FakeTokenStorage('saved-token');
    final client = MockClient((_) async => http.Response('', 401));

    await pumpAdminApp(tester, storage: storage, client: client);

    expect(find.text('Đăng nhập dành cho quản lý'), findsOneWidget);
    expect(find.byKey(const Key('admin-shell')), findsNothing);
    expect(storage.token, isNull);
    expect(storage.clearCount, 1);
  });

  testWidgets('đăng xuất xóa token và trở về đăng nhập', (tester) async {
    final storage = FakeTokenStorage('saved-token');
    final client = MockClient(
      (_) async => jsonResponse({
        'id': 7,
        'email': 'admin@xetruong.vn',
        'ho_ten': 'Nguyễn Văn Quản Lý',
        'sdt': '0901000001',
        'vai_tro': 'QUAN_LY',
      }, 200),
    );

    await pumpAdminApp(tester, storage: storage, client: client);
    expect(find.byKey(const Key('admin-shell')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập dành cho quản lý'), findsOneWidget);
    expect(find.byKey(const Key('admin-shell')), findsNothing);
    expect(storage.token, isNull);
    expect(storage.clearCount, 1);
  });

  testWidgets('lỗi mạng hiển thị nút thử lại; tải lại thành công', (
    tester,
  ) async {
    var soLanGoi = 0;
    final storage = FakeTokenStorage('saved-token');
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/toi') {
        soLanGoi += 1;
        if (soLanGoi == 1) {
          throw http.ClientException('offline');
        }
        return jsonResponse({
          'id': 7,
          'email': 'admin@xetruong.vn',
          'ho_ten': 'Nguyễn Văn Quản Lý',
          'sdt': '0901000001',
          'vai_tro': 'QUAN_LY',
        }, 200);
      }
      return jsonResponse({}, 404);
    });

    await pumpAdminApp(tester, storage: storage, client: client);

    expect(find.byKey(const Key('restore-retry')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(storage.token, 'saved-token');

    await tester.tap(find.byKey(const Key('restore-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-shell')), findsOneWidget);
    expect(soLanGoi, 2);
  });

  testWidgets('quản lý xe: thêm, sửa, xóa thành công', (tester) async {
    final storage = FakeTokenStorage('saved-token');
    final backend = FakeFleetBackend(
      xe: [
        {
          'id': 1,
          'bien_so': '51B-111.11',
          'suc_chua': 29,
          'han_dang_kiem': '2027-06-30',
        },
      ],
    );

    await pumpAdminApp(tester, storage: storage, client: backend.client);
    await tester.tap(find.byKey(const Key('overview-xe-button')));
    await tester.pumpAndSettle();

    expect(find.text('51B-111.11'), findsOneWidget);

    await tester.tap(find.byKey(const Key('xe-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('xe-form-plate')),
      '51B-222.22',
    );
    await tester.enterText(find.byKey(const Key('xe-form-capacity')), '30');
    await tester.tap(find.byKey(const Key('xe-form-save')));
    await tester.pumpAndSettle();

    expect(find.text('51B-222.22'), findsOneWidget);
    final idMoi = backend.xe.last['id'] as int;

    await tester.tap(find.byKey(Key('xe-edit-$idMoi')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('xe-form-plate')),
      '51B-333.33',
    );
    await tester.enterText(find.byKey(const Key('xe-form-capacity')), '32');
    await tester.tap(find.byKey(const Key('xe-form-save')));
    await tester.pumpAndSettle();

    expect(find.text('51B-333.33'), findsOneWidget);
    expect(find.text('51B-222.22'), findsNothing);

    await tester.tap(find.byKey(Key('xe-delete-$idMoi')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('xe-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('51B-333.33'), findsNothing);
    expect(find.text('51B-111.11'), findsOneWidget);
  });

  testWidgets('xóa xe bị ràng buộc FK hiện dialog hướng dẫn, không lộ SQL', (
    tester,
  ) async {
    final storage = FakeTokenStorage('saved-token');
    final backend = FakeFleetBackend(
      xe: [
        {
          'id': 1,
          'bien_so': '51B-111.11',
          'suc_chua': 29,
          'han_dang_kiem': null,
        },
      ],
    )..loiXoaXe = true;

    await pumpAdminApp(tester, storage: storage, client: backend.client);
    await tester.tap(find.byKey(const Key('overview-xe-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('xe-delete-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('xe-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Không thể xóa xe'), findsOneWidget);
    expect(find.textContaining('phân công'), findsOneWidget);
    expect(find.textContaining('tuyến'), findsOneWidget);
    expect(find.textContaining('violates foreign key'), findsNothing);
    expect(find.textContaining('tuyen_xe_id_fkey'), findsNothing);
    expect(find.text('51B-111.11'), findsOneWidget);
    expect(backend.xe, hasLength(1));
  });

  testWidgets(
    'xóa tài xế bị ràng buộc FK hiện dialog hướng dẫn, không lộ SQL',
    (tester) async {
      final storage = FakeTokenStorage('saved-token');
      final backend = FakeFleetBackend(
        taiXe: [
          {
            'id': 1,
            'nguoi_dung_id': 3,
            'email': 'taixe@xetruong.vn',
            'ho_ten': 'Trần Văn Tài Xế',
            'sdt': '0901000002',
            'so_gplx': '790123456789',
            'han_gplx': '2029-12-31',
          },
        ],
      )..loiXoaTaiXe = true;

      await pumpAdminApp(tester, storage: storage, client: backend.client);
      await tester.tap(find.byKey(const Key('overview-tai-xe-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tai-xe-delete-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tai-xe-delete-confirm')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Không thể xóa tài xế'), findsOneWidget);
      expect(find.textContaining('phân công'), findsOneWidget);
      expect(find.textContaining('tuyến'), findsOneWidget);
      expect(find.textContaining('violates foreign key'), findsNothing);
      expect(find.textContaining('tuyen_tai_xe_id_fkey'), findsNothing);
      expect(find.text('Trần Văn Tài Xế'), findsOneWidget);
      expect(backend.taiXe, hasLength(1));
    },
  );

  testWidgets('quản lý tài xế: thêm, sửa, xóa thành công', (tester) async {
    final storage = FakeTokenStorage('saved-token');
    final backend = FakeFleetBackend(
      taiXe: [
        {
          'id': 1,
          'nguoi_dung_id': 3,
          'email': 'taixe@xetruong.vn',
          'ho_ten': 'Trần Văn Tài Xế',
          'sdt': '0901000002',
          'so_gplx': '790123456789',
          'han_gplx': '2029-12-31',
        },
      ],
    );

    await pumpAdminApp(tester, storage: storage, client: backend.client);
    await tester.tap(find.byKey(const Key('overview-tai-xe-button')));
    await tester.pumpAndSettle();

    expect(find.text('Trần Văn Tài Xế'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tai-xe-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('tai-xe-form-email')),
      'taixe2@xetruong.vn',
    );
    await tester.enterText(
      find.byKey(const Key('tai-xe-form-password')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('tai-xe-form-name')),
      'Nguyễn Văn Tài Xế',
    );
    await tester.enterText(
      find.byKey(const Key('tai-xe-form-license')),
      '790987654321',
    );
    await tester.tap(find.byKey(const Key('tai-xe-form-save')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn Tài Xế'), findsOneWidget);
    final idMoi = backend.taiXe.last['id'] as int;

    await tester.tap(find.byKey(Key('tai-xe-edit-$idMoi')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('tai-xe-form-name')),
      'Nguyễn Văn Tài Xế Mới',
    );
    await tester.enterText(
      find.byKey(const Key('tai-xe-form-phone')),
      '0909999999',
    );
    await tester.tap(find.byKey(const Key('tai-xe-form-save')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn Tài Xế Mới'), findsOneWidget);

    await tester.tap(find.byKey(Key('tai-xe-delete-$idMoi')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tai-xe-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn Tài Xế Mới'), findsNothing);
    expect(find.text('Trần Văn Tài Xế'), findsOneWidget);
  });

  for (final vaiTro in const ['PHU_HUYNH', 'TAI_XE', 'BAO_MAU', 'UNKNOWN']) {
    testWidgets('vai trò $vaiTro không mở được shell hay điều hướng đội xe', (
      tester,
    ) async {
      final storage = FakeTokenStorage();
      final client = MockClient(
        (_) async => jsonResponse({
          'token': 'jwt-sai-quyen',
          'nguoiDung': nguoiDungJson(vaiTro),
        }, 200),
      );

      await pumpAdminApp(tester, storage: storage, client: client);
      await dangNhap(tester);

      expect(find.byKey(const Key('login-error')), findsOneWidget);
      expect(find.byKey(const Key('admin-shell')), findsNothing);
      expect(find.byKey(const Key('nav-xe')), findsNothing);
      expect(find.byKey(const Key('nav-tai-xe')), findsNothing);
      expect(find.byKey(const Key('overview-xe-button')), findsNothing);
      expect(find.byKey(const Key('overview-tai-xe-button')), findsNothing);
      expect(find.byKey(const Key('xe-add')), findsNothing);
      expect(find.byKey(const Key('tai-xe-add')), findsNothing);
      expect(storage.token, isNull);
      expect(storage.saveCount, 0);
    });
  }

  testWidgets('điều hướng drawer tới Giám sát và rail tới Báo cáo', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = FakeTokenStorage('saved-token');
    final client = _FakeNavigationBackend().client;

    await tester.binding.setSurfaceSize(const Size(500, 900));
    await pumpAdminApp(tester, storage: storage, client: client);

    expect(find.byKey(const Key('admin-shell')), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-drawer-giam-sat')));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Giám sát')),
      findsOneWidget,
    );
    expect(find.textContaining('51B-999.99'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Báo cáo')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bao-cao-kpi-xe')), findsOneWidget);
    expect(find.text('Hoàn thành: 3'), findsOneWidget);
  });

  testWidgets('theme sáng tối đổi ngay và ghi nhớ lựa chọn', (tester) async {
    final storage = FakeTokenStorage('saved-token');
    await pumpAdminApp(
      tester,
      storage: storage,
      client: _FakeNavigationBackend().client,
    );

    expect(
      Theme.of(tester.element(find.byKey(const Key('admin-shell')))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byKey(const Key('admin-theme-toggle')));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byKey(const Key('admin-shell')))).brightness,
      Brightness.dark,
    );
    expect(storage.themeMode, 'dark');
    expect(storage.themeModeSaveCount, 1);
  });

  testWidgets('theme tối đã lưu được khôi phục khi mở lại ứng dụng', (
    tester,
  ) async {
    final storage = FakeTokenStorage.withRememberedEmail(
      token: 'saved-token',
      themeMode: 'dark',
    );
    await pumpAdminApp(
      tester,
      storage: storage,
      client: _FakeNavigationBackend().client,
    );

    expect(
      Theme.of(tester.element(find.byKey(const Key('admin-shell')))).brightness,
      Brightness.dark,
    );
    expect(find.byKey(const Key('overview-background-art')), findsOneWidget);
    expect(find.text('Truy cập nhanh'), findsOneWidget);
  });

  testWidgets('tổng quan co giãn vừa màn hình điện thoại', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await pumpAdminApp(
      tester,
      storage: FakeTokenStorage('saved-token'),
      client: _FakeNavigationBackend().client,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('overview-background-art')), findsOneWidget);
    for (final key in [
      const Key('overview-xe-button'),
      const Key('overview-tai-xe-button'),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
    }
  });
}

class _FakeNavigationBackend {
  http.Client get client => MockClient((request) async {
    final path = request.url.path;
    if (path == '/api/auth/toi') {
      return jsonResponse({
        'id': 7,
        'email': 'admin@xetruong.vn',
        'ho_ten': 'Nguyễn Văn Quản Lý',
        'sdt': '0901000001',
        'vai_tro': 'QUAN_LY',
      }, 200);
    }
    if (path == '/api/quan-ly/giam-sat') {
      return jsonResponse([
        {
          'id': 1,
          'tuyen_id': 5,
          'ngay': '2026-11-17',
          'chieu': 'DON_SANG',
          'trang_thai': 'DANG_CHAY',
          'ten_tuyen': 'Tuyến 01',
          'bien_so': '51B-999.99',
          'vi_do': 10.1,
          'kinh_do': 106.1,
          'vi_tri_cap_nhat_luc': DateTime.now().toIso8601String(),
        },
      ], 200);
    }
    if (path == '/api/quan-ly/thong-ke') {
      return jsonResponse({
        'tong_xe': 3,
        'tong_tuyen': 2,
        'tong_hoc_sinh': 40,
        'tong_chuyen_ngay': 5,
        'chuyen_hoan_thanh': 3,
        'so_bao_nghi': 2,
        'so_da_len_xe': 35,
      }, 200);
    }
    if (path == '/api/quan-ly/xe' ||
        path == '/api/quan-ly/tai-xe' ||
        path == '/api/quan-ly/tuyen' ||
        path == '/api/quan-ly/bao-mau' ||
        path == '/api/quan-ly/hoc-sinh') {
      return jsonResponse([], 200);
    }
    return jsonResponse({'loi': 'Không tìm thấy endpoint giả lập'}, 404);
  });
}
