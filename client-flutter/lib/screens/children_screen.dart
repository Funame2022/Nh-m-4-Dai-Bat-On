import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
  String? _avatarB64;

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
    if (!mounted) return;
    setState(() {
      _parent = user;
      _avatarB64 = avatar;
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
            // ── Header Xanh Ngọc + Search Bar nổi ─────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 14,
                      20,
                      48,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.emeraldGradient,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onOpenProfileTab,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 2),
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: (_avatarB64 != null &&
                                      _avatarB64!.isNotEmpty)
                                  ? Image.memory(
                                      base64Decode(_avatarB64!),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parentName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Chúc bạn một ngày an lành ^^',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      ],
                    ),
                  ),
                  // Thanh tìm kiếm nổi
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: -24,
                    child: Material(
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm con em, mã HS, lớp...',
                          prefixIcon: const Icon(Icons.search_rounded,
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 36)),

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
                                        hocSinhId: first['id'] as int,
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
                      final int hocSinhId = child['id'] as int;
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
