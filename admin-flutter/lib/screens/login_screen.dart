import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../config/api_config.dart';
import '../models/nguoi_dung.dart';
import '../widgets/brand_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  final AuthService authService;
  final ValueChanged<NguoiDung> onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _matKhauController = TextEditingController();

  bool _dangDangNhap = false;
  bool _hienMatKhau = false;
  bool _dangTaiTaiKhoan = true;
  bool _ghiNhoTaiKhoan = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiTaiKhoanDaGhiNho();
  }

  Future<void> _taiTaiKhoanDaGhiNho() async {
    try {
      final email = await widget.authService.readRememberedEmail();
      if (!mounted) return;
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
        _ghiNhoTaiKhoan = true;
      }
    } catch (_) {
      // A missing saved email should not prevent signing in.
    } finally {
      if (mounted) {
        setState(() => _dangTaiTaiKhoan = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    if (_dangDangNhap) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _dangDangNhap = true;
      _loi = null;
    });

    try {
      final nguoiDung = await widget.authService.login(
        email: _emailController.text.trim(),
        matKhau: _matKhauController.text,
      );
      try {
        if (_ghiNhoTaiKhoan) {
          await widget.authService.rememberEmail(_emailController.text.trim());
        } else {
          await widget.authService.clearRememberedEmail();
        }
      } catch (_) {
        // A preference write failure must not turn a successful login into an error.
      }
      if (!mounted) return;
      widget.onLoginSuccess(nguoiDung);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _loi = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Đăng nhập thất bại. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _dangDangNhap = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chuaCauHinh = !widget.authService.daCauHinh;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: BrandBackground(
              key: const Key('login-background-art'),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 640;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 22 : 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.asset(
                                      BrandAssets.logo,
                                      key: const Key('login-brand-logo'),
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'BusCare For Admin',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                        color: colors.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Đăng nhập dành cho quản lý',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: compact ? 24 : 30),
                                TextFormField(
                                  key: const Key('login-email'),
                                  controller: _emailController,
                                  enabled:
                                      !_dangDangNhap &&
                                      !_dangTaiTaiKhoan &&
                                      !chuaCauHinh,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration(
                                    theme,
                                    label: 'Email',
                                    icon: Icons.mail_outline_rounded,
                                  ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!email.contains('@')) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: compact ? 14 : 18),
                                TextFormField(
                                  key: const Key('login-password'),
                                  controller: _matKhauController,
                                  enabled: !_dangDangNhap && !chuaCauHinh,
                                  obscureText: !_hienMatKhau,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.done,
                                  decoration:
                                      _inputDecoration(
                                        theme,
                                        label: 'Mật khẩu',
                                        icon: Icons.lock_outline_rounded,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          key: const Key(
                                            'login-password-visibility',
                                          ),
                                          tooltip: _hienMatKhau
                                              ? 'Ẩn mật khẩu'
                                              : 'Hiện mật khẩu',
                                          onPressed: () => setState(
                                            () => _hienMatKhau = !_hienMatKhau,
                                          ),
                                          icon: Icon(
                                            _hienMatKhau
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                          ),
                                        ),
                                      ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _dangNhap(),
                                ),
                                Material(
                                  type: MaterialType.transparency,
                                  child: CheckboxListTile(
                                    key: const Key('login-remember-account'),
                                    value: _ghiNhoTaiKhoan,
                                    onChanged: _dangDangNhap || _dangTaiTaiKhoan
                                        ? null
                                        : (remember) => setState(
                                            () => _ghiNhoTaiKhoan =
                                                remember ?? false,
                                          ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(
                                      'Ghi nhớ tài khoản',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ),
                                if (chuaCauHinh) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    ApiConfig.thongDiepChuaCauHinh,
                                    key: const Key('login-config-message'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: colors.error),
                                  ),
                                ],
                                if (_loi != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    key: const Key('login-error'),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.errorContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 20,
                                          color: colors.onErrorContainer,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _loi!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colors.onErrorContainer,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: compact ? 12 : 18),
                                SizedBox(
                                  height: 50,
                                  child: FilledButton(
                                    key: const Key('login-submit'),
                                    onPressed:
                                        chuaCauHinh ||
                                            _dangDangNhap ||
                                            _dangTaiTaiKhoan
                                        ? null
                                        : _dangNhap,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: _dangDangNhap
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Đăng nhập'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String label,
    required IconData icon,
  }) {
    final colors = theme.colorScheme;
    final border = UnderlineInputBorder(
      borderSide: BorderSide(color: colors.outlineVariant),
    );

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: colors.error)),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
    );
  }
}
