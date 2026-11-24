import 'package:flutter/material.dart';

import '../../../models/van_hanh.dart';
import 'hoc_sinh_item_widget.dart';

/// Widget quản lý tab danh sách học sinh kèm thanh tìm kiếm và bộ lọc trạng thái
class HocSinhListTabWidget extends StatefulWidget {
  const HocSinhListTabWidget({
    super.key,
    required this.chiTiet,
    required this.dangXuLyHocSinh,
    required this.onDiemDanhLenXe,
    required this.onDiemDanhXuongXe,
    this.onHocSinhTap,
  });

  final ChiTietChuyenDi chiTiet;
  final Set<int> dangXuLyHocSinh;
  final void Function(HocSinhDiemDanh hs) onDiemDanhLenXe;
  final void Function(HocSinhDiemDanh hs) onDiemDanhXuongXe;
  final void Function(HocSinhDiemDanh hs)? onHocSinhTap;

  @override
  State<HocSinhListTabWidget> createState() => _HocSinhListTabWidgetState();
}

class _HocSinhListTabWidgetState extends State<HocSinhListTabWidget>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _tuKhoa = '';
  TrangThaiHocSinh? _trangThaiLoc;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _datLaiBoLoc() {
    setState(() {
      _searchController.clear();
      _tuKhoa = '';
      _trangThaiLoc = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dsGoc = widget.chiTiet.hocSinh;

    if (dsGoc.isEmpty) {
      return const Center(
        child: Text('Chưa có học sinh nào đăng ký trên tuyến này.'),
      );
    }

    // Tra cứu tên trạm dừng
    final Map<int, String> diemDungMap = {
      for (final d in widget.chiTiet.diemDung) d.id: d.ten,
    };

    // Đếm số lượng theo trạng thái
    final soChuaLen = dsGoc.where((h) => h.trangThai == TrangThaiHocSinh.chuaLen).length;
    final soTrenXe = widget.chiTiet.soHocSinhTrenXe;
    final soDaXuong = widget.chiTiet.soHocSinhDaXuong;
    final soBaoNghi = widget.chiTiet.soHocSinhBaoNghi;

    // Lọc danh sách học sinh theo từ khóa và trạng thái
    final dsLoc = dsGoc.where((hs) {
      // 1. Lọc theo trạng thái
      if (_trangThaiLoc != null && hs.trangThai != _trangThaiLoc) {
        return false;
      }

      // 2. Lọc theo từ khóa tìm kiếm (họ tên, lớp, mã HS)
      if (_tuKhoa.isNotEmpty) {
        final query = _tuKhoa.toLowerCase();
        final matchTen = hs.hoTen.toLowerCase().contains(query);
        final matchLop = hs.tenLop.toLowerCase().contains(query);
        final matchMa = hs.maHs.toLowerCase().contains(query);
        if (!matchTen && !matchLop && !matchMa) {
          return false;
        }
      }

      return true;
    }).toList();

    return Column(
      children: [
        // Khung tìm kiếm và bộ lọc cố định phía trên
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh SearchBar
              TextField(
                key: const Key('input-tim-kiem-hoc-sinh'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, lớp, mã học sinh...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _tuKhoa.isNotEmpty
                      ? IconButton(
                          key: const Key('btn-clear-search-hoc-sinh'),
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _tuKhoa = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _tuKhoa = val.trim());
                },
              ),
              const SizedBox(height: 8),

              // Dải Chip Lọc trạng thái (cuộn ngang)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      keyName: 'filter-chip-tat-ca',
                      label: 'Tất cả (${dsGoc.length})',
                      isSelected: _trangThaiLoc == null,
                      onSelected: () => setState(() => _trangThaiLoc = null),
                      selectedColor: colors.primaryContainer,
                      selectedTextColor: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      keyName: 'filter-chip-chua-len',
                      label: 'Chưa lên ($soChuaLen)',
                      isSelected: _trangThaiLoc == TrangThaiHocSinh.chuaLen,
                      onSelected: () => setState(() => _trangThaiLoc = TrangThaiHocSinh.chuaLen),
                      selectedColor: colors.surfaceContainerHighest,
                      selectedTextColor: colors.onSurface,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      keyName: 'filter-chip-dang-tren-xe',
                      label: 'Đang trên xe ($soTrenXe)',
                      isSelected: _trangThaiLoc == TrangThaiHocSinh.dangTrenXe,
                      onSelected: () => setState(() => _trangThaiLoc = TrangThaiHocSinh.dangTrenXe),
                      selectedColor: Colors.blue.shade100,
                      selectedTextColor: Colors.blue.shade900,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      keyName: 'filter-chip-da-xuong',
                      label: 'Đã xuống ($soDaXuong)',
                      isSelected: _trangThaiLoc == TrangThaiHocSinh.daXuong,
                      onSelected: () => setState(() => _trangThaiLoc = TrangThaiHocSinh.daXuong),
                      selectedColor: Colors.green.shade100,
                      selectedTextColor: Colors.green.shade900,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      keyName: 'filter-chip-bao-nghi',
                      label: 'Báo nghỉ ($soBaoNghi)',
                      isSelected: _trangThaiLoc == TrangThaiHocSinh.baoNghi,
                      onSelected: () => setState(() => _trangThaiLoc = TrangThaiHocSinh.baoNghi),
                      selectedColor: Colors.orange.shade100,
                      selectedTextColor: Colors.orange.shade900,
                    ),
                  ],
                ),
              ),

              // Nhãn thống kê kết quả tìm kiếm khi có bộ lọc
              if (_tuKhoa.isNotEmpty || _trangThaiLoc != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        'Hiển thị ${dsLoc.length}/${dsGoc.length} học sinh',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        key: const Key('btn-reset-filters'),
                        onTap: _datLaiBoLoc,
                        child: Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 12),

        // Danh sách học sinh kết quả
        Expanded(
          child: dsLoc.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy học sinh nào phù hợp.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _datLaiBoLoc,
                          child: const Text('Xóa bộ lọc tìm kiếm'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: const PageStorageKey<String>('hoc-sinh-tab-list'),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: dsLoc.length,
                  itemBuilder: (context, index) {
                    final hs = dsLoc[index];
                    final tenTram = hs.diemDungId != null ? diemDungMap[hs.diemDungId] : null;

                    return HocSinhItemWidget(
                      key: ValueKey('hoc-sinh-${hs.id}'),
                      hocSinh: hs,
                      tenDiemDung: tenTram,
                      dangXuLy: widget.dangXuLyHocSinh.contains(hs.id),
                      onDiemDanhLenXe: () => widget.onDiemDanhLenXe(hs),
                      onDiemDanhXuongXe: () => widget.onDiemDanhXuongXe(hs),
                      onTap: widget.onHocSinhTap != null ? () => widget.onHocSinhTap!(hs) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String keyName,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color selectedColor,
    required Color selectedTextColor,
  }) {
    return ChoiceChip(
      key: Key(keyName),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? selectedTextColor : null,
      ),
      selectedColor: selectedColor,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
