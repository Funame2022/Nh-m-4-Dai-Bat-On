import 'package:flutter/material.dart';

class AppTheme {
  static const Color emeraldDark = Color(0xFF0A7B45);
  static const Color emerald = Color(0xFF10A35A);
  static const Color emeraldLight = Color(0xFF22C574);
  static const Color warmOrange = Color(0xFFFF7A30);
  static const Color warmOrangeLight = Color(0xFFFF9B42);
  static const Color mintBg = Color(0xFFF3F8F5);
  static const Color darkBg = Color(0xFF0E1712);

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [emeraldDark, emerald, emeraldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [warmOrange, warmOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: emerald,
      brightness: brightness,
      primary: emerald,
      secondary: warmOrange,
    ).copyWith(
      surface: isLight ? mintBg : darkBg,
      surfaceContainerLowest:
          isLight ? Colors.white : const Color(0xFF132019),
      surfaceContainerLow:
          isLight ? Colors.white : const Color(0xFF18281F),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? emerald : const Color(0xFF12231A),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isLight
                ? emerald.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xFF1B2D23),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight
                ? emerald.withValues(alpha: 0.25)
                : scheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: emerald, width: 1.6),
        ),
      ),
    );
  }
}

/// Chuyển cảnh mượt mà (Slide + Fade) giữa các màn hình
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
