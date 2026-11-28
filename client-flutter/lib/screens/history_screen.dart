import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Màn hình Lịch sử đi xe theo tháng (ListView.builder từ API)
class HistoryScreen extends StatefulWidget {
  final int hocSinhId;
  final String hoTen;
  final Future<void> Function() onSessionExpired;

  const HistoryScreen({
    super.key,
    required this.hocSinhId,
    required this.hoTen,
    required this.onSessionExpired,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late Future<Map<String, dynamic>> _futureThongBao;

  @override
  void initState() {
    super.initState();
    _futureThongBao = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    try {
      return await ApiService.getThongBao(limit: 100);
    } on SessionExpiredException {
      await widget.onSessionExpired();
      return {'notifications': []};
    }
  }

  void _refresh() {
    setState(() {
      _futureThongBao = _load();
    });
  }

  List<dynamic> _filterByMonth(List<dynamic> all) {
    return all.where((tb) {
      final loai = tb['loai_su_kien'] ?? '';
      if (![
        'STUDENT_BOARDED',
        'STUDENT_DROPPED_OFF',
        'TRIP_STARTED',
        'TRIP_COMPLETED'
      ].contains(loai)) {
        return false;
      }
      final hsId = tb['hoc_sinh_id'];
      if (hsId != null && hsId != widget.hocSinhId) return false;

      final taoLuc = tb['tao_luc'] as String?;
      if (taoLuc == null) return false;
      try {
        final dt = DateTime.parse(taoLuc).toLocal();
        return dt.month == _selectedMonth && dt.year == _selectedYear;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử · ${widget.hoTen}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 1) {
                            _selectedMonth = 12;
                            _selectedYear--;
                          } else {
                            _selectedMonth--;
                          }
                          _refresh();
                        });
                      },
                    ),
                    Text(
                      'Tháng $_selectedMonth / $_selectedYear',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        final now = DateTime.now();
                        if (_selectedYear < now.year ||
                            (_selectedYear == now.year &&
                                _selectedMonth < now.month)) {
                          setState(() {
                            if (_selectedMonth == 12) {
                              _selectedMonth = 1;
                              _selectedYear++;
                            } else {
                              _selectedMonth++;
                            }
                            _refresh();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _futureThongBao,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 48, color: scheme.outline),
                        const SizedBox(height: 8),
                        const Text('Không kết nối được máy chủ'),
                        const SizedBox(height: 8),
                        FilledButton(
                            onPressed: _refresh,
                            child: const Text('Thử lại')),
                      ],
                    ),
                  );
                }

                final allNotifs =
                    (snapshot.data?['notifications'] as List?) ?? [];
                final filtered = _filterByMonth(allNotifs);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'Không có dữ liệu tháng $_selectedMonth/$_selectedYear',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tb = filtered[index] as Map<String, dynamic>;
                    final loai = tb['loai_su_kien']?.toString() ?? '';
                    final tieuDe = tb['tieu_de']?.toString() ?? '';
                    final noiDung = tb['noi_dung']?.toString() ?? '';
                    final taoLuc = tb['tao_luc']?.toString();

                    IconData iconData;
                    Color iconColor;
                    switch (loai) {
                      case 'STUDENT_BOARDED':
                        iconData = Icons.login_rounded;
                        iconColor = Colors.green;
                        break;
                      case 'STUDENT_DROPPED_OFF':
                        iconData = Icons.logout_rounded;
                        iconColor = Colors.orange;
                        break;
                      case 'TRIP_STARTED':
                        iconData = Icons.play_arrow_rounded;
                        iconColor = Colors.blue;
                        break;
                      case 'TRIP_COMPLETED':
                        iconData = Icons.check_circle_rounded;
                        iconColor = Colors.purple;
                        break;
                      default:
                        iconData = Icons.notifications_rounded;
                        iconColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withValues(alpha: 0.14),
                          child: Icon(iconData, color: iconColor),
                        ),
                        title: Text(tieuDe,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (noiDung.isNotEmpty) Text(noiDung),
                            if (taoLuc != null)
                              Text(
                                _formatTime(taoLuc),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                        isThreeLine: noiDung.isNotEmpty,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
