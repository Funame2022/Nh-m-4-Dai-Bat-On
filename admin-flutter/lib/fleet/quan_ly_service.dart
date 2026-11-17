import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/token_storage.dart';

class QuanLyApiException implements Exception {
  const QuanLyApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class Xe {
  const Xe({
    required this.id,
    required this.bienSo,
    required this.sucChua,
    this.hanDangKiem,
  });

  final int id;
  final String bienSo;
  final int sucChua;
  final DateTime? hanDangKiem;

  factory Xe.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final bienSo = json['bien_so'];
    final sucChua = json['suc_chua'];
    if (id is! num || bienSo is! String || sucChua is! num) {
      throw const FormatException('Dữ liệu xe không hợp lệ');
    }
    return Xe(
      id: id.toInt(),
      bienSo: bienSo,
      sucChua: sucChua.toInt(),
      hanDangKiem: _docNgay(json['han_dang_kiem']),
    );
  }
}

class TaiXe {
  const TaiXe({
    required this.id,
    required this.nguoiDungId,
    required this.email,
    required this.hoTen,
    required this.soGplx,
    this.sdt,
    this.hanGplx,
  });

  final int id;
  final int nguoiDungId;
  final String email;
  final String hoTen;
  final String? sdt;
  final String soGplx;
  final DateTime? hanGplx;

  factory TaiXe.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nguoiDungId = json['nguoi_dung_id'];
    final email = json['email'];
    final hoTen = json['ho_ten'];
    final soGplx = json['so_gplx'];
    if (id is! num ||
        nguoiDungId is! num ||
        email is! String ||
        hoTen is! String ||
        soGplx is! String) {
      throw const FormatException('Dữ liệu tài xế không hợp lệ');
    }
    return TaiXe(
      id: id.toInt(),
      nguoiDungId: nguoiDungId.toInt(),
      email: email,
      hoTen: hoTen,
      sdt: json['sdt'] is String ? json['sdt'] as String : null,
      soGplx: soGplx,
      hanGplx: _docNgay(json['han_gplx']),
    );
  }
}

DateTime? _docNgay(Object? giaTri) {
  if (giaTri is! String || giaTri.isEmpty) return null;
  return DateTime.tryParse(giaTri);
}

String? _ngayGui(DateTime? giaTri) {
  if (giaTri == null) return null;
  final nam = giaTri.year.toString().padLeft(4, '0');
  final thang = giaTri.month.toString().padLeft(2, '0');
  final ngay = giaTri.day.toString().padLeft(2, '0');
  return '$nam-$thang-$ngay';
}

class QuanLyService {
  QuanLyService({
    required http.Client client,
    required TokenStorage storage,
    required String baseUrl,
  }) : this._(client, storage, baseUrl.trim());

  QuanLyService._(this._client, this._storage, this._baseUrl);

  final http.Client _client;
  final TokenStorage _storage;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String duongDan) {
    final goc = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$goc$duongDan');
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _storage.readToken();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _goi(Future<http.Response> Function() thucHien) async {
    try {
      return await thucHien().timeout(_timeout);
    } on QuanLyApiException {
      rethrow;
    } on Exception {
      throw const QuanLyApiException(
        0,
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
      );
    }
  }

  void _kiemTraThanhCong(http.Response response, Set<int> maThanhCong) {
    if (maThanhCong.contains(response.statusCode)) return;

    var thongDiep = '';
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json['loi'] is String) {
        thongDiep = json['loi'] as String;
      }
    } catch (_) {
      // Giữ thông báo mặc định khi body không phải JSON.
    }

    throw QuanLyApiException(
      response.statusCode,
      thongDiep.isNotEmpty
          ? thongDiep
          : 'Yêu cầu thất bại (mã ${response.statusCode}).',
    );
  }

  Xe _docXe(http.Response response, Set<int> maThanhCong) {
    _kiemTraThanhCong(response, maThanhCong);
    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi không phải JSON object');
      }
      return Xe.fromJson(json);
    } catch (_) {
      throw const QuanLyApiException(0, 'Phản hồi xe không hợp lệ.');
    }
  }

  TaiXe _docTaiXe(http.Response response, Set<int> maThanhCong) {
    _kiemTraThanhCong(response, maThanhCong);
    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi không phải JSON object');
      }
      return TaiXe.fromJson(json);
    } catch (_) {
      throw const QuanLyApiException(0, 'Phản hồi tài xế không hợp lệ.');
    }
  }

  Future<List<Xe>> layDanhSachXe() async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.get(_uri('/api/quan-ly/xe'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});

    try {
      final json = jsonDecode(response.body);
      if (json is! List) {
        throw const FormatException('Phản hồi không phải danh sách');
      }
      return json
          .map((item) => Xe.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const QuanLyApiException(0, 'Danh sách xe không hợp lệ.');
    }
  }

  Future<Xe> taoXe({
    required String bienSo,
    required int sucChua,
    DateTime? hanDangKiem,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.post(
        _uri('/api/quan-ly/xe'),
        headers: headers,
        body: jsonEncode({
          'bienSo': bienSo,
          'sucChua': sucChua,
          'hanDangKiem': _ngayGui(hanDangKiem),
        }),
      ),
    );
    return _docXe(response, {201});
  }

  Future<Xe> capNhatXe(
    int id, {
    required String bienSo,
    required int sucChua,
    DateTime? hanDangKiem,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.put(
        _uri('/api/quan-ly/xe/$id'),
        headers: headers,
        body: jsonEncode({
          'bienSo': bienSo,
          'sucChua': sucChua,
          'hanDangKiem': _ngayGui(hanDangKiem),
        }),
      ),
    );
    return _docXe(response, {200});
  }

  Future<void> xoaXe(int id) async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.delete(_uri('/api/quan-ly/xe/$id'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
  }

  Future<List<TaiXe>> layDanhSachTaiXe() async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.get(_uri('/api/quan-ly/tai-xe'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});

    try {
      final json = jsonDecode(response.body);
      if (json is! List) {
        throw const FormatException('Phản hồi không phải danh sách');
      }
      return json
          .map((item) => TaiXe.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const QuanLyApiException(0, 'Danh sách tài xế không hợp lệ.');
    }
  }

  Future<TaiXe> taoTaiXe({
    required String email,
    required String matKhau,
    required String hoTen,
    String? sdt,
    required String soGplx,
    DateTime? hanGplx,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.post(
        _uri('/api/quan-ly/tai-xe'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'matKhau': matKhau,
          'hoTen': hoTen,
          'sdt': sdt,
          'soGplx': soGplx,
          'hanGplx': _ngayGui(hanGplx),
        }),
      ),
    );
    return _docTaiXe(response, {201});
  }

  Future<void> capNhatTaiXe(
    int id, {
    required String hoTen,
    String? sdt,
    required String soGplx,
    DateTime? hanGplx,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.put(
        _uri('/api/quan-ly/tai-xe/$id'),
        headers: headers,
        body: jsonEncode({
          'hoTen': hoTen,
          'sdt': sdt,
          'soGplx': soGplx,
          'hanGplx': _ngayGui(hanGplx),
        }),
      ),
    );
    _kiemTraThanhCong(response, {200});
  }

  Future<void> xoaTaiXe(int id) async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.delete(_uri('/api/quan-ly/tai-xe/$id'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
  }
}
