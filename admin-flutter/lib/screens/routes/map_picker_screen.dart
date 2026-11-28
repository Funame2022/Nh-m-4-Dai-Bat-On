import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initial});

  final LatLng? initial;

  static Future<LatLng?> mo(BuildContext context, {LatLng? initial}) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (_) => MapPickerScreen(initial: initial),
      ),
    );
  }

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _tamMacDinh = LatLng(10.7769, 106.7009);

  late final LatLng _tamBanDau;
  late LatLng _viTriDaChon;

  bool _laToaDoGia(LatLng? viTri) {
    if (viTri == null) return true;
    return (viTri.latitude == 0 && viTri.longitude == 0) ||
        (viTri.latitude == 1 && viTri.longitude == 1);
  }

  @override
  void initState() {
    super.initState();
    _tamBanDau = _laToaDoGia(widget.initial) ? _tamMacDinh : widget.initial!;
    _viTriDaChon = _tamBanDau;
  }

  String get _toaDoText {
    return '${_viTriDaChon.latitude.toStringAsFixed(6)}, '
        '${_viTriDaChon.longitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn vị trí điểm dừng')),
      body: Stack(
        children: [
          FlutterMap(
            key: const Key('map-picker-map'),
            options: MapOptions(
              initialCenter: _tamBanDau,
              initialZoom: 16,
              onPositionChanged: (camera, hasGesture) {
                final tam = camera.center;
                if (tam.latitude != _viTriDaChon.latitude ||
                    tam.longitude != _viTriDaChon.longitude) {
                  setState(() => _viTriDaChon = tam);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'vn.xetruong.xe_truong_admin',
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Icon(
                    Icons.location_pin,
                    size: 48,
                    color: colors.error,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              color: colors.surface.withValues(alpha: 0.94),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Kéo bản đồ để đưa ghim đến vị trí điểm dừng.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Tọa độ đã chọn', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        _toaDoText,
                        key: const Key('map-picker-coordinates'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        key: const Key('map-picker-confirm'),
                        onPressed: () =>
                            Navigator.of(context).pop(_viTriDaChon),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Chọn vị trí này'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '© OpenStreetMap contributors',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
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
    );
  }
}
