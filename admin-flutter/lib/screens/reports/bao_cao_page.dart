import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../fleet/quan_ly_service.dart';
import '../../operations/quan_ly_operations_service.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/trang_thai_danh_sach.dart';

class BaoCaoPage extends StatefulWidget {
  const BaoCaoPage({super.key, required this.service});

  final QuanLyOperationsService service;

  @override
  State<BaoCaoPage> createState() => _BaoCaoPageState();
}

class _BaoCaoPageState extends State<BaoCaoPage> {
  late DateTime _ngayChon;
  ThongKe? _thongKe;
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ngayChon = DateTime(now.year, now.month, now.day);
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final thongKe = await widget.service.layThongKe(ngay: _ngayChon);
      if (!mounted) return;
      setState(() => _thongKe = thongKe);
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      setState(() => _loi = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loi = 'Không thể tải báo cáo thống kê.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final chon = await showDatePicker(
      context: context,
      initialDate: _ngayChon,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (chon == null || !mounted) return;

    setState(() {
      _ngayChon = DateTime(chon.year, chon.month, chon.day);
    });
    await _tai();
  }

  String _dinhDangNgay(DateTime ngay) {
    final ngayText = ngay.day.toString().padLeft(2, '0');
    final thangText = ngay.month.toString().padLeft(2, '0');
    return '$ngayText/$thangText/${ngay.year}';
  }

  Widget _noiDung(BuildContext context) {
    if (_dangTai && _thongKe == null) {
      return const TrangThaiDangTai(thongDiep: 'Đang tải báo cáo thống kê...');
    }

    if (_loi != null && _thongKe == null) {
      return TrangThaiLoi(
        thongDiep: _loi!,
        onThuLai: _tai,
        retryKey: const Key('bao-cao-retry'),
      );
    }

    if (_thongKe == null) {
      return TrangThaiRong(
        icon: Icons.insights_outlined,
        thongDiep: 'Chưa có dữ liệu báo cáo.',
        onLamMoi: _tai,
        refreshKey: const Key('bao-cao-refresh'),
      );
    }

    final thongKe = _thongKe!;
    final hoanThanh = math.max(0, thongKe.chuyenHoanThanh);
    final chuaHoanThanh = math.max(
      0,
      thongKe.tongChuyenNgay - thongKe.chuyenHoanThanh,
    );
    final daLenXe = math.max(0, thongKe.soDaLenXe);
    final baoNghi = math.max(0, thongKe.soBaoNghi);
    final theme = Theme.of(context);
    final mau = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Báo cáo ngày ${_dinhDangNgay(_ngayChon)}',
                style: theme.textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              key: const Key('bao-cao-chon-ngay'),
              onPressed: _chonNgay,
              icon: const Icon(Icons.event_outlined),
              label: const Text('Chọn ngày'),
            ),
          ],
        ),
        if (_dangTai) const LinearProgressIndicator(),
        if (_loi != null)
          Container(
            color: mau.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loi!,
                    style: TextStyle(color: mau.onErrorContainer),
                  ),
                ),
                TextButton(onPressed: _tai, child: const Text('Thử lại')),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              key: const Key('bao-cao-kpi-xe'),
              nhan: 'Tổng xe',
              giaTri: thongKe.tongXe,
            ),
            _KpiCard(
              key: const Key('bao-cao-kpi-tuyen'),
              nhan: 'Tổng tuyến',
              giaTri: thongKe.tongTuyen,
            ),
            _KpiCard(
              key: const Key('bao-cao-kpi-hoc-sinh'),
              nhan: 'Tổng học sinh',
              giaTri: thongKe.tongHocSinh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _BieuDoCot(
          key: const Key('bao-cao-chart-chuyen'),
          tieuDe: 'Chuyến đi',
          nhan1: 'Hoàn thành: $hoanThanh',
          nhan2: 'Chưa hoàn thành: $chuaHoanThanh',
          giaTri1: hoanThanh,
          giaTri2: chuaHoanThanh,
          mau1: mau.primary,
          mau2: mau.tertiary,
          semanticsLabel:
              'Biểu đồ chuyến đi: hoàn thành $hoanThanh, '
              'chưa hoàn thành $chuaHoanThanh',
        ),
        const SizedBox(height: 16),
        _BieuDoCot(
          key: const Key('bao-cao-chart-hoc-sinh'),
          tieuDe: 'Học sinh',
          nhan1: 'Đã lên xe: $daLenXe',
          nhan2: 'Báo nghỉ: $baoNghi',
          giaTri1: daLenXe,
          giaTri2: baoNghi,
          mau1: mau.primary,
          mau2: mau.error,
          semanticsLabel:
              'Biểu đồ học sinh: đã lên xe $daLenXe, báo nghỉ $baoNghi',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(child: _noiDung(context)),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({super.key, required this.nhan, required this.giaTri});

  final String nhan;
  final int giaTri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: SizedBox(
        width: 150,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('$giaTri', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(nhan, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _BieuDoCot extends StatelessWidget {
  const _BieuDoCot({
    super.key,
    required this.tieuDe,
    required this.nhan1,
    required this.nhan2,
    required this.giaTri1,
    required this.giaTri2,
    required this.mau1,
    required this.mau2,
    required this.semanticsLabel,
  });

  final String tieuDe;
  final String nhan1;
  final String nhan2;
  final int giaTri1;
  final int giaTri2;
  final Color mau1;
  final Color mau2;
  final String semanticsLabel;

  BarChartData _duLieu(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = math.max(1, math.max(giaTri1, giaTri2)).toDouble();
    final interval = math.max(1, (maxY / 5).ceil()).toDouble();

    return BarChartData(
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: giaTri1.toDouble(),
              color: mau1,
              width: 28,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: giaTri2.toDouble(),
              color: mau2,
              width: 28,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ],
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: interval,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tieuDe, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: Semantics(
                container: true,
                label: semanticsLabel,
                child: BarChart(_duLieu(context)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ChuThich(mau: mau1, nhan: nhan1),
                _ChuThich(mau: mau2, nhan: nhan2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChuThich extends StatelessWidget {
  const _ChuThich({required this.mau, required this.nhan});

  final Color mau;
  final String nhan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: mau, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(nhan),
      ],
    );
  }
}
