import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_bus_banner.dart';
import '../widgets/ui_effects.dart';
import 'child_detail_screen.dart';

/// Màn hình Trang chủ Dashboard — lấy cảm hứng từ ảnh mẫu 2
class ChildrenScreen extends StatefulWidget {
  final int unreadCount;
  final Future<void> Function() onSessionExpired;
  final VoidCallback onOpenQrTab;
  final VoidCallback onOpenNotifTab;
  final VoidCallback onOpenProfileTab;

  const ChildrenScreen({
    super.key,
    required this.unreadCount,
    required this.onSessionExpired,
    required this.onOpenQrTab,
    required this.onOpenNotifTab,
    required this.onOpenProfileTab,
  });

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  late Future<List<dynamic>> _futureChildren;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Map<String, dynamic>? _parent;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _futureChildren = _loadChildren();
    _loadParentHeader();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadParentHeader() async {
    final user = await ApiService.getNguoiDungHienTai();
    final avatar = await ApiService.getParentAvatarBase64();
    Uint8List? decoded;
    if (avatar != null && avatar.isNotEmpty) {
      try {
        decoded = base64Decode(avatar);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _parent = user;
      _avatarBytes = decoded;
    });
  }

  Future<List<dynamic>> _loadChildren() async {
    try {
      return await ApiService.getChildren();
    } on SessionExpiredException {
      await widget.onSessionExpired();
      return [];
    }
  }

