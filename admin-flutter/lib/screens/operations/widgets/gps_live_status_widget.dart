import 'package:flutter/material.dart';

import '../../../operations/gps_tracker_service.dart';

/// Widget hiển thị trạng thái và thông tin phát tọa độ GPS thời gian thực của xe
class GpsLiveStatusWidget extends StatefulWidget {
  const GpsLiveStatusWidget({
    super.key,
    required this.gpsTracker,
    this.onGuiNgay,
  });

  final GpsTrackerService gpsTracker;
  final VoidCallback? onGuiNgay;

  @override
  State<GpsLiveStatusWidget> createState() => _GpsLiveStatusWidgetState();
}

class _GpsLiveStatusWidgetState extends State<GpsLiveStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _dinhDangGio(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tracker = widget.gpsTracker;

    return StreamBuilder<ViTriGps>(
      stream: tracker.viTriStream,
      initialData: tracker.viTriHienTai,
      builder: (context, snapshot) {
        final viTri = snapshot.data;
        final dangPhat = tracker.dangTracking;

        final Color primaryColor = dangPhat ? Colors.green.shade700 : Colors.orange.shade700;
        final Color bgColor = dangPhat ? Colors.green.shade50 : Colors.orange.shade50;
        final Color borderColor = dangPhat ? Colors.green.shade200 : Colors.orange.shade200;

        return Card(
          key: const Key('card-gps-live-status'),
          elevation: 0,
          margin: const EdgeInsets.only(top: 12),
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Huy hiệu GPS LIVE & Nút Bật/Tắt phát
                Row(
                  children: [
                    FadeTransition(
                      opacity: dangPhat ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GPS LIVE TRACKING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    // Nút chuyển trạng thái Bật / Tạm dừng
                    TextButton.icon(
                      key: const Key('btn-toggle-gps-tracking'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          if (tracker.dangTracking) {
                            tracker.tamDung();
                          } else {
                            tracker.tiepTuc();
                          }
                        });
                      },
                      icon: Icon(
                        dangPhat ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                      label: Text(
                        dangPhat ? 'Tạm dừng' : 'Tiếp tục phát',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hàng 2: Tọa độ thời gian thực & Tốc độ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.satellite_alt_rounded,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viTri != null ? viTri.toaDoChuoi : 'Đang lấy tọa độ GPS...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Tốc độ: ${viTri?.tocDo.toStringAsFixed(0) ?? 0} km/h',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              if (viTri != null) ...[
                                Text(
                                  ' • Cập nhật: ${_dinhDangGio(viTri.thoiDiem)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Hàng 3: Nút gửi tọa độ thủ công ngay lập tức
                if (widget.onGuiNgay != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      key: const Key('btn-gui-vi-tri-ngay'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        minimumSize: const Size(0, 30),
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: widget.onGuiNgay,
                      icon: Icon(Icons.send_rounded, size: 14, color: primaryColor),
                      label: Text(
                        'Gửi vị trí ngay',
                        style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
