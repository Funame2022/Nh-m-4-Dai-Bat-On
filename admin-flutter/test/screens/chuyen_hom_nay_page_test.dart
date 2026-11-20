import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/models/nguoi_dung.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';
import 'package:xe_truong_admin/screens/operations/chuyen_hom_nay_page.dart';

import '../support/fake_token_storage.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  const testUser = NguoiDung(
    id: 1,
    email: 'taixe@xetruong.vn',
    hoTen: 'Nguyễn Văn Lái Xe',
    vaiTro: 'TAI_XE',
    sdt: '0901112233',
  );

  Widget createWidget({
    required http.Client client,
    ValueChanged<ChuyenDi>? onChonChuyen,
  }) {
    final storage = FakeTokenStorage('test-token');
    final service = VanHanhService(
      client: client,
      storage: storage,
      baseUrl: 'http://api.test',
    );

    return MaterialApp(
      home: Scaffold(
        body: ChuyenHomNayPage(
          vanHanhService: service,
          nguoiDung: testUser,
          onChonChuyen: onChonChuyen ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('Hiển thị trạng thái rỗng khi hôm nay không có chuyến nào', (tester) async {
    final client = MockClient((_) async => jsonResponse([]));

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card-ca-truc-header')), findsOneWidget);
    expect(find.text('Hôm nay bạn chưa có ca xe nào được phân công.'), findsOneWidget);
    expect(find.byKey(const Key('chuyen-refresh-empty')), findsOneWidget);
  });

  testWidgets('Hiển thị thông báo lỗi khi API lỗi và bấm Thử lại để tải lại thành công', (tester) async {
    int callCount = 0;
    final client = MockClient((_) async {
      callCount++;
      if (callCount == 1) {
        return http.Response('Lỗi máy chủ', 500);
      }
      return jsonResponse([
        {
          'id': 10,
          'tuyen_id': 1,
          'ngay': '2026-11-20',
          'chieu': 'DON_SANG',
          'trang_thai': 'DANG_CHAY',
          'ten_tuyen': 'Tuyến Q1 - Q7',
          'bien_so': '51B-123.45',
        }
      ]);
    });

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    // Thấy thông báo lỗi và nút Thử lại
    expect(find.byKey(const Key('chuyen-retry')), findsOneWidget);

    // Bấm Thử lại
    await tester.tap(find.byKey(const Key('chuyen-retry')));
    await tester.pumpAndSettle();

    // Tải thành công chuyến đi
    expect(find.byKey(const Key('chuyen-card-10')), findsOneWidget);
    expect(find.text('Tuyến Q1 - Q7'), findsOneWidget);
    expect(find.text('51B-123.45'), findsOneWidget);
    expect(find.text('Đang chạy'), findsOneWidget);
  });

  testWidgets('Hiển thị danh sách ca xe và bấm vào ca xe gọi onChonChuyen', (tester) async {
    ChuyenDi? chuyenDuocChon;
    final client = MockClient((_) async => jsonResponse([
          {
            'id': 101,
            'tuyen_id': 1,
            'ngay': '2026-11-20',
            'chieu': 'DON_SANG',
            'trang_thai': 'CHUA_CHAY',
            'ten_tuyen': 'Tuyến Tân Bình - Q1',
            'bien_so': '51B-999.88',
          },
          {
            'id': 102,
            'tuyen_id': 1,
            'ngay': '2026-11-20',
            'chieu': 'TRA_CHIEU',
            'trang_thai': 'HOAN_THANH',
            'ten_tuyen': 'Tuyến Q1 - Tân Bình',
            'bien_so': '51B-999.88',
          }
        ]));

    await tester.pumpWidget(createWidget(
      client: client,
      onChonChuyen: (c) => chuyenDuocChon = c,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chuyen-card-101')), findsOneWidget);
    expect(find.byKey(const Key('chuyen-card-102')), findsOneWidget);
    expect(find.text('Tuyến Tân Bình - Q1'), findsOneWidget);
    expect(find.text('Chưa chạy'), findsOneWidget);
    expect(find.text('Đã hoàn thành'), findsOneWidget);

    // Bấm vào nút mở ca xe 101
    await tester.tap(find.byKey(const Key('btn-chuyen-action-101')));
    await tester.pumpAndSettle();

    expect(chuyenDuocChon, isNotNull);
    expect(chuyenDuocChon!.id, 101);
    expect(chuyenDuocChon!.tenTuyen, 'Tuyến Tân Bình - Q1');
  });
}
