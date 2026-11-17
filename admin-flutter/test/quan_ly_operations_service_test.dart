import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/fleet/quan_ly_service.dart';
import 'package:xe_truong_admin/operations/quan_ly_operations_service.dart';

import 'support/fake_token_storage.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

QuanLyOperationsService taoService(
  http.Client client,
  FakeTokenStorage storage,
) => QuanLyOperationsService(
  client: client,
  storage: storage,
  baseUrl: 'http://api.test',
);

void main() {
  test('layDanhSachTuyen đọc snake_case, nhãn join và bearer token', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse([
        {
          'id': 5,
          'ten_tuyen': 'Tuyến 01',
          'xe_id': 1,
          'tai_xe_id': 2,
          'bao_mau_id': 3,
          'bien_so': '51B-246.89',
          'ten_tai_xe': 'Trần Văn Tài Xế',
          'ten_bao_mau': 'Lê Thị Bảo Mẫu',
        },
        {
          'id': 6,
          'ten_tuyen': 'Tuyến 02',
          'xe_id': 4,
          'tai_xe_id': 5,
          'bao_mau_id': null,
          'bien_so': '51B-111.11',
          'ten_tai_xe': 'Nguyễn Văn Tài Xế',
          'ten_bao_mau': null,
        },
      ]);
    });

    final danhSach = await taoService(client, storage).layDanhSachTuyen();

    expect(request.method, 'GET');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/tuyen');
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(danhSach, hasLength(2));
    expect(danhSach[0].id, 5);
    expect(danhSach[0].tenTuyen, 'Tuyến 01');
    expect(danhSach[0].xeId, 1);
    expect(danhSach[0].taiXeId, 2);
    expect(danhSach[0].baoMauId, 3);
    expect(danhSach[0].bienSo, '51B-246.89');
    expect(danhSach[0].tenTaiXe, 'Trần Văn Tài Xế');
    expect(danhSach[0].tenBaoMau, 'Lê Thị Bảo Mẫu');
    expect(danhSach[1].baoMauId, isNull);
    expect(danhSach[1].tenBaoMau, isNull);
  });

  test('layDanhSachDiemDung đọc snake_case và bearer token', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse([
        {
          'id': 9,
          'tuyen_id': 5,
          'thu_tu': 1,
          'ten': 'Nhà thờ Đức Bà',
          'vi_do': 10.7798,
          'kinh_do': 106.699,
          'gio_du_kien': '06:30',
        },
        {
          'id': 10,
          'tuyen_id': 5,
          'thu_tu': 2,
          'ten': 'Chợ Bến Thành',
          'vi_do': 10.7725,
          'kinh_do': 106.698,
          'gio_du_kien': null,
        },
      ]);
    });

    final danhSach = await taoService(client, storage).layDanhSachDiemDung(5);

    expect(request.method, 'GET');
    expect(
      request.url.toString(),
      'http://api.test/api/quan-ly/tuyen/5/diem-dung',
    );
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(danhSach, hasLength(2));
    expect(danhSach[0].id, 9);
    expect(danhSach[0].tuyenId, 5);
    expect(danhSach[0].thuTu, 1);
    expect(danhSach[0].viDo, 10.7798);
    expect(danhSach[0].gioDuKien, '06:30');
    expect(danhSach[1].gioDuKien, isNull);
  });

  test('taoTuyen gửi body camelCase đầy đủ và đọc route trả về', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse({
        'id': 10,
        'ten_tuyen': 'Tuyến mới',
        'xe_id': 1,
        'tai_xe_id': 2,
        'bao_mau_id': 3,
      }, 201);
    });

    final tuyen = await taoService(client, storage).taoTuyen(
      tenTuyen: 'Tuyến mới',
      xeId: 1,
      taiXeId: 2,
      baoMauId: 3,
      danhSachDiemDung: const [
        DiemDungMoi(
          thuTu: 1,
          ten: 'Điểm A',
          viDo: 10.1,
          kinhDo: 106.2,
          gioDuKien: '06:30',
        ),
        DiemDungMoi(thuTu: 2, ten: 'Điểm B', viDo: 10.3, kinhDo: 106.4),
      ],
    );

    expect(request.method, 'POST');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/tuyen');
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(jsonDecode(request.body), {
      'tenTuyen': 'Tuyến mới',
      'xeId': 1,
      'taiXeId': 2,
      'baoMauId': 3,
      'danhSachDiemDung': [
        {
          'thuTu': 1,
          'ten': 'Điểm A',
          'viDo': 10.1,
          'kinhDo': 106.2,
          'gioDuKien': '06:30',
        },
        {
          'thuTu': 2,
          'ten': 'Điểm B',
          'viDo': 10.3,
          'kinhDo': 106.4,
          'gioDuKien': null,
        },
      ],
    });
    expect(tuyen.id, 10);
    expect(tuyen.tenTuyen, 'Tuyến mới');
    expect(tuyen.xeId, 1);
    expect(tuyen.taiXeId, 2);
    expect(tuyen.baoMauId, 3);
    expect(tuyen.bienSo, isNull);
  });

  test('capNhatTuyen dùng PUT đúng id/body và đọc route', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse({
        'id': 5,
        'ten_tuyen': 'Tuyến đã sửa',
        'xe_id': 7,
        'tai_xe_id': 8,
        'bao_mau_id': null,
      });
    });

    final tuyen = await taoService(
      client,
      storage,
    ).capNhatTuyen(5, tenTuyen: 'Tuyến đã sửa', xeId: 7, taiXeId: 8);

    expect(request.method, 'PUT');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/tuyen/5');
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(jsonDecode(request.body), {
      'tenTuyen': 'Tuyến đã sửa',
      'xeId': 7,
      'taiXeId': 8,
      'baoMauId': null,
    });
    expect(tuyen.tenTuyen, 'Tuyến đã sửa');
    expect(tuyen.baoMauId, isNull);
  });

  test('xoaTuyen dùng DELETE và đọc lỗi 409 thành typed exception', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse({
        'loi': 'Không thể xóa tuyến vì vẫn còn chuyến đi hoặc học sinh đã đăng ký.',
      }, 409);
    });

    await expectLater(
      taoService(client, storage).xoaTuyen(5),
      throwsA(
        isA<QuanLyApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having(
              (e) => e.message,
              'message',
              contains('Không thể xóa tuyến'),
            ),
      ),
    );
    expect(request.method, 'DELETE');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/tuyen/5');
    expect(request.headers['Authorization'], 'Bearer saved-token');
  });

  test('capNhatDiemDung gửi body camelCase và đọc stop trả về', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse({
        'id': 9,
        'tuyen_id': 5,
        'thu_tu': 4,
        'ten': 'Điểm mới',
        'vi_do': 10.5,
        'kinh_do': 106.5,
        'gio_du_kien': null,
      });
    });

    final diemDung = await taoService(client, storage).capNhatDiemDung(
      5,
      9,
      thuTu: 4,
      ten: 'Điểm mới',
      viDo: 10.5,
      kinhDo: 106.5,
    );

    expect(request.method, 'PUT');
    expect(
      request.url.toString(),
      'http://api.test/api/quan-ly/tuyen/5/diem-dung/9',
    );
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(jsonDecode(request.body), {
      'thuTu': 4,
      'ten': 'Điểm mới',
      'viDo': 10.5,
      'kinhDo': 106.5,
      'gioDuKien': null,
    });
    expect(diemDung.id, 9);
    expect(diemDung.thuTu, 4);
    expect(diemDung.gioDuKien, isNull);
  });

  test('layDanhSachBaoMau đọc snake_case và bearer token', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse([
        {
          'id': 3,
          'nguoi_dung_id': 11,
          'ho_ten': 'Lê Thị Bảo Mẫu',
          'email': 'baomau@xetruong.vn',
          'sdt': null,
        },
      ]);
    });

    final danhSach = await taoService(client, storage).layDanhSachBaoMau();

    expect(request.method, 'GET');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/bao-mau');
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(danhSach.single.id, 3);
    expect(danhSach.single.nguoiDungId, 11);
    expect(danhSach.single.hoTen, 'Lê Thị Bảo Mẫu');
    expect(danhSach.single.email, 'baomau@xetruong.vn');
    expect(danhSach.single.sdt, isNull);
  });

  test('layDanhSachBaoMau từ chối payload thiếu ho_ten', () async {
    final storage = FakeTokenStorage('saved-token');
    final client = MockClient(
      (_) async => jsonResponse([
        {
          'id': 3,
          'nguoi_dung_id': 11,
          'email': 'baomau@xetruong.vn',
          'sdt': null,
        },
      ]),
    );

    await expectLater(
      taoService(client, storage).layDanhSachBaoMau(),
      throwsA(isA<QuanLyApiException>()),
    );
  });

  test('layDanhSachHocSinh đọc học sinh và lớp/trường join', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse([
        {
          'id': 1,
          'ma_hs': 'HS001',
          'ho_ten': 'Phạm Gia Bảo',
          'lop_id': 2,
          'anh_url': null,
          'ten_lop': '10A1',
          'ten_truong': 'THPT Thực Hành Sài Gòn',
        },
      ]);
    });

    final danhSach = await taoService(client, storage).layDanhSachHocSinh();

    expect(request.method, 'GET');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/hoc-sinh');
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(danhSach.single.id, 1);
    expect(danhSach.single.maHs, 'HS001');
    expect(danhSach.single.hoTen, 'Phạm Gia Bảo');
    expect(danhSach.single.lopId, 2);
    expect(danhSach.single.anhUrl, isNull);
    expect(danhSach.single.tenLop, '10A1');
    expect(danhSach.single.tenTruong, 'THPT Thực Hành Sài Gòn');
  });

  test('layDanhSachDangKyTuyen gửi bộ lọc và đọc join fields', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse([
        {
          'hoc_sinh_id': 1,
          'tuyen_id': 5,
          'diem_dung_id': 9,
          'chieu': 'DON_SANG',
          'ma_hs': 'HS001',
          'ho_ten': 'Phạm Gia Bảo',
          'anh_url': null,
          'ten_lop': '10A1',
          'ten_truong': 'THPT Thực Hành Sài Gòn',
          'ten_tuyen': 'Tuyến 01',
          'ten_diem_dung': 'Nhà thờ Đức Bà',
          'thu_tu_diem_dung': 1,
          'gio_du_kien': '06:30',
        },
      ]);
    });

    final danhSach = await taoService(
      client,
      storage,
    ).layDanhSachDangKyTuyen(hocSinhId: 1, tuyenId: 5, chieu: 'DON_SANG');

    expect(request.method, 'GET');
    expect(
      request.url.toString(),
      'http://api.test/api/quan-ly/dang-ky-tuyen?hocSinhId=1&tuyenId=5&chieu=DON_SANG',
    );
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(danhSach.single.hocSinhId, 1);
    expect(danhSach.single.tuyenId, 5);
    expect(danhSach.single.diemDungId, 9);
    expect(danhSach.single.chieu, 'DON_SANG');
    expect(danhSach.single.maHs, 'HS001');
    expect(danhSach.single.hoTen, 'Phạm Gia Bảo');
    expect(danhSach.single.tenLop, '10A1');
    expect(danhSach.single.tenTruong, 'THPT Thực Hành Sài Gòn');
    expect(danhSach.single.tenTuyen, 'Tuyến 01');
    expect(danhSach.single.tenDiemDung, 'Nhà thờ Đức Bà');
    expect(danhSach.single.thuTuDiemDung, 1);
    expect(danhSach.single.gioDuKien, '06:30');
  });

  test('taoDangKyTuyen gửi body camelCase và đọc assignment', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse({
        'hoc_sinh_id': 1,
        'tuyen_id': 5,
        'diem_dung_id': 9,
        'chieu': 'DON_SANG',
      }, 201);
    });

    final dangKy = await taoService(client, storage).taoDangKyTuyen(
      hocSinhId: 1,
      tuyenId: 5,
      diemDungId: 9,
      chieu: 'DON_SANG',
    );

    expect(request.method, 'POST');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/dang-ky-tuyen');
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(jsonDecode(request.body), {
      'hocSinhId': 1,
      'tuyenId': 5,
      'diemDungId': 9,
      'chieu': 'DON_SANG',
    });
    expect(dangKy.hocSinhId, 1);
    expect(dangKy.tuyenId, 5);
    expect(dangKy.diemDungId, 9);
    expect(dangKy.chieu, 'DON_SANG');
    expect(dangKy.tenTuyen, isNull);
  });

  test('layGiamSat đọc snapshot GPS và null timestamp', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse([
        {
          'id': 4,
          'tuyen_id': 5,
          'ngay': '2026-11-17',
          'chieu': 'DON_SANG',
          'trang_thai': 'DANG_CHAY',
          'ten_tuyen': 'Tuyến 01',
          'bien_so': '51B-246.89',
          'vi_do': 10.1,
          'kinh_do': 106.2,
          'vi_tri_cap_nhat_luc': '2026-11-17T01:02:03.000Z',
        },
        {
          'id': 5,
          'tuyen_id': 6,
          'ngay': '2026-11-17',
          'chieu': 'TRA_CHIEU',
          'trang_thai': 'CHUA_CHAY',
          'ten_tuyen': 'Tuyến 02',
          'bien_so': '51B-111.11',
          'vi_do': null,
          'kinh_do': null,
          'vi_tri_cap_nhat_luc': null,
        },
      ]);
    });

    final danhSach = await taoService(client, storage).layGiamSat();

    expect(request.method, 'GET');
    expect(request.url.toString(), 'http://api.test/api/quan-ly/giam-sat');
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(danhSach, hasLength(2));
    expect(danhSach[0].id, 4);
    expect(danhSach[0].tuyenId, 5);
    expect(danhSach[0].ngay?.year, 2026);
    expect(danhSach[0].chieu, 'DON_SANG');
    expect(danhSach[0].trangThai, 'DANG_CHAY');
    expect(danhSach[0].tenTuyen, 'Tuyến 01');
    expect(danhSach[0].bienSo, '51B-246.89');
    expect(danhSach[0].viDo, 10.1);
    expect(danhSach[0].kinhDo, 106.2);
    expect(danhSach[0].viTriCapNhatLuc, isNotNull);
    expect(danhSach[1].viDo, isNull);
    expect(danhSach[1].viTriCapNhatLuc, isNull);
  });

  test('layThongKe gửi ngày dạng yyyy-MM-dd và đọc số liệu', () async {
    final storage = FakeTokenStorage('saved-token');
    late http.Request request;
    final client = MockClient((req) async {
      request = req;
      return jsonResponse({
        'tong_xe': 3,
        'tong_tuyen': 2,
        'tong_hoc_sinh': 40,
        'tong_chuyen_ngay': 4,
        'chuyen_hoan_thanh': 1,
        'so_bao_nghi': 2,
        'so_da_len_xe': 35,
      });
    });

    final thongKe = await taoService(
      client,
      storage,
    ).layThongKe(ngay: DateTime(2026, 11, 17));

    expect(request.method, 'GET');
    expect(
      request.url.toString(),
      'http://api.test/api/quan-ly/thong-ke?ngay=2026-11-17',
    );
    expect(request.headers['Authorization'], 'Bearer saved-token');
    expect(thongKe.tongXe, 3);
    expect(thongKe.tongTuyen, 2);
    expect(thongKe.tongHocSinh, 40);
    expect(thongKe.tongChuyenNgay, 4);
    expect(thongKe.chuyenHoanThanh, 1);
    expect(thongKe.soBaoNghi, 2);
    expect(thongKe.soDaLenXe, 35);
  });
}
