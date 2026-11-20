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

    expect(find.byKey(const Key('timeline-card-1')), findsOneWidget);
    expect(find.byKey(const Key('timeline-card-2')), findsOneWidget);
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

  testWidgets('Bấm nút LÊN XE thực hiện điểm danh học sinh thành công', (tester) async {
    final mockDataWithUnboardedStudent = {
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
        }
      ],
      'hocSinh': [
        {
          'id': 301,
          'ma_hs': 'HS301',
          'ho_ten': 'Trần Văn An',
          'ten_lop': '3B',
          'diem_dung_id': 1,
          'da_len_xe': false,
          'da_xuong_xe': false,
        }
      ],
    };

    bool diemDanhCalled = false;
    final client = MockClient((request) async {
      if (request.url.path.contains('/diem-danh')) {
        diemDanhCalled = true;
        final body = jsonDecode(request.body);
        expect(body['hocSinhId'], 301);
        expect(body['suKien'], 'LEN_XE');
        return jsonResponse({
          'id': 1,
          'chuyen_di_id': 50,
          'hoc_sinh_id': 301,
          'su_kien': 'LEN_XE',
          'thoi_diem': '2026-11-20T06:45:00Z',
        });
      }
      return jsonResponse(mockDataWithUnboardedStudent);
    });

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    // Chuyển sang Tab Học sinh
    await tester.tap(find.textContaining('Học sinh'));
    await tester.pumpAndSettle();

    // Kiểm tra có nút LÊN XE
    expect(find.byKey(const Key('btn-len-xe-301')), findsOneWidget);

    // Bấm nút LÊN XE
    await tester.tap(find.byKey(const Key('btn-len-xe-301')));
    await tester.pumpAndSettle();

    expect(diemDanhCalled, isTrue);
    expect(find.textContaining('Đã điểm danh Trần Văn An LÊN XE thành công!'), findsOneWidget);
    // Sau khi lên xe, trạng thái chuyển sang Đang trên xe và hiển thị nút XUỐNG XE
    expect(find.byKey(const Key('btn-xuong-xe-301')), findsOneWidget);
  });

  testWidgets('Bấm nút XUỐNG XE thực hiện điểm danh học sinh xuống xe thành công', (tester) async {
    final mockDataWithBoardedStudent = {
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
        }
      ],
      'hocSinh': [
        {
          'id': 401,
          'ma_hs': 'HS401',
          'ho_ten': 'Phạm Gia Hưng',
          'ten_lop': '5A',
          'diem_dung_id': 1,
          'da_len_xe': true,
          'da_xuong_xe': false,
        }
      ],
    };

    bool diemDanhXuongCalled = false;
    final client = MockClient((request) async {
      if (request.url.path.contains('/diem-danh')) {
        diemDanhXuongCalled = true;
        final body = jsonDecode(request.body);
        expect(body['hocSinhId'], 401);
        expect(body['suKien'], 'XUONG_XE');
        return jsonResponse({
          'id': 2,
          'chuyen_di_id': 50,
          'hoc_sinh_id': 401,
          'su_kien': 'XUONG_XE',
          'thoi_diem': '2026-11-20T07:15:00Z',
        });
      }
      return jsonResponse(mockDataWithBoardedStudent);
    });

    await tester.pumpWidget(createWidget(client: client));
    await tester.pumpAndSettle();

    // Chuyển sang Tab Học sinh
    await tester.tap(find.textContaining('Học sinh'));
    await tester.pumpAndSettle();

    // Kiểm tra có nút XUỐNG XE cho học sinh đang trên xe
    expect(find.byKey(const Key('btn-xuong-xe-401')), findsOneWidget);

    // Bấm nút XUỐNG XE
    await tester.tap(find.byKey(const Key('btn-xuong-xe-401')));
    await tester.pumpAndSettle();

    expect(diemDanhXuongCalled, isTrue);
    expect(find.textContaining('Đã điểm danh Phạm Gia Hưng XUỐNG XE'), findsOneWidget);
    // Sau khi xuống xe, hiển thị nhãn Hoàn tất và không còn nút điểm danh
    expect(find.text('Hoàn tất'), findsOneWidget);
    expect(find.byKey(const Key('btn-xuong-xe-401')), findsNothing);
  });
}
