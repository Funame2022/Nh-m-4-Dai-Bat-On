import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../auth/token_storage.dart';
import '../fleet/quan_ly_service.dart' show QuanLyApiException;

abstract interface class GiamSatConnection {
  Stream<dynamic> get messages;
  Future<void> close();
}

typedef GiamSatConnector = Future<GiamSatConnection> Function(
  Uri uri,
  Map<String, String> headers,
);

class _WebSocketGiamSatConnection implements GiamSatConnection {
  const _WebSocketGiamSatConnection(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get messages => _socket;

  @override
  Future<void> close() => _socket.close();
}

int _soNguyen(Map<String, dynamic> json, String khoa) {
  final giaTri = json[khoa];
  if (giaTri is! num) throw FormatException('Thiếu số nguyên $khoa');
  return giaTri.toInt();
}

int? _soNguyenCoTheNull(Map<String, dynamic> json, String khoa) {
  final giaTri = json[khoa];
  if (giaTri == null) return null;
  if (giaTri is! num) throw FormatException('Sai kiểu số nguyên $khoa');
  return giaTri.toInt();
}

double _soThuc(Map<String, dynamic> json, String khoa) {
  final giaTri = json[khoa];
  if (giaTri is! num) throw FormatException('Thiếu số thực $khoa');
  return giaTri.toDouble();
}

double? _soThucCoTheNull(Map<String, dynamic> json, String khoa) {
  final giaTri = json[khoa];
  if (giaTri == null) return null;
  if (giaTri is! num) throw FormatException('Sai kiểu số thực $khoa');
  return giaTri.toDouble();
}

String _chuoi(Map<String, dynamic> json, String khoa) {
  final giaTri = json[khoa];
  if (giaTri is! String) throw FormatException('Thiếu chuỗi $khoa');
  return giaTri;
}

String? _chuoiCoTheNull(Map<String, dynamic> json, String khoa) {
  final giaTri = json[khoa];
  if (giaTri == null) return null;
  if (giaTri is! String) throw FormatException('Sai kiểu chuỗi $khoa');
  return giaTri;
}

DateTime? _ngayCoTheNull(Object? giaTri) {
  if (giaTri is! String || giaTri.isEmpty) return null;
  return DateTime.tryParse(giaTri);
}

String _ngayGui(DateTime ngay) {
  final nam = ngay.year.toString().padLeft(4, '0');
  final thang = ngay.month.toString().padLeft(2, '0');
  final ngayTrongThang = ngay.day.toString().padLeft(2, '0');
  return '$nam-$thang-$ngayTrongThang';
}

class Tuyen {
  const Tuyen({
    required this.id,
    required this.tenTuyen,
    required this.xeId,
    required this.taiXeId,
    this.baoMauId,
    this.bienSo,
    this.tenTaiXe,
    this.tenBaoMau,
  });

  final int id;
  final String tenTuyen;
  final int xeId;
  final int taiXeId;
  final int? baoMauId;
  final String? bienSo;
  final String? tenTaiXe;
  final String? tenBaoMau;

  factory Tuyen.fromJson(Map<String, dynamic> json) => Tuyen(
    id: _soNguyen(json, 'id'),
    tenTuyen: _chuoi(json, 'ten_tuyen'),
    xeId: _soNguyen(json, 'xe_id'),
    taiXeId: _soNguyen(json, 'tai_xe_id'),
    baoMauId: _soNguyenCoTheNull(json, 'bao_mau_id'),
    bienSo: _chuoiCoTheNull(json, 'bien_so'),
    tenTaiXe: _chuoiCoTheNull(json, 'ten_tai_xe'),
    tenBaoMau: _chuoiCoTheNull(json, 'ten_bao_mau'),
  );
}

class DiemDung {
  const DiemDung({
    required this.id,
    required this.tuyenId,
    required this.thuTu,
    required this.ten,
    required this.viDo,
    required this.kinhDo,
    this.gioDuKien,
  });

  final int id;
  final int tuyenId;
  final int thuTu;
  final String ten;
  final double viDo;
  final double kinhDo;
  final String? gioDuKien;

