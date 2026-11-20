import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../models/nguoi_dung.dart';
import '../models/van_hanh.dart';
import '../operations/van_hanh_service.dart';
import 'operations/chi_tiet_chuyen_page.dart';
import 'operations/chuyen_hom_nay_page.dart';
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

  static const List<String> _titles = [
    'Ca xe hôm nay',
    'Cài đặt & Hồ sơ',
  ];

  Future<void> _xacNhanDangXuat() async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('dialog-logout-confirm'),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn kết thúc ca làm việc và đăng xuất không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (xacNhan == true) {
      await widget.onLogout();
    }
  }

  void _moChiTietChuyen(ChuyenDi chuyen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChiTietChuyenPage(
          chuyenId: chuyen.id,
          initialChuyen: chuyen,
          vanHanhService: widget.vanHanhService,
          nguoiDung: widget.nguoiDung,
        ),
      ),
    );
  }

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

    return ChuyenHomNayPage(
      key: const Key('chuyen-hom-nay-page'),
      nguoiDung: widget.nguoiDung,
      vanHanhService: widget.vanHanhService,
      onChonChuyen: _moChiTietChuyen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final laTaiXe = widget.nguoiDung.laTaiXe;
    final roleColor = laTaiXe ? Colors.orange.shade700 : Colors.teal.shade700;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return Scaffold(
          key: const Key('van-hanh-shell'),
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 2,
            title: Row(
              children: [
                Container(
                  key: const Key('badge-role'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.nguoiDung.hoTen,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _titles[_currentIndex],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('btn-toggle-theme'),
                tooltip: widget.isDark ? 'Giao diện sáng' : 'Giao diện tối',
                onPressed: widget.onToggleTheme,
                icon: Icon(
                  widget.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
              PopupMenuButton<String>(
                key: const Key('menu-account-actions'),
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'switch') {
                    widget.onSwitchAccount();
                  } else if (val == 'logout') {
                    _xacNhanDangXuat();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'switch',
                    child: Row(
                      children: [
                        Icon(Icons.switch_account_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Đổi tài khoản'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                key: const Key('btn-logout'),
                tooltip: 'Đăng xuất',
                onPressed: _xacNhanDangXuat,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  key: const Key('van-hanh-nav-rail'),
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) =>
                      setState(() => _currentIndex = idx),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      child: Icon(
                        laTaiXe
                            ? Icons.directions_bus_rounded
                            : Icons.support_agent_rounded,
                        color: roleColor,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.directions_bus_outlined),
                      selectedIcon: Icon(Icons.directions_bus_rounded),
                      label: Text('Ca hôm nay'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_circle_outlined),
                      selectedIcon: Icon(Icons.account_circle_rounded),
                      label: Text('Hồ sơ'),
                    ),
                  ],
                ),
              if (isWide) const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _buildBody()),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  key: const Key('van-hanh-bottom-nav'),
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.directions_bus_outlined),
                      selectedIcon: Icon(Icons.directions_bus_rounded),
                      label: 'Ca hôm nay',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_circle_outlined),
                      selectedIcon: Icon(Icons.account_circle_rounded),
                      label: 'Hồ sơ',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
