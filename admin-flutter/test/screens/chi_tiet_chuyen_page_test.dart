import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/models/nguoi_dung.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';
import 'package:xe_truong_admin/screens/operations/chi_tiet_chuyen_page.dart';

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
    hoTen: 'Trần Văn Lái Xe',
    vaiTro: 'TAI_XE',
    sdt: '0901234567',
  );

  final mockChiTietJson = {
    'chuyenDi': {
      'id': 50,
      'tuyen_id': 3,
      'ngay': '2026-11-20',
      'chieu': 'DON_SANG',
      'trang_thai': 'DANG_CHAY',
      'ten_tuyen': 'Tuyến Q1 - Bình Thạnh',
      'bien_so': '51B-888.99',
    },
    'diemDung': [
      {
        'id': 1,
        'tuyen_id': 3,
        'thu_tu': 1,
        'ten': 'Trạm Ngã tư Hàng Xanh',
        'vi_do': 10.80,
        'kinh_do': 106.71,
        'gio_du_kien': '06:45',
      },
      {
        'id': 2,
        'tuyen_id': 3,
        'thu_tu': 2,
        'ten': 'Trường THCS Lê Quý Đôn',
        'vi_do': 10.78,
        'kinh_do': 106.69,
        'gio_du_kien': '07:15',
      }
    ],
    'hocSinh': [
      {
        'id': 201,
        'ma_hs': 'HS201',
        'ho_ten': 'Nguyễn Hoàng Nam',
        'ten_lop': '3B',
        'diem_dung_id': 1,
        'da_len_xe': true,
        'da_xuong_xe': false,
      },
      {
        'id': 202,
        'ma_hs': 'HS202',
        'ho_ten': 'Vũ Phương Linh',
        'ten_lop': '3B',
        'diem_dung_id': 1,
        'ly_do_nghi': 'Bị ốm',
        'da_len_xe': false,
        'da_xuong_xe': false,
      }
    ]
  };

  Widget createWidget({required http.Client client}) {
    final storage = FakeTokenStorage('test-token');
    final service = VanHanhService(
      client: client,
      storage: storage,
      baseUrl: 'http://api.test',
    );

    return MaterialApp(
      home: ChiTietChuyenPage(
        chuyenId: 50,
        vanHanhService: service,
        nguoiDung: testUser,
      ),
    );
  }

  testWidgets('Hiển thị thông tin tổng quan ca xe và 4 ô thống kê', (tester) async {
    final client = MockClient((_) async => jsonResponse(mockChiTietJson));

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chi-tiet-chuyen-page')), findsOneWidget);
    expect(find.byKey(const Key('card-chuyen-overview')), findsOneWidget);
    expect(find.text('Tuyến Q1 - Bình Thạnh'), findsWidgets);
    expect(find.textContaining('51B-888.99'), findsWidgets);
    expect(find.text('Đang chạy'), findsWidgets);

    // Kiểm tra số liệu thống kê: 2 tổng HS, 1 báo nghỉ, 1 đang trên xe, 0 đã xuống
    expect(find.text('Tổng học sinh'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Báo nghỉ học'), findsOneWidget);
    expect(find.text('Đang trên xe'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('Hiển thị danh sách trạm dừng ở Tab Điểm dừng', (tester) async {
    final client = MockClient((_) async => jsonResponse(mockChiTietJson));

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diem-dung-card-1')), findsOneWidget);
    expect(find.byKey(const Key('diem-dung-card-2')), findsOneWidget);
    expect(find.text('Trạm Ngã tư Hàng Xanh'), findsOneWidget);
    expect(find.text('Trường THCS Lê Quý Đôn'), findsOneWidget);
    expect(find.textContaining('06:45'), findsOneWidget);
  });

  testWidgets('Chuyển sang Tab Học sinh hiển thị danh sách học sinh và trạng thái', (tester) async {
    final client = MockClient((_) async => jsonResponse(mockChiTietJson));

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    // Bấm vào tab Học sinh
    await tester.tap(find.textContaining('Học sinh (2)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hoc-sinh-card-201')), findsOneWidget);
    expect(find.byKey(const Key('hoc-sinh-card-202')), findsOneWidget);
    expect(find.text('Nguyễn Hoàng Nam'), findsOneWidget);
    expect(find.text('Vũ Phương Linh'), findsOneWidget);
    expect(find.text('Đang trên xe'), findsOneWidget);
    expect(find.text('Nghỉ có phép'), findsOneWidget);
    expect(find.textContaining('Lý do nghỉ: Bị ốm'), findsOneWidget);
  });

  testWidgets('Hiển thị thông báo lỗi khi API lỗi và bấm Thử lại', (tester) async {
    int callCount = 0;
    final client = MockClient((_) async {
      callCount++;
      if (callCount == 1) {
        return http.Response('Lỗi kết nối', 500);
      }
      return jsonResponse(mockChiTietJson);
    });

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chi-tiet-retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chi-tiet-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card-chuyen-overview')), findsOneWidget);
  });
}
