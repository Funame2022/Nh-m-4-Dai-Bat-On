import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../models/nguoi_dung.dart';
import '../operations/van_hanh_service.dart';
import 'settings_screen.dart';

class VanHanhShell extends StatefulWidget {
  const VanHanhShell({
    super.key,
    required this.nguoiDung,
    required this.authService,
    required this.vanHanhService,
    required this.onLogout,
    required this.onSwitchAccount,
    required this.onUserUpdated,
    required this.isDark,
    required this.onToggleTheme,
  });

  final NguoiDung nguoiDung;
  final AuthService authService;
  final VanHanhService vanHanhService;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSwitchAccount;
  final ValueChanged<NguoiDung> onUserUpdated;
  final bool isDark;
  final Future<void> Function() onToggleTheme;

  @override
  State<VanHanhShell> createState() => _VanHanhShellState();
}

class _VanHanhShellState extends State<VanHanhShell> {
  int _currentIndex = 0;

  Widget _buildBody() {
    if (_currentIndex == 1) {
      return SettingsScreen(
        nguoiDung: widget.nguoiDung,
        authService: widget.authService,
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        onRename: widget.authService.doiTen,
        onUserUpdated: widget.onUserUpdated,
        onSwitchAccount: widget.onSwitchAccount,
        onLogout: widget.onLogout,
      );
    }

    return _ChuyenHomNayOverview(
      nguoiDung: widget.nguoiDung,
      vanHanhService: widget.vanHanhService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final laTaiXe = widget.nguoiDung.laTaiXe;

    return Scaffold(
      key: const Key('van-hanh-shell'),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: laTaiXe ? Colors.orange.shade700 : Colors.teal.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.nguoiDung.tenVaiTro.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.nguoiDung.hoTen,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Giao diện sáng' : 'Giao diện tối',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus_rounded),
            label: 'Chuyến hôm nay',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

class _ChuyenHomNayOverview extends StatelessWidget {
  const _ChuyenHomNayOverview({
    required this.nguoiDung,
    required this.vanHanhService,
  });

  final NguoiDung nguoiDung;
  final VanHanhService vanHanhService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_filled_rounded,
              size: 64,
              color: colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Hệ thống Vận hành Xe trường',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Xin chào ${nguoiDung.hoTen} (${nguoiDung.tenVaiTro})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
