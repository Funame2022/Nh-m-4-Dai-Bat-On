import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeFleetBackend {
  FakeFleetBackend({
    List<Map<String, dynamic>>? xe,
    List<Map<String, dynamic>>? taiXe,
  }) : xe = [...?xe],
       taiXe = [...?taiXe];

  final List<Map<String, dynamic>> xe;
  final List<Map<String, dynamic>> taiXe;
  bool loiXoaXe = false;
  bool loiXoaTaiXe = false;

  int _idXeTiepTheo = 100;
  int _idTaiXeTiepTheo = 100;

  http.Client get client => MockClient(_xuLy);

  Future<http.Response> _xuLy(http.Request request) async {
    final duongDan = request.url.path;

    if (duongDan == '/api/auth/toi') {
      return _json({
        'id': 7,
        'email': 'admin@xetruong.vn',
        'ho_ten': 'Nguyễn Văn Quản Lý',
        'sdt': '0901000001',
        'vai_tro': 'QUAN_LY',
      });
    }

    if (duongDan == '/api/quan-ly/xe') {
      if (request.method == 'GET') {
        return _json(xe);
      }
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final item = <String, dynamic>{
          'id': _idXeTiepTheo++,
          'bien_so': body['bienSo'],
          'suc_chua': body['sucChua'],
          'han_dang_kiem': body['hanDangKiem'],
        };
        xe.add(item);
        return _json(item, 201);
      }
    }

    if (duongDan.startsWith('/api/quan-ly/xe/')) {
      final id = int.parse(duongDan.split('/').last);
      final viTri = xe.indexWhere((item) => item['id'] == id);
      if (viTri == -1) return _json({'loi': 'Không tìm thấy xe'}, 404);

      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        xe[viTri] = {
          ...xe[viTri],
          'bien_so': body['bienSo'],
          'suc_chua': body['sucChua'],
          'han_dang_kiem': body['hanDangKiem'],
        };
        return _json(xe[viTri]);
      }

      if (request.method == 'DELETE') {
        if (loiXoaXe) {
          return _json({
            'loi':
                'update or delete on table "xe" violates foreign key '
                'constraint "tuyen_xe_id_fkey" on table "tuyen"',
          }, 400);
        }
        xe.removeAt(viTri);
        return _json({'thongBao': 'Đã xóa xe'});
      }
    }

    if (duongDan == '/api/quan-ly/tai-xe') {
      if (request.method == 'GET') {
        return _json(taiXe);
      }
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final item = <String, dynamic>{
          'id': _idTaiXeTiepTheo++,
          'nguoi_dung_id': 50,
          'email': body['email'],
          'ho_ten': body['hoTen'],
          'sdt': body['sdt'],
          'so_gplx': body['soGplx'],
          'han_gplx': body['hanGplx'],
          'vai_tro': 'TAI_XE',
        };
        taiXe.add(item);
        return _json(item, 201);
      }
    }

    if (duongDan.startsWith('/api/quan-ly/tai-xe/')) {
      final id = int.parse(duongDan.split('/').last);
      final viTri = taiXe.indexWhere((item) => item['id'] == id);
      if (viTri == -1) return _json({'loi': 'Không tìm thấy tài xế'}, 404);

      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        taiXe[viTri] = {
          ...taiXe[viTri],
          'ho_ten': body['hoTen'],
          'sdt': body['sdt'],
          'so_gplx': body['soGplx'],
          'han_gplx': body['hanGplx'],
        };
        return _json({
          'id': id,
          'nguoi_dung_id': taiXe[viTri]['nguoi_dung_id'],
        });
      }

      if (request.method == 'DELETE') {
        if (loiXoaTaiXe) {
          return _json({
            'loi':
                'update or delete on table "tai_xe" violates foreign key '
                'constraint "tuyen_tai_xe_id_fkey" on table "tuyen"',
          }, 400);
        }
        taiXe.removeAt(viTri);
        return _json({'thongBao': 'Đã xóa tài xế'});
      }
    }

    return _json({'loi': 'Không tìm thấy endpoint giả lập'}, 404);
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
