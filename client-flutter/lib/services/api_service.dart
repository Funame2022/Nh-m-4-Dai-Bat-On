import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([
    this.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  ]);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'https://nh-m-4-dai-bat-on.onrender.com';
  static const String logTag = 'BusCare_Nhom09';
  static const Duration _timeout = Duration(seconds: 90);

  // ─── Headers tự động gắn Token ────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return token.isNotEmpty;
  }

  // ─── Theme Mode (đồng bộ với admin-flutter) ───────────────────────────────
  static Future<String?> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode');
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
  }

  // ─── Ảnh đại diện phụ huynh (lưu base64 cục bộ) ────────────────────────────
  static Future<String?> getParentAvatarBase64() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('parent_avatar_b64');
  }

  static Future<void> saveParentAvatarBase64(String b64) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_avatar_b64', b64);
  }

  static Future<void> clearParentAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('parent_avatar_b64');
  }

  // ─── 1. Đăng nhập ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String matKhau) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/dang-nhap'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'matKhau': matKhau}),
          )
          .timeout(_timeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', decoded['token'] ?? '');
        await prefs.setString(
            'nguoiDung', jsonEncode(decoded['nguoiDung'] ?? {}));
        return {'ok': true, 'data': decoded};
      }
      return {
        'ok': false,
        'loi': decoded['loi'] ?? 'Email hoặc mật khẩu không đúng',
      };
    } catch (e) {
      return {
        'ok': false,
        'loi': 'Không thể kết nối máy chủ. Vui lòng thử lại.',
      };
    }
  }

  // ─── 2. Đăng xuất ─────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nguoiDung');
  }

  // ─── 3. Thông tin tài khoản ───────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getNguoiDungHienTai() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('nguoiDung');
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> fetchProfile() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/auth/toi'), headers: await _headers())
        .timeout(_timeout);
    if (response.statusCode == 401) throw const SessionExpiredException();
    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nguoiDung', jsonEncode({
        'id': data['id'],
        'email': data['email'],
        'hoTen': data['ho_ten'],
        'sdt': data['sdt'],
        'vaiTro': data['vai_tro'],
      }));
      return data;
    }
    return null;
  }

  static Future<String?> updateProfileName(String hoTen) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/auth/toi'),
            headers: await _headers(),
            body: jsonEncode({'hoTen': hoTen}),
          )
          .timeout(_timeout);
      if (response.statusCode == 401) throw const SessionExpiredException();
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nguoiDung', jsonEncode({
          'id': decoded['id'],
          'email': decoded['email'],
          'hoTen': decoded['ho_ten'],
          'sdt': decoded['sdt'],
          'vaiTro': decoded['vai_tro'],
        }));
        return null;
      }
      return decoded['loi']?.toString() ?? 'Không thể cập nhật tên';
    } on SessionExpiredException {
      rethrow;
    } catch (_) {
      return 'Lỗi kết nối máy chủ';
    }
  }

  static Future<String?> changePassword(
      String matKhauHienTai, String matKhauMoi) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/auth/mat-khau'),
            headers: await _headers(),
            body: jsonEncode({
              'matKhauHienTai': matKhauHienTai,
              'matKhauMoi': matKhauMoi,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 401) throw const SessionExpiredException();
      if (response.statusCode == 200) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['loi']?.toString() ?? 'Không thể đổi mật khẩu';
    } on SessionExpiredException {
      rethrow;
    } catch (_) {
      return 'Lỗi kết nối máy chủ';
    }
  }

  // ─── 4. Lấy danh sách con của phụ huynh ───────────────────────────────────
  static Future<List<dynamic>> getChildren() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/phu-huynh/con-cua-toi'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) throw const SessionExpiredException();
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    throw Exception('Lỗi máy chủ (${response.statusCode})');
  }

  // ─── 5. Theo dõi chuyến đi hôm nay của con ────────────────────────────────
  static Future<List<dynamic>> getTracking(int hocSinhId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/phu-huynh/con/$hocSinhId/theo-doi'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) throw const SessionExpiredException();
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) return decoded;
      return [];
    }
    throw Exception('Lỗi máy chủ (${response.statusCode})');
  }

  // ─── 6. Gửi đơn báo nghỉ ──────────────────────────────────────────────────
  static Future<bool> postBaoNghi(
      int hocSinhId, String ngay, String lyDo) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/phu-huynh/bao-nghi'),
          headers: await _headers(),
          body: jsonEncode({
            'hocSinhId': hocSinhId,
            'ngay': ngay,
            'lyDo': lyDo,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) throw const SessionExpiredException();
    return response.statusCode == 201;
  }

  // ─── 7. Thông báo ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getThongBao({int limit = 50}) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/phu-huynh/thong-bao?limit=$limit'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) throw const SessionExpiredException();
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    }
    throw Exception('Lỗi tải thông báo (${response.statusCode})');
  }

  static Future<void> docTatCaThongBao() async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/phu-huynh/thong-bao/doc-tat-ca'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) throw const SessionExpiredException();
  }

  static Future<void> docThongBao(int thongBaoId) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/phu-huynh/thong-bao/$thongBaoId/doc'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) throw const SessionExpiredException();
  }

  // ─── 8. Cài đặt thông báo ─────────────────────────────────────────────────
  static Future<Map<String, bool>> getNotificationSettings() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/phu-huynh/thong-bao/cai-dat'),
          headers: await _headers(),
        )
        .timeout(_timeout);
    if (response.statusCode == 401) throw const SessionExpiredException();
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prefs = decoded['preferences'] as Map<String, dynamic>? ?? {};
      return prefs.map((k, v) => MapEntry(k, v == true));
    }
    throw Exception('Không thể tải cài đặt thông báo');
  }

  static Future<Map<String, bool>> updateNotificationSettings(
      Map<String, bool> preferences) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/phu-huynh/thong-bao/cai-dat'),
          headers: await _headers(),
          body: jsonEncode({'preferences': preferences}),
        )
        .timeout(_timeout);
    if (response.statusCode == 401) throw const SessionExpiredException();
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prefs = decoded['preferences'] as Map<String, dynamic>? ?? {};
      return prefs.map((k, v) => MapEntry(k, v == true));
    }
    throw Exception('Không thể lưu cài đặt thông báo');
  }

  // ─── 9. Ghi chú một chiều tới bảo mẫu (ưu tiên API server, fallback cục bộ) ─
  static Future<List<Map<String, String>>> getNotesForChild(
      int hocSinhId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notes_hs_$hocSinhId');
    final localNotes = (raw == null || raw.isEmpty)
        ? <Map<String, String>>[]
        : (jsonDecode(raw) as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/phu-huynh/ghi-chu?hocSinhId=$hocSinhId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List serverList =
            jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return serverList.map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'noiDung': m['noi_dung']?.toString() ?? m['noiDung']?.toString() ?? '',
            'nguoiNhan': m['nguoi_nhan']?.toString() ?? 'Bảo mẫu',
            'thoiGian': m['tao_luc']?.toString() ?? '',
            'synced': 'true',
          };
        }).toList();
      }
    } catch (_) {}

    return localNotes;
  }

  static Future<bool> addNoteForChild(
      int hocSinhId, String noiDung, String nguoiNhan) async {
    bool synced = false;
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/phu-huynh/ghi-chu'),
            headers: await _headers(),
            body: jsonEncode({
              'hocSinhId': hocSinhId,
              'noiDung': noiDung,
              'nguoiNhan': nguoiNhan,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) {
        synced = true;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notes_hs_$hocSinhId');
    final notes = (raw == null || raw.isEmpty)
        ? <Map<String, String>>[]
        : (jsonDecode(raw) as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList();

    notes.insert(0, {
      'noiDung': noiDung,
      'nguoiNhan': nguoiNhan,
      'thoiGian': DateTime.now().toIso8601String(),
      'synced': synced ? 'true' : 'false',
    });
    await prefs.setString('notes_hs_$hocSinhId', jsonEncode(notes));
    return synced;
  }

  static Future<void> deleteNoteForChild(int hocSinhId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notes_hs_$hocSinhId');
    if (raw == null || raw.isEmpty) return;
    final notes = (jsonDecode(raw) as List)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();
    if (index >= 0 && index < notes.length) {
      notes.removeAt(index);
      await prefs.setString('notes_hs_$hocSinhId', jsonEncode(notes));
    }
  }
}
