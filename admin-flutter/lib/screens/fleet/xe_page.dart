import 'package:flutter/material.dart';

import '../../fleet/quan_ly_service.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/trang_thai_danh_sach.dart';

class XePage extends StatefulWidget {
  const XePage({super.key, required this.service});

  final QuanLyService service;

  @override
  State<XePage> createState() => _XePageState();
}

class _XePageState extends State<XePage> {
  List<Xe> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final danhSach = await widget.service.layDanhSachXe();
      if (!mounted) return;
      setState(() => _danhSach = danhSach);
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      setState(() => _loi = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loi = 'Không thể tải danh sách xe.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Future<void> _moTao() async {
    final thanhCong = await showDialog<bool>(
      context: context,
      builder: (context) => XeFormDialog(
        onSubmit: (duLieu) async {
          await widget.service.taoXe(
            bienSo: duLieu.bienSo,
            sucChua: duLieu.sucChua,
            hanDangKiem: duLieu.hanDangKiem,
          );
        },
      ),
    );
    if (!mounted || thanhCong != true) return;
    await _tai();
    if (mounted) _thongBao('Đã thêm xe.');
  }

  Future<void> _moSua(Xe xe) async {
    final thanhCong = await showDialog<bool>(
      context: context,
      builder: (context) => XeFormDialog(
        xe: xe,
        onSubmit: (duLieu) async {
          await widget.service.capNhatXe(
            xe.id,
            bienSo: duLieu.bienSo,
            sucChua: duLieu.sucChua,
            hanDangKiem: duLieu.hanDangKiem,
          );
        },
      ),
    );
    if (!mounted || thanhCong != true) return;
    await _tai();
    if (mounted) _thongBao('Đã cập nhật xe.');
  }

