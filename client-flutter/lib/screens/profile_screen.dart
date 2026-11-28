import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Màn hình Tài khoản — tương thích đầy đủ với auth.js (đổi tên, đổi mật khẩu, theme, đăng xuất)
class ProfileScreen extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onToggleTheme;
  final VoidCallback onLogout;
  final Future<void> Function() onSessionExpired;

  const ProfileScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onSessionExpired,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _nguoiDung;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = await ApiService.getNguoiDungHienTai();
    if (!mounted) return;
    setState(() {
      _nguoiDung = cached;
      _loading = false;
    });
  }

  Future<void> _showEditNameDialog() async {
    final controller =
        TextEditingController(text: _nguoiDung?['hoTen']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi họ tên'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Họ và tên'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng nhập họ tên'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final err = await ApiService.updateProfileName(
                    controller.text.trim());
                if (!ctx.mounted) return;
                if (err == null) {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                }
              } on SessionExpiredException {
                if (ctx.mounted) Navigator.pop(ctx, false);
                await widget.onSessionExpired();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (updated == true && mounted) {
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật họ tên'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Nhập mật khẩu hiện tại'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới (tối thiểu 8 ký tự)'),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Mật khẩu mới phải từ 8 ký tự'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final err = await ApiService.changePassword(
                  oldCtrl.text,
                  newCtrl.text,
                );
                if (!ctx.mounted) return;
                if (err == null) {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                }
              } on SessionExpiredException {
                if (ctx.mounted) Navigator.pop(ctx, false);
                await widget.onSessionExpired();
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    oldCtrl.dispose();
    newCtrl.dispose();
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đổi mật khẩu thành công'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi BusCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ApiService.logout();
    if (!mounted) return;
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.person_rounded,
                              size: 38, color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nguoiDung?['hoTen']?.toString() ?? 'Phụ huynh',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _nguoiDung?['email']?.toString() ?? '',
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Phụ huynh · ${_nguoiDung?['sdt'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Đổi họ tên hiển thị'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showEditNameDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded),
                        title: const Text('Đổi mật khẩu'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showChangePasswordDialog,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Giao diện tối (Dark Mode)'),
                        value: widget.isDark,
                        onChanged: (_) => widget.onToggleTheme(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.directions_bus_outlined),
                        title: Text('BusCare Phụ Huynh'),
                        subtitle: Text('Nhóm 01 · INT4211 · Đề 7'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded,
                            color: Colors.redAccent),
                        title: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600),
                        ),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
