import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../fleet/quan_ly_service.dart';
import '../../operations/quan_ly_operations_service.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/trang_thai_danh_sach.dart';

class GiamSatPage extends StatefulWidget {
  const GiamSatPage({super.key, required this.service});

  final QuanLyOperationsService service;

  @override
  State<GiamSatPage> createState() => _GiamSatPageState();
}

class _GiamSatPageState extends State<GiamSatPage> {
  static const Duration _nguongGpsCu = Duration(minutes: 2);
  static const List<int> _thoiGianThuLai = [1, 2, 4, 8, 16, 30];

  Timer? _timerThuLai;
  StreamSubscription<dynamic>? _socketSubscription;
  GiamSatConnection? _socket;
  List<GiamSat> _danhSach = [];
  bool _dangTai = false;
  bool _dangKetNoi = false;
  bool _daKetNoi = false;
  int _soLanThuLai = 0;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
    _ketNoiWebSocket();
  }

  @override
  void dispose() {
    _timerThuLai?.cancel();
    final subscription = _socketSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    final socket = _socket;
    if (socket != null) unawaited(socket.close());
    super.dispose();
  }

  Future<void> _tai({bool boQuaDangTai = false}) async {
    if (_dangTai && !boQuaDangTai) return;

    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final danhSach = await widget.service.layGiamSat();
      if (!mounted) return;
      final viTriHienTai = {for (final item in _danhSach) item.id: item};
      final daGhep = danhSach.map((item) {
        final cu = viTriHienTai[item.id];
        final thoiDiemCu = cu?.viTriCapNhatLuc;
        final thoiDiemMoi = item.viTriCapNhatLuc;
        if (cu == null ||
            thoiDiemCu == null ||
            cu.viDo == null ||
            cu.kinhDo == null ||
            (thoiDiemMoi != null && !thoiDiemCu.isAfter(thoiDiemMoi))) {
          return item;
        }
        return item.capNhatViTri(
          viDo: cu.viDo!,
          kinhDo: cu.kinhDo!,
          thoiDiem: thoiDiemCu,
        );
      }).toList();
      setState(() => _danhSach = daGhep);
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      setState(() => _loi = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loi = 'Không thể tải dữ liệu giám sát.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Future<void> _ketNoiWebSocket() async {
    if (!mounted || _dangKetNoi) return;
    setState(() => _dangKetNoi = true);
    try {
      final socket = await widget.service.ketNoiGiamSat();
      if (!mounted) {
        await socket.close();
        return;
      }
      _socket = socket;
      _soLanThuLai = 0;
      setState(() {
        _dangKetNoi = false;
        _daKetNoi = true;
      });
      _socketSubscription = socket.messages.listen(
        _nhanTinWebSocket,
        onError: (_, _) => _matKetNoi(socket),
        onDone: () => _matKetNoi(socket),
        cancelOnError: true,
      );
      await _tai(boQuaDangTai: true);
    } catch (_) {
      if (mounted) setState(() => _dangKetNoi = false);
      _datLichThuLai();
    }
  }

  void _nhanTinWebSocket(dynamic tin) {
    if (tin is! String) return;
    try {
      final thongDiep = jsonDecode(tin);
      if (thongDiep is! Map<String, dynamic> ||
          thongDiep['type'] != 'gps_updated') {
        return;
      }
      final data = thongDiep['data'];
      if (data is! Map<String, dynamic> ||
          data['chuyen_di_id'] is! num ||
          data['vi_do'] is! num ||
          data['kinh_do'] is! num ||
          data['thoi_diem'] is! String) {
        return;
      }

      final chuyenId = (data['chuyen_di_id'] as num).toInt();
      final thoiDiem = DateTime.tryParse(data['thoi_diem'] as String);
      final index = _danhSach.indexWhere((item) => item.id == chuyenId);
      if (!mounted || thoiDiem == null || index < 0) return;

      final hienTai = _danhSach[index];
      final viTriCu = hienTai.viTriCapNhatLuc;
      if (viTriCu != null && thoiDiem.isBefore(viTriCu)) return;

      final capNhat = List<GiamSat>.of(_danhSach);
      capNhat[index] = hienTai.capNhatViTri(
        viDo: (data['vi_do'] as num).toDouble(),
        kinhDo: (data['kinh_do'] as num).toDouble(),
        thoiDiem: thoiDiem,
      );
      setState(() => _danhSach = capNhat);
    } on FormatException {
      return;
    }
  }

  void _matKetNoi(GiamSatConnection socket) {
    if (!mounted || !identical(_socket, socket)) return;
    _socket = null;
    _socketSubscription = null;
    setState(() => _daKetNoi = false);
    _datLichThuLai();
  }

  void _datLichThuLai() {
    if (!mounted || _timerThuLai != null) return;
    final index = _soLanThuLai.clamp(0, _thoiGianThuLai.length - 1);
    final delay = Duration(seconds: _thoiGianThuLai[index]);
    _soLanThuLai += 1;
    _timerThuLai = Timer(delay, () {
      _timerThuLai = null;
      _ketNoiWebSocket();
    });
  }

  String _nhanChieu(String chieu) {
    return chieu == 'TRA_CHIEU' ? 'Trả chiều' : 'Đón sáng';
  }

  String _nhanTrangThai(String trangThai) {
    switch (trangThai) {
      case 'DANG_CHAY':
        return 'Đang chạy';
      case 'HOAN_THANH':
        return 'Hoàn thành';
      default:
        return 'Chưa chạy';
    }
  }

  String _dinhDangThoiGian(DateTime thoiDiem) {
    final ngay = thoiDiem.day.toString().padLeft(2, '0');
    final thang = thoiDiem.month.toString().padLeft(2, '0');
    final gio = thoiDiem.hour.toString().padLeft(2, '0');
    final phut = thoiDiem.minute.toString().padLeft(2, '0');
    final giay = thoiDiem.second.toString().padLeft(2, '0');
    return '$ngay/$thang/${thoiDiem.year} $gio:$phut:$giay';
  }

  Widget _thongTinGps(BuildContext context, GiamSat giamSat) {
    if (giamSat.viDo == null ||
        giamSat.kinhDo == null ||
        giamSat.viTriCapNhatLuc == null) {
      return const Text('Chưa có dữ liệu GPS');
    }

    final capNhat = giamSat.viTriCapNhatLuc!.toLocal();
    final laGpsCu = DateTime.now().difference(capNhat) > _nguongGpsCu;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vĩ độ: ${giamSat.viDo} • Kinh độ: ${giamSat.kinhDo}'),
        Text('GPS: ${_dinhDangThoiGian(capNhat)}'),
        if (laGpsCu)
          Text(
            'GPS cũ (quá 2 phút)',
            style: TextStyle(color: theme.colorScheme.error),
          ),
      ],
    );
  }

  Widget _noiDung(BuildContext context) {
    if (_dangTai && _danhSach.isEmpty) {
      return const TrangThaiDangTai(thongDiep: 'Đang tải dữ liệu giám sát...');
    }

    if (_loi != null && _danhSach.isEmpty) {
      return TrangThaiLoi(
        thongDiep: _loi!,
        onThuLai: _tai,
        retryKey: const Key('giam-sat-retry'),
      );
    }

    if (_danhSach.isEmpty) {
      return TrangThaiRong(
        icon: Icons.location_off_outlined,
        thongDiep: 'Chưa có chuyến đi nào hôm nay.',
        onLamMoi: _tai,
        refreshKey: const Key('giam-sat-empty-refresh'),
      );
    }

    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _daKetNoi
                      ? 'Đang nhận cập nhật trực tiếp.'
                      : _dangKetNoi
                      ? 'Đang kết nối cập nhật trực tiếp...'
                      : 'Mất kết nối; đang tự kết nối lại.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                key: const Key('giam-sat-refresh'),
                tooltip: 'Làm mới',
                onPressed: _tai,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (_dangTai) const LinearProgressIndicator(),
        if (_loi != null)
          Container(
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loi!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                TextButton(onPressed: _tai, child: const Text('Thử lại')),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _tai,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _danhSach.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final giamSat = _danhSach[index];
                return Card(
                  key: Key('giam-sat-row-${giamSat.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${giamSat.tenTuyen} • ${giamSat.bienSo}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_nhanChieu(giamSat.chieu)} • '
                          '${_nhanTrangThai(giamSat.trangThai)}',
                        ),
                        const SizedBox(height: 8),
                        _thongTinGps(context, giamSat),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(child: _noiDung(context)),
    );
  }
}
