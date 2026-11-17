import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/fleet/quan_ly_service.dart';

import 'support/fake_token_storage.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

QuanLyService taoService(http.Client client, FakeTokenStorage storage) =>
    QuanLyService(client: client, storage: storage, baseUrl: 'http://api.test');

void main() {
  group('xe', () {
    test('layDanhSachXe đọc snake_case và gửi bearer token', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse([
          {
            'id': 1,
            'bien_so': '51B-246.89',
            'suc_chua': 29,
            'han_dang_kiem': '2027-06-30',
          },
          {
            'id': 2,
            'bien_so': '51B-111.11',
            'suc_chua': 16,
            'han_dang_kiem': null,
          },
        ]);
      });

      final danhSach = await taoService(client, storage).layDanhSachXe();

      expect(request.method, 'GET');
      expect(request.url.toString(), 'http://api.test/api/quan-ly/xe');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(danhSach, hasLength(2));
      expect(danhSach[0].id, 1);
      expect(danhSach[0].bienSo, '51B-246.89');
      expect(danhSach[0].sucChua, 29);
      expect(danhSach[0].hanDangKiem?.year, 2027);
      expect(danhSach[0].hanDangKiem?.month, 6);
      expect(danhSach[0].hanDangKiem?.day, 30);
      expect(danhSach[1].hanDangKiem, isNull);
    });

    test('taoXe gửi body camelCase, ngày yyyy-MM-dd và đọc response', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({
          'id': 12,
          'bien_so': '51B-999.99',
          'suc_chua': 30,
          'han_dang_kiem': '2027-06-30',
        }, 201);
      });

      final xe = await taoService(client, storage).taoXe(
        bienSo: '51B-999.99',
        sucChua: 30,
        hanDangKiem: DateTime(2027, 6, 30),
      );

      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://api.test/api/quan-ly/xe');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(jsonDecode(request.body), {
        'bienSo': '51B-999.99',
        'sucChua': 30,
        'hanDangKiem': '2027-06-30',
      });
      expect(xe.id, 12);
      expect(xe.bienSo, '51B-999.99');
      expect(xe.sucChua, 30);
      expect(xe.hanDangKiem?.year, 2027);
    });

    test('capNhatXe gửi PUT đúng id/body và đọc response', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({
          'id': 12,
          'bien_so': '51B-888.88',
          'suc_chua': 32,
          'han_dang_kiem': '2028-01-15',
        });
      });

      final xe = await taoService(client, storage).capNhatXe(
        12,
        bienSo: '51B-888.88',
        sucChua: 32,
        hanDangKiem: DateTime(2028, 1, 15),
      );

      expect(request.method, 'PUT');
      expect(request.url.toString(), 'http://api.test/api/quan-ly/xe/12');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(jsonDecode(request.body), {
        'bienSo': '51B-888.88',
        'sucChua': 32,
        'hanDangKiem': '2028-01-15',
      });
      expect(xe.bienSo, '51B-888.88');
      expect(xe.sucChua, 32);
    });

    test('xoaXe gửi DELETE đúng route và token', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({'thongBao': 'Đã xóa xe'});
      });

      await taoService(client, storage).xoaXe(12);

      expect(request.method, 'DELETE');
      expect(request.url.toString(), 'http://api.test/api/quan-ly/xe/12');
      expect(request.headers['Authorization'], 'Bearer saved-token');
    });
  });

  group('tai xe', () {
    test('layDanhSachTaiXe đọc snake_case và gửi bearer token', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse([
          {
            'id': 9,
            'nguoi_dung_id': 3,
            'email': 'taixe@xetruong.vn',
            'ho_ten': 'Trần Văn Tài Xế',
            'sdt': '0901000002',
            'so_gplx': '790123456789',
            'han_gplx': '2029-12-31',
          },
        ]);
      });

      final danhSach = await taoService(client, storage).layDanhSachTaiXe();

      expect(request.method, 'GET');
      expect(request.url.toString(), 'http://api.test/api/quan-ly/tai-xe');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(danhSach, hasLength(1));
      expect(danhSach.single.id, 9);
      expect(danhSach.single.nguoiDungId, 3);
      expect(danhSach.single.email, 'taixe@xetruong.vn');
      expect(danhSach.single.hoTen, 'Trần Văn Tài Xế');
      expect(danhSach.single.sdt, '0901000002');
      expect(danhSach.single.soGplx, '790123456789');
      expect(danhSach.single.hanGplx?.year, 2029);
    });

    test(
      'taoTaiXe gửi body camelCase gồm mật khẩu/ngày và đọc response',
      () async {
        final storage = FakeTokenStorage('saved-token');
        late http.Request request;
        final client = MockClient((req) async {
          request = req;
          return jsonResponse({
            'id': 10,
            'nguoi_dung_id': 4,
            'email': 'taixe2@xetruong.vn',
            'ho_ten': 'Nguyễn Văn Tài Xế',
            'sdt': '0901000005',
            'so_gplx': '790987654321',
            'han_gplx': '2030-05-20',
            'vai_tro': 'TAI_XE',
          }, 201);
        });

        final taiXe = await taoService(client, storage).taoTaiXe(
          email: 'taixe2@xetruong.vn',
          matKhau: '123456',
          hoTen: 'Nguyễn Văn Tài Xế',
          sdt: '0901000005',
          soGplx: '790987654321',
          hanGplx: DateTime(2030, 5, 20),
        );

        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://api.test/api/quan-ly/tai-xe');
        expect(request.headers['Authorization'], 'Bearer saved-token');
        expect(jsonDecode(request.body), {
          'email': 'taixe2@xetruong.vn',
          'matKhau': '123456',
          'hoTen': 'Nguyễn Văn Tài Xế',
          'sdt': '0901000005',
          'soGplx': '790987654321',
          'hanGplx': '2030-05-20',
        });
        expect(taiXe.id, 10);
        expect(taiXe.nguoiDungId, 4);
        expect(taiXe.email, 'taixe2@xetruong.vn');
        expect(taiXe.hoTen, 'Nguyễn Văn Tài Xế');
        expect(taiXe.sdt, '0901000005');
        expect(taiXe.soGplx, '790987654321');
        expect(taiXe.hanGplx?.year, 2030);
      },
    );

    test('capNhatTaiXe gửi PUT đúng id/body và token', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({'id': 9, 'nguoi_dung_id': 3});
      });

      await taoService(client, storage).capNhatTaiXe(
        9,
        hoTen: 'Trần Văn Tài Xế Mới',
        sdt: '0909999999',
        soGplx: '790000000001',
        hanGplx: DateTime(2031, 2, 10),
      );

      expect(request.method, 'PUT');
      expect(request.url.toString(), 'http://api.test/api/quan-ly/tai-xe/9');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      expect(jsonDecode(request.body), {
        'hoTen': 'Trần Văn Tài Xế Mới',
        'sdt': '0909999999',
        'soGplx': '790000000001',
        'hanGplx': '2031-02-10',
      });
    });

    test('xoaTaiXe gửi DELETE đúng route và token', () async {
      final storage = FakeTokenStorage('saved-token');
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return jsonResponse({'thongBao': 'Đã xóa tài xế'});
      });

      await taoService(client, storage).xoaTaiXe(9);

      expect(request.method, 'DELETE');
      expect(request.url.toString(), 'http://api.test/api/quan-ly/tai-xe/9');
      expect(request.headers['Authorization'], 'Bearer saved-token');
    });
  });

  test('400 với {loi} ném typed exception có status và message', () async {
    final storage = FakeTokenStorage('saved-token');
    final client = MockClient(
      (_) async => jsonResponse({'loi': 'Biển số đã tồn tại'}, 400),
    );

    await expectLater(
      taoService(client, storage).taoXe(bienSo: '51B-246.89', sucChua: 29),
      throwsA(
        isA<QuanLyApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.message,
              'message',
              contains('Biển số đã tồn tại'),
            ),
      ),
    );
  });
}
