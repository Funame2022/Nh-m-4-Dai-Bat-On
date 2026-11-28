import 'package:flutter/material.dart';
import 'api_service.dart';
import 'children_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Khung chính với Scaffold + NavigationBar (tiêu chí C.2.5)
class HomeScreen extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onToggleTheme;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _handleSessionExpired() async {
    await ApiService.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onLogout();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final data = await ApiService.getThongBao(limit: 1);
      if (!mounted) return;
      setState(() {
        _unreadCount = data['unreadCount'] as int? ?? 0;
      });
    } on SessionExpiredException {
      await _handleSessionExpired();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChildrenScreen(onSessionExpired: _handleSessionExpired),
      NotificationsScreen(
        onSessionExpired: _handleSessionExpired,
        onUnreadChanged: (count) {
          if (mounted) setState(() => _unreadCount = count);
        },
      ),
      ProfileScreen(
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        onLogout: widget.onLogout,
        onSessionExpired: _handleSessionExpired,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) _loadUnreadCount();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.child_care_outlined),
            selectedIcon: Icon(Icons.child_care),
            label: 'Con em',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Thông báo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
