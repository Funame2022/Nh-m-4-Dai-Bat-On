import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/models/nguoi_dung.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';
import 'package:xe_truong_admin/screens/operations/chi_tiet_chuyen_page.dart';

import '../support/fake_token_storage.dart';

void main() {
  const taiXeUser = NguoiDung(
    id: 5,
    email: 'taixe.nguyen@xetruong.vn',
    hoTen: 'Nguyễn Văn Tài',
    vaiTro: 'TAI_XE',
    sdt: '0912345678',
  );

  testWidgets('E2E Flow: Tài xế bắt đầu chuyến, xem trạm, tìm kiếm HS, điểm danh LÊN/XUỐNG xe và kết thúc ca', (tester) async {
    // Dữ liệu mô phỏng chuyến đi
    final mockChuyenDi = {
      'id': 88,
      'tuyen_id': 1,
      'ngay': '2026-11-20',
      'chieu': 'DON_SANG',
      'trang_thai': 'CHUA_CHAY',
      'ten_tuyen': 'Tuyến Tân Bình - Q1',
      'bien_so': '51B-777.88',
    };

    final mockDiemDung = [
      {
        'id': 10,
        'tuyen_id': 1,
        'thu_tu': 1,
        'ten': 'Trạm Ngã tư Bảy Hiền',
        'vi_do': 10.79,
        'kinh_do': 106.65,
        'gio_du_kien': '06:15',
      },
      {
        'id': 20,
        'tuyen_id': 1,
        'thu_tu': 2,
        'ten': 'Trường Tiểu học Nguyễn Huệ',
        'vi_do': 10.77,
        'kinh_do': 106.69,
        'gio_du_kien': '06:50',
      },
    ];

    final mockHocSinh = [
      {
        'id': 801,
        'ma_hs': 'HS801',
        'ho_ten': 'Trần Hoàng Long',
        'ten_lop': '2A',
        'diem_dung_id': 10,
        'da_len_xe': false,
        'da_xuong_xe': false,
      },
      {
        'id': 802,
        'ma_hs': 'HS802',
        'ho_ten': 'Lê Thảo My',
        'ten_lop': '3B',
        'diem_dung_id': 10,
        'ly_do_nghi': 'Bị cảm sốt',
        'da_len_xe': false,
        'da_xuong_xe': false,
      },
    ];

    bool batDauCalled = false;
    bool diemDanhLenCalled = false;
    bool diemDanhXuongCalled = false;
    bool ketThucCalled = false;

    final client = MockClient((request) async {
      final path = request.url.path;

      // 1. Chi tiết chuyến ban đầu
      if (path == '/api/van-hanh/chuyen/88' && request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'chuyenDi': mockChuyenDi,
            'diemDung': mockDiemDung,
            'hocSinh': mockHocSinh,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      // 2. Bắt đầu chuyến
      if (path.contains('/bat-dau')) {
        batDauCalled = true;
        mockChuyenDi['trang_thai'] = 'DANG_CHAY';
        return http.Response(
          jsonEncode(mockChuyenDi),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      // 3. Điểm danh
      if (path.contains('/diem-danh')) {
        final body = jsonDecode(request.body);
        if (body['suKien'] == 'LEN_XE') {
          diemDanhLenCalled = true;
          return http.Response(
            jsonEncode({'id': 1, 'chuyen_di_id': 88, 'hoc_sinh_id': 801, 'su_kien': 'LEN_XE'}),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (body['suKien'] == 'XUONG_XE') {
          diemDanhXuongCalled = true;
          return http.Response(
            jsonEncode({'id': 2, 'chuyen_di_id': 88, 'hoc_sinh_id': 801, 'su_kien': 'XUONG_XE'}),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      }

      // 4. Cập nhật vị trí GPS
      if (path.contains('/vi-tri')) {
        return http.Response('{"ok":true}', 201, headers: {'content-type': 'application/json'});
      }

      // 5. Kết thúc chuyến
      if (path.contains('/ket-thuc')) {
        ketThucCalled = true;
        mockChuyenDi['trang_thai'] = 'DA_HOAN_THANH';
        return http.Response(
          jsonEncode(mockChuyenDi),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return http.Response('Not Found', 404);
    });

    final storage = FakeTokenStorage('test-token');
    final service = VanHanhService(client: client, storage: storage, baseUrl: 'http://api.test');

    await tester.pumpWidget(MaterialApp(
      home: ChiTietChuyenPage(
        chuyenId: 88,
        vanHanhService: service,
        nguoiDung: taiXeUser,
      ),
    ));
    await tester.pumpAndSettle();

    // BƯỚC 1: Kiểm tra ca xe chưa chạy -> Bấm BẮT ĐẦU CHUYẾN
    expect(find.text('Tuyến Tân Bình - Q1'), findsWidgets);
    expect(find.text('Chưa chạy'), findsWidgets);
    expect(find.byKey(const Key('btn-bat-dau-chuyen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-bat-dau-chuyen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-dialog-xac-nhan-bat-dau')));
    await tester.pumpAndSettle();

    expect(batDauCalled, isTrue);
    expect(find.text('Đang chạy'), findsWidgets);
    expect(find.byKey(const Key('btn-ket-thuc-chuyen')), findsOneWidget);

    // BƯỚC 2: Kiểm tra GPS Live card xuất hiện
    expect(find.byKey(const Key('card-gps-live-status')), findsOneWidget);

    // BƯỚC 3: Sang Tab Học sinh, tìm kiếm học sinh
    await tester.tap(find.textContaining('Học sinh'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input-tim-kiem-hoc-sinh')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('input-tim-kiem-hoc-sinh')), 'Hoàng Long');
    await tester.pumpAndSettle();

    expect(find.text('Trần Hoàng Long'), findsOneWidget);
    expect(find.text('Lê Thảo My'), findsNothing); // Em nghỉ ốm bị lọc ẩn đi

    // BƯỚC 4: Bấm LÊN XE cho học sinh
    expect(find.byKey(const Key('btn-len-xe-801')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn-len-xe-801')));
    await tester.pumpAndSettle();

    expect(diemDanhLenCalled, isTrue);
    expect(find.textContaining('Đã điểm danh Trần Hoàng Long LÊN XE'), findsOneWidget);
    expect(find.byKey(const Key('btn-xuong-xe-801')), findsOneWidget);

    // BƯỚC 5: Bấm XUỐNG XE cho học sinh khi đến trường
    await tester.tap(find.byKey(const Key('btn-xuong-xe-801')));
    await tester.pumpAndSettle();

    expect(diemDanhXuongCalled, isTrue);
    expect(find.text('Hoàn tất'), findsOneWidget);

    // BƯỚC 6: Bấm KẾT THÚC CHUYẾN
    await tester.tap(find.byKey(const Key('btn-ket-thuc-chuyen')));
    await tester.pumpAndSettle();

    expect(ketThucCalled, isTrue);
    expect(find.textContaining('Chuyến đi đã kết thúc thành công!'), findsOneWidget);
    expect(find.text('Chuyến đi đã hoàn tất và kết thúc an toàn'), findsOneWidget);
  });
}
