import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Màn hình Tài khoản — Hỗ trợ Thêm / Sửa / Xóa ảnh đại diện phụ huynh + Đổi tên + Đổi mật khẩu
class ProfileScreen extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onToggleTheme;
  final VoidCallback onLogout;
  final Future<void> Function() onSessionExpired;
  final VoidCallback? onProfileChanged;

  const ProfileScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onSessionExpired,
    this.onProfileChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _nguoiDung;
  String? _avatarB64;
  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = await ApiService.getNguoiDungHienTai();
    final avatar = await ApiService.getParentAvatarBase64();
    if (!mounted) return;
    setState(() {
      _nguoiDung = cached;
      _avatarB64 = avatar;
      _loading = false;
    });
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      await ApiService.saveParentAvatarBase64(b64);
      if (!mounted) return;
      setState(() => _avatarB64 = b64);
      widget.onProfileChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật ảnh đại diện!'),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chọn ảnh trên thiết bị này'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ảnh đại diện phụ huynh',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE6F6ED),
                child: Icon(Icons.photo_library_rounded,
                    color: AppTheme.emerald),
              ),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF0E6),
                child: Icon(Icons.camera_alt_rounded,
                    color: AppTheme.warmOrange),
              ),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
            if (_avatarB64 != null && _avatarB64!.isNotEmpty)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFDECEC),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                ),
                title: const Text(
                  'Xóa ảnh đại diện',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ApiService.clearParentAvatar();
                  if (!mounted) return;
                  setState(() => _avatarB64 = null);
                  widget.onProfileChanged?.call();
                },
              ),
          ],
        ),
      ),
    );
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
      widget.onProfileChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật họ tên'),
          backgroundColor: AppTheme.emerald,
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
          backgroundColor: AppTheme.emerald,
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
      appBar: AppBar(title: const Text('Tài khoản cá nhân')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // ── Profile Header Card với nút Sửa ảnh đại diện ────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.emeraldGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emerald.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarOptions,
                        child: Stack(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey(_avatarB64?.length ?? 0),
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border:
                                      Border.all(color: Colors.white, width: 2.5),
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(19),
                                  child: (_avatarB64 != null &&
                                          _avatarB64!.isNotEmpty)
                                      ? Image.memory(
                                          base64Decode(_avatarB64!),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.person_rounded,
                                          size: 42, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppTheme.warmOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nguoiDung?['hoTen']?.toString() ?? 'Phụ huynh',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _nguoiDung?['email']?.toString() ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _showAvatarOptions,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Chạm để đổi ảnh đại diện',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined,
                            color: AppTheme.emerald),
                        title: const Text('Số điện thoại'),
                        subtitle: Text(
                            _nguoiDung?['sdt']?.toString() ?? 'Chưa cập nhật'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined,
                            color: AppTheme.emerald),
                        title: const Text('Đổi họ tên hiển thị'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showEditNameDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded,
                            color: AppTheme.emerald),
                        title: const Text('Đổi mật khẩu'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showChangePasswordDialog,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(Icons.dark_mode_outlined,
                            color: scheme.primary),
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
                        leading: Icon(Icons.directions_bus_outlined,
                            color: AppTheme.emerald),
                        title: Text('BusCare Phụ Huynh'),
                        subtitle: Text('Nhóm 01 · INT4211 · Đề tài 07'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded,
                            color: Colors.redAccent),
                        title: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
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