  void _refresh() {
    _loadParentHeader();
    setState(() {
      _futureChildren = _loadChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parentName = _parent?['hoTen']?.toString() ?? 'Phụ huynh';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: CustomScrollView(
          slivers: [
            // ── Header kiểu VinBus + Search Card nổi ──────────────────────
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: Stack(
                      children: [
                        CityBusBackdrop(
                          height: MediaQuery.of(context).padding.top + 210,
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            MediaQuery.of(context).padding.top + 10,
                            16,
                            16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chuông thông báo bên trái
                              IconButton(
                                onPressed: widget.onOpenNotifTab,
                                icon: Badge(
                                  isLabelVisible: widget.unreadCount > 0,
                                  label: Text('${widget.unreadCount}'),
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              // Tiêu đề BUSCARE + Hồ Chí Minh ở giữa
                              Expanded(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 6),
                                    const Text(
                                      'BUSCARE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Hồ Chí Minh',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white, size: 18),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Avatar tròn + Chào, <Tên> bên phải
                              GestureDetector(
                                onTap: widget.onOpenProfileTab,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppTheme.limeGreen,
                                            width: 2.5),
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                      ),
                                      child: ClipOval(
                                        child: _avatarBytes != null
                                            ? Image.memory(
                                                _avatarBytes!,
                                                fit: BoxFit.cover,
                                                gaplessPlayback: true,
                                              )
                                            : const Icon(Icons.person_rounded,
                                                color: Colors.white, size: 28),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 112),
                                      child: Text(
                                        'Chào, ${parentName.trim().split(RegExp(r'\s+')).last}',
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        maxLines: 2,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black38,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Card tìm kiếm nổi đè lên mép dưới banner (giống ảnh VinBus)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: -44,
                    child: Material(
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      color: scheme.surfaceContainerLowest,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (v) =>
                                  setState(() => _query = v.trim()),
                              decoration: InputDecoration(
                                hintText: 'Nhập tên bé, mã HS hoặc lớp...',
                                prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                    color: AppTheme.emerald),
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _query = '');
                                        },
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.refresh_rounded,
                                            color: AppTheme.emerald),
                                        onPressed: _refresh,
                                      ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                            const Divider(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickTag(
                                    label: '[Đón] Ca sáng · 06:30',
                                    onTap: () {
                                      _searchCtrl.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _QuickTag(
                                    label: '[Trả] Ca chiều · 16:30',
                                    onTap: widget.onOpenQrTab,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 58)),

            // ── 2 Card nổi bật (Cam & Xanh ngọc giống ảnh 2) ──────────────
            SliverToBoxAdapter(
              child: FutureBuilder<List<dynamic>>(
                future: _futureChildren,
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  final first = list.isNotEmpty
                      ? list.first as Map<String, dynamic>
                      : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureTile(
                                title: 'Theo dõi GPS',
                                subtitle: 'Vị trí xe trực tiếp',
                                icon: Icons.location_on_rounded,
                                gradient: AppTheme.orangeGradient,
                                onTap: () {
                                  if (first == null) return;
                                  Navigator.push(
                                    context,
                                    SmoothPageRoute(
                                      page: ChildDetailScreen(
                                        hocSinhId: int.tryParse(
                                                first['id']?.toString() ??
                                                    '') ??
                                            0,
                                        hoTen:
                                            first['ho_ten']?.toString() ?? '',
                                        anhUrl: first['anh_url']?.toString(),
                                        tenLop: first['ten_lop']?.toString(),
                                        tenTruong:
                                            first['ten_truong']?.toString(),
                                        onSessionExpired:
                                            widget.onSessionExpired,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeatureTile(
                                title: 'Thẻ QR học sinh',
                                subtitle: 'Mở thẻ & quét lên xe',
                                icon: Icons.qr_code_scanner_rounded,
                                gradient: AppTheme.emeraldGradient,
                                onTap: widget.onOpenQrTab,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 2 Card thống kê nhỏ
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Con em theo dõi',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${list.length} bé',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CircleAvatar(
                                        backgroundColor: AppTheme.warmOrange
                                            .withValues(alpha: 0.14),
                                        child: const Icon(
                                          Icons.child_care_rounded,
                                          color: AppTheme.warmOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: widget.onOpenNotifTab,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Thông báo mới',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${widget.unreadCount} tin',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        CircleAvatar(
                                          backgroundColor: AppTheme.emerald
                                              .withValues(alpha: 0.14),
                                          child: const Icon(
                                            Icons.notifications_active_rounded,
                                            color: AppTheme.emerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Tiêu đề danh sách con ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách con em',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Chạm để xem hành trình',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.emerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Danh sách con (ListView.builder + 3 trạng thái) ────────────
            SliverToBoxAdapter(
              child: FutureBuilder<List<dynamic>>(
                future: _futureChildren,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ShimmerListPlaceholder(itemCount: 3);
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 54, color: scheme.outline),
                          const SizedBox(height: 10),
                          const Text('Không tải được danh sách con'),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final filtered = _query.isEmpty
                      ? all
                      : all.where((e) {
                          final m = e as Map<String, dynamic>;
                          final text =
                              '${m['ho_ten']} ${m['ma_hs']} ${m['ten_lop']}'
                                  .toLowerCase();
                          return text.contains(_query.toLowerCase());
                        }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Không tìm thấy học sinh phù hợp.'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final child = filtered[index] as Map<String, dynamic>;
                      final int hocSinhId =
                          int.tryParse(child['id']?.toString() ?? '') ?? 0;
                      final String hoTen = child['ho_ten'] ?? 'Không rõ';
                      final String maHs = child['ma_hs'] ?? '';
                      final String tenLop = child['ten_lop'] ?? '';
                      final String tenTruong = child['ten_truong'] ?? '';
                      final String? anhUrl = child['anh_url'] as String?;
                      final String quanHe = child['quan_he'] ?? '';

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 300 + index * 90),
                        curve: Curves.easeOutCubic,
                        builder: (ctx, val, w) => Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - val)),
                            child: w,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(
                                  page: ChildDetailScreen(
                                    hocSinhId: hocSinhId,
                                    hoTen: hoTen,
                                    anhUrl: anhUrl,
                                    tenLop: tenLop,
                                    tenTruong: tenTruong,
                                    onSessionExpired: widget.onSessionExpired,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Hero(
                                    tag: 'student_avatar_$hocSinhId',
                                    child:
                                        _StudentAvatar(anhUrl: anhUrl, size: 60),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                hoTen,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (quanHe.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.emerald
                                                      .withValues(alpha: 0.14),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  quanHe,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.emerald,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Mã HS: $maHs · Lớp $tenLop',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          tenTruong,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppTheme.emerald),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTag extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickTag({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.mintBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.emeraldDark,
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị ảnh học sinh từ URL có cả loadingBuilder và errorBuilder (tiêu chí C.2.8)
class _StudentAvatar extends StatelessWidget {
  final String? anhUrl;
  final double size;

  const _StudentAvatar({required this.anhUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = anhUrl?.trim() ?? '';

    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.emerald.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.face_rounded,
            size: size * 0.55, color: AppTheme.emerald),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: scheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: AppTheme.emerald.withValues(alpha: 0.14),
            child: Icon(Icons.face_rounded,
                size: size * 0.55, color: AppTheme.emerald),
          );
        },
      ),
    );
  }
}