  Future<void> _xoa(Xe xe) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa xe'),
        content: Text('Bạn chắc chắn muốn xóa xe ${xe.bienSo}?'),
        actions: [
          TextButton(
            key: const Key('xe-delete-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('xe-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || xacNhan != true) return;

    try {
      await widget.service.xoaXe(xe.id);
      if (!mounted) return;
      await _tai();
      if (mounted) _thongBao('Đã xóa xe.');
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      if (_laLoiXeDangDuocTuyenSuDung(e)) {
        await _hienThiKhongTheXoa(xe);
      } else {
        _thongBao(e.message, laLoi: true);
      }
    } catch (_) {
      if (mounted) _thongBao('Không thể xóa xe.', laLoi: true);
    }
  }

  bool _laLoiXeDangDuocTuyenSuDung(QuanLyApiException e) {
    return e.statusCode == 400 && e.message.contains('tuyen_xe_id_fkey');
  }

  Future<void> _hienThiKhongTheXoa(Xe xe) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không thể xóa xe'),
        content: Text(
          'Xe ${xe.bienSo} đang được phân công cho một tuyến. '
          'Vui lòng đổi xe khác hoặc gỡ xe khỏi tuyến trước khi xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _thongBao(String thongDiep, {bool laLoi = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(thongDiep),
          backgroundColor: laLoi ? theme.colorScheme.error : null,
        ),
      );
  }

  Widget _noiDung(BuildContext context) {
    if (_dangTai && _danhSach.isEmpty) {
      return const TrangThaiDangTai(thongDiep: 'Đang tải danh sách xe...');
    }

    if (_loi != null && _danhSach.isEmpty) {
      return TrangThaiLoi(
        thongDiep: _loi!,
        onThuLai: _tai,
        retryKey: const Key('xe-retry'),
      );
    }

    if (_danhSach.isEmpty) {
      return TrangThaiRong(
        icon: Icons.directions_bus_outlined,
        thongDiep: 'Chưa có xe nào trong hệ thống.',
        onLamMoi: _tai,
        refreshKey: const Key('xe-refresh'),
      );
    }

    final theme = Theme.of(context);
    return Column(
      children: [
        if (_dangTai) const LinearProgressIndicator(),
        if (_loi != null)
          Container(
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loi!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                TextButton(onPressed: _tai, child: const Text('Thử lại')),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _tai,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: _danhSach.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final xe = _danhSach[index];
                return Card(
                  child: ListTile(
                    key: Key('xe-row-${xe.id}'),
                    leading: const CircleAvatar(
                      child: Icon(Icons.directions_bus_outlined),
                    ),
                    title: Text(xe.bienSo),
                    subtitle: Text(
                      'Sức chứa: ${xe.sucChua} • '
                      'Đăng kiểm: ${dinhDangNgay(xe.hanDangKiem)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('xe-edit-${xe.id}'),
                          tooltip: 'Sửa xe',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _moSua(xe),
                        ),
                        IconButton(
                          key: Key('xe-delete-${xe.id}'),
                          tooltip: 'Xóa xe',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _xoa(xe),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(child: _noiDung(context)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('xe-add'),
        onPressed: _moTao,
        icon: const Icon(Icons.add),
        label: const Text('Thêm xe'),
      ),
    );
  }
}

class XeFormData {
  const XeFormData({
    required this.bienSo,
    required this.sucChua,
    this.hanDangKiem,
  });

  final String bienSo;
  final int sucChua;
  final DateTime? hanDangKiem;
}

class XeFormDialog extends StatefulWidget {
  const XeFormDialog({super.key, this.xe, required this.onSubmit});

  final Xe? xe;
  final Future<void> Function(XeFormData duLieu) onSubmit;

  @override
  State<XeFormDialog> createState() => _XeFormDialogState();
}

class _XeFormDialogState extends State<XeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bienSoController;
  late final TextEditingController _sucChuaController;
  DateTime? _hanDangKiem;
  bool _dangLuu = false;
  String? _loi;

  bool get _laSua => widget.xe != null;

  @override
  void initState() {
    super.initState();
    _bienSoController = TextEditingController(text: widget.xe?.bienSo ?? '');
    _sucChuaController = TextEditingController(
      text: widget.xe?.sucChua.toString() ?? '',
    );
    _hanDangKiem = widget.xe?.hanDangKiem;
  }

  @override
  void dispose() {
    _bienSoController.dispose();
    _sucChuaController.dispose();
    super.dispose();
  }

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final chon = await showDatePicker(
      context: context,
      initialDate: _hanDangKiem ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (chon != null && mounted) {
      setState(() => _hanDangKiem = chon);
    }
  }

  Future<void> _luu() async {
    if (_dangLuu) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _dangLuu = true;
      _loi = null;
    });

    try {
      await widget.onSubmit(
        XeFormData(
          bienSo: _bienSoController.text.trim(),
          sucChua: int.parse(_sucChuaController.text.trim()),
          hanDangKiem: _hanDangKiem,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on QuanLyApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Không thể lưu xe. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_laSua ? 'Sửa xe' : 'Thêm xe'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('xe-form-plate'),
                  controller: _bienSoController,
                  enabled: !_dangLuu,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Biển số *'),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Vui lòng nhập biển số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('xe-form-capacity'),
                  controller: _sucChuaController,
                  enabled: !_dangLuu,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Sức chứa *'),
                  validator: (value) {
                    final so = int.tryParse(value?.trim() ?? '');
                    if (so == null || so <= 0) {
                      return 'Sức chứa phải là số nguyên dương';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('xe-form-date'),
                  onPressed: _dangLuu ? null : _chonNgay,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _hanDangKiem == null
                        ? 'Chọn ngày đăng kiểm (không bắt buộc)'
                        : 'Đăng kiểm: ${dinhDangNgay(_hanDangKiem)}',
                  ),
                ),
                if (_hanDangKiem != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('xe-form-date-clear'),
                      onPressed: _dangLuu
                          ? null
                          : () => setState(() => _hanDangKiem = null),
                      child: const Text('Xóa ngày đăng kiểm'),
                    ),
                  ),
                if (_loi != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loi!,
                    key: const Key('xe-form-error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('xe-form-cancel'),
          onPressed: _dangLuu ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const Key('xe-form-save'),
          onPressed: _dangLuu ? null : _luu,
          child: _dangLuu
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
