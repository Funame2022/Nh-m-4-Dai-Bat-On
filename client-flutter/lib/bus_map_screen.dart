import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Màn hình bản đồ toàn màn hình theo dõi vị trí xe trường
class BusMapScreen extends StatelessWidget {
  final String hoTen;
  final double? lat;
  final double? lng;
  final String? bienSo;
  final String? tenTuyen;
  final String? capNhatLuc;

  const BusMapScreen({
    super.key,
    required this.hoTen,
    this.lat,
    this.lng,
    this.bienSo,
    this.tenTuyen,
    this.capNhatLuc,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasGps = lat != null && lng != null;
    final center =
        hasGps ? LatLng(lat!, lng!) : const LatLng(10.7769, 106.7009);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bản đồ xe · $hoTen'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: hasGps ? 16.0 : 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nhom01.school_bus_client',
              ),
              if (hasGps)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: hasGps
                          ? Colors.green.withValues(alpha: 0.16)
                          : scheme.surfaceContainerHighest,
                      child: Icon(
                        hasGps
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_off_rounded,
                        color: hasGps ? Colors.green : scheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tenTuyen ?? 'Xe đưa đón học sinh',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            hasGps
                                ? 'Biển số: ${bienSo ?? 'N/A'} · ($lat, $lng)'
                                : 'Xe chưa phát tín hiệu GPS hôm nay.',
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
            ),
          ),
        ],
      ),
    );
  }
}
