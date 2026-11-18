import 'dart:convert';

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../models/nguoi_dung.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.nguoiDung,
    required this.authService,
    required this.isDark,
    required this.onToggleTheme,
    required this.onRename,
    required this.onUserUpdated,
    required this.onSwitchAccount,
    required this.onLogout,
  });

  final NguoiDung nguoiDung;
  final AuthService authService;
  final bool isDark;
  final Future<void> Function() onToggleTheme;
  final Future<NguoiDung> Function(String hoTen) onRename;
  final ValueChanged<NguoiDung> onUserUpdated;
  final Future<void> Function() onSwitchAccount;
  final Future<void> Function() onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _loadingNotificationPreference = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final enabled = await widget.authService.readNotificationsEnabled();
      if (mounted) setState(() => _notificationsEnabled = enabled);
    } catch (_) {
      // Keep notifications disabled when local preferences cannot be read.
    } finally {
      if (mounted) setState(() => _loadingNotificationPreference = false);
    }
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    final previous = _notificationsEnabled;
    setState(() => _notificationsEnabled = enabled);
    try {
      await widget.authService.saveNotificationsEnabled(enabled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _notificationsEnabled = previous);
      _showMessage('Không thể lưu cài đặt thông báo trên thiết bị.');
    }
  }

  Future<void> _changeName() async {
    final updatedUser = await showDialog<NguoiDung>(
      context: context,
      builder: (_) => _ChangeNameDialog(
        initialName: widget.nguoiDung.hoTen,
        onSave: widget.onRename,
      ),
    );
    if (updatedUser != null && mounted) {
      widget.onUserUpdated(updatedUser);
      _showMessage('Đã cập nhật tên tài khoản.');
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(authService: widget.authService),
    );
    if (changed == true && mounted) {
      _showMessage('Đã đổi mật khẩu.');
    }
  }

  Future<void> _confirmAccountAction({required bool switchAccount}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(switchAccount ? 'Đổi tài khoản' : 'Đăng xuất'),
        content: Text(
          switchAccount
              ? 'Bạn sẽ được đưa về màn hình đăng nhập để dùng tài khoản khác.'
              : 'Bạn có chắc muốn đăng xuất khỏi tài khoản này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('settings-confirm-action'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(switchAccount ? 'Tiếp tục' : 'Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (switchAccount) {
      await widget.onSwitchAccount();
    } else {
      await widget.onLogout();
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'BusCare For Admin',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.directions_bus_filled,
        color: Theme.of(context).colorScheme.primary,
        size: 36,
      ),
      children: const [Text('Ứng dụng quản lý xe đưa đón học sinh.')],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Card(
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0) const Divider(height: 1, indent: 56),
                  children[index],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: const Icon(Icons.person_outline),
            ),
            title: Text(widget.nguoiDung.hoTen),
            subtitle: Text(widget.nguoiDung.email),
          ),
        ),
        const SizedBox(height: 20),
        _section('Giao diện', [
          SwitchListTile(
            key: const Key('settings-theme-toggle'),
            secondary: Icon(
              widget.isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            title: const Text('Giao diện tối'),
            subtitle: Text(widget.isDark ? 'Đang bật' : 'Đang tắt'),
            value: widget.isDark,
            onChanged: (_) => widget.onToggleTheme(),
          ),
        ]),
        _section('Tài khoản', [
          ListTile(
            key: const Key('settings-rename'),
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Đổi tên'),
            subtitle: const Text('Cập nhật tên hiển thị của bạn'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeName,
          ),
          ListTile(
            key: const Key('settings-change-password'),
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            subtitle: const Text('Cập nhật mật khẩu đăng nhập'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
        ]),
        _section('Thông báo', [
          SwitchListTile(
            key: const Key('settings-notifications-toggle'),
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Thông báo trên thiết bị'),
            subtitle: const Text(
              'Lưu lựa chọn trên thiết bị. Hệ thống chưa kết nối dịch vụ gửi thông báo.',
            ),
            value: _notificationsEnabled,
            onChanged: _loadingNotificationPreference
                ? null
                : _setNotificationsEnabled,
          ),
        ]),
        _section('Khác', [
          ListTile(
            key: const Key('settings-switch-account'),
            leading: const Icon(Icons.switch_account_outlined),
            title: const Text('Đổi tài khoản'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmAccountAction(switchAccount: true),
          ),
          ListTile(
            key: const Key('settings-logout'),
            leading: Icon(Icons.logout, color: colors.error),
            title: Text('Đăng xuất', style: TextStyle(color: colors.error)),
            onTap: () => _confirmAccountAction(switchAccount: false),
          ),
          ListTile(
            key: const Key('settings-about'),
            leading: const Icon(Icons.info_outline),
            title: const Text('Giới thiệu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),
        ]),
      ],
    );
  }
}

class _ChangeNameDialog extends StatefulWidget {
  const _ChangeNameDialog({required this.initialName, required this.onSave});

  final String initialName;
  final Future<NguoiDung> Function(String hoTen) onSave;

  @override
  State<_ChangeNameDialog> createState() => _ChangeNameDialogState();
}

class _ChangeNameDialogState extends State<_ChangeNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || name.length > 120) {
      setState(() => _error = 'Tên cần có từ 1 đến 120 ký tự.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = await widget.onSave(name);
      if (mounted) Navigator.pop(context, user);
    } on AuthException catch (exception) {
      if (mounted) setState(() => _error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể cập nhật tên. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đổi tên'),
    content: TextField(
      key: const Key('settings-name-field'),
      controller: _controller,
      autofocus: true,
      maxLength: 120,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: 'Tên hiển thị', errorText: _error),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        key: const Key('settings-name-save'),
        onPressed: _saving ? null : _save,
        child: const Text('Lưu'),
      ),
    ],
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.authService});

  final AuthService authService;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentController.text;
    final next = _newController.text;
    if (current.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu hiện tại.');
      return;
    }
    if (next.length < 8 || utf8.encode(next).length > 72) {
      setState(
        () => _error = 'Mật khẩu mới cần từ 8 ký tự và không quá 72 byte.',
      );
      return;
    }
    if (next != _confirmController.text) {
      setState(() => _error = 'Mật khẩu nhập lại chưa khớp.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.authService.doiMatKhau(
        matKhauHienTai: current,
        matKhauMoi: next,
      );
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (exception) {
      if (mounted) setState(() => _error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể đổi mật khẩu. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đổi mật khẩu'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('settings-current-password'),
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('settings-new-password'),
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu mới',
              helperText: 'Tối thiểu 8 ký tự; tối đa 72 byte',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('settings-confirm-password'),
            controller: _confirmController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nhập lại mật khẩu mới',
              errorText: _error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        key: const Key('settings-password-save'),
        onPressed: _saving ? null : _save,
        child: const Text('Cập nhật'),
      ),
    ],
  );
}
