import 'package:flutter/material.dart';

String dinhDangNgay(DateTime? ngay) {
  if (ngay == null) return 'Chưa có';
  final ngayText = ngay.day.toString().padLeft(2, '0');
  final thangText = ngay.month.toString().padLeft(2, '0');
  return '$ngayText/$thangText/${ngay.year}';
}

class TrangThaiDangTai extends StatelessWidget {
  const TrangThaiDangTai({super.key, required this.thongDiep});

  final String thongDiep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(thongDiep),
        ],
      ),
    );
  }
}

class TrangThaiLoi extends StatelessWidget {
  const TrangThaiLoi({
    super.key,
    required this.thongDiep,
    required this.onThuLai,
    this.retryKey,
  });

  final String thongDiep;
  final VoidCallback onThuLai;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(thongDiep, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                key: retryKey,
                onPressed: onThuLai,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrangThaiRong extends StatelessWidget {
  const TrangThaiRong({
    super.key,
    required this.icon,
    required this.thongDiep,
    required this.onLamMoi,
    this.refreshKey,
  });

  final IconData icon;
  final String thongDiep;
  final VoidCallback onLamMoi;
  final Key? refreshKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(thongDiep, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: refreshKey,
                onPressed: onLamMoi,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
