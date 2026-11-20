import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';

import '../support/fake_token_storage.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

VanHanhService taoVanHanhService(
  http.Client client,
  FakeTokenStorage storage, {
  Future<void> Function()? onTokenExpired,
}) =>
    VanHanhService(
      client: client,
      storage: storage,
      baseUrl: 'http://api.test',
      onTokenExpired: onTokenExpired,
    );

void main() {
  group('VanHanhService', () {
    test('layDanhSachChuyenHomNay gửi Bearer token và trả về danh sách ChuyenDi', () async {
      final storage = FakeTokenStorage('test-token-123');
      late http.Request sentRequest;

      final client = MockClient((req) async {
        sentRequest = req;
        return jsonResponse([
          {
            'id': 10,
            'tuyen_id': 2,
            'ngay': '2026-11-20',
            'chieu': 'DON_SANG',
            'trang_thai': 'CHUA_CHAY',
            'ten_tuyen': 'Tuyến Q1 - Q7',
            'bien_so': '51B-123.45',
          }
        ]);
      });

      final service = taoVanHanhService(client, storage);
      final dsChuyen = await service.layDanhSachChuyenHomNay();

      expect(sentRequest.method, 'GET');
      expect(sentRequest.url.path, '/api/van-hanh/chuyen-hom-nay');
      expect(sentRequest.headers['authorization'], 'Bearer test-token-123');
      expect(dsChuyen.length, 1);
      expect(dsChuyen.first.id, 10);
      expect(dsChuyen.first.tenTuyen, 'Tuyến Q1 - Q7');
      expect(dsChuyen.first.chieu, ChieuChuyen.donSang);
    });

    test('layChiTietChuyen parse đủ chuyến đi, điểm dừng và học sinh', () async {
      final storage = FakeTokenStorage('test-token-123');
      final client = MockClient((req) async {
        expect(req.url.path, '/api/van-hanh/chuyen/10');
        return jsonResponse({
          'chuyenDi': {
            'id': 10,
            'tuyen_id': 2,
            'ngay': '2026-11-20',
            'chieu': 'DON_SANG',
            'trang_thai': 'DANG_CHAY',
            'ten_tuyen': 'Tuyến 1',
            'bien_so': '51B-11111',
          },
          'diemDung': [
            {
              'id': 1,
              'tuyen_id': 2,
              'thu_tu': 1,
              'ten': 'Trạm Nguyễn Thị Minh Khai',
              'vi_do': 10.77,
              'kinh_do': 106.69,
              'gio_du_kien': '06:30',
            }
          ],
          'hocSinh': [
            {
              'id': 101,
              'ma_hs': 'HS001',
              'ho_ten': 'Phạm Gia Bảo',
              'ten_lop': '1A',
              'diem_dung_id': 1,
              'da_len_xe': true,
              'da_xuong_xe': false,
            }
          ]
        });
      });

      final service = taoVanHanhService(client, storage);
      final chiTiet = await service.layChiTietChuyen(10);

      expect(chiTiet.chuyenDi.id, 10);
      expect(chiTiet.diemDung.length, 1);
      expect(chiTiet.diemDung.first.ten, 'Trạm Nguyễn Thị Minh Khai');
      expect(chiTiet.hocSinh.length, 1);
      expect(chiTiet.hocSinh.first.hoTen, 'Phạm Gia Bảo');
      expect(chiTiet.soHocSinhTrenXe, 1);
    });

    test('batDauChuyen gửi POST và cập nhật trạng thái', () async {
      final storage = FakeTokenStorage('test-token-123');
      final client = MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/van-hanh/chuyen/10/bat-dau');
        return jsonResponse({
          'id': 10,
          'tuyen_id': 2,
          'ngay': '2026-11-20',
          'chieu': 'DON_SANG',
          'trang_thai': 'DANG_CHAY',
          'ten_tuyen': 'Tuyến 1',
          'bien_so': '51B-11111',
        });
      });

      final service = taoVanHanhService(client, storage);
      final chuyen = await service.batDauChuyen(10);

      expect(chuyen.trangThai, TrangThaiChuyen.dangChay);
      expect(chuyen.laDangChay, isTrue);
    });

    test('ketThucChuyen ném KetThucChuyenException khi mã 409', () async {
      final storage = FakeTokenStorage('test-token-123');
      final client = MockClient((req) async {
        expect(req.url.path, '/api/van-hanh/chuyen/10/ket-thuc');
        return jsonResponse({
          'canhBao': 'Không thể kết thúc chuyến vì còn học sinh chưa hoàn tất điểm danh!',
          'danhSachChuaHoanTat': ['Phạm Gia Bảo (chưa xuống xe)'],
        }, 409);
      });

      final service = taoVanHanhService(client, storage);

      try {
        await service.ketThucChuyen(10);
        fail('Phải ném ngoại lệ KetThucChuyenException');
      } on KetThucChuyenException catch (e) {
        expect(e.statusCode, 409);
        expect(e.canhBao, contains('chưa hoàn tất điểm danh'));
        expect(e.danhSachChuaHoanTat, contains('Phạm Gia Bảo (chưa xuống xe)'));
      }
    });

    test('diemDanh gửi đúng body LEN_XE và nhận kết quả', () async {
      final storage = FakeTokenStorage('test-token-123');
      late http.Request sentRequest;

      final client = MockClient((req) async {
        sentRequest = req;
        return jsonResponse({
          'id': 99,
          'chuyen_di_id': 10,
          'hoc_sinh_id': 101,
          'diem_dung_id': 1,
          'su_kien': 'LEN_XE',
          'thoi_diem': '2026-11-20T06:45:00.000Z',
        }, 201);
      });

      final service = taoVanHanhService(client, storage);
      final kq = await service.diemDanh(
        chuyenId: 10,
        hocSinhId: 101,
        diemDungId: 1,
        suKien: 'LEN_XE',
      );

      expect(sentRequest.url.path, '/api/van-hanh/chuyen/10/diem-danh');
      expect(jsonDecode(sentRequest.body), {
        'hocSinhId': 101,
        'diemDungId': 1,
        'suKien': 'LEN_XE',
      });
      expect(kq.id, 99);
      expect(kq.suKien, 'LEN_XE');
    });

    test('capNhatViTriGps gửi tọa độ GPS thành công', () async {
      final storage = FakeTokenStorage('test-token-123');
      late http.Request sentRequest;

      final client = MockClient((req) async {
        sentRequest = req;
        return jsonResponse({'id': 1, 'vi_do': 10.77, 'kinh_do': 106.69}, 201);
      });

      final service = taoVanHanhService(client, storage);
      await service.capNhatViTriGps(
        chuyenId: 10,
        viDo: 10.77,
        kinhDo: 106.69,
      );

      expect(sentRequest.url.path, '/api/van-hanh/chuyen/10/vi-tri');
      expect(jsonDecode(sentRequest.body), {'viDo': 10.77, 'kinhDo': 106.69});
    });

    test('401 kích hoạt callback onTokenExpired và ném ngoại lệ 401', () async {
      final storage = FakeTokenStorage('expired-token');
      bool tokenExpiredCalled = false;

      final client = MockClient((_) async => jsonResponse({'loi': 'Token hết hạn'}, 401));

      final service = taoVanHanhService(
        client,
        storage,
        onTokenExpired: () async {
          tokenExpiredCalled = true;
        },
      );

      expect(
        () => service.layDanhSachChuyenHomNay(),
        throwsA(
          isA<VanHanhApiException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      // Đợi microtask callback
      await Future<void>.delayed(Duration.zero);
      expect(tokenExpiredCalled, isTrue);
    });
  });
}