  factory DiemDung.fromJson(Map<String, dynamic> json) => DiemDung(
    id: _soNguyen(json, 'id'),
    tuyenId: _soNguyen(json, 'tuyen_id'),
    thuTu: _soNguyen(json, 'thu_tu'),
    ten: _chuoi(json, 'ten'),
    viDo: _soThuc(json, 'vi_do'),
    kinhDo: _soThuc(json, 'kinh_do'),
    gioDuKien: _chuoiCoTheNull(json, 'gio_du_kien'),
  );
}

class DiemDungMoi {
  const DiemDungMoi({
    required this.thuTu,
    required this.ten,
    required this.viDo,
    required this.kinhDo,
    this.gioDuKien,
  });

  final int thuTu;
  final String ten;
  final double viDo;
  final double kinhDo;
  final String? gioDuKien;

  Map<String, dynamic> toJson() => {
    'thuTu': thuTu,
    'ten': ten,
    'viDo': viDo,
    'kinhDo': kinhDo,
    'gioDuKien': gioDuKien,
  };
}

class BaoMau {
  const BaoMau({
    required this.id,
    required this.nguoiDungId,
    required this.hoTen,
    required this.email,
    this.sdt,
  });

  final int id;
  final int nguoiDungId;
  final String hoTen;
  final String email;
  final String? sdt;

  factory BaoMau.fromJson(Map<String, dynamic> json) => BaoMau(
    id: _soNguyen(json, 'id'),
    nguoiDungId: _soNguyen(json, 'nguoi_dung_id'),
    hoTen: _chuoi(json, 'ho_ten'),
    email: _chuoi(json, 'email'),
    sdt: _chuoiCoTheNull(json, 'sdt'),
  );
}

class HocSinh {
  const HocSinh({
    required this.id,
    required this.maHs,
    required this.hoTen,
    required this.lopId,
    required this.tenLop,
    required this.tenTruong,
    this.anhUrl,
  });

  final int id;
  final String maHs;
  final String hoTen;
  final int lopId;
  final String tenLop;
  final String tenTruong;
  final String? anhUrl;

  factory HocSinh.fromJson(Map<String, dynamic> json) => HocSinh(
    id: _soNguyen(json, 'id'),
    maHs: _chuoi(json, 'ma_hs'),
    hoTen: _chuoi(json, 'ho_ten'),
    lopId: _soNguyen(json, 'lop_id'),
    tenLop: _chuoi(json, 'ten_lop'),
    tenTruong: _chuoi(json, 'ten_truong'),
    anhUrl: _chuoiCoTheNull(json, 'anh_url'),
  );
}

class DangKyTuyen {
  const DangKyTuyen({
    required this.hocSinhId,
    required this.tuyenId,
    required this.diemDungId,
    required this.chieu,
    this.maHs,
    this.hoTen,
    this.anhUrl,
    this.tenLop,
    this.tenTruong,
    this.tenTuyen,
    this.tenDiemDung,
    this.thuTuDiemDung,
    this.gioDuKien,
  });

  final int hocSinhId;
  final int tuyenId;
  final int diemDungId;
  final String chieu;
  final String? maHs;
  final String? hoTen;
  final String? anhUrl;
  final String? tenLop;
  final String? tenTruong;
  final String? tenTuyen;
  final String? tenDiemDung;
  final int? thuTuDiemDung;
  final String? gioDuKien;

  factory DangKyTuyen.fromJson(Map<String, dynamic> json) => DangKyTuyen(
    hocSinhId: _soNguyen(json, 'hoc_sinh_id'),
    tuyenId: _soNguyen(json, 'tuyen_id'),
    diemDungId: _soNguyen(json, 'diem_dung_id'),
    chieu: _chuoi(json, 'chieu'),
    maHs: _chuoiCoTheNull(json, 'ma_hs'),
    hoTen: _chuoiCoTheNull(json, 'ho_ten'),
    anhUrl: _chuoiCoTheNull(json, 'anh_url'),
    tenLop: _chuoiCoTheNull(json, 'ten_lop'),
    tenTruong: _chuoiCoTheNull(json, 'ten_truong'),
    tenTuyen: _chuoiCoTheNull(json, 'ten_tuyen'),
    tenDiemDung: _chuoiCoTheNull(json, 'ten_diem_dung'),
    thuTuDiemDung: _soNguyenCoTheNull(json, 'thu_tu_diem_dung'),
    gioDuKien: _chuoiCoTheNull(json, 'gio_du_kien'),
  );
}

class GiamSat {
  const GiamSat({
    required this.id,
    required this.tuyenId,
    required this.chieu,
    required this.trangThai,
    required this.tenTuyen,
    required this.bienSo,
    this.ngay,
    this.viDo,
    this.kinhDo,
    this.viTriCapNhatLuc,
  });

