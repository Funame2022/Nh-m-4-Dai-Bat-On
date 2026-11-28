import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'child_detail_screen.dart';

/// Màn hình danh sách con — dùng ListView.builder + Image.network (loadingBuilder & errorBuilder)
class ChildrenScreen extends StatefulWidget {
  final Future<void> Function() onSessionExpired;

  const ChildrenScreen({super.key, required this.onSessionExpired});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  late Future<List<dynamic>> _futureChildren;

  @override
  void initState() {
    super.initState();
    _futureChildren = _loadChildren();
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
    setState(() {
      _futureChildren = _loadChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BusCare',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Danh sách học sinh của bạn',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureChildren,
        builder: (context, snapshot) {
          // 1. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Lỗi mạng
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 64, color: scheme.outline),
                    const SizedBox(height: 12),
                    const Text(
                      'Không tải được danh sách con',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kiểm tra kết nối mạng và thử lại nhé.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Có dữ liệu
          final children = snapshot.data ?? [];
          if (children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care_rounded,
                      size: 64, color: scheme.outline),
                  const SizedBox(height: 12),
                  const Text('Chưa có học sinh nào được liên kết.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: _refresh, child: const Text('Tải lại')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index] as Map<String, dynamic>;
                final int hocSinhId = child['id'] as int;
                final String hoTen = child['ho_ten'] ?? 'Không rõ';
                final String maHs = child['ma_hs'] ?? '';
                final String tenLop = child['ten_lop'] ?? '';
                final String tenTruong = child['ten_truong'] ?? '';
                final String? anhUrl = child['anh_url'] as String?;
                final String quanHe = child['quan_he'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildDetailScreen(
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StudentAvatar(anhUrl: anhUrl, size: 60),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hoTen,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                    if (quanHe.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: scheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          quanHe,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Mã HS: $maHs · Lớp $tenLop',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tenTruong,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.directions_bus_outlined,
                                        size: 15, color: scheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Chạm để theo dõi xe & bản đồ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: scheme.outline),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
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
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.face_rounded,
            size: size * 0.55, color: scheme.onPrimaryContainer),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
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
            color: scheme.primaryContainer,
            child: Icon(Icons.face_rounded,
                size: size * 0.55, color: scheme.onPrimaryContainer),
          );
        },
      ),
    );
  }
}
