import 'package:flutter/material.dart';

import '../../fleet/quan_ly_service.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/trang_thai_danh_sach.dart';

class TaiXePage extends StatefulWidget {
  const TaiXePage({super.key, required this.service});

  final QuanLyService service;

  @override
  State<TaiXePage> createState() => _TaiXePageState();
}

class _TaiXePageState extends State<TaiXePage> {
  List<TaiXe> _danhSach = [];
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
      final danhSach = await widget.service.layDanhSachTaiXe();
      if (!mounted) return;
      setState(() => _danhSach = danhSach);
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      setState(() => _loi = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loi = 'Không thể tải danh sách tài xế.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Future<void> _moTao() async {
    final thanhCong = await showDialog<bool>(
      context: context,
      builder: (context) => TaiXeFormDialog(
        onSubmit: (duLieu) async {
          await widget.service.taoTaiXe(
            email: duLieu.email!,
            matKhau: duLieu.matKhau!,
            hoTen: duLieu.hoTen,
            sdt: duLieu.sdt,
            soGplx: duLieu.soGplx,
            hanGplx: duLieu.hanGplx,
          );
        },
      ),
    );
    if (!mounted || thanhCong != true) return;
    await _tai();
    if (mounted) _thongBao('Đã thêm tài xế.');
  }

  Future<void> _moSua(TaiXe taiXe) async {
    final thanhCong = await showDialog<bool>(
      context: context,
      builder: (context) => TaiXeFormDialog(
        taiXe: taiXe,
        onSubmit: (duLieu) async {
          await widget.service.capNhatTaiXe(
            taiXe.id,
            hoTen: duLieu.hoTen,
            sdt: duLieu.sdt,
            soGplx: duLieu.soGplx,
            hanGplx: duLieu.hanGplx,
          );
        },
      ),
    );
    if (!mounted || thanhCong != true) return;
    await _tai();
    if (mounted) _thongBao('Đã cập nhật tài xế.');
  }

