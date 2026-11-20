import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/token_storage.dart';
import '../config/api_config.dart';
import '../models/van_hanh.dart';

/// Lỗi xảy ra khi gọi API Vận hành & Điểm danh
class VanHanhApiException implements Exception {
  const VanHanhApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Lỗi 409 khi kết thúc chuyến nhưng còn học sinh chưa hoàn tất điểm danh
class KetThucChuyenException extends VanHanhApiException {
  const KetThucChuyenException({
    required int statusCode,
    required String message,
    required this.canhBao,
    required this.danhSachChuaHoanTat,
  }) : super(statusCode, message);

  final String canhBao;
  final List<String> danhSachChuaHoanTat;
}

/// Service phụ trách gọi API vận hành chuyến đi và điểm danh học sinh
class VanHanhService {
  VanHanhService({
    required http.Client client,
    required TokenStorage storage,
    required String baseUrl,
    this.onTokenExpired,
  })  : _client = client,
        _storage = storage,
        _baseUrl = baseUrl.trim();

  final http.Client _client;
  final TokenStorage _storage;
  final String _baseUrl;
  final Future<void> Function()? onTokenExpired;

  static const Duration _timeout = Duration(seconds: 20);

  bool get daCauHinh => _baseUrl.isNotEmpty;

  Uri _uri(String path) {
    final goc = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$goc$path');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const VanHanhApiException(
        401,
        'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Never _xuLyLoi(http.Response response) {
    if (response.statusCode == 401) {
      onTokenExpired?.call();
      throw const VanHanhApiException(
        401,
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }

    String thongDiep = 'Lỗi máy chủ (${response.statusCode})';
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        if (json['loi'] is String) thongDiep = json['loi'] as String;
        if (json['message'] is String) thongDiep = json['message'] as String;

        // Xử lý cảnh báo 409 khi kết thúc chuyến
        if (response.statusCode == 409 && json['canhBao'] != null) {
          final canhBao = json['canhBao'].toString();
          final rawList = json['danhSachChuaHoanTat'] ??
              json['danhSachChuaXuong'] ??
              [];
          final dsChuaXuong = (rawList as List)
              .map((e) => e.toString())
              .toList();
          throw KetThucChuyenException(
            statusCode: 409,
            message: canhBao,
            canhBao: canhBao,
            danhSachChuaHoanTat: dsChuaXuong,
          );
        }
      }
    } catch (e) {
      if (e is KetThucChuyenException) rethrow;
    }

    throw VanHanhApiException(response.statusCode, thongDiep);
  }

