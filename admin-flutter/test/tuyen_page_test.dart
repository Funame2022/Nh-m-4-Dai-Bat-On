import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xe_truong_admin/fleet/quan_ly_service.dart';
import 'package:xe_truong_admin/operations/quan_ly_operations_service.dart';
import 'package:xe_truong_admin/screens/routes/tuyen_page.dart';

import 'support/fake_operations_backend.dart';
import 'support/fake_token_storage.dart';

Future<void> pumpTuyenPage(
  WidgetTester tester,
  FakeOperationsBackend backend,
) async {
  final storage = FakeTokenStorage('saved-token');
  final client = backend.client;

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: TuyenPage(
        operationsService: QuanLyOperationsService(
          client: client,
          storage: storage,
          baseUrl: 'http://api.test',
        ),
        fleetService: QuanLyService(
          client: client,
          storage: storage,
          baseUrl: 'http://api.test',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> nhap(WidgetTester tester, Key key, String giaTri) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, giaTri);
}

Future<void> chon(WidgetTester tester, Key key, String nhan) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text(nhan).last);
  await tester.pumpAndSettle();
}

Future<void> chonViTriBanDo(WidgetTester tester, Key buttonKey) async {
  final button = find.byKey(buttonKey);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  expect(find.byKey(const Key('map-picker-map')), findsOneWidget);
  await tester.tap(find.byKey(const Key('map-picker-confirm')));
  await tester.pumpAndSettle();
}

FakeOperationsBackend taoBackend() => FakeOperationsBackend(
  xe: [
    {'id': 1, 'bien_so': '51B-111.11', 'suc_chua': 29, 'han_dang_kiem': null},
  ],
  taiXe: [
    {
      'id': 1,
      'nguoi_dung_id': 3,
      'email': 'taixe@xetruong.vn',
      'ho_ten': 'Trần Văn Tài Xế',
      'sdt': null,
      'so_gplx': 'GPLX-1',
      'han_gplx': null,
    },
  ],
  baoMau: [
    {
      'id': 1,
      'nguoi_dung_id': 4,
      'ho_ten': 'Lê Thị Bảo Mẫu',
      'email': 'baomau@xetruong.vn',
      'sdt': null,
    },
  ],
  hocSinh: [
    {
      'id': 1,
      'ma_hs': 'HS001',
      'ho_ten': 'Phạm Gia Bảo',
      'lop_id': 1,
      'anh_url': null,
      'ten_lop': '10A1',
      'ten_truong': 'THPT Thực Hành Sài Gòn',
    },
  ],
);

