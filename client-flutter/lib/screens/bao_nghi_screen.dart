import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Màn hình Đăng ký báo nghỉ học — điều hướng riêng & trả kết quả về màn hình trước (tiêu chí C.2.2 & C.2.4)
class BaoNghiScreen extends StatefulWidget {
  final int hocSinhId;
  final String hoTen;

  const BaoNghiScreen({
    super.key,
    required this.hocSinhId,
    required this.hoTen,
  });

  @override
  State<BaoNghiScreen> createState() => _BaoNghiScreenState();
}

class _BaoNghiScreenState extends State<BaoNghiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ngayController = TextEditingController();
  final _lyDoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Mặc định ngày mai
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _ngayController.text = tomorrow.toIso8601String().split('T')[0];
  }

  @override
  void dispose() {
    _ngayController.dispose();
    _lyDoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_ngayController.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _ngayController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final ok = await ApiService.postBaoNghi(
        widget.hocSinhId,
        _ngayController.text.trim(),
        _lyDoController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (ok) {
        // Trả kết quả true về màn hình trước (tiêu chí C.2.2)
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không gửi được đơn báo nghỉ. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.redAccent,
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
        title: const Text('Đăng ký báo nghỉ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.child_care,
                        color: scheme.onPrimaryContainer),
                  ),
                  title: Text(
                    widget.hoTen,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Thông báo nghỉ xe đưa đón'),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _ngayController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày nghỉ',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng chọn ngày nghỉ'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lyDoController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Lý do nghỉ học',
                          hintText: 'Ví dụ: Bé bị sốt, gia đình tự đưa đón...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập lý do nghỉ';
                          }
                          if (v.trim().length < 5) {
                            return 'Lý do cần ít nhất 5 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Bị ốm / sốt',
                          'Gia đình tự đón',
                          'Việc gia đình',
                        ].map((preset) {
                          return ActionChip(
                            label: Text(preset),
                            onPressed: () {
                              _lyDoController.text = preset;
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Gửi đơn báo nghỉ',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
