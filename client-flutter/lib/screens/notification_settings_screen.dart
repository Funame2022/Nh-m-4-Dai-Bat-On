import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Màn hình Cài đặt thông báo — gọi GET/PUT /api/phu-huynh/thong-bao/cai-dat
/// Trả về true qua Navigator.pop(context, true) khi lưu thành công (tiêu chí C.2.2)
class NotificationSettingsScreen extends StatefulWidget {
  final Future<void> Function() onSessionExpired;

  const NotificationSettingsScreen({
    super.key,
    required this.onSessionExpired,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, bool> _prefs = {
    'TRIP_STARTED': true,
    'STUDENT_BOARDED': true,
    'STUDENT_DROPPED_OFF': true,
    'TRIP_COMPLETED': true,
  };

  static const Map<String, String> _labels = {
    'TRIP_STARTED': 'Xe bắt đầu khởi hành',
    'STUDENT_BOARDED': 'Con đã lên xe',
    'STUDENT_DROPPED_OFF': 'Con đã xuống xe',
    'TRIP_COMPLETED': 'Chuyến đi hoàn tất',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getNotificationSettings();
      if (!mounted) return;
      setState(() {
        if (data.isNotEmpty) _prefs = data;
        _loading = false;
      });
    } on SessionExpiredException {
      await widget.onSessionExpired();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được cài đặt thông báo';
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateNotificationSettings(_prefs);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on SessionExpiredException {
      await widget.onSessionExpired();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu cài đặt thất bại. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadSettings,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Column(
                        children: _prefs.entries.map((entry) {
                          return SwitchListTile(
                            title: Text(_labels[entry.key] ?? entry.key),
                            value: entry.value,
                            onChanged: (v) {
                              setState(() => _prefs[entry.key] = v);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveSettings,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Lưu cài đặt'),
                    ),
                  ],
                ),
    );
  }
}
