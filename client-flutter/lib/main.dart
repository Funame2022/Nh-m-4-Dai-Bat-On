import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const BusCareParentApp());
}

class BusCareParentApp extends StatefulWidget {
  const BusCareParentApp({super.key});

  @override
  State<BusCareParentApp> createState() => _BusCareParentAppState();
}

class _BusCareParentAppState extends State<BusCareParentApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _checkingSession = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final savedTheme = await ApiService.readThemeMode();
    final hasToken = await ApiService.hasToken();
    bool sessionValid = false;
    if (hasToken) {
      try {
        final profile = await ApiService.fetchProfile();
        sessionValid = profile != null;
      } catch (_) {
        await ApiService.logout();
        sessionValid = false;
      }
    }
    if (!mounted) return;
    setState(() {
      if (savedTheme == 'dark') _themeMode = ThemeMode.dark;
      _loggedIn = sessionValid;
      _checkingSession = false;
    });
  }

  Future<void> _toggleTheme() async {
    final next =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = next);
    await ApiService.saveThemeMode(next == ThemeMode.dark ? 'dark' : 'light');
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6976A8),
      brightness: brightness,
    ).copyWith(
      surface: isLight ? const Color(0xFFFAF9FD) : const Color(0xFF171923),
      surfaceContainerLowest:
          isLight ? const Color(0xFFFFFEFF) : const Color(0xFF11131B),
      surfaceContainerLow:
          isLight ? const Color(0xFFF5F3FA) : const Color(0xFF20222D),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusCare Phụ Huynh — Nhóm 01',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: _checkingSession
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang khôi phục phiên đăng nhập...'),
                  ],
                ),
              ),
            )
          : _loggedIn
              ? HomeScreen(
                  isDark: _themeMode == ThemeMode.dark,
                  onToggleTheme: _toggleTheme,
                  onLogout: () => setState(() => _loggedIn = false),
                )
              : LoginScreen(
                  onLoginSuccess: () => setState(() => _loggedIn = true),
                ),
    );
  }
}
