import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://nh-m-4-dai-bat-on.onrender.com';

void main() {
  runApp(const XeTruongApp());
}

class XeTruongApp extends StatelessWidget {
  const XeTruongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đưa Đón Học Sinh - Nhóm 4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber.shade700),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. MÀN HÌNH ĐĂNG NHẬP (KHỚP /api/auth/dang-nhap)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'taixe@xetruong.vn');
  final _passCtrl = TextEditingController(text: '123456');
  bool _loading = false;
  String? _error;

  Future<void> _dangNhap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/dang-nhap'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailCtrl.text.trim(),
              'matKhau': _passCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        final token = data['token'] as String;
        final user = data['nguoiDung'] as Map<String, dynamic>;
        final vaiTro = user['vaiTro'] ?? '';

        if (!mounted) return;
        if (vaiTro == 'TAI_XE' || vaiTro == 'BAO_MAU') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VanHanhScreen(token: token, user: user),
            ),
          );
        } else if (vaiTro == 'PHU_HUYNH') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PhuHuynhScreen(token: token, user: user),
            ),
          );
        } else {
          setState(
            () => _error = 'Tài khoản Quản lý vui lòng dùng App Admin Android!',
          );
        }
      } else {
        setState(() => _error = data['loi'] ?? 'Sai email hoặc mật khẩu');
      }
    } catch (e) {
      setState(() => _error = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _chonTaiKhoanNhanh(String email) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = '123456';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus_filled,
                      size: 64,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'XE ĐƯA ĐÓN HỌC SINH',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Nhóm 4 - Đại Bất Ổn',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _loading ? null : _dangNhap,
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ĐĂNG NHẬP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Điền nhanh tài khoản test:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Tài xế'),
                          onPressed: () =>
                              _chonTaiKhoanNhanh('taixe@xetruong.vn'),
                        ),
                        ActionChip(
                          label: const Text('Bảo mẫu'),
                          onPressed: () =>
                              _chonTaiKhoanNhanh('baomau@xetruong.vn'),
                        ),
                        ActionChip(
                          label: const Text('Phụ huynh'),
                          onPressed: () =>
                              _chonTaiKhoanNhanh('phuhuynh@xetruong.vn'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. MÀN HÌNH TÀI XẾ & BẢO MẪU (/api/van-hanh)
// ==========================================
class VanHanhScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const VanHanhScreen({super.key, required this.token, required this.user});

  @override
  State<VanHanhScreen> createState() => _VanHanhScreenState();
}

class _VanHanhScreenState extends State<VanHanhScreen> {
  bool _loading = true;
  Map<String, dynamic>? _chuyen;
  List<dynamic> _diemDung = [];
  List<dynamic> _hocSinh = [];
  String? _loi;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _taiChuyenHomNay();
  }

  Future<void> _taiChuyenHomNay() async {
    setState(() {
      _loading = true;
      _loi = null;
    });
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/van-hanh/chuyen-hom-nay'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final dsChuyen = jsonDecode(res.body) as List;
        if (dsChuyen.isEmpty) {
          setState(() => _chuyen = null);
          return;
        }
        final chuyenId = dsChuyen[0]['id'];
        final resChiTiet = await http.get(
          Uri.parse('$baseUrl/api/van-hanh/chuyen/$chuyenId'),
          headers: _headers,
        );
        if (resChiTiet.statusCode == 200) {
          final ct = jsonDecode(resChiTiet.body);
          setState(() {
            _chuyen = ct['chuyenDi'];
            _diemDung = ct['diemDung'] ?? [];
            _hocSinh = ct['hocSinh'] ?? [];
          });
        }
      } else {
        setState(
          () => _loi = 'Không tải được dữ liệu chuyến đi (${res.statusCode})',
        );
      }
    } catch (e) {
      setState(() => _loi = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _batDauChuyen(int chuyenId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/van-hanh/chuyen/$chuyenId/bat-dau'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      _thongBao('Đã bắt đầu chuyến đi!');
      _taiChuyenHomNay();
    } else {
      _thongBao('Lỗi bắt đầu chuyến');
    }
  }

  Future<void> _ketThucChuyen(int chuyenId, {bool boQua = false}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/van-hanh/chuyen/$chuyenId/ket-thuc'),
      headers: _headers,
      body: jsonEncode({'xacNhanBoQua': boQua}),
    );
    if (res.statusCode == 200) {
      _thongBao('Đã hoàn thành chuyến đi!');
      _taiChuyenHomNay();
    } else if (res.statusCode == 409) {
      final data = jsonDecode(res.body);
      _thongBao(
        '${data['canhBao']} (${(data['danhSachChuaXuong'] as List).join(', ')})',
      );
    } else {
      _thongBao('Lỗi kết thúc chuyến');
    }
  }

  Future<void> _guiToaDoGps(int chuyenId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/van-hanh/chuyen/$chuyenId/vi-tri'),
      headers: _headers,
      body: jsonEncode({'viDo': 10.7755, 'kinhDo': 106.6950}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      _thongBao('Đã gửi tọa độ GPS xe (10.7755, 106.6950)!');
    } else {
      _thongBao('Lỗi gửi GPS');
    }
  }

  Future<void> _diemDanh(
    int chuyenId,
    int hocSinhId,
    int? diemDungId,
    String suKien,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/van-hanh/chuyen/$chuyenId/diem-danh'),
      headers: _headers,
      body: jsonEncode({
        'hocSinhId': hocSinhId,
        'diemDungId': diemDungId,
        'suKien': suKien,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      _thongBao(
        suKien == 'LEN_XE' ? 'Đã điểm danh LÊN XE' : 'Đã điểm danh XUỐNG XE',
      );
      _taiChuyenHomNay();
    } else {
      _thongBao('Lỗi điểm danh');
    }
  }

  String _tenDiemDung(int? id) {
    final found = _diemDung.where((d) => d['id'] == id).toList();
    return found.isNotEmpty ? (found[0]['ten'] ?? 'Điểm đón') : 'Điểm đón';
  }

  void _thongBao(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final laTaiXe = widget.user['vaiTro'] == 'TAI_XE';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          laTaiXe
              ? 'Tài xế: ${widget.user['hoTen']}'
              : 'Bảo mẫu: ${widget.user['hoTen']}',
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _taiChuyenHomNay,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loi != null
          ? Center(
              child: Text(_loi!, style: const TextStyle(color: Colors.red)),
            )
          : _chuyen == null
          ? const Center(
              child: Text('Hôm nay chưa có chuyến đi nào được phân công.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _chuyen!['ten_tuyen'] ?? 'Tuyến xe trường',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Biển số: ${_chuyen!['bien_so']} | Chiều: ${_chuyen!['chieu']}',
                        ),
                        Text(
                          'Trạng thái: ${_chuyen!['trang_thai']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (laTaiXe)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _batDauChuyen(_chuyen!['id']),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Bắt đầu chạy'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => _guiToaDoGps(_chuyen!['id']),
                                icon: const Icon(Icons.my_location),
                                label: const Text('Gửi vị trí GPS'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _ketThucChuyen(_chuyen!['id']),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Hoàn thành'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DANH SÁCH HỌC SINH TRÊN TUYẾN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ..._hocSinh.map((hs) {
                  final daLen = hs['da_len_xe'] == true;
                  final daXuong = hs['da_xuong_xe'] == true;
                  final lyDoNghi = hs['ly_do_nghi'];
                  final trangThai = lyDoNghi != null
                      ? 'Báo nghỉ: $lyDoNghi'
                      : daXuong
                      ? 'Đã xuống xe'
                      : daLen
                      ? 'Đang ở trên xe'
                      : 'Chưa lên xe';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(hs['ma_hs'] ?? 'HS')),
                      title: Text(
                        '${hs['ho_ten']} (${hs['ten_lop'] ?? ''})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Điểm dừng: ${_tenDiemDung(hs['diem_dung_id'])}\nTrạng thái: $trangThai',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () => _diemDanh(
                              _chuyen!['id'],
                              hs['id'],
                              hs['diem_dung_id'],
                              'LEN_XE',
                            ),
                            child: const Text('Lên xe'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () => _diemDanh(
                              _chuyen!['id'],
                              hs['id'],
                              hs['diem_dung_id'],
                              'XUONG_XE',
                            ),
                            child: const Text('Xuống'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

// ==========================================
// 3. MÀN HÌNH PHỤ HUYNH (/api/phu-huynh)
// ==========================================
class PhuHuynhScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const PhuHuynhScreen({super.key, required this.token, required this.user});

  @override
  State<PhuHuynhScreen> createState() => _PhuHuynhScreenState();
}

class _PhuHuynhScreenState extends State<PhuHuynhScreen> {
  bool _loading = true;
  List<dynamic> _danhSachCon = [];
  List<dynamic> _theoDoi = [];
  String? _loi;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _taiThongTinTheoDoi();
  }

  Future<void> _taiThongTinTheoDoi() async {
    setState(() {
      _loading = true;
      _loi = null;
    });
    try {
      final resCon = await http.get(
        Uri.parse('$baseUrl/api/phu-huynh/con-cua-toi'),
        headers: _headers,
      );
      if (resCon.statusCode == 200) {
        final dsCon = jsonDecode(resCon.body) as List;
        List<dynamic> dsTheoDoi = [];
        if (dsCon.isNotEmpty) {
          final hsId = dsCon[0]['id'];
          final resTd = await http.get(
            Uri.parse('$baseUrl/api/phu-huynh/con/$hsId/theo-doi'),
            headers: _headers,
          );
          if (resTd.statusCode == 200) {
            dsTheoDoi = jsonDecode(resTd.body) as List;
          }
        }
        setState(() {
          _danhSachCon = dsCon;
          _theoDoi = dsTheoDoi;
        });
      } else {
        setState(() => _loi = 'Lỗi tải dữ liệu (${resCon.statusCode})');
      }
    } catch (e) {
      setState(() => _loi = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chuyenHienTai = _theoDoi.isNotEmpty ? _theoDoi[0] : null;
    final lichSu = (chuyenHienTai?['lich_su_diem_danh'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Phụ huynh: ${widget.user['hoTen']}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _taiThongTinTheoDoi,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loi != null
          ? Center(
              child: Text(_loi!, style: const TextStyle(color: Colors.red)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'THÔNG TIN HỌC SINH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (_danhSachCon.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa liên kết học sinh nào.'),
                    ),
                  ),
                ..._danhSachCon.map(
                  (con) => Card(
                    color: Colors.teal.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.face,
                        size: 40,
                        color: Colors.teal,
                      ),
                      title: Text(
                        '${con['ho_ten']} (${con['ma_hs']})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Lớp: ${con['ten_lop']} - ${con['ten_truong']}\nQuan hệ: ${con['quan_he']}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VỊ TRÍ XE TRƯỜNG & CHUYẾN ĐI HÔM NAY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 36,
                    ),
                    title: Text(
                      chuyenHienTai != null
                          ? '${chuyenHienTai['ten_tuyen']} (${chuyenHienTai['bien_so']}) - ${chuyenHienTai['trang_thai']}'
                          : 'Hôm nay chưa có chuyến đi',
                    ),
                    subtitle: Text(
                      chuyenHienTai?['vi_do'] != null
                          ? 'Tọa độ GPS: ${chuyenHienTai['vi_do']}, ${chuyenHienTai['kinh_do']}\nTài xế: ${chuyenHienTai['ten_tai_xe']} (${chuyenHienTai['sdt_tai_xe']})'
                          : 'Chưa có tín hiệu GPS mới từ tài xế',
                    ),
                    isThreeLine: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'LỊCH SỬ ĐIỂM DANH LÊN / XUỐNG XE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (lichSu.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Hôm nay chưa có lịch sử điểm danh.'),
                    ),
                  ),
                ...lichSu.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(
                        item['su_kien'] == 'LEN_XE'
                            ? Icons.arrow_circle_up
                            : Icons.arrow_circle_down,
                        color: item['su_kien'] == 'LEN_XE'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        item['su_kien'] == 'LEN_XE'
                            ? 'CON ĐÃ LÊN XE'
                            : 'CON ĐÃ XUỐNG XE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Thời gian: ${item['thoi_diem']}'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
