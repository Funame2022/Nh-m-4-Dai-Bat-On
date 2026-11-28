import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusCare Phụ Huynh — Nhóm 01',
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _checkingSession
            ? Scaffold(
                key: const ValueKey('splash'),
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.emeraldGradient,
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_bus_rounded,
                            size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 14),
                        Text(
                          'Đang kết nối BusCare...',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : _loggedIn
                ? HomeScreen(
                    key: const ValueKey('home'),
                    isDark: _themeMode == ThemeMode.dark,
                    onToggleTheme: _toggleTheme,
                    onLogout: () => setState(() => _loggedIn = false),
                  )
                : LoginScreen(
                    key: const ValueKey('login'),
                    onLoginSuccess: () => setState(() => _loggedIn = true),
                  ),
      ),
    );
  }
}
