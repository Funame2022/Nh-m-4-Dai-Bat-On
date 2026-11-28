import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Nền thành phố TP.HCM + Xe buýt xanh-đen chạy ngang (giống ảnh mẫu VinBus)
class CityBusBackdrop extends StatefulWidget {
  final double height;
  final bool animateBus;

  const CityBusBackdrop({
    super.key,
    this.height = 240,
    this.animateBus = true,
  });

  @override
  State<CityBusBackdrop> createState() => _CityBusBackdropState();
}

class _CityBusBackdropState extends State<CityBusBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    if (widget.animateBus) {
      _ctrl.repeat();
    } else {
      _ctrl.value = 0.5;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _VinBusCityPainter(
              progress: widget.animateBus ? _ctrl.value : 0.45,
            ),
          );
        },
      ),
    );
  }
}

class _VinBusCityPainter extends CustomPainter {
  final double progress;

  _VinBusCityPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Nền trời gradient pha trộn Xanh dương -> Xanh ngọc -> Xanh lá
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      bgRect,
      Paint()..shader = AppTheme.vinBusGradient.createShader(bgRect),
    );

    // 2. Đường chân trời các tòa nhà TP.HCM (Bitexco, Landmark...)
    final buildingPaint = Paint()
      ..color = const Color(0xFF0A4D68).withValues(alpha: 0.25);

    final roadY = size.height - 34;
    final buildings = [
      Rect.fromLTWH(size.width * 0.02, roadY - 82, 34, 82),
      Rect.fromLTWH(size.width * 0.11, roadY - 115, 28, 115),
      Rect.fromLTWH(size.width * 0.19, roadY - 68, 42, 68),
      Rect.fromLTWH(size.width * 0.31, roadY - 96, 30, 96),
      Rect.fromLTWH(size.width * 0.44, roadY - 78, 46, 78),
      Rect.fromLTWH(size.width * 0.58, roadY - 102, 32, 102),
      // Tòa nhà cao kiểu Landmark
      Rect.fromLTWH(size.width * 0.71, roadY - 138, 28, 138),
      Rect.fromLTWH(size.width * 0.81, roadY - 88, 38, 88),
      Rect.fromLTWH(size.width * 0.91, roadY - 65, 36, 65),
    ];
    for (final b in buildings) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(4)),
        buildingPaint,
      );
    }

    // 3. Mặt đường nhựa & vạch kẻ đường
    canvas.drawRect(
      Rect.fromLTWH(0, roadY, size.width, 34),
      Paint()..color = const Color(0xFF1F3541).withValues(alpha: 0.55),
    );
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 2;
    for (double x = 8; x < size.width; x += 26) {
      canvas.drawLine(
        Offset(x, roadY + 17),
        Offset(x + 14, roadY + 17),
        dashPaint,
      );
    }

    // 4. Xe buýt xanh-đen kiểu VinBus
    final busW = 132.0;
    final busH = 48.0;
    // Cho xe chạy qua lại mượt mà quanh giữa màn hình
    final busX = -busW + (size.width + busW * 2) * progress;
    final busTop = roadY - busH + 6;

    // Thân xe xanh lá chuối tươi
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(busX, busTop, busW, busH),
      const Radius.circular(11),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF7CE843));

    // Phần kính & thân đen ở giữa (đặc trưng giống ảnh mẫu)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busX + 14, busTop + 8, busW - 22, 26),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF17272B),
    );

    // Các ô kính sáng nhẹ
    final glassPaint = Paint()..color = const Color(0xFF3E636B);
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(busX + 18 + i * 24, busTop + 11, 19, 17),
          const Radius.circular(3),
        ),
        glassPaint,
      );
    }

    // Đèn trước
    canvas.drawCircle(
      Offset(busX + busW - 5, busTop + busH - 11),
      3.5,
      Paint()..color = const Color(0xFFFFF59D),
    );

    // Bánh xe
    final tirePaint = Paint()..color = const Color(0xFF111827);
    final rimPaint = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawCircle(Offset(busX + 28, busTop + busH), 9.5, tirePaint);
    canvas.drawCircle(Offset(busX + 28, busTop + busH), 4.5, rimPaint);
    canvas.drawCircle(Offset(busX + busW - 26, busTop + busH), 9.5, tirePaint);
    canvas.drawCircle(Offset(busX + busW - 26, busTop + busH), 4.5, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _VinBusCityPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
