import 'package:flutter/material.dart';

import '../../models/nguoi_dung.dart';
import '../../models/van_hanh.dart';
import '../../operations/van_hanh_service.dart';
import '../../widgets/trang_thai_danh_sach.dart';

class ChuyenHomNayPage extends StatefulWidget {
  const ChuyenHomNayPage({
    super.key,
    required this.vanHanhService,
    required this.nguoiDung,
    required this.onChonChuyen,
  });

  final VanHanhService vanHanhService;
  final NguoiDung nguoiDung;
  final ValueChanged<ChuyenDi> onChonChuyen;

  @override
  State<ChuyenHomNayPage> createState() => _ChuyenHomNayPageState();
}

class _ChuyenHomNayPageState extends State<ChuyenHomNayPage> {
  bool _dangTai = true;
  String? _loi;
  List<ChuyenDi> _dsChuyen = [];

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  Future<void> _taiDuLieu() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final ketQua = await widget.vanHanhService.layDanhSachChuyenHomNay();
      if (!mounted) return;
      setState(() {
        _dsChuyen = ketQua;
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
        _loi = 'Không thể tải danh sách chuyến đi ($e)';
        _dangTai = false;
      });
    }
  }

  String _formatNgayHienTai() {
    final now = DateTime.now();
    const thu = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final tenThu = thu[now.weekday - 1];
    return '$tenThu, ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final colors = theme.colorScheme;
    final laTaiXe = widget.nguoiDung.laTaiXe;
    final roleColor = laTaiXe ? Colors.orange.shade700 : Colors.teal.shade700;

    return Card(
      key: const Key('card-ca-truc-header'),
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    laTaiXe
                        ? Icons.directions_bus_rounded
                        : Icons.support_agent_rounded,
                    color: roleColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nguoiDung.hoTen,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.nguoiDung.tenVaiTro} • ${widget.nguoiDung.sdt ?? 'SĐT: Chưa có'}',
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 13,
                        color: Colors.green.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sẵn sàng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatNgayHienTai(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChuyenCard(ChuyenDi chuyen, ThemeData theme) {
    final colors = theme.colorScheme;
    final laDangChay = chuyen.laDangChay;
    final laHoanThanh = chuyen.laHoanThanh;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (laDangChay) {
      statusColor = Colors.green.shade700;
      statusText = 'Đang chạy';
      statusIcon = Icons.sensors_rounded;
    } else if (laHoanThanh) {
      statusColor = Colors.teal.shade700;
      statusText = 'Đã hoàn thành';
      statusIcon = Icons.task_alt_rounded;
    } else {
      statusColor = Colors.orange.shade700;
      statusText = 'Chưa chạy';
      statusIcon = Icons.schedule_rounded;
    }

    return Card(
      key: Key('chuyen-card-${chuyen.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: laDangChay ? 2 : 0,
      color: laDangChay
          ? colors.surfaceContainerLow
          : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: laDangChay
              ? colors.primary.withValues(alpha: 0.6)
              : colors.outlineVariant.withValues(alpha: 0.5),
          width: laDangChay ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onChonChuyen(chuyen),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng 1: Tuyến & Biển số xe
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      chuyen.tenTuyen,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          size: 14,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chuyen.bienSo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hàng 2: Chiều đi & Trạng thái
              Row(
                children: [
                  Icon(
                    chuyen.chieu == ChieuChuyen.donSang
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chuyen.chieu.ten,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hàng 3: Nút hành động chính
              SizedBox(
                width: double.infinity,
                child: laDangChay
                    ? FilledButton.icon(
                        key: Key('btn-chuyen-action-${chuyen.id}'),
                        onPressed: () => widget.onChonChuyen(chuyen),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.checklist_rounded),
                        label: const Text('Tiếp tục ca xe & Điểm danh'),
                      )
                    : (laHoanThanh
                        ? OutlinedButton.icon(
                            key: Key('btn-chuyen-action-${chuyen.id}'),
                            onPressed: () => widget.onChonChuyen(chuyen),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.history_rounded),
                            label: const Text('Xem lịch sử điểm danh'),
                          )
                        : FilledButton.tonalIcon(
                            key: Key('btn-chuyen-action-${chuyen.id}'),
                            onPressed: () => widget.onChonChuyen(chuyen),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Mở ca xe & Điểm danh'),
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_dangTai) {
      return const TrangThaiDangTai(
        thongDiep: 'Đang tải danh sách ca xe hôm nay...',
      );
    }

    if (_loi != null) {
      return TrangThaiLoi(
        retryKey: const Key('chuyen-retry'),
        thongDiep: _loi!,
        onThuLai: _taiDuLieu,
      );
    }

    if (_dsChuyen.isEmpty) {
      return RefreshIndicator(
        onRefresh: _taiDuLieu,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeaderCard(theme),
            const SizedBox(height: 40),
            TrangThaiRong(
              refreshKey: const Key('chuyen-refresh-empty'),
              icon: Icons.directions_bus_outlined,
              thongDiep: 'Hôm nay bạn chưa có ca xe nào được phân công.',
              onLamMoi: _taiDuLieu,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _taiDuLieu,
      child: ListView.builder(
        key: const PageStorageKey<String>('ds-chuyen-hom-nay-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _dsChuyen.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeaderCard(theme);
          }
          final chuyen = _dsChuyen[index - 1];
          return _buildChuyenCard(chuyen, theme);
        },
      ),
    );
  }
}
