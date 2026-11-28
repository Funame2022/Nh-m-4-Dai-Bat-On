import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'bao_nghi_screen.dart';
import 'bus_map_screen.dart';
import 'history_screen.dart';
import 'note_bao_mau_screen.dart';
import 'route_detail_screen.dart';

/// Màn hình chi tiết học sinh — Theo dõi bản đồ GPS + Điểm danh + Điều hướng nhanh
class ChildDetailScreen extends StatefulWidget {
  final int hocSinhId;
  final String hoTen;
  final String? anhUrl;
  final String? tenLop;
  final String? tenTruong;
  final Future<void> Function() onSessionExpired;

  const ChildDetailScreen({
    super.key,
    required this.hocSinhId,
    required this.hoTen,
    this.anhUrl,
    this.tenLop,
    this.tenTruong,
    required this.onSessionExpired,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late Future<List<dynamic>> _futureTracking;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _futureTracking = _loadTracking();
    // Tự động cập nhật vị trí GPS mỗi 15 giây
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<List<dynamic>> _loadTracking() async {
    try {
      return await ApiService.getTracking(widget.hocSinhId);
    } on SessionExpiredException {
      await widget.onSessionExpired();
      return [];
    }
  }

  void _refresh({bool silent = false}) {
    if (!mounted) return;
    setState(() {
      _futureTracking = _loadTracking();
    });
  }

  Future<void> _openBaoNghi() async {
    // Điều hướng và nhận kết quả trả về từ màn hình BaoNghiScreen (tiêu chí C.2.2)
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BaoNghiScreen(
          hocSinhId: widget.hocSinhId,
          hoTen: widget.hoTen,
        ),
      ),
    );
    if (!mounted) return;
    if (submitted == true) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi nhận đơn báo nghỉ cho con'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hoTen),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Cập nhật GPS',
            onPressed: () => _refresh(),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureTracking,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 56, color: scheme.outline),
                    const SizedBox(height: 12),
                    const Text('Lỗi kết nối máy chủ'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final trackingList = snapshot.data ?? [];
          final firstTrip = trackingList.isNotEmpty
              ? trackingList.first as Map<String, dynamic>
              : null;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                // ── 1. Card học sinh ────────────────────────────────────────
                _buildStudentHeader(scheme),
                const SizedBox(height: 12),

                // ── 2. Lưới 4 nút thao tác nhanh ────────────────────────────
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                  children: [
                    _QuickAction(
                      icon: Icons.route_rounded,
                      label: 'Tuyến xe',
                      color: scheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RouteDetailScreen(
                              hocSinhId: widget.hocSinhId,
                              hoTen: widget.hoTen,
                              trackingList: trackingList,
                            ),
                          ),
                        );
                      },
                    ),
                    _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'Lịch sử',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryScreen(
                              hocSinhId: widget.hocSinhId,
                              hoTen: widget.hoTen,
                              onSessionExpired: widget.onSessionExpired,
                            ),
                          ),
                        );
                      },
                    ),
                    _QuickAction(
                      icon: Icons.chat_outlined,
                      label: 'Bảo mẫu',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteBaoMauScreen(
                              hocSinhId: widget.hocSinhId,
                              hoTen: widget.hoTen,
                              tenTuyen: firstTrip?['ten_tuyen']?.toString(),
                            ),
                          ),
                        );
                      },
                    ),
                    _QuickAction(
                      icon: Icons.event_busy_rounded,
                      label: 'Báo nghỉ',
                      color: Colors.orange.shade700,
                      onTap: _openBaoNghi,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 3. Bản đồ vị trí xe ─────────────────────────────────────
                _buildMapCard(context, trackingList),
                const SizedBox(height: 16),

                // ── 4. Danh sách chuyến hôm nay & điểm danh ─────────────────
                if (trackingList.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: scheme.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Hôm nay chưa có chuyến đi nào được khởi tạo cho con em.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...trackingList
                      .map((item) => _buildTripCard(context, item)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentHeader(ColorScheme scheme) {
    final url = widget.anhUrl?.trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: url.isEmpty
                  ? Container(
                      width: 56,
                      height: 56,
                      color: scheme.primaryContainer,
                      child: Icon(Icons.face_rounded,
                          size: 32, color: scheme.onPrimaryContainer),
                    )
                  : Image.network(
                      url,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 56,
                          height: 56,
                          color: scheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, st) => Container(
                        width: 56,
                        height: 56,
                        color: scheme.primaryContainer,
                        child: Icon(Icons.face_rounded,
                            size: 32, color: scheme.onPrimaryContainer),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hoTen,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  if ((widget.tenLop ?? '').isNotEmpty ||
                      (widget.tenTruong ?? '').isNotEmpty)
                    Text(
                      '${widget.tenLop ?? ''} · ${widget.tenTruong ?? ''}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, List<dynamic> trackingList) {
    final scheme = Theme.of(context).colorScheme;

    // Tìm chuyến có tọa độ GPS mới nhất
    double? lat;
    double? lng;
    String? bienSo;
    String? tenTuyen;
    String? capNhatLuc;

    for (final raw in trackingList) {
      final item = raw as Map<String, dynamic>;
      final v = double.tryParse(item['vi_do']?.toString() ?? '');
      final k = double.tryParse(item['kinh_do']?.toString() ?? '');
      if (v != null && k != null) {
        lat = v;
        lng = k;
        bienSo = item['bien_so']?.toString();
        tenTuyen = item['ten_tuyen']?.toString();
        capNhatLuc = item['cap_nhat_luc']?.toString();
        break;
      }
    }

    final hasGps = lat != null && lng != null;
    final center = hasGps ? LatLng(lat, lng) : const LatLng(10.7769, 106.7009);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(
                  hasGps ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  color: hasGps ? Colors.green : scheme.outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vị trí xe trên bản đồ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        hasGps
                            ? '${bienSo ?? 'Xe trường'} · Cập nhật ${_formatTime(capNhatLuc)}'
                            : 'Chưa có tín hiệu GPS trực tiếp (hiển thị TP.HCM)',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusMapScreen(
                          hoTen: widget.hoTen,
                          lat: lat,
                          lng: lng,
                          bienSo: bienSo,
                          tenTuyen: tenTuyen,
                          capNhatLuc: capNhatLuc,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Mở rộng'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: hasGps ? 15.0 : 12.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nhom01.school_bus_client',
                ),
                if (hasGps)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 48,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, dynamic rawItem) {
    final item = rawItem as Map<String, dynamic>;
    final scheme = Theme.of(context).colorScheme;
    final trangThai = item['trang_thai']?.toString() ?? 'CHUA_CHAY';
    final tenTuyen = item['ten_tuyen']?.toString() ?? '';
    final bienSo = item['bien_so']?.toString() ?? '';
    final tenTaiXe = item['ten_tai_xe']?.toString() ?? '';
    final sdtTaiXe = item['sdt_tai_xe']?.toString() ?? '';
    final tenDiemDung = item['ten_diem_dung']?.toString() ?? '';
    final gioDuKien = item['gio_du_kien']?.toString() ?? '';
    final chieu = item['chieu']?.toString() ?? '';
    final List<dynamic> lichSu =
        item['lich_su_diem_danh'] is List ? item['lich_su_diem_danh'] : [];

    final chieuLabel =
        chieu == 'DON_SANG' ? 'Đón buổi sáng' : 'Trả buổi chiều';
    final statusColor = _colorForStatus(trangThai);
    final statusLabel = _labelForStatus(trangThai);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  chieu == 'DON_SANG'
                      ? Icons.wb_sunny_outlined
                      : Icons.nights_stay_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chieuLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _infoRow(Icons.route_outlined, 'Tuyến', tenTuyen),
            _infoRow(Icons.airport_shuttle_outlined, 'Xe', bienSo),
            _infoRow(
              Icons.person_outline,
              'Tài xế',
              '$tenTaiXe${sdtTaiXe.isNotEmpty ? ' · $sdtTaiXe' : ''}',
            ),
            _infoRow(
              Icons.location_on_outlined,
              'Điểm đón',
              '$tenDiemDung${gioDuKien.isNotEmpty ? ' ($gioDuKien)' : ''}',
            ),
            const SizedBox(height: 12),
            Text(
              'Điểm danh hôm nay',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            if (lichSu.isEmpty)
              Text(
                'Chưa có lượt điểm danh nào.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              )
            else
              ...lichSu.map((dd) {
                final suKien = dd['su_kien']?.toString() ?? '';
                final thoiDiem = dd['thoi_diem']?.toString() ?? '';
                final isLen = suKien == 'LEN_XE';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isLen ? Icons.login_rounded : Icons.logout_rounded,
                        size: 18,
                        color: isLen ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLen ? 'Đã lên xe' : 'Đã xuống xe',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(thoiDiem),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'DANG_CHAY':
        return Colors.green;
      case 'HOAN_THANH':
        return Colors.blue;
      case 'CHUA_CHAY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'DANG_CHAY':
        return 'Đang chạy';
      case 'HOAN_THANH':
        return 'Hoàn thành';
      case 'CHUA_CHAY':
        return 'Chưa chạy';
      default:
        return status;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
