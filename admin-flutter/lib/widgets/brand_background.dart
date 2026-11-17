import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class BrandAssets {
  static const background = 'assets/images/school_route_background.jpg';
  static const logo = 'assets/images/buscare_app_logo.jpg';
}

class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = math.min(
          constraints.maxWidth * 746 / 1002,
          constraints.maxHeight * 0.52,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.surface),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    BrandAssets.background,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.medium,
                  ),
                  if (isDark)
                    ColoredBox(color: colors.surface.withValues(alpha: 0.76)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.surface,
                          colors.surface.withValues(alpha: 0.84),
                          colors.surface.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.34, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
