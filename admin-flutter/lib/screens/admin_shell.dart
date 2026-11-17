import 'package:flutter/material.dart';

import '../fleet/quan_ly_service.dart';
import '../models/nguoi_dung.dart';
import '../operations/quan_ly_operations_service.dart';
import 'fleet/tai_xe_page.dart';
import 'fleet/xe_page.dart';
import 'monitoring/giam_sat_page.dart';
import 'reports/bao_cao_page.dart';
import 'routes/tuyen_page.dart';
import '../widgets/brand_background.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.nguoiDung,
    required this.onLogout,
    required this.quanLyService,
    required this.operationsService,
    required this.isDark,
    required this.onToggleTheme,
  });

  final NguoiDung nguoiDung;
  final Future<void> Function() onLogout;
  final QuanLyService quanLyService;
  final QuanLyOperationsService operationsService;
  final bool isDark;
  final Future<void> Function() onToggleTheme;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const List<String> _tieuDe = [
    'Tổng quan',
    'Xe',
    'Tài xế',
    'Tuyến',
    'Giám sát',
    'Báo cáo',
  ];
  int _chiSo = 0;

  void _chonTrang(int chiSo) {
    if (chiSo == _chiSo) return;
    setState(() => _chiSo = chiSo);
  }

  Widget _trangHienTai() {
    switch (_chiSo) {
      case 1:
        return XePage(service: widget.quanLyService);
      case 2:
        return TaiXePage(service: widget.quanLyService);
      case 3:
        return TuyenPage(
          operationsService: widget.operationsService,
          fleetService: widget.quanLyService,
        );
      case 4:
        return GiamSatPage(service: widget.operationsService);
      case 5:
        return BaoCaoPage(service: widget.operationsService);
      default:
        return _TongQuanPage(
          nguoiDung: widget.nguoiDung,
          onChonXe: () => _chonTrang(1),
          onChonTaiXe: () => _chonTrang(2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rong = constraints.maxWidth >= 720;
        final noiDung = _trangHienTai();

        return Scaffold(
          key: const Key('admin-shell'),
          appBar: AppBar(
            leading: rong
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      key: const Key('admin-drawer-button'),
                      tooltip: 'Mở menu',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu),
                    ),
                  ),
            title: Text(_tieuDe[_chiSo]),
            actions: [
              IconButton(
                key: const Key('admin-theme-toggle'),
                tooltip: widget.isDark
                    ? 'Chuyển sang giao diện sáng'
                    : 'Chuyển sang giao diện tối',
                onPressed: () => widget.onToggleTheme(),
                icon: Icon(
                  widget.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
              IconButton(
                key: const Key('logout-button'),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  await widget.onLogout();
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: rong
              ? null
              : Builder(
                  builder: (drawerContext) => NavigationDrawer(
                    selectedIndex: _chiSo,
                    onDestinationSelected: (chiSo) {
                      Scaffold.of(drawerContext).closeDrawer();
                      _chonTrang(chiSo);
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                BrandAssets.logo,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xe Trường Admin',
                                    style: Theme.of(drawerContext)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  Text(
                                    widget.nguoiDung.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(drawerContext)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                      ..._drawerDestinations,
                      const Divider(indent: 20, endIndent: 20),
                      ListTile(
                        key: const Key('drawer-theme-toggle'),
                        leading: Icon(
                          widget.isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                        title: Text(
                          widget.isDark ? 'Giao diện sáng' : 'Giao diện tối',
                        ),
                        onTap: () {
                          Navigator.of(drawerContext).pop();
                          widget.onToggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
          body: rong
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _chiSo,
                      onDestinationSelected: _chonTrang,
                      labelType: NavigationRailLabelType.all,
                      destinations: _railDestinations,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: noiDung),
                  ],
                )
              : noiDung,
        );
      },
    );
  }

  static const List<NavigationRailDestination> _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Tổng quan'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.directions_bus_outlined),
      selectedIcon: Icon(Icons.directions_bus),
      label: Text('Xe'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Tài xế'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: Text('Tuyến'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.my_location_outlined),
      selectedIcon: Icon(Icons.my_location),
      label: Text('Giám sát'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: Text('Báo cáo'),
    ),
  ];

  static const List<Widget> _drawerDestinations = [
    NavigationDrawerDestination(
      key: Key('nav-drawer-overview'),
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Tổng quan'),
    ),
    NavigationDrawerDestination(
      key: Key('nav-drawer-xe'),
      icon: Icon(Icons.directions_bus_outlined),
      selectedIcon: Icon(Icons.directions_bus),
      label: Text('Xe'),
    ),
    NavigationDrawerDestination(
      key: Key('nav-drawer-tai-xe'),
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Tài xế'),
    ),
    NavigationDrawerDestination(
      key: Key('nav-drawer-tuyen'),
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: Text('Tuyến'),
    ),
    NavigationDrawerDestination(
      key: Key('nav-drawer-giam-sat'),
      icon: Icon(Icons.my_location_outlined),
      selectedIcon: Icon(Icons.my_location),
      label: Text('Giám sát'),
    ),
    NavigationDrawerDestination(
      key: Key('nav-drawer-bao-cao'),
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: Text('Báo cáo'),
    ),
  ];
}

class _TongQuanPage extends StatelessWidget {
  const _TongQuanPage({
    required this.nguoiDung,
    required this.onChonXe,
    required this.onChonTaiXe,
  });

  final NguoiDung nguoiDung;
  final VoidCallback onChonXe;
  final VoidCallback onChonTaiXe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BrandBackground(
      key: const Key('overview-background-art'),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, pageConstraints) {
            final compact = pageConstraints.maxWidth < 520;
            return SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 20 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      final cardWidth = contentConstraints.maxWidth >= 640
                          ? (contentConstraints.maxWidth - 16) / 2
                          : contentConstraints.maxWidth;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: colors.primaryContainer,
                                foregroundColor: colors.onPrimaryContainer,
                                child: Text(
                                  nguoiDung.hoTen.isEmpty
                                      ? '?'
                                      : nguoiDung.hoTen.substring(0, 1),
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Xin chào,',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      nguoiDung.hoTen,
                                      key: const Key('overview-greeting'),
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Quản lý hoạt động đưa đón học sinh.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons.verified_user_outlined,
                                  size: 18,
                                ),
                                label: const Text('Quản lý'),
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.mail_outline,
                                  size: 18,
                                ),
                                label: Text(nguoiDung.email),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Truy cập nhanh',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Các tác vụ quản lý đội xe',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _TheChucNang(
                                key: const Key('overview-xe-button'),
                                width: cardWidth,
                                icon: Icons.directions_bus_outlined,
                                tieuDe: 'Xe',
                                moTa: 'Quản lý phương tiện và ngày đăng kiểm.',
                                onTap: onChonXe,
                              ),
                              _TheChucNang(
                                key: const Key('overview-tai-xe-button'),
                                width: cardWidth,
                                icon: Icons.person_outline,
                                tieuDe: 'Tài xế',
                                moTa: 'Tài khoản và giấy phép lái xe.',
                                onTap: onChonTaiXe,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TheChucNang extends StatelessWidget {
  const _TheChucNang({
    super.key,
    required this.width,
    required this.icon,
    required this.tieuDe,
    required this.moTa,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String tieuDe;
  final String moTa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Icon(icon),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tieuDe,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(moTa, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
