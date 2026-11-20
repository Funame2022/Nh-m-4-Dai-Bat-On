import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth/auth_service.dart';
import 'auth/token_storage.dart';
import 'fleet/quan_ly_service.dart';
import 'models/nguoi_dung.dart';
import 'operations/quan_ly_operations_service.dart';
import 'operations/van_hanh_service.dart';
import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/van_hanh_shell.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({
    super.key,
    required this.authService,
    required this.quanLyService,
    required this.operationsService,
    this.vanHanhService,
  });

  final AuthService authService;
  final QuanLyService quanLyService;
  final QuanLyOperationsService operationsService;
  final VanHanhService? vanHanhService;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _taiTheme();
  }

  Future<void> _taiTheme() async {
    try {
      final saved = await widget.authService.readThemeMode();
      if (!mounted) return;
      if (saved == 'dark' || saved == 'light') {
        setState(
          () => _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light,
        );
      }
    } catch (_) {
      // Use the light theme when saved preferences are unavailable.
    }
  }

  Future<void> _doiTheme() async {
    final next = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setState(() => _themeMode = next);
    try {
      await widget.authService.saveThemeMode(
        next == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // Keep the current session usable if preference storage is unavailable.
    }
  }

  ThemeData _theme(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6976A8),
          brightness: brightness,
        ).copyWith(
          surface: brightness == Brightness.light
              ? const Color(0xFFFAF9FD)
              : const Color(0xFF171923),
          surfaceContainerLowest: brightness == Brightness.light
              ? const Color(0xFFFFFEFF)
              : const Color(0xFF11131B),
          surfaceContainerLow: brightness == Brightness.light
              ? const Color(0xFFF5F3FA)
              : const Color(0xFF20222D),
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
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusCare For Admin',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _themeMode,
      home: AuthGate(
        authService: widget.authService,
        quanLyService: widget.quanLyService,
        operationsService: widget.operationsService,
        vanHanhService: widget.vanHanhService,
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _doiTheme,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.quanLyService,
    required this.operationsService,
    this.vanHanhService,
    required this.isDark,
    required this.onToggleTheme,
  });

  final AuthService authService;
  final QuanLyService quanLyService;
  final QuanLyOperationsService operationsService;
  final VanHanhService? vanHanhService;
  final bool isDark;
  final Future<void> Function() onToggleTheme;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _dangKhoiPhuc = true;
  NguoiDung? _nguoiDung;
  AuthException? _loi;
  StreamSubscription<void>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _sessionSub = widget.authService.onSessionExpired.listen((_) {
      if (!mounted) return;
      setState(() => _nguoiDung = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('session-expired-snack'),
          content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
    _khoiPhuc();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  Future<void> _khoiPhuc() async {
    setState(() {
      _dangKhoiPhuc = true;
      _loi = null;
    });

    try {
      final nguoiDung = await widget.authService.restoreSession();
      if (!mounted) return;
      setState(() {
        _nguoiDung = nguoiDung;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _nguoiDung = null;
        _loi = e;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nguoiDung = null;
        _loi = const AuthException(
          'Không thể kiểm tra phiên đăng nhập. Vui lòng thử lại.',
          retryable: true,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _dangKhoiPhuc = false);
      }
    }
  }

  Future<void> _dangXuat() async {
    await widget.authService.logout();
    if (!mounted) return;
    setState(() => _nguoiDung = null);
  }

  Future<void> _doiTaiKhoan() async {
    await widget.authService.logout();
    try {
      await widget.authService.clearRememberedEmail();
    } catch (_) {
      // Continue to login even if the remembered account cannot be cleared.
    }
    if (!mounted) return;
    setState(() => _nguoiDung = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_dangKhoiPhuc) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang kiểm tra phiên đăng nhập...'),
            ],
          ),
        ),
      );
    }

    if (_loi != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loi!.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('restore-retry'),
                  onPressed: _khoiPhuc,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_nguoiDung != null) {
      if (_nguoiDung!.laQuanLy) {
        return AdminShell(
          key: const Key('admin-shell'),
          nguoiDung: _nguoiDung!,
          authService: widget.authService,
          onLogout: _dangXuat,
          onSwitchAccount: _doiTaiKhoan,
          onUserUpdated: (user) => setState(() => _nguoiDung = user),
          quanLyService: widget.quanLyService,
          operationsService: widget.operationsService,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      } else if (_nguoiDung!.laNhanVienVanHanh) {
        final effectiveVanHanh = widget.vanHanhService ??
            VanHanhService(
              client: http.Client(),
              storage: const SecureTokenStorage(),
              baseUrl: widget.authService.baseUrl,
              onTokenExpired: () async => widget.authService.notifySessionExpired(),
            );

        return VanHanhShell(
          key: const Key('van-hanh-shell'),
          nguoiDung: _nguoiDung!,
          authService: widget.authService,
          vanHanhService: effectiveVanHanh,
          onLogout: _dangXuat,
          onSwitchAccount: _doiTaiKhoan,
          onUserUpdated: (user) => setState(() => _nguoiDung = user),
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      }
    }

    return LoginScreen(
      authService: widget.authService,
      onLoginSuccess: (nguoiDung) {
        setState(() => _nguoiDung = nguoiDung);
      },
    );
  }
}
