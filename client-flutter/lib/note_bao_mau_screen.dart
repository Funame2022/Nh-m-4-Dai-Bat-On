import 'package:flutter/material.dart';
import 'api_service.dart';

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
    final text = _noteController.text.trim();
    await ApiService.addNoteForChild(
      widget.hocSinhId,
      text,
      widget.tenTuyen != null ? 'Bảo mẫu (${widget.tenTuyen})' : 'Bảo mẫu xe',
    );
    if (!mounted) return;
    _noteController.clear();
    await _loadNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi ghi chú cho bảo mẫu chuyến hôm nay'),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ghi chú một chiều cho chuyến hôm nay',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _sendNote,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Gửi ghi chú'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                child: Icon(Icons.chat_bubble_outline,
                                    color: scheme.onPrimaryContainer,
                                    size: 20),
                              ),
                              title: Text(note['noiDung'] ?? ''),
                              subtitle: Text(
                                '${note['nguoiNhan'] ?? ''} · ${_formatTime(note['thoiGian'] ?? '')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
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
