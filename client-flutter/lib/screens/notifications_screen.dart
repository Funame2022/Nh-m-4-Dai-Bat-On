import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/ui_effects.dart';
import 'notification_settings_screen.dart';

/// Màn hình Thông báo — ListView.builder + AlertDialog xác nhận xóa + SnackBar Hoàn tác
class NotificationsScreen extends StatefulWidget {
  final Future<void> Function() onSessionExpired;
  final ValueChanged<int>? onUnreadChanged;

  const NotificationsScreen({
    super.key,
    required this.onSessionExpired,
    this.onUnreadChanged,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<Map<String, dynamic>> _futureThongBao;
  List<dynamic> _notifications = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _futureThongBao = _fetchAndStore();
  }

  Future<Map<String, dynamic>> _fetchAndStore() async {
    try {
      final data = await ApiService.getThongBao(limit: 50);
      if (!mounted) return data;
      final list = (data['notifications'] as List?) ?? [];
      setState(() {
        _notifications = list;
        _loaded = true;
      });
      widget.onUnreadChanged?.call(data['unreadCount'] as int? ?? 0);
      return data;
    } on SessionExpiredException {
      await widget.onSessionExpired();
      return {'notifications': [], 'unreadCount': 0};
    }
  }

  void _refresh() {
    setState(() {
      _futureThongBao = _fetchAndStore();
    });
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.docTatCaThongBao();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((tb) {
          return {...tb as Map, 'da_doc_luc': DateTime.now().toIso8601String()};
        }).toList();
      });
      widget.onUnreadChanged?.call(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả là đã đọc'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on SessionExpiredException {
      await widget.onSessionExpired();
    } catch (_) {}
  }

  Future<void> _markOneRead(int index, int id) async {
    try {
      await ApiService.docThongBao(id);
      if (!mounted) return;
      setState(() {
        _notifications[index] = {
          ..._notifications[index] as Map,
          'da_doc_luc': DateTime.now().toIso8601String(),
        };
      });
      final unread =
          _notifications.where((tb) => tb['da_doc_luc'] == null).length;
      widget.onUnreadChanged?.call(unread);
    } on SessionExpiredException {
      await widget.onSessionExpired();
    } catch (_) {}
  }

  void _deleteNotification(int index) {
    final removed = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });
    final unread =
        _notifications.where((tb) => tb['da_doc_luc'] == null).length;
    widget.onUnreadChanged?.call(unread);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã xóa thông báo'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _notifications.insert(index, removed);
            });
            final restoredUnread =
                _notifications.where((tb) => tb['da_doc_luc'] == null).length;
            widget.onUnreadChanged?.call(restoredUnread);
          },
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationSettingsScreen(
          onSessionExpired: widget.onSessionExpired,
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt nhận thông báo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unreadCount =
        _notifications.where((tb) => tb['da_doc_luc'] == null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Đọc tất cả'),
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Cài đặt thông báo',
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureThongBao,
        builder: (context, snapshot) {
          if (!_loaded &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 12),
              child: ShimmerListPlaceholder(itemCount: 5),
            );
          }
          if (snapshot.hasError && _notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: scheme.outline),
                  const SizedBox(height: 8),
                  const Text('Không tải được thông báo'),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: _refresh, child: const Text('Thử lại')),
                ],
              ),
            );
          }

          if (_notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có thông báo nào.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final tb = _notifications[index] as Map<String, dynamic>;
                final int id = tb['id'] as int;
                final String loai = tb['loai_su_kien']?.toString() ?? '';
                final String tieuDe = tb['tieu_de']?.toString() ?? '';
                final String noiDung = tb['noi_dung']?.toString() ?? '';
                final String? taoLuc = tb['tao_luc']?.toString();
                final bool daDoc = tb['da_doc_luc'] != null;

                return Dismissible(
                  key: Key('tb_$id'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: const Text(
                            'Bạn có chắc muốn xóa thông báo này không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _deleteNotification(index),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: daDoc
                        ? null
                        : scheme.primaryContainer.withValues(alpha: 0.35),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor:
                            _colorForLoai(loai).withValues(alpha: 0.14),
                        child: Icon(_iconForLoai(loai),
                            color: _colorForLoai(loai)),
                      ),
                      title: Text(
                        tieuDe,
                        style: TextStyle(
                          fontWeight:
                              daDoc ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (noiDung.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(noiDung),
                          ],
                          if (taoLuc != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(taoLuc),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                      trailing: daDoc
                          ? null
                          : Icon(Icons.circle,
                              color: scheme.primary, size: 10),
                      onTap: daDoc ? null : () => _markOneRead(index, id),
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

  IconData _iconForLoai(String loai) {
    switch (loai) {
      case 'STUDENT_BOARDED':
        return Icons.login_rounded;
      case 'STUDENT_DROPPED_OFF':
        return Icons.logout_rounded;
      case 'TRIP_STARTED':
        return Icons.play_arrow_rounded;
      case 'TRIP_COMPLETED':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForLoai(String loai) {
    switch (loai) {
      case 'STUDENT_BOARDED':
        return Colors.green;
      case 'STUDENT_DROPPED_OFF':
        return Colors.orange;
      case 'TRIP_STARTED':
        return Colors.blue;
      case 'TRIP_COMPLETED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
