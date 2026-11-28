import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Màn hình Nhắn tin một chiều tới bảo mẫu (ghi chú cho chuyến hôm nay) — yêu cầu Đề 7
class NoteBaoMauScreen extends StatefulWidget {
  final int hocSinhId;
  final String hoTen;
  final String? tenTuyen;

  const NoteBaoMauScreen({
    super.key,
    required this.hocSinhId,
    required this.hoTen,
    this.tenTuyen,
  });

  @override
  State<NoteBaoMauScreen> createState() => _NoteBaoMauScreenState();
}

class _NoteBaoMauScreenState extends State<NoteBaoMauScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  List<Map<String, String>> _notes = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final data = await ApiService.getNotesForChild(widget.hocSinhId);
    if (!mounted) return;
    setState(() {
      _notes = data;
      _loading = false;
    });
  }

  Future<void> _sendNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final text = _noteController.text.trim();
    final synced = await ApiService.addNoteForChild(
      widget.hocSinhId,
      text,
      widget.tenTuyen != null ? 'Bảo mẫu (${widget.tenTuyen})' : 'Bảo mẫu xe',
    );
    if (!mounted) return;
    _noteController.clear();
    setState(() => _sending = false);
    await _loadNotes();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Đã gửi ghi chú tới bảo mẫu trên hệ thống!'
              : 'Đã lưu ghi chú cho chuyến hôm nay',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removed = _notes[index];
    await ApiService.deleteNoteForChild(widget.hocSinhId, index);
    if (!mounted) return;
    setState(() => _notes.removeAt(index));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã xóa ghi chú'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () async {
            await ApiService.addNoteForChild(
              widget.hocSinhId,
              removed['noiDung'] ?? '',
              removed['nguoiNhan'] ?? 'Bảo mẫu',
            );
            if (mounted) _loadNotes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Nhắn bảo mẫu · ${widget.hoTen}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_rounded,
                              color: AppTheme.emerald, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Ghi chú một chiều cho chuyến hôm nay',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Ví dụ: Nhờ cô nhắc bé uống thuốc sau khi lên xe...',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập nội dung ghi chú'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          'Hôm nay bà ngoại đón ở cổng',
                          'Nhờ cô cho bé ngồi ghế đầu',
                          'Bé có mang theo cặp thêm',
                        ].map((sample) {
                          return ActionChip(
                            label: Text(sample,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => _noteController.text = sample,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _sending ? null : _sendNote,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Gửi ghi chú cho bảo mẫu'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ghi chú đã gửi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có ghi chú nào cho bảo mẫu.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          final isSynced = note['synced'] == 'true';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.emerald
                                    .withValues(alpha: 0.14),
                                child: const Icon(Icons.chat_bubble_outline,
                                    color: AppTheme.emerald, size: 20),
                              ),
                              title: Text(note['noiDung'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${note['nguoiNhan'] ?? ''} · ${_formatTime(note['thoiGian'] ?? '')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isSynced
                                              ? AppTheme.emerald
                                              : AppTheme.warmOrange)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isSynced
                                          ? 'Đã đồng bộ server'
                                          : 'Đã lưu cho chuyến',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSynced
                                            ? AppTheme.emerald
                                            : AppTheme.warmOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _confirmDelete(index),
                              ),
                            ),
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
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
