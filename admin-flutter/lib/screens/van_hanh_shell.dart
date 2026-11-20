import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../models/nguoi_dung.dart';
import '../operations/van_hanh_service.dart';
import '../widgets/brand_background.dart';
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

    return _CaTrucOverviewPage(
      nguoiDung: widget.nguoiDung,
      vanHanhService: widget.vanHanhService,
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

/// Khung Banner ca trực và thông tin nhân viên
class _CaTrucOverviewPage extends StatelessWidget {
  const _CaTrucOverviewPage({
    required this.nguoiDung,
    required this.vanHanhService,
  });

  final NguoiDung nguoiDung;
  final VanHanhService vanHanhService;

  String _formatNgayHienTai() {
    final now = DateTime.now();
    const thu = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final tenThu = thu[now.weekday - 1];
    return '$tenThu, ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final laTaiXe = nguoiDung.laTaiXe;
    final roleColor = laTaiXe ? Colors.orange.shade700 : Colors.teal.shade700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Ca trực hôm nay
          Card(
            key: const Key('card-ca-truc-header'),
            elevation: 0,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          laTaiXe
                              ? Icons.directions_bus_rounded
                              : Icons.support_agent_rounded,
                          color: roleColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nguoiDung.hoTen,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${nguoiDung.tenVaiTro} • ${nguoiDung.sdt ?? 'SĐT: Chưa có'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.padLeft ? null : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 14,
                              color: Colors.green.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đang trực',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatNgayHienTai(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Vùng hiển thị trạng thái chuẩn bị vào Chuyến hôm nay
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.departure_board_rounded,
                  size: 48,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Danh sách Chuyến đi Trong ngày',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Theo dõi lộ trình, điểm đón/trả và thực hiện điểm danh học sinh',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
