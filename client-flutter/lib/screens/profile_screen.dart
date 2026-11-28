import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_bus_banner.dart';

/// Màn hình Tài khoản — Tối ưu cache ảnh avatar + sửa lỗi crash đổi tên/mật khẩu
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
  Uint8List? _avatarBytes;
  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = await ApiService.getNguoiDungHienTai();
    final avatarB64 = await ApiService.getParentAvatarBase64();
    Uint8List? decoded;
    if (avatarB64 != null && avatarB64.isNotEmpty) {
      try {
        decoded = base64Decode(avatarB64);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _nguoiDung = cached;
      _avatarBytes = decoded;
      _loading = false;
    });
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      await ApiService.saveParentAvatarBase64(b64);
      if (!mounted) return;
      setState(() => _avatarBytes = bytes);
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
            if (_avatarBytes != null)
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
                  setState(() => _avatarBytes = null);
                  widget.onProfileChanged?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog() async {
    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditNameDialog(
        initialName: _nguoiDung?['hoTen']?.toString() ?? '',
        onSessionExpired: widget.onSessionExpired,
      ),
    );

    if (newName != null && mounted) {
      setState(() {
        _nguoiDung = {
          ...(_nguoiDung ?? {}),
          'hoTen': newName,
        };
      });
      widget.onProfileChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật họ tên thành công!'),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePasswordDialog(
        onSessionExpired: widget.onSessionExpired,
      ),
    );

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
                // ── Profile Header Card với nền xe buýt giống ảnh mẫu ───────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      const CityBusBackdrop(height: 150, animateBus: false),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _showAvatarOptions,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                          color: Colors.white, width: 2.5),
                                      color: Colors.white
                                          .withValues(alpha: 0.25),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(19),
                                      child: _avatarBytes != null
                                          ? Image.memory(
                                              _avatarBytes!,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            )
                                          : const Icon(Icons.person_rounded,
                                              size: 42, color: Colors.white),
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
                                      child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 14),
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
                                    _nguoiDung?['hoTen']?.toString() ??
                                        'Phụ huynh',
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
                                        color:
                                            Colors.white.withValues(alpha: 0.22),
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

/// Dialog riêng tự quản lý TextEditingController để không bao giờ crash khi đóng
class _EditNameDialog extends StatefulWidget {
  final String initialName;
  final Future<void> Function() onSessionExpired;

  const _EditNameDialog({
    required this.initialName,
    required this.onSessionExpired,
  });

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final newName = _controller.text.trim();
    try {
      final err = await ApiService.updateProfileName(newName);
      if (!mounted) return;
      if (err == null) {
        Navigator.pop(context, newName);
      } else {
        setState(() {
          _saving = false;
          _error = err;
        });
      }
    } on SessionExpiredException {
      if (mounted) Navigator.pop(context);
      await widget.onSessionExpired();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi họ tên'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              enabled: !_saving,
              autofocus: true,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập họ tên'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

/// Dialog riêng cho Đổi mật khẩu — tránh crash dispose controller
class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function() onSessionExpired;

  const _ChangePasswordDialog({required this.onSessionExpired});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final err =
          await ApiService.changePassword(_oldCtrl.text, _newCtrl.text);
      if (!mounted) return;
      if (err == null) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _saving = false;
          _error = err;
        });
      }
    } on SessionExpiredException {
      if (mounted) Navigator.pop(context, false);
      await widget.onSessionExpired();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _oldCtrl,
              enabled: !_saving,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nhập mật khẩu hiện tại' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCtrl,
              enabled: !_saving,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới (tối thiểu 8 ký tự)'),
              validator: (v) => (v == null || v.length < 8)
                  ? 'Mật khẩu mới phải từ 8 ký tự'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}
