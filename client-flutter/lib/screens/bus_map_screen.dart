import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

/// Màn hình bản đồ toàn màn hình theo dõi vị trí xe trường
class BusMapScreen extends StatefulWidget {
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
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _hcmCenter = LatLng(10.7769, 106.7009);

  bool get _hasGps => widget.lat != null && widget.lng != null;

  bool get _isInVietnam =>
      _hasGps &&
      widget.lat! >= 8.0 &&
      widget.lat! <= 24.0 &&
      widget.lng! >= 102.0 &&
      widget.lng! <= 110.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busPoint = _hasGps ? LatLng(widget.lat!, widget.lng!) : _hcmCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bản đồ xe · ${widget.hoTen}'),
        actions: [
          IconButton(
            tooltip: 'Về TP.HCM',
            icon: const Icon(Icons.location_city_rounded),
            onPressed: () => _mapController.move(_hcmCenter, 13.5),
          ),
          if (_hasGps)
            IconButton(
              tooltip: 'Về vị trí xe',
              icon: const Icon(Icons.my_location_rounded),
              onPressed: () => _mapController.move(busPoint, 15.5),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: busPoint,
              initialZoom: _hasGps ? 15.0 : 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nhom09.school_bus_client',
              ),
              if (_hasGps)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: busPoint,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.emerald,
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
          if (_hasGps && !_isInVietnam)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                color: AppTheme.warmOrange,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tọa độ từ Admin đang nằm ngoài Việt Nam (giữa biển).',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _mapController.move(_hcmCenter, 13.5),
                        child: const Text(
                          'Xem TP.HCM',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                      backgroundColor: _hasGps
                          ? Colors.green.withValues(alpha: 0.16)
                          : scheme.surfaceContainerHighest,
                      child: Icon(
                        _hasGps
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_off_rounded,
                        color: _hasGps ? Colors.green : scheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.tenTuyen ?? 'Xe đưa đón học sinh',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _hasGps
                                ? 'Biển số: ${widget.bienSo ?? 'N/A'} · (${widget.lat}, ${widget.lng})'
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
