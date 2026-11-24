import 'package:flutter/material.dart';

import '../../models/nguoi_dung.dart';
import '../../models/van_hanh.dart';
import '../../operations/van_hanh_service.dart';
import '../../operations/gps_tracker_service.dart';
import '../../widgets/trang_thai_danh_sach.dart';
import 'widgets/diem_dung_timeline_widget.dart';
import 'widgets/hoc_sinh_item_widget.dart';
import 'widgets/hoc_sinh_list_tab_widget.dart';
import 'widgets/gps_live_status_widget.dart';

class ChiTietChuyenPage extends StatefulWidget {
  const ChiTietChuyenPage({
    super.key,
    required this.chuyenId,
    this.initialChuyen,
    required this.vanHanhService,
    required this.nguoiDung,
    this.gpsTracker,
  });

  final int chuyenId;
  final ChuyenDi? initialChuyen;
  final VanHanhService vanHanhService;
  final NguoiDung nguoiDung;
  final GpsTrackerService? gpsTracker;

  @override
  State<ChiTietChuyenPage> createState() => _ChiTietChuyenPageState();
}

class _ChiTietChuyenPageState extends State<ChiTietChuyenPage>
    with SingleTickerProviderStateMixin {
  bool _dangTai = true;
  String? _loi;
  ChiTietChuyenDi? _chiTiet;
  late TabController _tabController;
  final Set<int> _dangXuLyHocSinh = {};
  bool _dangXuLyChuyen = false;
  late final GpsTrackerService _gpsTracker;
  bool _soHuuGpsTracker = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.gpsTracker != null) {
      _gpsTracker = widget.gpsTracker!;
      _soHuuGpsTracker = false;
    } else {
      _gpsTracker = GpsTrackerService(vanHanhService: widget.vanHanhService);
      _soHuuGpsTracker = true;
    }
    _taiDuLieu();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_soHuuGpsTracker) {
      _gpsTracker.dispose();
    } else {
      _gpsTracker.dungTracking();
    }
    super.dispose();
  }

  Future<void> _taiDuLieu() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final res = await widget.vanHanhService.layChiTietChuyen(widget.chuyenId);
      if (!mounted) return;
      setState(() {
        _chiTiet = res;
        _dangTai = false;
      });

      if (res.chuyenDi.laDangChay && !_gpsTracker.dangTracking) {
        _gpsTracker.batDauTracking(
          chuyenId: widget.chuyenId,
          loTrinh: res.diemDung,
        );
      }
    } on VanHanhApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e.message;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = 'Không thể tải chi tiết ca xe ($e)';
        _dangTai = false;
      });
    }
  }

  /// Ghi nhận điểm danh LÊN XE cho học sinh
  Future<void> _diemDanhLenXe(HocSinhDiemDanh hs) async {
    if (_dangXuLyHocSinh.contains(hs.id)) return;

    if (hs.coDonBaoNghi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hs.hoTen} đã có đơn xin nghỉ phép.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (_chiTiet?.chuyenDi.trangThai == TrangThaiChuyen.daKetThuc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyến đi đã kết thúc, không thể điểm danh thêm.'),
        ),
      );
      return;
    }

    setState(() {
      _dangXuLyHocSinh.add(hs.id);
    });

    try {
      await widget.vanHanhService.diemDanh(
        chuyenId: widget.chuyenId,
        hocSinhId: hs.id,
        diemDungId: hs.diemDungId,
        suKien: 'LEN_XE',
      );

      if (!mounted) return;
      setState(() {
        _chiTiet = _chiTiet?.capNhatDiemDanh(
          hocSinhId: hs.id,
          suKien: 'LEN_XE',
        );
        _dangXuLyHocSinh.remove(hs.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã điểm danh ${hs.hoTen} LÊN XE thành công!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } on VanHanhApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _dangXuLyHocSinh.remove(hs.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi điểm danh: ${e.message}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dangXuLyHocSinh.remove(hs.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể kết nối máy chủ: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Ghi nhận điểm danh XUỐNG XE cho học sinh (tại trường hoặc trạm trả)
  Future<void> _diemDanhXuongXe(HocSinhDiemDanh hs) async {
    if (_dangXuLyHocSinh.contains(hs.id)) return;

    if (!hs.daLenXe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hs.hoTen} chưa lên xe, không thể điểm danh xuống xe!'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (hs.daXuongXe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hs.hoTen} đã được điểm danh xuống xe trước đó.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_chiTiet?.chuyenDi.trangThai == TrangThaiChuyen.daKetThuc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyến đi đã kết thúc, không thể điểm danh thêm.'),
        ),
      );
      return;
    }

    setState(() {
      _dangXuLyHocSinh.add(hs.id);
    });

    try {
      await widget.vanHanhService.diemDanh(
        chuyenId: widget.chuyenId,
        hocSinhId: hs.id,
        diemDungId: hs.diemDungId,
        suKien: 'XUONG_XE',
      );

      if (!mounted) return;
      setState(() {
        _chiTiet = _chiTiet?.capNhatDiemDanh(
          hocSinhId: hs.id,
          suKien: 'XUONG_XE',
        );
        _dangXuLyHocSinh.remove(hs.id);
      });

      final soHsTrenXe = _chiTiet?.soHocSinhTrenXe ?? 0;
      final thongDiep = soHsTrenXe == 0
          ? 'Đã điểm danh ${hs.hoTen} XUỐNG XE. Tất cả học sinh đã xuống xe an toàn!'
          : 'Đã điểm danh ${hs.hoTen} XUỐNG XE thành công!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(thongDiep),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } on VanHanhApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _dangXuLyHocSinh.remove(hs.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi điểm danh: ${e.message}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dangXuLyHocSinh.remove(hs.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể kết nối máy chủ: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Xác nhận và thực hiện bắt đầu chuyến xe
  Future<void> _xacNhanBatDauChuyen() async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions_bus_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Bắt đầu chuyến đi?'),
          ],
        ),
        content: const Text(
          'Xe sẽ chuyển sang trạng thái Đang chạy và hệ thống sẽ bắt đầu theo dõi tiến trình lộ trình và điểm danh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('btn-dialog-xac-nhan-bat-dau'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );

    if (xacNhan != true) return;

    setState(() => _dangXuLyChuyen = true);
    try {
      final updated = await widget.vanHanhService.batDauChuyen(widget.chuyenId);
      if (!mounted) return;
      setState(() {
        _chiTiet = _chiTiet?.copyWith(chuyenDi: updated);
        _dangXuLyChuyen = false;
      });
      _gpsTracker.batDauTracking(
        chuyenId: widget.chuyenId,
        loTrinh: _chiTiet?.diemDung ?? [],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chuyến đi đã bắt đầu! Chúc bạn có lộ trình an toàn.'),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangXuLyChuyen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể bắt đầu chuyến: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Hiển thị Dialog cảnh báo an toàn khi kết thúc chuyến mà còn học sinh chưa xác nhận xuống xe
  Future<void> _hienDialogCanhBaoChuaXuongXe(
    String canhBao,
    List<String> dsChuaXuong,
  ) async {
    final List<String> danhSachHienThi = dsChuaXuong.isNotEmpty
        ? dsChuaXuong
        : (_chiTiet?.hocSinh
                .where((h) => !h.coDonBaoNghi && (!h.daLenXe || !h.daXuongXe))
                .map((h) => '${h.hoTen} (${h.tenLop})')
                .toList() ??
            []);

    final xacNhanBoQua = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('dialog-canh-bao-chua-xuong-xe'),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 40,
          ),
        ),
        title: Text(
          'CẢNH BÁO AN TOÀN TRẺ EM',
          style: TextStyle(
            color: Colors.red.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canhBao.isNotEmpty
                    ? canhBao
                    : 'Còn học sinh chưa được xác nhận xuống xe! Hãy kiểm tra kỹ tất cả các hàng ghế trước khi rời xe để đảm bảo không bỏ quên học sinh!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (danhSachHienThi.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Danh sách học sinh chưa xác nhận:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: danhSachHienThi
                        .map(
                          (ten) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 14, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ten,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            key: const Key('btn-dialog-kiem-tra-lai'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kiểm tra lại xe'),
          ),
          FilledButton(
            key: const Key('btn-dialog-bo-qua-ket-thuc'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bỏ qua & Kết thúc'),
          ),
        ],
      ),
    );

    if (xacNhanBoQua == true) {
      await _thucHienKetThucChuyen(boQua: true);
    }
  }

  /// Thực hiện gọi API kết thúc chuyến đi
  Future<void> _thucHienKetThucChuyen({bool boQua = false}) async {
    setState(() => _dangXuLyChuyen = true);
    try {
      final updated = await widget.vanHanhService.ketThucChuyen(
        widget.chuyenId,
        boQua: boQua,
      );
      if (!mounted) return;
      setState(() {
        _chiTiet = _chiTiet?.copyWith(chuyenDi: updated);
        _dangXuLyChuyen = false;
      });
      _gpsTracker.dungTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chuyến đi đã kết thúc thành công!'),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on KetThucChuyenException catch (e) {
      if (!mounted) return;
      setState(() => _dangXuLyChuyen = false);
      await _hienDialogCanhBaoChuaXuongXe(e.canhBao, e.danhSachChuaHoanTat);
    } on VanHanhApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangXuLyChuyen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết thúc chuyến: ${e.message}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangXuLyChuyen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể kết nối máy chủ: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildThongKeItem({
    required BuildContext context,
    required String tieuDe,
    required String giaTri,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tieuDe,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  giaTri,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripActionButtons(ChuyenDi chuyen, ThemeData theme) {
    if (_dangXuLyChuyen) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (chuyen.laChuaChay) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('btn-bat-dau-chuyen'),
          onPressed: _xacNhanBatDauChuyen,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(
            'BẮT ĐẦU CHUYẾN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (chuyen.laDangChay) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('btn-ket-thuc-chuyen'),
          onPressed: () => _thucHienKetThucChuyen(boQua: false),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text(
            'KẾT THÚC CHUYẾN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (chuyen.laHoanThanh) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.teal.shade700, size: 18),
            const SizedBox(width: 8),
            Text(
              'Chuyến đi đã hoàn tất và kết thúc an toàn',
              style: TextStyle(
                color: Colors.teal.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildOverviewHeader(ChiTietChuyenDi chiTiet, ThemeData theme) {
    final colors = theme.colorScheme;
    final chuyen = chiTiet.chuyenDi;

    Color statusColor;
    String statusText;
    if (chuyen.laDangChay) {
      statusColor = Colors.green.shade700;
      statusText = 'Đang chạy';
    } else if (chuyen.laHoanThanh) {
      statusColor = Colors.teal.shade700;
      statusText = 'Đã hoàn thành';
    } else {
      statusColor = Colors.orange.shade700;
      statusText = 'Chưa chạy';
    }

    return Card(
      key: const Key('card-chuyen-overview'),
      elevation: 0,
      margin: const EdgeInsets.all(16),
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chuyen.tenTuyen,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${chuyen.chieu.ten} • Biển số: ${chuyen.bienSo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lưới 4 ô thống kê học sinh
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildThongKeItem(
                  context: context,
                  tieuDe: 'Tổng học sinh',
                  giaTri: '${chiTiet.tongSoHocSinh}',
                  icon: Icons.people_alt_outlined,
                  color: colors.primary,
                ),
                _buildThongKeItem(
                  context: context,
                  tieuDe: 'Báo nghỉ học',
                  giaTri: '${chiTiet.soHocSinhBaoNghi}',
                  icon: Icons.event_busy_outlined,
                  color: Colors.orange.shade800,
                ),
                _buildThongKeItem(
                  context: context,
                  tieuDe: 'Đang trên xe',
                  giaTri: '${chiTiet.soHocSinhTrenXe}',
                  icon: Icons.airline_seat_recline_normal_rounded,
                  color: Colors.blue.shade700,
                ),
                _buildThongKeItem(
                  context: context,
                  tieuDe: 'Đã xuống xe',
                  giaTri: '${chiTiet.soHocSinhDaXuong}',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green.shade700,
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildTripActionButtons(chuyen, theme),
            if (chuyen.laDangChay) ...[
              GpsLiveStatusWidget(
                gpsTracker: _gpsTracker,
                onGuiNgay: () async {
                  final vt = _gpsTracker.viTriHienTai;
                  if (vt != null) {
                    await _gpsTracker.guiToaDoThuCong(
                      chuyenId: widget.chuyenId,
                      viDo: vt.viDo,
                      kinhDo: vt.kinhDo,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã cập nhật tọa độ GPS lên hệ thống.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiemDungTab(ChiTietChuyenDi chiTiet, ThemeData theme) {
    return DiemDungTimelineWidget(
      chiTiet: chiTiet,
      onDiemDanhTaiTram: (diemDung) {
        _tabController.animateTo(1);
      },
    );
  }

  Widget _buildHocSinhTab(ChiTietChuyenDi chiTiet, ThemeData theme) {
    return HocSinhListTabWidget(
      chiTiet: chiTiet,
      dangXuLyHocSinh: _dangXuLyHocSinh,
      onDiemDanhLenXe: _diemDanhLenXe,
      onDiemDanhXuongXe: _diemDanhXuongXe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = widget.initialChuyen;
    final tieuDe = _chiTiet?.chuyenDi.tenTuyen ?? initial?.tenTuyen ?? 'Chi tiết ca xe';

    return Scaffold(
      key: const Key('chi-tiet-chuyen-page'),
      appBar: AppBar(
        title: Text(tieuDe),
        actions: [
          IconButton(
            key: const Key('btn-refresh-chi-tiet'),
            tooltip: 'Làm mới',
            onPressed: _taiDuLieu,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _dangTai
          ? const TrangThaiDangTai(thongDiep: 'Đang tải dữ liệu ca xe...')
          : _loi != null
              ? TrangThaiLoi(
                  retryKey: const Key('chi-tiet-retry'),
                  thongDiep: _loi!,
                  onThuLai: _taiDuLieu,
                )
              : _chiTiet == null
                  ? const Center(child: Text('Không tìm thấy thông tin ca xe.'))
                  : OrientationBuilder(
                      builder: (context, orientation) {
                        final laNgang = orientation == Orientation.landscape;

                        final tabBar = TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(
                              icon: const Icon(Icons.alt_route_rounded, size: 20),
                              text: 'Điểm dừng (${_chiTiet!.diemDung.length})',
                            ),
                            Tab(
                              icon: const Icon(Icons.people_alt_outlined, size: 20),
                              text: 'Học sinh (${_chiTiet!.hocSinh.length})',
                            ),
                          ],
                        );

                        final tabViews = TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDiemDungTab(_chiTiet!, theme),
                            _buildHocSinhTab(_chiTiet!, theme),
                          ],
                        );

                        if (laNgang) {
                          // Bố cục tối ưu xoay ngang (Landscape Mode)
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Cột trái: Thông tin tổng quan ca xe & Nút thao tác
                              SizedBox(
                                width: 360,
                                child: SingleChildScrollView(
                                  key: const PageStorageKey<String>('landscape-header-scroll'),
                                  child: _buildOverviewHeader(_chiTiet!, theme),
                                ),
                              ),
                              const VerticalDivider(width: 1),
                              // Cột phải: TabBar và TabBarView
                              Expanded(
                                child: Column(
                                  children: [
                                    tabBar,
                                    Expanded(child: tabViews),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        // Bố cục xoay dọc mặc định (Portrait Mode)
                        return Column(
                          children: [
                            _buildOverviewHeader(_chiTiet!, theme),
                            tabBar,
                            Expanded(child: tabViews),
                          ],
                        );
                      },
                    ),
    );
  }
}