  /// Lấy danh sách các chuyến đi được phân công trong ngày hôm nay
  Future<List<ChuyenDi>> layDanhSachChuyenHomNay() async {
    if (!daCauHinh) {
      throw const VanHanhApiException(0, ApiConfig.thongDiepChuaCauHinh);
    }

    final headers = await _headers();
    http.Response response;
    try {
      response = await _client
          .get(_uri('/api/van-hanh/chuyen-hom-nay'), headers: headers)
          .timeout(_timeout);
    } on Exception catch (e) {
      throw VanHanhApiException(0, 'Lỗi kết nối máy chủ: $e');
    }

    if (response.statusCode != 200) {
      _xuLyLoi(response);
    }

    try {
      final jsonList = jsonDecode(response.body) as List;
      return jsonList
          .map((item) => ChuyenDi.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const VanHanhApiException(
        500,
        'Dữ liệu danh sách chuyến đi không đúng định dạng.',
      );
    }
  }

  /// Lấy chi tiết một chuyến đi (gồm các điểm dừng và học sinh được phân công)
  Future<ChiTietChuyenDi> layChiTietChuyen(int chuyenId) async {
    if (!daCauHinh) {
      throw const VanHanhApiException(0, ApiConfig.thongDiepChuaCauHinh);
    }

    final headers = await _headers();
    http.Response response;
    try {
      response = await _client
          .get(_uri('/api/van-hanh/chuyen/$chuyenId'), headers: headers)
          .timeout(_timeout);
    } on Exception catch (e) {
      throw VanHanhApiException(0, 'Lỗi kết nối máy chủ: $e');
    }

    if (response.statusCode != 200) {
      _xuLyLoi(response);
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChiTietChuyenDi.fromJson(json);
    } catch (_) {
      throw const VanHanhApiException(
        500,
        'Dữ liệu chi tiết chuyến đi không đúng định dạng.',
      );
    }
  }

  /// Bắt đầu chuyến đi (chuyển trạng thái sang DANG_CHAY)
  Future<ChuyenDi> batDauChuyen(int chuyenId) async {
    if (!daCauHinh) {
      throw const VanHanhApiException(0, ApiConfig.thongDiepChuaCauHinh);
    }

    final headers = await _headers();
    http.Response response;
    try {
      response = await _client
          .post(_uri('/api/van-hanh/chuyen/$chuyenId/bat-dau'), headers: headers)
          .timeout(_timeout);
    } on Exception catch (e) {
      throw VanHanhApiException(0, 'Lỗi kết nối máy chủ: $e');
    }

    if (response.statusCode != 200) {
      _xuLyLoi(response);
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChuyenDi.fromJson(json);
    } catch (_) {
      throw const VanHanhApiException(
        500,
        'Dữ liệu phản hồi bắt đầu chuyến không hợp lệ.',
      );
    }
  }

  /// Kết thúc chuyến đi (kiểm tra an toàn học sinh đã xuống xe hết chưa)
  Future<ChuyenDi> ketThucChuyen(int chuyenId, {bool boQua = false}) async {
    if (!daCauHinh) {
      throw const VanHanhApiException(0, ApiConfig.thongDiepChuaCauHinh);
    }

    final headers = await _headers();
    http.Response response;
    try {
      response = await _client
          .post(
            _uri('/api/van-hanh/chuyen/$chuyenId/ket-thuc'),
            headers: headers,
            body: jsonEncode({'boQua': boQua}),
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      throw VanHanhApiException(0, 'Lỗi kết nối máy chủ: $e');
    }

    if (response.statusCode != 200) {
      _xuLyLoi(response);
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChuyenDi.fromJson(json);
    } catch (_) {
      throw const VanHanhApiException(
        500,
        'Dữ liệu phản hồi kết thúc chuyến không hợp lệ.',
      );
    }
  }

  /// Ghi nhận điểm danh LÊN XE hoặc XUỐNG XE cho học sinh tại điểm dừng
  Future<KetQuaDiemDanh> diemDanh({
    required int chuyenId,
    required int hocSinhId,
    int? diemDungId,
    required String suKien,
  }) async {
    if (!daCauHinh) {
      throw const VanHanhApiException(0, ApiConfig.thongDiepChuaCauHinh);
    }

    final headers = await _headers();
    http.Response response;
    try {
      response = await _client
          .post(
            _uri('/api/van-hanh/chuyen/$chuyenId/diem-danh'),
            headers: headers,
            body: jsonEncode({
              'hocSinhId': hocSinhId,
              'diemDungId': diemDungId,
              'suKien': suKien,
            }),
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      throw VanHanhApiException(0, 'Lỗi kết nối máy chủ: $e');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      _xuLyLoi(response);
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return KetQuaDiemDanh.fromJson(json);
    } catch (_) {
      throw const VanHanhApiException(
        500,
        'Dữ liệu phản hồi điểm danh không hợp lệ.',
      );
    }
  }

  /// Cập nhật tọa độ GPS thời gian thực cho chuyến đi
  Future<void> capNhatViTriGps({
    required int chuyenId,
    required double viDo,
    required double kinhDo,
  }) async {
    if (!daCauHinh) {
      throw const VanHanhApiException(0, ApiConfig.thongDiepChuaCauHinh);
    }

    final headers = await _headers();
    http.Response response;
    try {
      response = await _client
          .post(
            _uri('/api/van-hanh/chuyen/$chuyenId/vi-tri'),
            headers: headers,
            body: jsonEncode({'viDo': viDo, 'kinhDo': kinhDo}),
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      throw VanHanhApiException(0, 'Lỗi kết nối khi gửi vị trí GPS: $e');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      _xuLyLoi(response);
    }
  }
}
