import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'bao_nghi_screen.dart';
import 'children_screen.dart';
import 'note_bao_mau_screen.dart';
import 'notification_settings_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'student_pass_screen.dart';

/// Khung chính với BottomAppBar + FAB (+) trung tâm (giống ảnh mẫu 2, 3, 4)
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
  int _profileRefreshKey = 0;

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

  Future<void> _openQuickActions() async {
    List<dynamic> children = [];
    try {
      children = await ApiService.getChildren();
    } catch (_) {}
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final first = children.isNotEmpty
            ? children.first as Map<String, dynamic>
            : null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thao tác nhanh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.warmOrange.withValues(alpha: 0.16),
                  child: const Icon(Icons.event_busy_rounded,
                      color: AppTheme.warmOrange),
                ),
                title: const Text('Đăng ký báo nghỉ học'),
                subtitle: Text(first != null
                    ? 'Cho bé ${first['ho_ten']}'
                    : 'Báo nghỉ cho con'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (first == null) return;
                  final ok = await Navigator.push<bool>(
                    context,
                    SmoothPageRoute(
                      page: BaoNghiScreen(
                        hocSinhId: first['id'] as int,
                        hoTen: first['ho_ten']?.toString() ?? '',
                      ),
                    ),
                  );
                  if (ok == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gửi đơn báo nghỉ thành công!'),
                        backgroundColor: AppTheme.emerald,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.emerald.withValues(alpha: 0.16),
                  child: const Icon(Icons.chat_outlined,
                      color: AppTheme.emerald),
                ),
                title: const Text('Nhắn ghi chú tới bảo mẫu'),
                subtitle: const Text('Dặn dò cho chuyến xe hôm nay'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (first == null) return;
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      page: NoteBaoMauScreen(
                        hocSinhId: first['id'] as int,
                        hoTen: first['ho_ten']?.toString() ?? '',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.16),
                  child: const Icon(Icons.tune_rounded, color: Colors.blue),
                ),
                title: const Text('Cài đặt nhận thông báo'),
                subtitle: const Text('Bật/tắt cảnh báo lên xuống xe'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final saved = await Navigator.push<bool>(
                    context,
                    SmoothPageRoute(
                      page: NotificationSettingsScreen(
                        onSessionExpired: _handleSessionExpired,
                      ),
                    ),
                  );
                  if (saved == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu cài đặt thông báo'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChildrenScreen(
        key: ValueKey('dash_$_profileRefreshKey'),
        unreadCount: _unreadCount,
        onSessionExpired: _handleSessionExpired,
        onOpenQrTab: () => setState(() => _currentIndex = 1),
        onOpenNotifTab: () {
          setState(() => _currentIndex = 2);
          _loadUnreadCount();
        },
        onOpenProfileTab: () => setState(() => _currentIndex = 3),
      ),
      StudentPassScreen(onSessionExpired: _handleSessionExpired),
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
        onProfileChanged: () =>
            setState(() => _profileRefreshKey++),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickActions,
        backgroundColor: AppTheme.emerald,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 66,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Trang chủ',
              selected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _NavItem(
              icon: Icons.qr_code_2_rounded,
              activeIcon: Icons.qr_code_rounded,
              label: 'Thẻ QR',
              selected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(width: 44), // Space for center FAB
            _NavItem(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications_rounded,
              label: 'Thông báo',
              badgeCount: _unreadCount,
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                _loadUnreadCount();
              },
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Cá nhân',
              selected: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.emerald : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount'),
              child: Icon(selected ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
