import 'package:flutter/material.dart';

import '../../models/nguoi_dung.dart';
import '../../models/van_hanh.dart';
import '../../operations/van_hanh_service.dart';
import '../../widgets/trang_thai_danh_sach.dart';
import 'widgets/diem_dung_timeline_widget.dart';
import 'widgets/hoc_sinh_item_widget.dart';

class ChiTietChuyenPage extends StatefulWidget {
  const ChiTietChuyenPage({
    super.key,
    required this.chuyenId,
    this.initialChuyen,
    required this.vanHanhService,
    required this.nguoiDung,
  });

  final int chuyenId;
  final ChuyenDi? initialChuyen;
  final VanHanhService vanHanhService;
  final NguoiDung nguoiDung;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _taiDuLieu();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final dsHocSinh = chiTiet.hocSinh;

    if (dsHocSinh.isEmpty) {
      return const Center(
        child: Text('Chưa có học sinh nào đăng ký trên tuyến này.'),
      );
    }

    final Map<int, String> diemDungMap = {
      for (final d in chiTiet.diemDung) d.id: d.ten,
    };

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dsHocSinh.length,
      itemBuilder: (context, index) {
        final hs = dsHocSinh[index];
        final tenTram = hs.diemDungId != null ? diemDungMap[hs.diemDungId] : null;

        return HocSinhItemWidget(
          key: ValueKey('hoc-sinh-${hs.id}'),
          hocSinh: hs,
          tenDiemDung: tenTram,
          dangXuLy: _dangXuLyHocSinh.contains(hs.id),
          onDiemDanhLenXe: () => _diemDanhLenXe(hs),
          onDiemDanhXuongXe: () => _diemDanhXuongXe(hs),
        );
      },
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
                  : Column(
                      children: [
                        _buildOverviewHeader(_chiTiet!, theme),
                        TabBar(
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
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildDiemDungTab(_chiTiet!, theme),
                              _buildHocSinhTab(_chiTiet!, theme),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
