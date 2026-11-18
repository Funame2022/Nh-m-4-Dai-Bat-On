import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
          setState(() => _error = 'Vui lòng dùng ứng dụng Admin để đăng nhập');
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
class GpsCoordinates {
  const GpsCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

abstract interface class GpsLocationSource {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Stream<GpsCoordinates> get positions;
}

class _DeviceGpsLocationSource implements GpsLocationSource {
  const _DeviceGpsLocationSource();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Stream<GpsCoordinates> get positions =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).map(
        (position) => GpsCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
}

class VanHanhScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final GpsLocationSource? gpsLocationSource;
  final http.Client? client;

  const VanHanhScreen({
    super.key,
    required this.token,
    required this.user,
    this.gpsLocationSource,
    this.client,
  });

  @override
  State<VanHanhScreen> createState() => _VanHanhScreenState();
}

class _VanHanhScreenState extends State<VanHanhScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  Map<String, dynamic>? _chuyen;
  List<dynamic> _diemDung = [];
  List<dynamic> _hocSinh = [];
  String? _loi;
  String? _loiGps;
  StreamSubscription<GpsCoordinates>? _gpsSubscription;
  bool _dangGuiGps = false;
  late final http.Client _client = widget.client ?? http.Client();
  bool get _tuSoHuuHttpClient => widget.client == null;
  GpsLocationSource get _gpsSource =>
      widget.gpsLocationSource ?? const _DeviceGpsLocationSource();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taiChuyenHomNay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_gpsSubscription?.cancel());
    if (_tuSoHuuHttpClient) _client.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_chuyen?['trang_thai'] == 'DANG_CHAY') {
        unawaited(_batDauTheoDoiGps(_chuyen!['id'] as int));
      }
      return;
    }

    final subscription = _gpsSubscription;
    _gpsSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (mounted) setState(() {});
  }

  Future<void> _taiChuyenHomNay() async {
    setState(() {
      _loading = true;
      _loi = null;
    });
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/van-hanh/chuyen-hom-nay'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final dsChuyen = jsonDecode(res.body) as List;
        if (dsChuyen.isEmpty) {
          setState(() => _chuyen = null);
          final subscription = _gpsSubscription;
          _gpsSubscription = null;
          if (subscription != null) await subscription.cancel();
          return;
        }
        final chuyenId = dsChuyen[0]['id'];
        final resChiTiet = await _client.get(
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
          if (_chuyen?['trang_thai'] == 'DANG_CHAY' &&
              widget.user['vaiTro'] == 'TAI_XE') {
            await _batDauTheoDoiGps(chuyenId as int);
          } else {
            final subscription = _gpsSubscription;
            _gpsSubscription = null;
            if (subscription != null) await subscription.cancel();
          }
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
    final res = await _client.post(
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
    final res = await _client.post(
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

  Future<void> _batDauTheoDoiGps(int chuyenId) async {
    if (widget.user['vaiTro'] != 'TAI_XE' ||
        _gpsSubscription != null ||
        _chuyen?['trang_thai'] != 'DANG_CHAY') {
      return;
    }

    try {
      if (!await _gpsSource.isServiceEnabled()) {
        _thongBao('Hãy bật dịch vụ vị trí để chia sẻ GPS của chuyến xe.');
        return;
      }

      var permission = await _gpsSource.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _gpsSource.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _thongBao('Cần cấp quyền vị trí khi dùng ứng dụng để gửi GPS.');
        return;
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _thongBao('Thiết bị chưa cấp quyền truy cập vị trí.');
        return;
      }

      if (!mounted || _chuyen?['trang_thai'] != 'DANG_CHAY') return;
      setState(() => _loiGps = null);
      _gpsSubscription = _gpsSource.positions.listen(
        (coordinates) => unawaited(
          _guiToaDoGps(chuyenId, coordinates.latitude, coordinates.longitude),
        ),
        onError: (Object _) {
          if (mounted) {
            setState(() => _loiGps = 'Không nhận được vị trí GPS từ thiết bị.');
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _loiGps = 'Không thể khởi động dịch vụ vị trí.');
        _thongBao(_loiGps!);
      }
    }
  }

  Future<void> _guiToaDoGps(int chuyenId, double viDo, double kinhDo) async {
    if (_dangGuiGps) return;
    _dangGuiGps = true;
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/api/van-hanh/chuyen/$chuyenId/vi-tri'),
            headers: _headers,
            body: jsonEncode({'viDo': viDo, 'kinhDo': kinhDo}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (_loiGps != null && mounted) setState(() => _loiGps = null);
      } else if (mounted) {
        setState(() => _loiGps = 'Máy chủ chưa nhận được vị trí GPS mới.');
      }
    } catch (_) {
      if (mounted) setState(() => _loiGps = 'Mất kết nối khi gửi vị trí GPS.');
    } finally {
      _dangGuiGps = false;
    }
  }

  Future<void> _diemDanh(
    int chuyenId,
    int hocSinhId,
    int? diemDungId,
    String suKien,
  ) async {
    final res = await _client.post(
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
                              if (_chuyen!['trang_thai'] != 'DANG_CHAY')
                                FilledButton.icon(
                                  onPressed: () =>
                                      _batDauChuyen(_chuyen!['id']),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Bắt đầu chạy'),
                                ),
                              if (_chuyen!['trang_thai'] == 'DANG_CHAY' &&
                                  laTaiXe)
                                Chip(
                                  avatar: Icon(
                                    _gpsSubscription == null
                                        ? Icons.location_searching
                                        : Icons.my_location,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _gpsSubscription == null
                                        ? 'Đang chờ GPS'
                                        : 'Đang chia sẻ GPS',
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: () => _ketThucChuyen(_chuyen!['id']),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Hoàn thành'),
                              ),
                            ],
                          ),
                        if (_loiGps != null && laTaiXe) ...[
                          const SizedBox(height: 8),
                          Text(
                            _loiGps!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
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
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key, required this.token, this.client});

  final String token;
  final http.Client? client;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const int _pageSize = 50;
  static const Map<String, ({String title, String subtitle})> _loai = {
    'TRIP_STARTED': (
      title: 'Chuyến xe bắt đầu',
      subtitle: 'Khi tài xế bắt đầu chuyến đi.',
    ),
    'STUDENT_BOARDED': (
      title: 'Học sinh lên xe',
      subtitle: 'Khi học sinh được điểm danh lên xe.',
    ),
    'STUDENT_DROPPED_OFF': (
      title: 'Học sinh xuống xe',
      subtitle: 'Khi học sinh được điểm danh xuống xe.',
    ),
    'TRIP_COMPLETED': (
      title: 'Chuyến xe hoàn tất',
      subtitle: 'Khi chuyến đi kết thúc thành công.',
    ),
  };

  late final http.Client _client = widget.client ?? http.Client();
  bool get _tuSoHuuHttpClient => widget.client == null;
  List<Map<String, dynamic>> _notifications = [];
  Map<String, bool> _preferences = {
    for (final event in _loai.keys) event: true,
  };
  bool _loading = true;
  bool _loadingMore = false;
  bool _saving = false;
  String? _error;
  int _unreadCount = 0;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  @override
  void dispose() {
    if (_tuSoHuuHttpClient) _client.close();
    super.dispose();
  }

  Future<void> _taiDuLieu() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        _client.get(
          Uri.parse('$baseUrl/api/phu-huynh/thong-bao?limit=$_pageSize'),
          headers: _headers,
        ),
        _client.get(
          Uri.parse('$baseUrl/api/phu-huynh/thong-bao/cai-dat'),
          headers: _headers,
        ),
      ]);
      if (responses.any((response) => response.statusCode != 200)) {
        throw const FormatException('Không tải được hộp thư.');
      }
      final inbox = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final settings = jsonDecode(responses[1].body) as Map<String, dynamic>;
      final preferences = Map<String, bool>.from(_preferences);
      final saved = settings['preferences'] as Map<String, dynamic>;
      for (final event in _loai.keys) {
        final value = saved[event];
        if (value is bool) preferences[event] = value;
      }
      if (!mounted) return;
      setState(() {
        _notifications = (inbox['notifications'] as List)
            .cast<Map<String, dynamic>>();
        _unreadCount = (inbox['unreadCount'] as num).toInt();
        _preferences = preferences;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể tải hộp thư thông báo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _taiThem() async {
    if (_loadingMore || _notifications.length < _pageSize) return;
    final before = _notifications.last['id'];
    if (before is! num) return;
    setState(() => _loadingMore = true);
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/api/phu-huynh/thong-bao?limit=$_pageSize&before=${before.toInt()}',
        ),
        headers: _headers,
      );
      if (response.statusCode != 200) throw const FormatException();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final more = (data['notifications'] as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _notifications = [..._notifications, ...more];
          _unreadCount = (data['unreadCount'] as num).toInt();
        });
      }
    } catch (_) {
      if (mounted) _thongBao('Không thể tải thêm thông báo.');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _danhDauDaDoc(int index) async {
    final item = _notifications[index];
    if (item['da_doc_luc'] != null) return;
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/api/phu-huynh/thong-bao/${item['id']}/doc'),
        headers: _headers,
      );
      if (response.statusCode != 200) throw const FormatException();
      final updated = List<Map<String, dynamic>>.of(_notifications);
      updated[index] = {
        ...item,
        'da_doc_luc':
            (jsonDecode(response.body) as Map<String, dynamic>)['da_doc_luc'],
      };
      setState(() {
        _notifications = updated;
        _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30).toInt();
      });
    } catch (_) {
      _thongBao('Không thể cập nhật trạng thái đã đọc.');
    }
  }

  Future<void> _danhDauTatCaDaDoc() async {
    if (_unreadCount == 0) return;
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/api/phu-huynh/thong-bao/doc-tat-ca'),
        headers: _headers,
      );
      if (response.statusCode != 200) throw const FormatException();
      final now = DateTime.now().toIso8601String();
      setState(() {
        _notifications = _notifications
            .map((item) => {...item, 'da_doc_luc': item['da_doc_luc'] ?? now})
            .toList();
        _unreadCount = 0;
      });
    } catch (_) {
      _thongBao('Không thể đánh dấu thông báo đã đọc.');
    }
  }

  Future<void> _luuTuyChon(String event, bool enabled) async {
    setState(() => _saving = true);
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/phu-huynh/thong-bao/cai-dat'),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'preferences': {event: enabled},
        }),
      );
      if (response.statusCode != 200) throw const FormatException();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final saved = data['preferences'] as Map<String, dynamic>;
      setState(() {
        _preferences = {
          for (final key in _loai.keys)
            key: saved[key] is bool ? saved[key] as bool : _preferences[key]!,
        };
      });
    } catch (_) {
      _thongBao('Không thể lưu cài đặt thông báo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _thoiGian(String? value) {
    final time = DateTime.tryParse(value ?? '')?.toLocal();
    if (time == null) return 'Không rõ thời gian';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _thongBao(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Thông báo ($_unreadCount chưa đọc)'),
          actions: [
            IconButton(
              key: const Key('notifications-mark-all-read'),
              tooltip: 'Đánh dấu tất cả đã đọc',
              onPressed: _unreadCount == 0 ? null : _danhDauTatCaDaDoc,
              icon: const Icon(Icons.done_all),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hộp thư'),
              Tab(text: 'Cài đặt'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _taiDuLieu,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            : TabBarView(children: [_buildHopThu(), _buildCaiDat()]),
      ),
    );
  }

  Widget _buildHopThu() {
    if (_notifications.isEmpty) {
      return const Center(child: Text('Chưa có thông báo nào.'));
    }
    return RefreshIndicator(
      onRefresh: _taiDuLieu,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount:
            _notifications.length +
            (_notifications.length >= _pageSize ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return Center(
              child: TextButton(
                onPressed: _loadingMore ? null : _taiThem,
                child: Text(
                  _loadingMore ? 'Đang tải…' : 'Tải thông báo cũ hơn',
                ),
              ),
            );
          }
          final item = _notifications[index];
          final unread = item['da_doc_luc'] == null;
          return Card(
            key: Key('notification-item-${item['id']}'),
            color: unread
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            child: ListTile(
              leading: Icon(
                unread
                    ? Icons.mark_email_unread_outlined
                    : Icons.drafts_outlined,
              ),
              title: Text(
                item['tieu_de'] as String? ?? 'Thông báo',
                style: TextStyle(
                  fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                '${item['noi_dung'] ?? ''}\n${_thoiGian(item['tao_luc'] as String?)}',
              ),
              isThreeLine: true,
              trailing: unread ? const Text('Chưa đọc') : const Text('Đã đọc'),
              onTap: unread ? () => _danhDauDaDoc(index) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaiDat() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Nhận thông báo trong hộp thư khi có các sự kiện sau:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        for (final entry in _loai.entries)
          SwitchListTile(
            key: Key('notification-preference-${entry.key}'),
            title: Text(entry.value.title),
            subtitle: Text(entry.value.subtitle),
            value: _preferences[entry.key] ?? true,
            onChanged: _saving
                ? null
                : (enabled) => _luuTuyChon(entry.key, enabled),
          ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

abstract interface class ParentGpsConnection {
  Stream<dynamic> get messages;
  Future<void> close();
}

class _IoParentGpsConnection implements ParentGpsConnection {
  const _IoParentGpsConnection(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get messages => _socket;

  @override
  Future<void> close() => _socket.close();
}

typedef ParentGpsConnector = Future<ParentGpsConnection> Function(
  Uri uri,
  Map<String, String> headers,
);

class PhuHuynhScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final http.Client? client;
  final ParentGpsConnector? gpsConnector;

  const PhuHuynhScreen({
    super.key,
    required this.token,
    required this.user,
    this.client,
    this.gpsConnector,
  });

  @override
  State<PhuHuynhScreen> createState() => _PhuHuynhScreenState();
}

class _PhuHuynhScreenState extends State<PhuHuynhScreen> {
  static const List<int> _thoiGianThuLai = [1, 2, 4, 8, 16, 30];
  bool _loading = true;
  List<dynamic> _danhSachCon = [];
  Map<int, List<dynamic>> _theoDoi = {};
  int? _hocSinhDangChonId;
  String? _loi;
  bool _dangKetNoiGps = false;
  int _soLanThuLai = 0;
  int _socketGeneration = 0;
  StreamSubscription<dynamic>? _gpsSubscription;
  ParentGpsConnection? _gpsConnection;
  Timer? _timerThuLai;
  Timer? _timerTrangThaiGps;
  late final http.Client _client = widget.client ?? http.Client();
  bool get _tuSoHuuHttpClient => widget.client == null;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _timerTrangThaiGps = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _taiThongTinTheoDoi();
  }

  @override
  void dispose() {
    _timerThuLai?.cancel();
    _timerTrangThaiGps?.cancel();
    unawaited(_gpsSubscription?.cancel());
    unawaited(_gpsConnection?.close());
    if (_tuSoHuuHttpClient) _client.close();
    super.dispose();
  }

  Future<void> _taiThongTinTheoDoi() async {
    setState(() {
      _loading = true;
      _loi = null;
    });
    try {
      final resCon = await _client.get(
        Uri.parse('$baseUrl/api/phu-huynh/con-cua-toi'),
        headers: _headers,
      );
      if (resCon.statusCode == 200) {
        final dsCon = (jsonDecode(resCon.body) as List)
            .cast<Map<String, dynamic>>();
        final dsTheoDoi = <int, List<dynamic>>{};
        for (final con in dsCon) {
          final hsId = (con['id'] as num).toInt();
          final resTd = await _client.get(
            Uri.parse('$baseUrl/api/phu-huynh/con/$hsId/theo-doi'),
            headers: _headers,
          );
          if (resTd.statusCode == 200) {
            dsTheoDoi[hsId] = jsonDecode(resTd.body) as List<dynamic>;
          } else {
            throw const FormatException('Không thể tải hành trình học sinh.');
          }
        }
        final selectedId =
            dsCon.any((con) => (con['id'] as num).toInt() == _hocSinhDangChonId)
            ? _hocSinhDangChonId
            : dsCon.isEmpty
            ? null
            : (dsCon.first['id'] as num).toInt();
        setState(() {
          _danhSachCon = dsCon;
          _theoDoi = dsTheoDoi;
          _hocSinhDangChonId = selectedId;
        });
        if (selectedId != null) {
          await _ketNoiTheoDoi(selectedId);
        } else {
          await _dongKetNoiGps();
        }
      } else {
        setState(() => _loi = 'Lỗi tải dữ liệu (${resCon.statusCode})');
      }
    } catch (e) {
      if (mounted) setState(() => _loi = 'Không thể tải dữ liệu theo dõi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moHopThuThongBao() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotificationCenterScreen(token: widget.token, client: _client),
      ),
    );
  }

  Future<void> _dongKetNoiGps() async {
    _socketGeneration += 1;
    _timerThuLai?.cancel();
    _timerThuLai = null;
    final subscription = _gpsSubscription;
    final connection = _gpsConnection;
    _gpsSubscription = null;
    _gpsConnection = null;
    if (subscription != null) await subscription.cancel();
    if (connection != null) await connection.close();
    if (mounted) setState(() => _dangKetNoiGps = false);
  }

  Future<void> _ketNoiTheoDoi(int hocSinhId) async {
    _timerThuLai?.cancel();
    _timerThuLai = null;
    final generation = ++_socketGeneration;
    final subscription = _gpsSubscription;
    final oldConnection = _gpsConnection;
    _gpsSubscription = null;
    _gpsConnection = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (oldConnection != null) unawaited(oldConnection.close());
    if (!mounted || _hocSinhDangChonId != hocSinhId) return;

    setState(() => _dangKetNoiGps = false);
    try {
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
        path: '/api/phu-huynh/theo-doi/ws',
        queryParameters: {'hocSinhId': '$hocSinhId'},
      );
      final headers = _headers;
      final connection = widget.gpsConnector != null
          ? await widget.gpsConnector!(uri, headers)
          : _IoParentGpsConnection(
              await WebSocket.connect(
                uri.toString(),
                headers: headers,
              ).timeout(const Duration(seconds: 10)),
            );
      if (!mounted ||
          generation != _socketGeneration ||
          _hocSinhDangChonId != hocSinhId) {
        await connection.close();
        return;
      }
      _gpsConnection = connection;
      _soLanThuLai = 0;
      setState(() => _dangKetNoiGps = true);
      _gpsSubscription = connection.messages.listen(
        (message) => _nhanCapNhatGps(hocSinhId, message),
        onError: (Object _) => _matKetNoiGps(connection, hocSinhId),
        onDone: () => _matKetNoiGps(connection, hocSinhId),
        cancelOnError: true,
      );
    } catch (_) {
      if (mounted && generation == _socketGeneration) {
        setState(() => _dangKetNoiGps = false);
        _datLichThuLai(hocSinhId);
      }
    }
  }

  void _nhanCapNhatGps(int hocSinhId, dynamic message) {
    if (message is! String || _hocSinhDangChonId != hocSinhId) return;
    try {
      final event = jsonDecode(message);
      if (event is! Map<String, dynamic> || event['type'] != 'gps_updated') {
        return;
      }
      final data = event['data'];
      if (data is! Map<String, dynamic> ||
          data['chuyen_di_id'] is! num ||
          data['vi_do'] is! num ||
          data['kinh_do'] is! num ||
          data['thoi_diem'] is! String) {
        return;
      }
      final chuyenId = (data['chuyen_di_id'] as num).toInt();
      final timestamp = DateTime.tryParse(data['thoi_diem'] as String);
      final journeys = _theoDoi[hocSinhId];
      if (!mounted || timestamp == null || journeys == null) return;
      final index = journeys.indexWhere(
        (journey) => (journey['chuyen_di_id'] as num?)?.toInt() == chuyenId,
      );
      if (index < 0) return;

      final old = journeys[index];
      final oldTimestamp = DateTime.tryParse('${old['cap_nhat_luc'] ?? ''}');
      if (oldTimestamp != null && timestamp.isBefore(oldTimestamp)) return;
      final updated = List<dynamic>.of(journeys);
      updated[index] = {
        ...old,
        'vi_do': (data['vi_do'] as num).toDouble(),
        'kinh_do': (data['kinh_do'] as num).toDouble(),
        'cap_nhat_luc': timestamp.toIso8601String(),
      };
      setState(() => _theoDoi[hocSinhId] = updated);
    } on FormatException {
      return;
    }
  }

  void _matKetNoiGps(ParentGpsConnection connection, int hocSinhId) {
    if (!mounted ||
        !identical(_gpsConnection, connection) ||
        _hocSinhDangChonId != hocSinhId) {
      return;
    }
    _gpsConnection = null;
    _gpsSubscription = null;
    setState(() => _dangKetNoiGps = false);
    _datLichThuLai(hocSinhId);
  }

  void _datLichThuLai(int hocSinhId) {
    if (!mounted || _timerThuLai != null) return;
    final index = _soLanThuLai.clamp(0, _thoiGianThuLai.length - 1);
    _soLanThuLai += 1;
    _timerThuLai = Timer(Duration(seconds: _thoiGianThuLai[index]), () {
      _timerThuLai = null;
      if (_hocSinhDangChonId == hocSinhId) {
        unawaited(_ketNoiTheoDoi(hocSinhId));
      }
    });
  }

  void _chonHocSinh(int? hocSinhId) {
    if (hocSinhId == null || hocSinhId == _hocSinhDangChonId) return;
    setState(() {
      _hocSinhDangChonId = hocSinhId;
      _dangKetNoiGps = false;
    });
    unawaited(_ketNoiTheoDoi(hocSinhId));
  }

  String _dinhDangGps(dynamic timestamp) {
    final parsed = DateTime.tryParse('$timestamp');
    if (parsed == null) return 'Chưa có dữ liệu GPS';
    final local = parsed.toLocal();
    final isStale =
        DateTime.now().difference(local) > const Duration(minutes: 2);
    final formatted =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
    return isStale ? 'GPS cũ • $formatted' : 'Cập nhật GPS • $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final journeys = _theoDoi[_hocSinhDangChonId] ?? const <dynamic>[];
    final lichSu = journeys
        .expand(
          (journey) => (journey['lich_su_diem_danh'] as List?) ?? const [],
        )
        .toList();
    final hocSinhDangChon = _danhSachCon.where(
      (con) => (con['id'] as num?)?.toInt() == _hocSinhDangChonId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Phụ huynh: ${widget.user['hoTen']}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('parent-notification-inbox'),
            tooltip: 'Hộp thư thông báo',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _moHopThuThongBao,
          ),
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
                if (_danhSachCon.isNotEmpty)
                  Card(
                    child: ListTile(
                      title: const Text('Học sinh đang xem'),
                      trailing: PopupMenuButton<int>(
                        key: const Key('parent-child-selector'),
                        tooltip: 'Chọn học sinh',
                        onSelected: _chonHocSinh,
                        itemBuilder: (context) => _danhSachCon.map((con) {
                          final name = con['ho_ten'] ?? 'Học sinh';
                          final code = con['ma_hs'] ?? '';
                          return PopupMenuItem<int>(
                            value: (con['id'] as num).toInt(),
                            child: Text('$name ($code)'),
                          );
                        }).toList(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Đổi'),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hocSinhDangChon.isNotEmpty)
                  Card(
                    color: Colors.teal.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.face,
                        size: 40,
                        color: Colors.teal,
                      ),
                      title: Text(
                        '${hocSinhDangChon.first['ho_ten']} (${hocSinhDangChon.first['ma_hs']})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Lớp: ${hocSinhDangChon.first['ten_lop']} - ${hocSinhDangChon.first['ten_truong']}\nQuan hệ: ${hocSinhDangChon.first['quan_he']}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'VỊ TRÍ XE TRƯỜNG & CHUYẾN ĐI HÔM NAY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (_danhSachCon.isNotEmpty)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _dangKetNoiGps ? Icons.wifi_tethering : Icons.sync,
                        color: _dangKetNoiGps ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      title: Text(
                        _dangKetNoiGps
                            ? 'Đang nhận cập nhật trực tiếp'
                            : 'Đang kết nối lại với xe',
                      ),
                      subtitle: const Text(
                        'Vị trí chỉ hiển thị khi chuyến thuộc học sinh đã liên kết.',
                      ),
                    ),
                  ),
                if (journeys.isEmpty && _danhSachCon.isNotEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Hôm nay chưa có chuyến đi được phân công.'),
                    ),
                  ),
                ...journeys.map((journey) {
                  final viDo = journey['vi_do'];
                  final kinhDo = journey['kinh_do'];
                  final coGps = viDo is num && kinhDo is num;
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 36,
                      ),
                      title: Text(
                        '${journey['ten_tuyen']} (${journey['bien_so']}) • ${journey['chieu'] == 'TRA_CHIEU' ? 'Trả chiều' : 'Đón sáng'}',
                      ),
                      subtitle: Text(
                        '${journey['trang_thai']}\n'
                        '${coGps ? 'Tọa độ GPS: $viDo, $kinhDo' : 'Chưa có dữ liệu GPS'}\n'
                        '${_dinhDangGps(journey['cap_nhat_luc'])}\n'
                        'Tài xế: ${journey['ten_tai_xe']} (${journey['sdt_tai_xe']})',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
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
