import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeOperationsBackend {
  FakeOperationsBackend({
    List<Map<String, dynamic>>? tuyen,
    List<Map<String, dynamic>>? diemDung,
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? xe,
    List<Map<String, dynamic>>? taiXe,
    List<Map<String, dynamic>>? baoMau,
    List<Map<String, dynamic>>? hocSinh,
  }) : tuyen = [...?tuyen],
       diemDung = [...?diemDung],
       assignments = [...?assignments],
       xe = [...?xe],
       taiXe = [...?taiXe],
       baoMau = [...?baoMau],
       hocSinh = [...?hocSinh] {
    _idTuyenTiepTheo = this.tuyen.isEmpty ? 10 : _idLonNhat(this.tuyen) + 1;
    _idDiemDungTiepTheo = this.diemDung.isEmpty
        ? 100
        : _idLonNhat(this.diemDung) + 1;
  }

  final List<Map<String, dynamic>> tuyen;
  final List<Map<String, dynamic>> diemDung;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> xe;
  final List<Map<String, dynamic>> taiXe;
  final List<Map<String, dynamic>> baoMau;
  final List<Map<String, dynamic>> hocSinh;

  bool loiXoaTuyen = false;
  String loiXoaTuyenMessage =
      'Không thể xóa tuyến vì vẫn còn chuyến đi hoặc học sinh đã đăng ký. '
      'Vui lòng xử lý dữ liệu liên quan trước.';

  late int _idTuyenTiepTheo;
  late int _idDiemDungTiepTheo;

  http.Client get client => MockClient(_xuLy);

  int _idLonNhat(List<Map<String, dynamic>> ds) {
    var lonNhat = 0;
    for (final item in ds) {
      final id = item['id'];
      if (id is int && id > lonNhat) lonNhat = id;
    }
    return lonNhat;
  }

  Map<String, dynamic> _timTheoId(List<Map<String, dynamic>> ds, Object? id) {
    for (final item in ds) {
      if (item['id'] == id) return item;
    }
    return const {};
  }

  Map<String, dynamic> _routeResponse(Map<String, dynamic> route) {
    final x = _timTheoId(xe, route['xe_id']);
    final tx = _timTheoId(taiXe, route['tai_xe_id']);
    final bm = _timTheoId(baoMau, route['bao_mau_id']);
    return {
      ...route,
      'bien_so': x['bien_so'],
      'ten_tai_xe': tx['ho_ten'],
      'ten_bao_mau': bm['ho_ten'],
    };
  }

  Map<String, dynamic> _assignmentResponse(Map<String, dynamic> a) {
    final hs = _timTheoId(hocSinh, a['hoc_sinh_id']);
    final route = _timTheoId(tuyen, a['tuyen_id']);
    final stop = _timTheoId(diemDung, a['diem_dung_id']);
    return {
      ...a,
      'ma_hs': hs['ma_hs'],
      'ho_ten': hs['ho_ten'],
      'anh_url': hs['anh_url'],
      'ten_lop': hs['ten_lop'],
      'ten_truong': hs['ten_truong'],
      'ten_tuyen': route['ten_tuyen'],
      'ten_diem_dung': stop['ten'],
      'thu_tu_diem_dung': stop['thu_tu'],
      'gio_du_kien': stop['gio_du_kien'],
    };
  }

  Future<http.Response> _xuLy(http.Request request) async {
    final segments = request.url.pathSegments;
    final method = request.method;

    if (segments.length == 3 &&
        segments[0] == 'api' &&
        segments[1] == 'quan-ly') {
      switch (segments[2]) {
        case 'xe':
          if (method == 'GET') return _json(xe);
        case 'tai-xe':
          if (method == 'GET') return _json(taiXe);
        case 'bao-mau':
          if (method == 'GET') return _json(baoMau);
        case 'hoc-sinh':
          if (method == 'GET') return _json(hocSinh);
        case 'tuyen':
          if (method == 'GET') {
            return _json(tuyen.map(_routeResponse).toList());
          }
          if (method == 'POST') {
            return _taoTuyen(request);
          }
        case 'dang-ky-tuyen':
          if (method == 'GET') return _layDangKy(request);
          if (method == 'POST') return _taoDangKy(request);
      }
    }

    if (segments.length >= 4 &&
        segments[0] == 'api' &&
        segments[1] == 'quan-ly' &&
        segments[2] == 'tuyen') {
      final tuyenId = int.parse(segments[3]);

      if (segments.length == 4 && method == 'PUT') {
        return _capNhatTuyen(tuyenId, request);
      }
      if (segments.length == 4 && method == 'DELETE') {
        return _xoaTuyen(tuyenId);
      }
      if (segments.length == 5 &&
          segments[4] == 'diem-dung' &&
          method == 'GET') {
        return _json(
          diemDung.where((item) => item['tuyen_id'] == tuyenId).toList(),
        );
      }
      if (segments.length == 5 &&
          segments[4] == 'diem-dung' &&
          method == 'POST') {
        return _taoDiemDung(tuyenId, request);
      }
      if (segments.length == 6 &&
          segments[4] == 'diem-dung' &&
          method == 'PUT') {
        return _capNhatDiemDung(tuyenId, int.parse(segments[5]), request);
      }
    }

    return _json({'loi': 'Không tìm thấy endpoint giả lập'}, 404);
  }

  http.Response _taoTuyen(http.Request request) {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final route = <String, dynamic>{
      'id': _idTuyenTiepTheo++,
      'ten_tuyen': body['tenTuyen'],
      'xe_id': body['xeId'],
      'tai_xe_id': body['taiXeId'],
      'bao_mau_id': body['baoMauId'],
    };
    tuyen.add(route);

    for (final stop in body['danhSachDiemDung'] as List<dynamic>) {
      final item = stop as Map<String, dynamic>;
      diemDung.add({
        'id': _idDiemDungTiepTheo++,
        'tuyen_id': route['id'],
        'thu_tu': item['thuTu'],
        'ten': item['ten'],
        'vi_do': item['viDo'],
        'kinh_do': item['kinhDo'],
        'gio_du_kien': item['gioDuKien'],
      });
    }

    return _json(_routeResponse(route), 201);
  }

  http.Response _capNhatTuyen(int id, http.Request request) {
    final viTri = tuyen.indexWhere((item) => item['id'] == id);
    if (viTri == -1) return _json({'loi': 'Không tìm thấy tuyến'}, 404);

    final body = jsonDecode(request.body) as Map<String, dynamic>;
    tuyen[viTri] = {
      ...tuyen[viTri],
      'ten_tuyen': body['tenTuyen'],
      'xe_id': body['xeId'],
      'tai_xe_id': body['taiXeId'],
      'bao_mau_id': body['baoMauId'],
    };
    return _json(_routeResponse(tuyen[viTri]));
  }

  http.Response _xoaTuyen(int id) {
    if (loiXoaTuyen) {
      return _json({'loi': loiXoaTuyenMessage}, 409);
    }

    tuyen.removeWhere((item) => item['id'] == id);
    diemDung.removeWhere((item) => item['tuyen_id'] == id);
    assignments.removeWhere((item) => item['tuyen_id'] == id);
    return _json({'thongBao': 'Đã xóa tuyến'});
  }

  http.Response _taoDiemDung(int tuyenId, http.Request request) {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    if (diemDung.any(
      (item) => item['tuyen_id'] == tuyenId && item['thu_tu'] == body['thuTu'],
    )) {
      return _json({'loi': 'Thứ tự điểm dừng đã tồn tại trong tuyến'}, 409);
    }

    final item = <String, dynamic>{
      'id': _idDiemDungTiepTheo++,
      'tuyen_id': tuyenId,
      'thu_tu': body['thuTu'],
      'ten': body['ten'],
      'vi_do': body['viDo'],
      'kinh_do': body['kinhDo'],
      'gio_du_kien': body['gioDuKien'],
    };
    diemDung.add(item);
    return _json(item, 201);
  }

  http.Response _capNhatDiemDung(
    int tuyenId,
    int diemDungId,
    http.Request request,
  ) {
    final viTri = diemDung.indexWhere(
      (item) => item['id'] == diemDungId && item['tuyen_id'] == tuyenId,
    );
    if (viTri == -1) return _json({'loi': 'Không tìm thấy điểm dừng'}, 404);

    final body = jsonDecode(request.body) as Map<String, dynamic>;
    diemDung[viTri] = {
      ...diemDung[viTri],
      'thu_tu': body['thuTu'],
      'ten': body['ten'],
      'vi_do': body['viDo'],
      'kinh_do': body['kinhDo'],
      'gio_du_kien': body['gioDuKien'],
    };
    return _json(diemDung[viTri]);
  }

  http.Response _layDangKy(http.Request request) {
    final query = request.url.queryParameters;
    final ds = assignments
        .where((item) {
          if (query['hocSinhId'] != null &&
              item['hoc_sinh_id'].toString() != query['hocSinhId']) {
            return false;
          }
          if (query['tuyenId'] != null &&
              item['tuyen_id'].toString() != query['tuyenId']) {
            return false;
          }
          if (query['chieu'] != null && item['chieu'] != query['chieu']) {
            return false;
          }
          return true;
        })
        .map(_assignmentResponse)
        .toList();
    return _json(ds);
  }

  http.Response _taoDangKy(http.Request request) {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final hocSinhId = body['hocSinhId'];
    final chieu = body['chieu'];

    assignments.removeWhere(
      (item) => item['hoc_sinh_id'] == hocSinhId && item['chieu'] == chieu,
    );
    assignments.add({
      'hoc_sinh_id': hocSinhId,
      'tuyen_id': body['tuyenId'],
      'diem_dung_id': body['diemDungId'],
      'chieu': chieu,
    });

    return _json({
      'hoc_sinh_id': hocSinhId,
      'tuyen_id': body['tuyenId'],
      'diem_dung_id': body['diemDungId'],
      'chieu': chieu,
    }, 201);
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
