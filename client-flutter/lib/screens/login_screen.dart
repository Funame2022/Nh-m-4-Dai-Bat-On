import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController =
      TextEditingController(text: 'phuhuynh@xetruong.vn');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _busCtrl;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _busCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _busCtrl.dispose();
    _entryCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['ok'] == true) {
      widget.onLoginSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['loi']?.toString() ?? 'Đăng nhập thất bại'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.emeraldGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'VN · INT4211',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showInfoDialog(
                        'BusCare Phụ Huynh',
                        'Hệ thống theo dõi xe đưa đón học sinh — Đề tài 07 (Nhóm 01).',
                      ),
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),

              // ── Form Card ────────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _entryCtrl,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _entryCtrl,
                          curve: Curves.easeOutCubic,
                        )),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo + Tiêu đề giống ảnh mẫu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus_rounded,
                                    color: AppTheme.emerald,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'XE TRƯỜNG ĐIỆN TỬ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'Theo dõi hành trình an toàn cho bé',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Frosted Glass Container
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Tài khoản phụ huynh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                          color: Colors.black87),
                                      decoration: InputDecoration(
                                        hintText: 'Nhập email phụ huynh',
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                          color: AppTheme.emerald,
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Vui lòng nhập email';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Email không hợp lệ';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      style: const TextStyle(
                                          color: Colors.black87),
                                      decoration: InputDecoration(
                                        hintText: 'Nhập mật khẩu',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          color: AppTheme.emerald,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Vui lòng nhập mật khẩu';
                                        }
                                        if (v.length < 6) {
                                          return 'Mật khẩu tối thiểu 6 ký tự';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppTheme.emeraldDark,
                                        minimumSize:
                                            const Size(double.infinity, 50),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: AppTheme.emerald,
                                              ),
                                            )
                                          : const Text(
                                              'ĐĂNG NHẬP',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _FrostedLink(
                                          icon: Icons.support_agent_rounded,
                                          label: 'Hỗ trợ',
                                          onTap: () => _showInfoDialog(
                                            'Hỗ trợ phụ huynh',
                                            'Tài khoản test: phuhuynh@xetruong.vn / 123456.\nNếu quên mật khẩu, liên hệ nhà trường để được cấp lại.',
                                          ),
                                        ),
                                        _FrostedLink(
                                          icon: Icons.info_outline_rounded,
                                          label: 'Thông tin',
                                          onTap: () => _showInfoDialog(
                                            'Thông tin ứng dụng',
                                            'BusCare Phụ Huynh v1.0\nĐồ án cuối kỳ INT4211 · Đề tài 7 · Nhóm 01',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Animated City & Moving Bus Footer ────────────────────────
              SizedBox(
                height: 120,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _busCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CityBusPainter(progress: _busCtrl.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostedLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FrostedLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vẽ nền thành phố + mây + xe buýt chạy ngang mượt mà
class _CityBusPainter extends CustomPainter {
  final double progress;

  _CityBusPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final buildingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13);

    // Skyline buildings
    final buildings = [
      Rect.fromLTWH(size.width * 0.05, 30, 44, size.height - 30),
      Rect.fromLTWH(size.width * 0.16, 14, 52, size.height - 14),
      Rect.fromLTWH(size.width * 0.30, 42, 38, size.height - 42),
      Rect.fromLTWH(size.width * 0.58, 22, 56, size.height - 22),
      Rect.fromLTWH(size.width * 0.74, 8, 48, size.height - 8),
      Rect.fromLTWH(size.width * 0.87, 36, 40, size.height - 36),
    ];
    for (final b in buildings) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(6)),
        buildingPaint,
      );
    }

    // Road
    final roadPaint = Paint()..color = Colors.black.withValues(alpha: 0.16);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 24, size.width, 24),
      roadPaint,
    );

    // Moving clouds
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    final cloudX = (size.width * (1.0 - progress));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cloudX, 12, 46, 14),
        const Radius.circular(8),
      ),
      cloudPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((cloudX + size.width * 0.5) % size.width, 26, 36, 12),
        const Radius.circular(8),
      ),
      cloudPaint,
    );

    // Moving Bus
    final busW = 112.0;
    final busX = -busW + (size.width + busW * 2) * progress;
    final busTop = size.height - 62.0;

    // Bus body
    final busBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(busX, busTop, busW, 38),
      const Radius.circular(10),
    );
    canvas.drawRRect(busBody, Paint()..color = const Color(0xFF1CE283));
    canvas.drawRRect(
      busBody,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Bus windows (warm orange glow)
    final winPaint = Paint()..color = const Color(0xFFFFD199);
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(busX + 10 + i * 22, busTop + 8, 17, 14),
          const Radius.circular(4),
        ),
        winPaint,
      );
    }

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1F2937);
    final hubPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(busX + 24, busTop + 38), 8, wheelPaint);
    canvas.drawCircle(Offset(busX + 24, busTop + 38), 3, hubPaint);
    canvas.drawCircle(Offset(busX + 86, busTop + 38), 8, wheelPaint);
    canvas.drawCircle(Offset(busX + 86, busTop + 38), 3, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _CityBusPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