void main() {
  testWidgets(
    'tạo tuyến hai điểm dừng, sửa điểm dừng và gán học sinh cùng chiều hai lần',
    (tester) async {
      final backend = taoBackend();
      await pumpTuyenPage(tester, backend);

      expect(find.textContaining('Chưa có tuyến'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tuyen-add')));
      await tester.pumpAndSettle();

      await nhap(tester, const Key('tuyen-form-ten'), 'Tuyến thử');
      await chon(tester, const Key('tuyen-form-xe'), '51B-111.11');
      await chon(tester, const Key('tuyen-form-tai-xe'), 'Trần Văn Tài Xế');
      await chon(tester, const Key('tuyen-form-bao-mau'), 'Lê Thị Bảo Mẫu');

      await nhap(tester, const Key('tuyen-form-stop-0-thu-tu'), '1');
      await nhap(tester, const Key('tuyen-form-stop-0-ten'), 'Điểm A');
      await nhap(tester, const Key('tuyen-form-stop-0-vi-do'), '10.1');
      await nhap(tester, const Key('tuyen-form-stop-0-kinh-do'), '106.1');
      await nhap(tester, const Key('tuyen-form-stop-0-gio'), '06:30');

      await tester.tap(find.byKey(const Key('tuyen-form-add-stop')));
      await tester.pumpAndSettle();

      await nhap(tester, const Key('tuyen-form-stop-1-thu-tu'), '2');
      await nhap(tester, const Key('tuyen-form-stop-1-ten'), 'Điểm B');
      await nhap(tester, const Key('tuyen-form-stop-1-vi-do'), '10.2');
      await nhap(tester, const Key('tuyen-form-stop-1-kinh-do'), '106.2');
      await nhap(tester, const Key('tuyen-form-stop-1-gio'), '06:45');

      await tester.ensureVisible(find.byKey(const Key('tuyen-form-save')));
      await tester.tap(find.byKey(const Key('tuyen-form-save')));
      await tester.pumpAndSettle();

      expect(find.text('Tuyến thử'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('diem-dung-row-100')),
          matching: find.text('Điểm A'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('diem-dung-row-101')),
          matching: find.text('Điểm B'),
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(find.byKey(const Key('diem-dung-edit-100')));
      await tester.tap(find.byKey(const Key('diem-dung-edit-100')));
      await tester.pumpAndSettle();
      await nhap(tester, const Key('diem-dung-form-ten'), 'Điểm A đã sửa');
      await tester.tap(find.byKey(const Key('diem-dung-form-save')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('diem-dung-row-100')),
          matching: find.text('Điểm A đã sửa'),
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(find.byKey(const Key('diem-dung-add')));
      await tester.tap(find.byKey(const Key('diem-dung-add')));
      await tester.pumpAndSettle();
      await nhap(tester, const Key('diem-dung-form-ten'), 'Điểm C');
      await chonViTriBanDo(tester, const Key('diem-dung-form-chon-vi-tri'));
      await tester.ensureVisible(find.byKey(const Key('diem-dung-form-save')));
      await tester.tap(find.byKey(const Key('diem-dung-form-save')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('diem-dung-row-102')),
          matching: find.text('Điểm C'),
        ),
        findsOneWidget,
      );

      await chon(tester, const Key('assignment-student'), 'Phạm Gia Bảo');
      await chon(tester, const Key('assignment-stop'), 'Điểm A đã sửa');
      await chon(tester, const Key('assignment-chieu'), 'Đón sáng (DON_SANG)');
      await tester.ensureVisible(find.byKey(const Key('assignment-submit')));
      await tester.tap(find.byKey(const Key('assignment-submit')));
      await tester.pumpAndSettle();

      final dongDangKy = find.byKey(const Key('assignment-row-1-DON_SANG'));
      expect(dongDangKy, findsOneWidget);
      expect(
        find.descendant(
          of: dongDangKy,
          matching: find.textContaining('Điểm A đã sửa'),
        ),
        findsOneWidget,
      );

      await chon(tester, const Key('assignment-stop'), 'Điểm B');
      await tester.ensureVisible(find.byKey(const Key('assignment-submit')));
      await tester.tap(find.byKey(const Key('assignment-submit')));
      await tester.pumpAndSettle();

      expect(backend.assignments, hasLength(1));
      expect(backend.assignments.single['hoc_sinh_id'], 1);
      expect(backend.assignments.single['chieu'], 'DON_SANG');
      expect(backend.assignments.single['diem_dung_id'], 101);

      expect(dongDangKy, findsOneWidget);
      expect(
        find.descendant(
          of: dongDangKy,
          matching: find.textContaining('Điểm B'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dongDangKy,
          matching: find.textContaining('Điểm A đã sửa'),
        ),
        findsNothing,
      );

      backend.loiXoaTuyen = true;
      await tester.drag(find.byType(ListView).first, const Offset(0, 500));
      await tester.pumpAndSettle();
      final nutXoaTuyen = find.byKey(const Key('tuyen-delete-10'));
      await tester.ensureVisible(nutXoaTuyen);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tuyen-delete-10')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tuyen-delete-confirm')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Không thể xóa tuyến'), findsOneWidget);
      expect(find.textContaining('Không thể xóa tuyến vì'), findsOneWidget);
      expect(find.text('Tuyến thử'), findsOneWidget);
    },
  );
}
