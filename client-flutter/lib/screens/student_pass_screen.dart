import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'child_detail_screen.dart';

/// Màn hình Thẻ QR & Danh sách thẻ học sinh (lấy cảm hứng từ ảnh 3 & 4)
class StudentPassScreen extends StatefulWidget {
  final Future<void> Function() onSessionExpired;

  const StudentPassScreen({super.key, required this.onSessionExpired});

  @override
  State<StudentPassScreen> createState() => _StudentPassScreenState();
}

class _StudentPassScreenState extends State<StudentPassScreen> {
  late Future<List<dynamic>> _futureChildren;
  final PageController _pageCtrl = PageController(viewportFraction: 0.92);
  int _selectedIndex = 0;
  bool _qrUnlocked = true;

  @override
  void initState() {
    super.initState();
    _futureChildren = _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _load() async {
    try {
      return await ApiService.getChildren();
    } on SessionExpiredException {
      await widget.onSessionExpired();
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ xe buýt & Mã QR'),
        actions: [
          IconButton(
            icon: Icon(
                _qrUnlocked ? Icons.lock_open_rounded : Icons.lock_outline),
            tooltip: _qrUnlocked ? 'Khóa mã QR' : 'Mở khóa mã QR',
            onPressed: () => setState(() => _qrUnlocked = !_qrUnlocked),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureChildren,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => setState(() => _futureChildren = _load()),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            );
          }

          final children = snapshot.data ?? [];
          if (children.isEmpty) {
            return const Center(child: Text('Chưa có thẻ học sinh nào.'));
          }

          final current =
              children[_selectedIndex.clamp(0, children.length - 1)]
                  as Map<String, dynamic>;
          final maHs = current['ma_hs']?.toString() ?? 'HS000';
          final hoTen = current['ho_ten']?.toString() ?? '';
          final tenLop = current['ten_lop']?.toString() ?? '';
          final tenTruong = current['ten_truong']?.toString() ?? '';
          final quanHe = current['quan_he']?.toString() ?? '';

          return ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 96),
            children: [
              // ── Bộ chọn thẻ ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.emerald.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded,
                          color: AppTheme.emerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '(${_selectedIndex + 1}/${children.length}) $maHs · $hoTen',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Swipeable Card (Xanh ngọc / Cam ấm) ──────────────────────
              SizedBox(
                height: 205,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: children.length,
                  onPageChanged: (i) => setState(() => _selectedIndex = i),
                  itemBuilder: (context, index) {
                    final child = children[index] as Map<String, dynamic>;
                    final isEven = index % 2 == 0;
                    final grad = isEven
                        ? AppTheme.emeraldGradient
                        : AppTheme.orangeGradient;
                    final anhUrl = child['anh_url']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: grad,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: (isEven
                                      ? AppTheme.emerald
                                      : AppTheme.warmOrange)
                                  .withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'THẺ XE BUÝT HỌC SINH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    child['ten_lop']?.toString() ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: anhUrl.isEmpty
                                      ? Container(
                                          width: 58,
                                          height: 68,
                                          color: Colors.white
                                              .withValues(alpha: 0.25),
                                          child: const Icon(
                                              Icons.person_rounded,
                                              color: Colors.white,
                                              size: 34),
                                        )
                                      : Image.network(
                                          anhUrl,
                                          width: 58,
                                          height: 68,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (c, child, p) =>
                                              p == null
                                                  ? child
                                                  : Container(
                                                      width: 58,
                                                      height: 68,
                                                      color: Colors.white24,
                                                    ),
                                          errorBuilder: (c, e, s) => Container(
                                            width: 58,
                                            height: 68,
                                            color: Colors.white24,
                                            child: const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child['ho_ten']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mã HS: ${child['ma_hs'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        child['ten_truong']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'BusCare · Đề 07',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      _qrUnlocked
                                          ? Icons.check_circle_rounded
                                          : Icons.lock_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _qrUnlocked
                                          ? 'Đang hoạt động'
                                          : 'Đã khóa QR',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // ── Khu vực QR Code có hiệu ứng Khóa/Mở ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _qrUnlocked
                          ? Column(
                              key: const ValueKey('qr_open'),
                              children: [
                                const Text(
                                  'Đưa mã QR này cho bảo mẫu khi lên/xuống xe',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AppTheme.emerald
                                          .withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: QrImageView(
                                    data: 'BUSCARE:$maHs:${current['id']}',
                                    size: 168,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: AppTheme.emeraldDark,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape:
                                          QrDataModuleShape.square,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  maHs,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    fontSize: 16,
                                    color: AppTheme.emerald,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('qr_locked'),
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald
                                        .withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_rounded,
                                      size: 46, color: AppTheme.emerald),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Mã QR đang tạm khóa',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Nhấn nút bên dưới để mở khóa và quét thẻ',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: () =>
                                      setState(() => _qrUnlocked = true),
                                  icon: const Icon(Icons.lock_open_rounded),
                                  label: const Text('Mở khóa mã QR'),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Thông tin chi tiết thẻ (giống ảnh 4) ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin_rounded,
                                color: AppTheme.emerald, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'THÔNG TIN THẺ HỌC SINH',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _detailRow('Mã học sinh', maHs),
                        _detailRow('Họ và tên', hoTen),
                        _detailRow('Lớp', tenLop),
                        _detailRow('Trường', tenTruong),
                        _detailRow('Quan hệ', quanHe),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                page: ChildDetailScreen(
                                  hocSinhId: current['id'] as int,
                                  hoTen: hoTen,
                                  anhUrl: current['anh_url']?.toString(),
                                  tenLop: tenLop,
                                  tenTruong: tenTruong,
                                  onSessionExpired: widget.onSessionExpired,
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.gps_fixed_rounded),
                          label: const Text('Theo dõi chuyến & Bản đồ xe'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value.isEmpty ? 'Chưa cập nhật' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
