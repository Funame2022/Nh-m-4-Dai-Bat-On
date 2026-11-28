import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hiệu ứng Shimmer Skeleton lấp lánh khi đang tải dữ liệu
class ShimmerListPlaceholder extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerListPlaceholder({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 86,
  });

  @override
  State<ShimmerListPlaceholder> createState() => _ShimmerListPlaceholderState();
}

class _ShimmerListPlaceholderState extends State<ShimmerListPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1F3127) : const Color(0xFFE6EFEA);
    final highlight =
        isDark ? const Color(0xFF2B4436) : const Color(0xFFF6FBF8);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: widget.itemCount,
          itemBuilder: (ctx, idx) {
            return Container(
              height: widget.itemHeight,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment(-1.5 + _ctrl.value * 3, -0.3),
                  end: Alignment(-0.5 + _ctrl.value * 3, 0.3),
                  colors: [base, highlight, base],
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: isDark ? 0.06 : 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 11,
                          width: 210,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: isDark ? 0.05 : 0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      ),
    );
  }
}

/// Chấm LIVE nhấp nháy khi xe đang chạy trên bản đồ
class LivePulseBadge extends StatefulWidget {
  final String label;
  final Color color;

  const LivePulseBadge({
    super.key,
    this.label = 'LIVE',
    this.color = AppTheme.emerald,
  });

  @override
  State<LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.45 + 0.55 * _ctrl.value),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.45 * _ctrl.value),
                    blurRadius: 6 * _ctrl.value + 2,
                    spreadRadius: 1.5 * _ctrl.value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiệu ứng nhấn nảy nhẹ cho các thẻ tương tác
class TapBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TapBounce({super.key, required this.child, required this.onTap});

  @override
  State<TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<TapBounce> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Timeline hành trình dọc cho chuyến đi & điểm danh học sinh
class TripTimeline extends StatelessWidget {
  final String trangThaiChuyen;
  final String? gioLenXe;
  final String? gioXuongXe;

  const TripTimeline({
    super.key,
    required this.trangThaiChuyen,
    this.gioLenXe,
    this.gioXuongXe,
  });

  @override
  Widget build(BuildContext context) {
    final started =
        trangThaiChuyen == 'DANG_CHAY' || trangThaiChuyen == 'HOAN_THANH';
    final boarded = gioLenXe != null && gioLenXe!.isNotEmpty;
    final dropped = gioXuongXe != null && gioXuongXe!.isNotEmpty;
    final completed = trangThaiChuyen == 'HOAN_THANH';

    final steps = [
      _StepData('Xe khởi hành', started ? 'Đã xuất phát' : 'Đang chờ', started),
      _StepData(
        'Con lên xe',
        boarded ? 'Lúc $gioLenXe' : 'Chưa điểm danh',
        boarded,
      ),
      _StepData(
        'Con xuống xe',
        dropped ? 'Lúc $gioXuongXe' : 'Chưa điểm danh',
        dropped,
      ),
      _StepData(
        'Hoàn thành chuyến',
        completed ? 'Đã đến nơi an toàn' : 'Đang trong hành trình',
        completed,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        final isLast = i == steps.length - 1;
        final color = s.done ? AppTheme.emerald : Colors.grey.shade400;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.done
                        ? AppTheme.emerald
                        : Colors.grey.withValues(alpha: 0.18),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(
                    s.done ? Icons.check_rounded : Icons.circle,
                    size: s.done ? 14 : 6,
                    color: s.done ? Colors.white : Colors.grey,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 24,
                    color: s.done
                        ? AppTheme.emerald.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.25),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(
                        fontWeight: s.done ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        color: s.done ? null : Colors.grey,
                      ),
                    ),
                    Text(
                      s.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: s.done ? AppTheme.emerald : Colors.grey,
                        fontWeight:
                            s.done ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StepData {
  final String title;
  final String subtitle;
  final bool done;

  const _StepData(this.title, this.subtitle, this.done);
}