  final int id;
  final int tuyenId;
  final DateTime? ngay;
  final String chieu;
  final String trangThai;
  final String tenTuyen;
  final String bienSo;
  final double? viDo;
  final double? kinhDo;
  final DateTime? viTriCapNhatLuc;

  GiamSat capNhatViTri({
    required double viDo,
    required double kinhDo,
    required DateTime thoiDiem,
  }) => GiamSat(
    id: id,
    tuyenId: tuyenId,
    ngay: ngay,
    chieu: chieu,
    trangThai: trangThai,
    tenTuyen: tenTuyen,
    bienSo: bienSo,
    viDo: viDo,
    kinhDo: kinhDo,
    viTriCapNhatLuc: thoiDiem,
  );

  factory GiamSat.fromJson(Map<String, dynamic> json) => GiamSat(
    id: _soNguyen(json, 'id'),
    tuyenId: _soNguyen(json, 'tuyen_id'),
    ngay: _ngayCoTheNull(json['ngay']),
    chieu: _chuoi(json, 'chieu'),
    trangThai: _chuoi(json, 'trang_thai'),
    tenTuyen: _chuoi(json, 'ten_tuyen'),
    bienSo: _chuoi(json, 'bien_so'),
    viDo: _soThucCoTheNull(json, 'vi_do'),
    kinhDo: _soThucCoTheNull(json, 'kinh_do'),
    viTriCapNhatLuc: _ngayCoTheNull(json['vi_tri_cap_nhat_luc']),
  );
}

class ThongKe {
  const ThongKe({
    required this.tongXe,
    required this.tongTuyen,
    required this.tongHocSinh,
    required this.tongChuyenNgay,
    required this.chuyenHoanThanh,
    required this.soBaoNghi,
    required this.soDaLenXe,
  });

  final int tongXe;
  final int tongTuyen;
  final int tongHocSinh;
  final int tongChuyenNgay;
  final int chuyenHoanThanh;
  final int soBaoNghi;
  final int soDaLenXe;

  factory ThongKe.fromJson(Map<String, dynamic> json) => ThongKe(
    tongXe: _soNguyen(json, 'tong_xe'),
    tongTuyen: _soNguyen(json, 'tong_tuyen'),
    tongHocSinh: _soNguyen(json, 'tong_hoc_sinh'),
    tongChuyenNgay: _soNguyen(json, 'tong_chuyen_ngay'),
    chuyenHoanThanh: _soNguyen(json, 'chuyen_hoan_thanh'),
    soBaoNghi: _soNguyen(json, 'so_bao_nghi'),
    soDaLenXe: _soNguyen(json, 'so_da_len_xe'),
  );
}

class QuanLyOperationsService {
  QuanLyOperationsService({
    required http.Client client,
    required TokenStorage storage,
    required String baseUrl,
    GiamSatConnector? giamSatConnector,
  }) : this._(client, storage, baseUrl.trim(), giamSatConnector);

  QuanLyOperationsService._(
    this._client,
    this._storage,
    this._baseUrl,
    this._giamSatConnector,
  );

  final http.Client _client;
  final TokenStorage _storage;
  final String _baseUrl;
  final GiamSatConnector? _giamSatConnector;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String duongDan, [Map<String, String>? query]) {
    final goc = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final uri = Uri.parse('$goc$duongDan');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
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
      // Giữ thông báo mặc định.
    }