  Future<void> _xoa(TaiXe taiXe) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài xế'),
        content: Text(
          'Tài khoản ${taiXe.email} sẽ bị xóa. Bạn chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            key: const Key('tai-xe-delete-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('tai-xe-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
    if (!mounted || xacNhan != true) return;

    try {
      await widget.service.xoaTaiXe(taiXe.id);
      if (!mounted) return;
      await _tai();
      if (mounted) _thongBao('Đã xóa tài xế.');
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      if (_laLoiTaiXeDangDuocTuyenSuDung(e)) {
        await _hienThiKhongTheXoa(taiXe);
      } else {
        _thongBao(e.message, laLoi: true);
      }
    } catch (_) {
      if (mounted) _thongBao('Không thể xóa tài xế.', laLoi: true);
    }
  }

  bool _laLoiTaiXeDangDuocTuyenSuDung(QuanLyApiException e) {
    return e.statusCode == 400 && e.message.contains('tuyen_tai_xe_id_fkey');
  }

  Future<void> _hienThiKhongTheXoa(TaiXe taiXe) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không thể xóa tài xế'),
        content: Text(
          'Tài xế ${taiXe.hoTen} đang được phân công cho một tuyến. '
          'Vui lòng phân công tài xế khác hoặc gỡ tài xế khỏi tuyến '
          'trước khi xóa.',
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
      return const TrangThaiDangTai(thongDiep: 'Đang tải danh sách tài xế...');
    }

    if (_loi != null && _danhSach.isEmpty) {
      return TrangThaiLoi(
        thongDiep: _loi!,
        onThuLai: _tai,
        retryKey: const Key('tai-xe-retry'),
      );
    }

    if (_danhSach.isEmpty) {
      return TrangThaiRong(
        icon: Icons.person_outline,
        thongDiep: 'Chưa có tài xế nào trong hệ thống.',
        onLamMoi: _tai,
        refreshKey: const Key('tai-xe-refresh'),
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
                final taiXe = _danhSach[index];
                return Card(
                  child: ListTile(
                    key: Key('tai-xe-row-${taiXe.id}'),
                    isThreeLine: true,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(taiXe.hoTen),
                    subtitle: Text(
                      '${taiXe.email}\n'
                      'SĐT: ${taiXe.sdt ?? 'Chưa có'} • '
                      'GPLX: ${taiXe.soGplx} • '
                      'Hạn: ${dinhDangNgay(taiXe.hanGplx)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('tai-xe-edit-${taiXe.id}'),
                          tooltip: 'Sửa tài xế',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _moSua(taiXe),
                        ),
                        IconButton(
                          key: Key('tai-xe-delete-${taiXe.id}'),
                          tooltip: 'Xóa tài xế',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _xoa(taiXe),
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
        key: const Key('tai-xe-add'),
        onPressed: _moTao,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Thêm tài xế'),
      ),
    );
  }
}

class TaiXeFormData {
  const TaiXeFormData({
    this.email,
    this.matKhau,
    required this.hoTen,
    this.sdt,
    required this.soGplx,
    this.hanGplx,
  });

  final String? email;
  final String? matKhau;
  final String hoTen;
  final String? sdt;
  final String soGplx;
  final DateTime? hanGplx;
}

class TaiXeFormDialog extends StatefulWidget {
  const TaiXeFormDialog({super.key, this.taiXe, required this.onSubmit});

  final TaiXe? taiXe;
  final Future<void> Function(TaiXeFormData duLieu) onSubmit;

  @override
  State<TaiXeFormDialog> createState() => _TaiXeFormDialogState();
}

class _TaiXeFormDialogState extends State<TaiXeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _matKhauController;
  late final TextEditingController _hoTenController;
  late final TextEditingController _sdtController;
  late final TextEditingController _soGplxController;
  DateTime? _hanGplx;
  bool _dangLuu = false;
  String? _loi;

  bool get _laSua => widget.taiXe != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.taiXe?.email ?? '');
    _matKhauController = TextEditingController();
    _hoTenController = TextEditingController(text: widget.taiXe?.hoTen ?? '');
    _sdtController = TextEditingController(text: widget.taiXe?.sdt ?? '');
    _soGplxController = TextEditingController(text: widget.taiXe?.soGplx ?? '');
    _hanGplx = widget.taiXe?.hanGplx;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _matKhauController.dispose();
    _hoTenController.dispose();
    _sdtController.dispose();
    _soGplxController.dispose();
    super.dispose();
  }

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final chon = await showDatePicker(
      context: context,
      initialDate: _hanGplx ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (chon != null && mounted) {
      setState(() => _hanGplx = chon);
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
      final sdt = _sdtController.text.trim();
      await widget.onSubmit(
        TaiXeFormData(
          email: _laSua ? null : _emailController.text.trim(),
          matKhau: _laSua ? null : _matKhauController.text,
          hoTen: _hoTenController.text.trim(),
          sdt: sdt.isEmpty ? null : sdt,
          soGplx: _soGplxController.text.trim(),
          hanGplx: _hanGplx,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on QuanLyApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Không thể lưu tài xế. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_laSua ? 'Sửa tài xế' : 'Thêm tài xế'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_laSua) ...[
                  Text(
                    'Email: ${widget.taiXe!.email}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email và mật khẩu không thể sửa tại đây.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  TextFormField(
                    key: const Key('tai-xe-form-email'),
                    controller: _emailController,
                    enabled: !_dangLuu,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Vui lòng nhập email';
                      if (!email.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('tai-xe-form-password'),
                    controller: _matKhauController,
                    enabled: !_dangLuu,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu *',
                      helperText: 'Tối thiểu 6 ký tự',
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const Key('tai-xe-form-name'),
                  controller: _hoTenController,
                  enabled: !_dangLuu,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Họ tên *'),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('tai-xe-form-phone'),
                  controller: _sdtController,
                  enabled: !_dangLuu,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('tai-xe-form-license'),
                  controller: _soGplxController,
                  enabled: !_dangLuu,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Số giấy phép lái xe *',
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Vui lòng nhập số giấy phép lái xe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('tai-xe-form-expiry'),
                  onPressed: _dangLuu ? null : _chonNgay,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _hanGplx == null
                        ? 'Chọn hạn GPLX (không bắt buộc)'
                        : 'Hạn GPLX: ${dinhDangNgay(_hanGplx)}',
                  ),
                ),
                if (_hanGplx != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('tai-xe-form-expiry-clear'),
                      onPressed: _dangLuu
                          ? null
                          : () => setState(() => _hanGplx = null),
                      child: const Text('Xóa hạn GPLX'),
                    ),
                  ),
                if (_loi != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loi!,
                    key: const Key('tai-xe-form-error'),
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
          key: const Key('tai-xe-form-cancel'),
          onPressed: _dangLuu ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const Key('tai-xe-form-save'),
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
