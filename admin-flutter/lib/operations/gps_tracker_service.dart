import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/van_hanh.dart';
import 'van_hanh_service.dart';

/// Dữ liệu tọa độ GPS tại một thời điểm
@immutable
class ViTriGps {
  const ViTriGps({
    required this.viDo,
    required this.kinhDo,
    required this.thoiDiem,
    this.tocDo = 25.0, // km/h mặc định
  });

  final double viDo;
  final double kinhDo;
  final DateTime thoiDiem;
  final double tocDo;

  String get toaDoChuoi =>
      '${viDo.toStringAsFixed(5)}° N, ${kinhDo.toStringAsFixed(5)}° E';

  @override
  String toString() => 'ViTriGps($viDo, $kinhDo, $thoiDiem)';
}

/// Dịch vụ theo dõi và truyền tọa độ GPS xe thời gian thực
class GpsTrackerService {
  GpsTrackerService({
    required this.vanHanhService,
    this.chuKy = const Duration(seconds: 5),
  });

  final VanHanhService vanHanhService;
  final Duration chuKy;

  Timer? _timer;
  int? _chuyenIdHienTai;
  List<DiemDung> _loTrinh = [];
  int _chiSoDiemHienTai = 0;
  ViTriGps? _viTriHienTai;
  bool _dangTamDung = false;

  final StreamController<ViTriGps> _viTriController =
      StreamController<ViTriGps>.broadcast();
  final StreamController<bool> _trangThaiController =
      StreamController<bool>.broadcast();

  bool get dangTracking => _timer != null && _timer!.isActive && !_dangTamDung;
  bool get dangTamDung => _dangTamDung;
  ViTriGps? get viTriHienTai => _viTriHienTai;
  Stream<ViTriGps> get viTriStream => _viTriController.stream;
  Stream<bool> get trangThaiStream => _trangThaiController.stream;

  /// Bắt đầu phát tọa độ GPS theo chu kỳ cho chuyến đi
  void batDauTracking({
    required int chuyenId,
    List<DiemDung> loTrinh = const [],
    ViTriGps? viTriBanDau,
  }) {
    dungTracking();

    _chuyenIdHienTai = chuyenId;
    _loTrinh = loTrinh;
    _chiSoDiemHienTai = 0;
    _dangTamDung = false;

    // Thiết lập vị trí khởi đầu
    if (viTriBanDau != null) {
      _viTriHienTai = viTriBanDau;
    } else if (loTrinh.isNotEmpty) {
      _viTriHienTai = ViTriGps(
        viDo: loTrinh.first.viDo,
        kinhDo: loTrinh.first.kinhDo,
        thoiDiem: DateTime.now(),
      );
    } else {
      // Tọa độ trung tâm TP.HCM mặc định nếu không có lộ trình
      _viTriHienTai = ViTriGps(
        viDo: 10.7769,
        kinhDo: 106.7009,
        thoiDiem: DateTime.now(),
      );
    }

    _viTriController.add(_viTriHienTai!);
    _trangThaiController.add(true);

    // Gửi tọa độ ban đầu ngay lập tức
    _guiToaDoHienTai();

    // Thiết lập timer định kỳ
    _timer = Timer.periodic(chuKy, (_) => _buocTiepTheo());
  }

  /// Tạm dừng phát GPS (ví dụ tài xế tắt tạm thời)
  void tamDung() {
    _dangTamDung = true;
    _trangThaiController.add(false);
  }

  /// Tiếp tục phát GPS
  void tiepTuc() {
    if (_chuyenIdHienTai == null) return;
    _dangTamDung = false;
    _trangThaiController.add(true);
    _guiToaDoHienTai();
  }

  /// Dừng hoàn toàn việc phát tọa độ GPS
  void dungTracking() {
    _timer?.cancel();
    _timer = null;
    _chuyenIdHienTai = null;
    _dangTamDung = false;
    _trangThaiController.add(false);
  }

  /// Tính toán tọa độ bước tiếp theo dọc theo lộ trình các trạm dừng
  void _buocTiepTheo() {
    if (_dangTamDung || _chuyenIdHienTai == null) return;

    if (_loTrinh.length > 1) {
      _chiSoDiemHienTai = (_chiSoDiemHienTai + 1) % _loTrinh.length;
      final diem = _loTrinh[_chiSoDiemHienTai];
      // Thêm một chút dao động thực tế (+- 0.0001 độ)
      final offset = ((_chiSoDiemHienTai % 3) - 1) * 0.00008;
      _viTriHienTai = ViTriGps(
        viDo: diem.viDo + offset,
        kinhDo: diem.kinhDo + offset,
        thoiDiem: DateTime.now(),
      );
    } else if (_viTriHienTai != null) {
      // Di chuyển tịnh tiến nhẹ
      _viTriHienTai = ViTriGps(
        viDo: _viTriHienTai!.viDo + 0.0002,
        kinhDo: _viTriHienTai!.kinhDo + 0.0002,
        thoiDiem: DateTime.now(),
      );
    }

    if (_viTriHienTai != null) {
      _viTriController.add(_viTriHienTai!);
      _guiToaDoHienTai();
    }
  }

  /// Gửi tọa độ hiện tại lên server qua VanHanhService
  Future<void> _guiToaDoHienTai() async {
    if (_chuyenIdHienTai == null || _viTriHienTai == null) return;
    try {
      await vanHanhService.capNhatViTriGps(
        chuyenId: _chuyenIdHienTai!,
        viDo: _viTriHienTai!.viDo,
        kinhDo: _viTriHienTai!.kinhDo,
      );
    } catch (e) {
      debugPrint('[GPS Tracker] Gửi vị trí thất bại: $e');
    }
  }

  /// Gửi thủ công tọa độ chỉ định
  Future<void> guiToaDoThuCong({
    required int chuyenId,
    required double viDo,
    required double kinhDo,
  }) async {
    _viTriHienTai = ViTriGps(
      viDo: viDo,
      kinhDo: kinhDo,
      thoiDiem: DateTime.now(),
    );
    _viTriController.add(_viTriHienTai!);

    await vanHanhService.capNhatViTriGps(
      chuyenId: chuyenId,
      viDo: viDo,
      kinhDo: kinhDo,
    );
  }

  void dispose() {
    dungTracking();
    _viTriController.close();
    _trangThaiController.close();
  }
}
