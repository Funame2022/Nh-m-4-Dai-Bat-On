import 'package:flutter/material.dart';

import '../../../models/van_hanh.dart';

/// Callback khi người dùng bấm vào một điểm dừng để thực hiện điểm danh
typedef OnChonDiemDung = void Function(DiemDung diemDung);

/// Widget hiển thị danh sách các điểm dừng dạng Timeline Stepper dọc tuyến
class DiemDungTimelineWidget extends StatefulWidget {
  const DiemDungTimelineWidget({
    super.key,
    required this.chiTiet,
    this.onDiemDanhTaiTram,
  });

  final ChiTietChuyenDi chiTiet;
  final OnChonDiemDung? onDiemDanhTaiTram;

  @override
  State<DiemDungTimelineWidget> createState() => _DiemDungTimelineWidgetState();
}

class _DiemDungTimelineWidgetState extends State<DiemDungTimelineWidget>
    with AutomaticKeepAliveClientMixin {
  final Set<int> _diemMoRong = {};

  @override
  bool get wantKeepAlive => true;

  void _toggleMoRong(int diemId) {
    setState(() {
      if (_diemMoRong.contains(diemId)) {
        _diemMoRong.remove(diemId);
      } else {
        _diemMoRong.add(diemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dsDiemDung = widget.chiTiet.diemDung;
    final chuyen = widget.chiTiet.chuyenDi;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (dsDiemDung.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.alt_route_rounded,
                size: 48,
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Tuyến này chưa thiết lập điểm dừng đón/trả.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const PageStorageKey<String>('diem-dung-timeline-list'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: dsDiemDung.length,
      itemBuilder: (context, index) {
        final d = dsDiemDung[index];
        final laDiemDau = index == 0;
        final laDiemCuoi = index == dsDiemDung.length - 1;
        final hsTaiDiem = widget.chiTiet.dsHocSinhTheoDiem(d.id);
        final moRong = _diemMoRong.contains(d.id);

        final soHsNghi = hsTaiDiem.where((h) => h.coDonBaoNghi).length;
        final soHsDaLen = hsTaiDiem.where((h) => h.daLenXe).length;
        final soHsDaXuong = hsTaiDiem.where((h) => h.daXuongXe).length;

        // Đánh giá hoàn tất trạm
        final laDonSang = chuyen.chieu == ChieuChuyen.donSang;
        final daHoanTatTram = hsTaiDiem.isNotEmpty &&
            hsTaiDiem.every((h) => h.coDonBaoNghi || (laDonSang ? h.daLenXe : h.daXuongXe));

        Color nodeColor;
        Widget nodeIcon;

        if (daHoanTatTram) {
          nodeColor = Colors.green.shade700;
          nodeIcon = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
        } else if (laDiemCuoi) {
          nodeColor = Colors.purple.shade700;
          nodeIcon = const Icon(Icons.school_rounded, size: 14, color: Colors.white);
        } else if (laDiemDau) {
          nodeColor = colors.primary;
          nodeIcon = const Icon(Icons.trip_origin_rounded, size: 14, color: Colors.white);
        } else {
          nodeColor = colors.primary;
          nodeIcon = Text(
            '${d.thuTu}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cột Timeline bên trái
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    // Đoạn đường nối phía trên
                    Container(
                      width: 2.5,
                      height: 14,
                      color: laDiemDau
                          ? Colors.transparent
                          : colors.outlineVariant.withValues(alpha: 0.8),
                    ),
                    // Nút điểm dừng (Node)
                    Container(
                      key: Key('timeline-node-${d.id}'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: nodeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: nodeIcon,
                    ),
                    // Đoạn đường nối phía dưới
                    Expanded(
                      child: Container(
                        width: 2.5,
                        color: laDiemCuoi
                            ? Colors.transparent
                            : colors.outlineVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Thẻ nội dung trạm dừng bên phải
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    key: Key('timeline-card-${d.id}'),
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: daHoanTatTram
                        ? colors.surfaceContainerLowest
                        : colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: daHoanTatTram
                            ? Colors.green.shade300.withValues(alpha: 0.7)
                            : colors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _toggleMoRong(d.id),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hàng 1: Tên điểm dừng & Nhãn thứ tự/loại trạm
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    d.ten,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: daHoanTatTram
                                          ? TextDecoration.none
                                          : null,
                                    ),
                                  ),
                                ),
                                if (laDiemDau)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Điểm đầu',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: colors.onPrimaryContainer,
                                      ),
                                    ),
                                  )
                                else if (laDiemCuoi)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Trường học',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Hàng 2: Giờ dự kiến & Tọa độ trạm
                            Row(
                              children: [
                                if (d.gioDuKien != null && d.gioDuKien!.isNotEmpty) ...[
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    d.gioDuKien!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${d.viDo.toStringAsFixed(4)}, ${d.kinhDo.toStringAsFixed(4)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Hàng 3: Thống kê học sinh tại trạm & Nút thao tác
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildMiniChip(
                                        label: '${hsTaiDiem.length} HS',
                                        color: colors.surfaceContainerHighest,
                                        textColor: colors.onSurfaceVariant,
                                      ),
                                      if (soHsDaLen > 0)
                                        _buildMiniChip(
                                          label: '$soHsDaLen đã lên',
                                          color: Colors.blue.shade50,
                                          textColor: Colors.blue.shade800,
                                        ),
                                      if (soHsDaXuong > 0)
                                        _buildMiniChip(
                                          label: '$soHsDaXuong đã xuống',
                                          color: Colors.green.shade50,
                                          textColor: Colors.green.shade800,
                                        ),
                                      if (soHsNghi > 0)
                                        _buildMiniChip(
                                          label: '$soHsNghi báo nghỉ',
                                          color: Colors.orange.shade50,
                                          textColor: Colors.orange.shade900,
                                        ),
                                    ],
                                  ),
                                ),
                                if (widget.onDiemDanhTaiTram != null && hsTaiDiem.isNotEmpty)
                                  FilledButton.tonal(
                                    key: Key('btn-diem-danh-tram-${d.id}'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => widget.onDiemDanhTaiTram!(d),
                                    child: const Text('Điểm danh', style: TextStyle(fontSize: 12)),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  moRong
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: colors.onSurfaceVariant,
                                ),
                              ],
                            ),

                            // Danh sách học sinh khi bấm mở rộng
                            if (moRong && hsTaiDiem.isNotEmpty) ...[
                              const Divider(height: 18),
                              ...hsTaiDiem.map((hs) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hs.coDonBaoNghi
                                              ? Icons.event_busy_rounded
                                              : (hs.daXuongXe
                                                  ? Icons.check_circle_rounded
                                                  : (hs.daLenXe
                                                      ? Icons.airline_seat_recline_normal_rounded
                                                      : Icons.radio_button_unchecked_rounded)),
                                          size: 15,
                                          color: hs.coDonBaoNghi
                                              ? Colors.orange.shade700
                                              : (hs.daXuongXe
                                                  ? Colors.green.shade700
                                                  : (hs.daLenXe
                                                      ? Colors.blue.shade700
                                                      : Colors.grey)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${hs.hoTen} (${hs.tenLop})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              decoration: hs.coDonBaoNghi
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          hs.trangThai.moTa,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: hs.coDonBaoNghi
                                                ? Colors.orange.shade800
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniChip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
