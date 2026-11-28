import 'package:flutter/material.dart';

/// Màn hình Tuyến & Điểm dừng — ListView.builder hiển thị tuyến đón / trả của con
class RouteDetailScreen extends StatelessWidget {
  final int hocSinhId;
  final String hoTen;
  final List<dynamic> trackingList;

  const RouteDetailScreen({
    super.key,
    required this.hocSinhId,
    required this.hoTen,
    required this.trackingList,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tuyến xe của $hoTen'),
      ),
      body: trackingList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route_rounded, size: 64, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Hôm nay chưa có thông tin tuyến.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trackingList.length,
              itemBuilder: (context, index) {
                final item = trackingList[index] as Map<String, dynamic>;
                final chieu = item['chieu']?.toString() ?? '';
                final tenTuyen = item['ten_tuyen']?.toString() ?? 'Chưa có tên';
                final bienSo = item['bien_so']?.toString() ?? '';
                final tenTaiXe = item['ten_tai_xe']?.toString() ?? '';
                final sdtTaiXe = item['sdt_tai_xe']?.toString() ?? '';
                final tenDiemDung = item['ten_diem_dung']?.toString() ?? '';
                final gioDuKien = item['gio_du_kien']?.toString() ?? '';
                final trangThai = item['trang_thai']?.toString() ?? 'CHUA_CHAY';

                final chieuLabel = (chieu == 'DON' || chieu == 'DON_SANG')
                    ? 'Đón buổi sáng'
                    : 'Trả buổi chiều';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(Icons.directions_bus_rounded,
                                  color: scheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chieuLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    tenTuyen,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                _labelForStatus(trangThai),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _row(scheme, Icons.airport_shuttle_outlined, 'Biển số',
                            bienSo.isEmpty ? 'Chưa cập nhật' : bienSo),
                        _row(scheme, Icons.person_outline, 'Tài xế',
                            tenTaiXe.isEmpty ? 'Chưa cập nhật' : tenTaiXe),
                        if (sdtTaiXe.isNotEmpty)
                          _row(scheme, Icons.phone_outlined, 'SĐT tài xế',
                              sdtTaiXe),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  color: scheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tenDiemDung.isEmpty
                                          ? 'Điểm dừng chưa xác định'
                                          : tenDiemDung,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      gioDuKien.isNotEmpty
                                          ? 'Giờ đón dự kiến: $gioDuKien'
                                          : 'Giờ đón dự kiến: Chưa có',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
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
                );
              },
            ),
    );
  }

  Widget _row(
      ColorScheme scheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _labelForStatus(String s) {
    switch (s) {
      case 'DANG_CHAY':
        return 'Đang chạy';
      case 'HOAN_THANH':
        return 'Hoàn thành';
      case 'CHUA_CHAY':
        return 'Chưa chạy';
      default:
        return s;
    }
  }
}
