import 'package:flutter/material.dart';

import '../../../models/van_hanh.dart';

/// Callback khi bấm điểm danh học sinh
typedef OnDiemDanhHocSinh = void Function(HocSinhDiemDanh hocSinh);

/// Widget hiển thị thẻ từng học sinh trong danh sách điểm danh
class HocSinhItemWidget extends StatelessWidget {
  const HocSinhItemWidget({
    super.key,
    required this.hocSinh,
    this.tenDiemDung,
    this.onDiemDanhLenXe,
    this.onDiemDanhXuongXe,
    this.onTap,
    this.dangXuLy = false,
  });

  final HocSinhDiemDanh hocSinh;
  final String? tenDiemDung;
  final VoidCallback? onDiemDanhLenXe;
  final VoidCallback? onDiemDanhXuongXe;
  final VoidCallback? onTap;
  final bool dangXuLy;

  /// Lấy chữ cái đầu làm avatar nếu không có ảnh
  String _layChuCaiDau(String hoTen) {
    final parts = hoTen.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'HS';
    return parts.last.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final trangThai = hocSinh.trangThai;

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;

    switch (trangThai) {
      case TrangThaiHocSinh.baoNghi:
        badgeColor = Colors.orange.shade800;
        badgeBg = Colors.orange.shade50;
        badgeIcon = Icons.event_busy_rounded;
        break;
      case TrangThaiHocSinh.dangTrenXe:
        badgeColor = Colors.blue.shade800;
        badgeBg = Colors.blue.shade50;
        badgeIcon = Icons.airline_seat_recline_normal_rounded;
        break;
      case TrangThaiHocSinh.daXuong:
        badgeColor = Colors.green.shade800;
        badgeBg = Colors.green.shade50;
        badgeIcon = Icons.check_circle_rounded;
        break;
      case TrangThaiHocSinh.chuaLen:
        badgeColor = Colors.grey.shade700;
        badgeBg = colors.surfaceContainerHighest.withValues(alpha: 0.5);
        badgeIcon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return Card(
      key: Key('hoc-sinh-card-${hocSinh.id}'),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hocSinh.coDonBaoNghi
              ? Colors.orange.shade200
              : colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng thông tin chính: Avatar, Họ tên, Lớp, Mã HS, Badge trạng thái
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar học sinh
                  _buildAvatar(colors),
                  const SizedBox(width: 12),

                  // Cột thông tin học sinh
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hocSinh.hoTen,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: hocSinh.coDonBaoNghi
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: hocSinh.coDonBaoNghi
                                      ? colors.onSurfaceVariant
                                      : colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Chip thông tin lớp & mã HS
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Lớp ${hocSinh.tenLop}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hocSinh.maHs,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Tên trạm đón/trả
                        if (tenDiemDung != null && tenDiemDung!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                size: 13,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tenDiemDung!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Badge trạng thái góc trên bên phải
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          trangThai.moTa,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Nếu có đơn báo nghỉ: hiển thị khung lý do nghỉ
              if (hocSinh.coDonBaoNghi) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Lý do nghỉ: ${hocSinh.lyDoNghi}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Thanh thao tác Điểm danh (nếu học sinh không nghỉ)
              if (!hocSinh.coDonBaoNghi) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(context),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colors) {
    if (hocSinh.anhUrl != null && hocSinh.anhUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(hocSinh.anhUrl!),
        onBackgroundImageError: (_, __) {},
        child: Text(
          _layChuCaiDau(hocSinh.hoTen),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      child: Text(
        _layChuCaiDau(hocSinh.hoTen),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (dangXuLy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Trường hợp 1: Học sinh chưa lên xe -> Nút LÊN XE
    if (!hocSinh.daLenXe) {
      return FilledButton.icon(
        key: Key('btn-len-xe-${hocSinh.id}'),
        onPressed: onDiemDanhLenXe,
        icon: const Icon(Icons.login_rounded, size: 16),
        label: const Text(
          'LÊN XE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // Trường hợp 2: Đang trên xe và chưa xuống xe -> Nút XUỐNG XE
    if (hocSinh.daLenXe && !hocSinh.daXuongXe) {
      return FilledButton.icon(
        key: Key('btn-xuong-xe-${hocSinh.id}'),
        onPressed: onDiemDanhXuongXe,
        icon: const Icon(Icons.logout_rounded, size: 16),
        label: const Text(
          'XUỐNG XE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // Trường hợp 3: Đã xuống xe an toàn -> Nhãn Hoàn tất
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_rounded, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'Hoàn tất',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
