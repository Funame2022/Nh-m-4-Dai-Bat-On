import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/models/nguoi_dung.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';
import 'package:xe_truong_admin/screens/operations/chi_tiet_chuyen_page.dart';

class FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => 'test-token';
  @override
  Future<void> writeToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
}

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
      'id': 70,
      'tuyen_id': 5,
      'ngay': '2026-11-20',
      'chieu': 'DON_SANG',
      'trang_thai': 'DANG_CHAY',
      'ten_tuyen': 'Tuyến Xe Buýt Học Sinh Quận 1',
      'bien_so': '51B-999.88',
    },
    'diemDung': [
      {
        'id': 1,
        'tuyen_id': 5,
        'thu_tu': 1,
        'ten': 'Trạm Khởi Hành',
        'vi_do': 10.77,
        'kinh_do': 106.69,
        'gio_du_kien': '06:30',
      },
      {
        'id': 2,
        'tuyen_id': 5,
        'thu_tu': 2,
        'ten': 'Trường Học Đích Đến',
        'vi_do': 10.78,
        'kinh_do': 106.70,
        'gio_du_kien': '07:15',
      }
    ],
    'hocSinh': [
      {
        'id': 701,
        'ma_hs': 'HS701',
        'ho_ten': 'Nguyễn Văn Minh',
        'ten_lop': '1A',
        'diem_dung_id': 1,
        'da_len_xe': false,
        'da_xuong_xe': false,
      }
    ],
  };

  Widget createWidget() {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode(mockChiTietJson),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final storage = FakeTokenStorage();
    final service = VanHanhService(client: client, storage: storage, baseUrl: 'http://api.test');

    return MaterialApp(
      home: ChiTietChuyenPage(
        chuyenId: 70,
        vanHanhService: service,
        nguoiDung: testUser,
      ),
    );
  }

  testWidgets('Hiển thị chuẩn ở Portrait và thích ứng linh hoạt khi xoay ngang Landscape không bị overflow', (tester) async {
    // 1. Chế độ Màn hình Dọc (Portrait: 400x800)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chi-tiet-chuyen-page')), findsOneWidget);
    expect(find.byKey(const Key('card-chuyen-overview')), findsOneWidget);
    expect(find.byKey(const Key('card-gps-live-status')), findsOneWidget);

    // 2. Xoay Màn hình Ngang (Landscape: 800x400 - dạng giá đỡ táp-lô xe buýt)
    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Kiểm tra bố cục ngang xuất hiện thanh cuộn header và hiển thị đầy đủ thông tin
    expect(find.byKey(const Key('landscape-header-scroll')), findsOneWidget);
    expect(find.byKey(const Key('card-chuyen-overview')), findsOneWidget);
    expect(find.text('Điểm dừng (2)'), findsOneWidget);
    expect(find.text('Học sinh (1)'), findsOneWidget);

    // Chuyển sang Tab Học sinh khi đang ở Landscape
    await tester.tap(find.text('Học sinh (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.byKey(const Key('btn-len-xe-701')), findsOneWidget);

    // Chuyển lại về Tab Điểm dừng: trạng thái giữ nguyên
    await tester.tap(find.text('Điểm dừng (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Trạm Khởi Hành'), findsOneWidget);
    expect(find.text('Trường Học Đích Đến'), findsOneWidget);
  });
}