    throw QuanLyApiException(
      response.statusCode,
      thongDiep.isNotEmpty
          ? thongDiep
          : 'Yêu cầu thất bại (mã ${response.statusCode}).',
    );
  }

  List<T> _docDanhSach<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
    String thongDiep,
  ) {
    try {
      final json = jsonDecode(response.body);
      if (json is! List) throw const FormatException();
      return json.map((item) => parser(item as Map<String, dynamic>)).toList();
    } catch (_) {
      throw QuanLyApiException(0, thongDiep);
    }
  }

  T _docMot<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
    String thongDiep,
  ) {
    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return parser(json);
    } catch (_) {
      throw QuanLyApiException(0, thongDiep);
    }
  }

  Future<List<Tuyen>> layDanhSachTuyen() async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.get(_uri('/api/quan-ly/tuyen'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
    return _docDanhSach(
      response,
      Tuyen.fromJson,
      'Danh sách tuyến không hợp lệ.',
    );
  }

  Future<List<DiemDung>> layDanhSachDiemDung(int tuyenId) async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.get(
        _uri('/api/quan-ly/tuyen/$tuyenId/diem-dung'),
        headers: headers,
      ),
    );
    _kiemTraThanhCong(response, {200});
    return _docDanhSach(
      response,
      DiemDung.fromJson,
      'Danh sách điểm dừng không hợp lệ.',
    );
  }

  Future<Tuyen> taoTuyen({
    required String tenTuyen,
    required int xeId,
    required int taiXeId,
    int? baoMauId,
    required List<DiemDungMoi> danhSachDiemDung,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.post(
        _uri('/api/quan-ly/tuyen'),
        headers: headers,
        body: jsonEncode({
          'tenTuyen': tenTuyen,
          'xeId': xeId,
          'taiXeId': taiXeId,
          'baoMauId': baoMauId,
          'danhSachDiemDung': danhSachDiemDung
              .map((diem) => diem.toJson())
              .toList(),
        }),
      ),
    );
    _kiemTraThanhCong(response, {201});
    return _docMot(response, Tuyen.fromJson, 'Phản hồi tuyến không hợp lệ.');
  }

  Future<Tuyen> capNhatTuyen(
    int id, {
    required String tenTuyen,
    required int xeId,
    required int taiXeId,
    int? baoMauId,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.put(
        _uri('/api/quan-ly/tuyen/$id'),
        headers: headers,
        body: jsonEncode({
          'tenTuyen': tenTuyen,
          'xeId': xeId,
          'taiXeId': taiXeId,
          'baoMauId': baoMauId,
        }),
      ),
    );
    _kiemTraThanhCong(response, {200});
    return _docMot(response, Tuyen.fromJson, 'Phản hồi tuyến không hợp lệ.');
  }

  Future<void> xoaTuyen(int id) async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.delete(_uri('/api/quan-ly/tuyen/$id'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
  }

  Future<DiemDung> themDiemDung(
    int tuyenId, {
    required int thuTu,
    required String ten,
    required double viDo,
    required double kinhDo,
    String? gioDuKien,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.post(
        _uri('/api/quan-ly/tuyen/$tuyenId/diem-dung'),
        headers: headers,
        body: jsonEncode({
          'thuTu': thuTu,
          'ten': ten,
          'viDo': viDo,
          'kinhDo': kinhDo,
          'gioDuKien': gioDuKien,
        }),
      ),
    );
    _kiemTraThanhCong(response, {201});
    return _docMot(
      response,
      DiemDung.fromJson,
      'Phản hồi điểm dừng không hợp lệ.',
    );
  }

  Future<DiemDung> capNhatDiemDung(
    int tuyenId,
    int diemDungId, {
    required int thuTu,
    required String ten,
    required double viDo,
    required double kinhDo,
    String? gioDuKien,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.put(
        _uri('/api/quan-ly/tuyen/$tuyenId/diem-dung/$diemDungId'),
        headers: headers,
        body: jsonEncode({
          'thuTu': thuTu,
          'ten': ten,
          'viDo': viDo,
          'kinhDo': kinhDo,
          'gioDuKien': gioDuKien,
        }),
      ),
    );
    _kiemTraThanhCong(response, {200});
    return _docMot(
      response,
      DiemDung.fromJson,
      'Phản hồi điểm dừng không hợp lệ.',
    );
  }

  Future<List<BaoMau>> layDanhSachBaoMau() async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.get(_uri('/api/quan-ly/bao-mau'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
    return _docDanhSach(
      response,
      BaoMau.fromJson,
      'Danh sách bảo mẫu không hợp lệ.',
    );
  }

  Future<List<HocSinh>> layDanhSachHocSinh() async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.get(_uri('/api/quan-ly/hoc-sinh'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
    return _docDanhSach(
      response,
      HocSinh.fromJson,
      'Danh sách học sinh không hợp lệ.',
    );
  }

  Future<List<DangKyTuyen>> layDanhSachDangKyTuyen({
    int? hocSinhId,
    int? tuyenId,
    String? chieu,
  }) async {
    final query = <String, String>{};
    if (hocSinhId != null) query['hocSinhId'] = hocSinhId.toString();
    if (tuyenId != null) query['tuyenId'] = tuyenId.toString();
    if (chieu != null) query['chieu'] = chieu;

    final headers = await _headers();
    final response = await _goi(
      () => _client.get(
        _uri('/api/quan-ly/dang-ky-tuyen', query),
        headers: headers,
      ),
    );
    _kiemTraThanhCong(response, {200});
    return _docDanhSach(
      response,
      DangKyTuyen.fromJson,
      'Danh sách đăng ký tuyến không hợp lệ.',
    );
  }

  Future<DangKyTuyen> taoDangKyTuyen({
    required int hocSinhId,
    required int tuyenId,
    required int diemDungId,
    required String chieu,
  }) async {
    final headers = await _headers(json: true);
    final response = await _goi(
      () => _client.post(
        _uri('/api/quan-ly/dang-ky-tuyen'),
        headers: headers,
        body: jsonEncode({
          'hocSinhId': hocSinhId,
          'tuyenId': tuyenId,
          'diemDungId': diemDungId,
          'chieu': chieu,
        }),
      ),
    );
    _kiemTraThanhCong(response, {201});
    return _docMot(
      response,
      DangKyTuyen.fromJson,
      'Phản hồi đăng ký tuyến không hợp lệ.',
    );
  }

  Future<List<GiamSat>> layGiamSat() async {
    final headers = await _headers();
    final response = await _goi(
      () => _client.get(_uri('/api/quan-ly/giam-sat'), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
    return _docDanhSach(
      response,
      GiamSat.fromJson,
      'Danh sách giám sát không hợp lệ.',
    );
  }

  Future<GiamSatConnection> ketNoiGiamSat() async {
    final token = await _storage.readToken();
    if (token == null || token.trim().isEmpty) {
      throw const QuanLyApiException(401, 'Phiên đăng nhập không hợp lệ.');
    }

    final uri = _uri('/api/quan-ly/giam-sat/ws');
    final scheme = switch (uri.scheme) {
      'http' => 'ws',
      'https' => 'wss',
      _ => throw const QuanLyApiException(
        0,
        'Địa chỉ máy chủ không hỗ trợ kết nối thời gian thực.',
      ),
    };
    final webSocketUri = uri.replace(scheme: scheme);
    final headers = {'Authorization': 'Bearer $token'};
    final connector = _giamSatConnector;
    if (connector != null) return connector(webSocketUri, headers);

    final socket = await WebSocket.connect(
      webSocketUri.toString(),
      headers: headers,
    ).timeout(_timeout);
    return _WebSocketGiamSatConnection(socket);
  }

  Future<ThongKe> layThongKe({DateTime? ngay}) async {
    final query = <String, String>{};
    if (ngay != null) query['ngay'] = _ngayGui(ngay);

    final headers = await _headers();
    final response = await _goi(
      () => _client.get(_uri('/api/quan-ly/thong-ke', query), headers: headers),
    );
    _kiemTraThanhCong(response, {200});
    return _docMot(
      response,
      ThongKe.fromJson,
      'Phản hồi thống kê không hợp lệ.',
    );
  }
}
