import 'package:flutter/material.dart';

import '../../fleet/quan_ly_service.dart';
import '../../operations/quan_ly_operations_service.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/trang_thai_danh_sach.dart';

class TuyenPage extends StatefulWidget {
  const TuyenPage({
    super.key,
    required this.operationsService,
    required this.fleetService,
  });

  final QuanLyOperationsService operationsService;
  final QuanLyService fleetService;

  @override
  State<TuyenPage> createState() => _TuyenPageState();
}

class _TuyenPageState extends State<TuyenPage> {
  List<Tuyen> _tuyen = [];
  List<Xe> _xe = [];
  List<TaiXe> _taiXe = [];
  List<BaoMau> _baoMau = [];
  List<HocSinh> _hocSinh = [];

  int? _selectedId;
  List<DiemDung> _diemDung = [];
  List<DangKyTuyen> _dangKy = [];
  bool _dangTai = true;
  String? _loi;
  bool _dangTaiChiTiet = false;
  String? _loiChiTiet;
  int? _hocSinhChon;
  int? _diemDungChon;
  String _chieuChon = 'DON_SANG';

  @override
  void initState() {
    super.initState();
    _taiTatCa();
  }

  Future<void> _taiTatCa({int? selectId}) async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final tuyen = await widget.operationsService.layDanhSachTuyen();
      final xe = await widget.fleetService.layDanhSachXe();
      final taiXe = await widget.fleetService.layDanhSachTaiXe();
      final baoMau = await widget.operationsService.layDanhSachBaoMau();
      final hocSinh = await widget.operationsService.layDanhSachHocSinh();
      if (!mounted) return;

      setState(() {
        _tuyen = tuyen;
        _xe = xe;
        _taiXe = taiXe;
        _baoMau = baoMau;
        _hocSinh = hocSinh;
      });

      final idCanChon =
          selectId ?? _selectedId ?? (tuyen.isNotEmpty ? tuyen.first.id : null);
      if (idCanChon != null && tuyen.any((item) => item.id == idCanChon)) {
        await _chonTuyen(idCanChon);
      } else {
        setState(() {
          _selectedId = null;
          _diemDung = [];
          _dangKy = [];
          _hocSinhChon = null;
          _diemDungChon = null;
        });
      }
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      setState(() => _loi = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loi = 'Không thể tải dữ liệu tuyến.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Future<void> _chonTuyen(int id) async {
    setState(() {
      _selectedId = id;
      _dangTaiChiTiet = true;
      _loiChiTiet = null;
    });

    try {
      final diemDung = await widget.operationsService.layDanhSachDiemDung(id);
      final dangKy = await widget.operationsService.layDanhSachDangKyTuyen(
        tuyenId: id,
      );
      if (!mounted) return;

      setState(() {
        _diemDung = diemDung;
        _dangKy = dangKy;
        if (_hocSinhChon == null ||
            !_hocSinh.any((hocSinh) => hocSinh.id == _hocSinhChon)) {
          _hocSinhChon = _hocSinh.isNotEmpty ? _hocSinh.first.id : null;
        }
        if (_diemDungChon == null ||
            !diemDung.any((diem) => diem.id == _diemDungChon)) {
          _diemDungChon = diemDung.isNotEmpty ? diemDung.first.id : null;
        }
      });
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      setState(() => _loiChiTiet = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loiChiTiet = 'Không thể tải chi tiết tuyến.');
    } finally {
      if (mounted) setState(() => _dangTaiChiTiet = false);
    }
  }

  Future<void> _moTaoTuyen() async {
    final tuyenMoi = await showDialog<Tuyen>(
      context: context,
      builder: (context) => TuyenFormDialog(
        danhSachXe: _xe,
        danhSachTaiXe: _taiXe,
        danhSachBaoMau: _baoMau,
        onSubmit: (duLieu) => widget.operationsService.taoTuyen(
          tenTuyen: duLieu.tenTuyen,
          xeId: duLieu.xeId,
          taiXeId: duLieu.taiXeId,
          baoMauId: duLieu.baoMauId,
          danhSachDiemDung: duLieu.danhSachDiemDung,
        ),
      ),
    );
    if (!mounted || tuyenMoi == null) return;
    await _taiTatCa(selectId: tuyenMoi.id);
    if (mounted) _thongBao('Đã thêm tuyến.');
  }

  Future<void> _moSuaTuyen(Tuyen tuyen) async {
    final daSua = await showDialog<Tuyen>(
      context: context,
      builder: (context) => TuyenFormDialog(
        tuyen: tuyen,
        danhSachXe: _xe,
        danhSachTaiXe: _taiXe,
        danhSachBaoMau: _baoMau,
        onSubmit: (duLieu) => widget.operationsService.capNhatTuyen(
          tuyen.id,
          tenTuyen: duLieu.tenTuyen,
          xeId: duLieu.xeId,
          taiXeId: duLieu.taiXeId,
          baoMauId: duLieu.baoMauId,
        ),
      ),
    );
    if (!mounted || daSua == null) return;
    await _taiTatCa(selectId: daSua.id);
    if (mounted) _thongBao('Đã cập nhật tuyến.');
  }

  Future<void> _xoaTuyen(Tuyen tuyen) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tuyến'),
        content: Text('Bạn chắc chắn muốn xóa tuyến ${tuyen.tenTuyen}?'),
        actions: [
          TextButton(
            key: const Key('tuyen-delete-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('tuyen-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || xacNhan != true) return;

    try {
      await widget.operationsService.xoaTuyen(tuyen.id);
      if (!mounted) return;
      setState(() {
        _selectedId = null;
        _diemDung = [];
        _dangKy = [];
      });
      await _taiTatCa();
      if (mounted) _thongBao('Đã xóa tuyến.');
    } on QuanLyApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        await _hienThiKhongTheXoaTuyen(e.message);
      } else {
        _thongBao(e.message, laLoi: true);
      }
    } catch (_) {
      if (mounted) _thongBao('Không thể xóa tuyến.', laLoi: true);
    }
  }

  Future<void> _hienThiKhongTheXoaTuyen(String thongDiep) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không thể xóa tuyến'),
        content: Text(thongDiep),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _moSuaDiemDung(DiemDung diemDung) async {
    final tuyenId = _selectedId;
    if (tuyenId == null) return;

    final thanhCong = await showDialog<bool>(
      context: context,
      builder: (context) => DiemDungFormDialog(
        diemDung: diemDung,
        danhSachHienCo: _diemDung,
        onSubmit: (duLieu) => widget.operationsService.capNhatDiemDung(
          tuyenId,
          diemDung.id,
          thuTu: duLieu.thuTu,
          ten: duLieu.ten,
          viDo: duLieu.viDo,
          kinhDo: duLieu.kinhDo,
          gioDuKien: duLieu.gioDuKien,
        ),
      ),
    );
    if (!mounted || thanhCong != true) return;
    await _chonTuyen(tuyenId);
    if (mounted) _thongBao('Đã cập nhật điểm dừng.');
  }

  Future<void> _ganHocSinh() async {
    final tuyenId = _selectedId;
    final hocSinhId = _hocSinhChon;
    final diemDungId = _diemDungChon;
    if (tuyenId == null || hocSinhId == null || diemDungId == null) {
      return;
    }

    try {
      await widget.operationsService.taoDangKyTuyen(
        hocSinhId: hocSinhId,
        tuyenId: tuyenId,
        diemDungId: diemDungId,
        chieu: _chieuChon,
      );
      if (!mounted) return;
      await _chonTuyen(tuyenId);
      if (mounted) {
        _thongBao(
          'Đã lưu đăng ký. Đăng ký cùng chiều cũ đã được thay thế nếu có.',
        );
      }
    } on QuanLyApiException catch (e) {
      if (mounted) _thongBao(e.message, laLoi: true);
    } catch (_) {
      if (mounted) _thongBao('Không thể phân công học sinh.', laLoi: true);
    }
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

  Tuyen? _tuyenDangChon() {
    for (final tuyen in _tuyen) {
      if (tuyen.id == _selectedId) return tuyen;
    }
    return null;
  }

  String _nhanChieu(String chieu) {
    return chieu == 'TRA_CHIEU'
        ? 'Trả chiều (TRA_CHIEU)'
        : 'Đón sáng (DON_SANG)';
  }

  Widget _noiDung(BuildContext context) {
    if (_dangTai && _tuyen.isEmpty) {
      return const TrangThaiDangTai(thongDiep: 'Đang tải danh sách tuyến...');
    }

    if (_loi != null && _tuyen.isEmpty) {
      return TrangThaiLoi(
        thongDiep: _loi!,
        onThuLai: _taiTatCa,
        retryKey: const Key('tuyen-retry'),
      );
    }

    if (_tuyen.isEmpty) {
      return TrangThaiRong(
        icon: Icons.route_outlined,
        thongDiep: 'Chưa có tuyến nào trong hệ thống.',
        onLamMoi: _taiTatCa,
        refreshKey: const Key('tuyen-refresh'),
      );
    }

    final tuyen = _tuyenDangChon();
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => _taiTatCa(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text('Danh sách tuyến', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_dangTai) const LinearProgressIndicator(),
          if (_loi != null) _BangLoi(thongDiep: _loi!, onThuLai: _taiTatCa),
          const SizedBox(height: 8),
          ..._tuyen.map(
            (tuyen) => _TheTuyen(
              tuyen: tuyen,
              dangChon: tuyen.id == _selectedId,
              onChon: () => _chonTuyen(tuyen.id),
              onSua: () => _moSuaTuyen(tuyen),
              onXoa: () => _xoaTuyen(tuyen),
            ),
          ),
          if (tuyen != null) ...[
            const SizedBox(height: 24),
            _chiTietTuyen(context, tuyen),
          ],
        ],
      ),
    );
  }

  Widget _chiTietTuyen(BuildContext context, Tuyen tuyen) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết tuyến: ${tuyen.tenTuyen}',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('Xe: ${tuyen.bienSo ?? tuyen.xeId}'),
            Text('Tài xế: ${tuyen.tenTaiXe ?? tuyen.taiXeId}'),
            Text('Bảo mẫu: ${tuyen.tenBaoMau ?? 'Chưa phân công'}'),
          ],
        ),
        const SizedBox(height: 16),
        if (_dangTaiChiTiet) const LinearProgressIndicator(),
        if (_loiChiTiet != null)
          _BangLoi(
            thongDiep: _loiChiTiet!,
            onThuLai: () => _chonTuyen(tuyen.id),
          ),
        Text('Điểm dừng', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_diemDung.isEmpty)
          const Text('Chưa có điểm dừng.')
        else
          ..._diemDung.map(
            (diem) => Card(
              child: ListTile(
                key: Key('diem-dung-row-${diem.id}'),
                title: Text(diem.ten),
                subtitle: Text(
                  'Thứ tự ${diem.thuTu} • '
                  '${diem.viDo}, ${diem.kinhDo} • '
                  '${diem.gioDuKien ?? 'Chưa có giờ'}',
                ),
                trailing: IconButton(
                  key: Key('diem-dung-edit-${diem.id}'),
                  tooltip: 'Sửa điểm dừng',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _moSuaDiemDung(diem),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text('Đăng ký hiện tại', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_dangKy.isEmpty)
          const Text('Chưa có đăng ký.')
        else
          ..._dangKy.map(
            (dangKy) => Card(
              child: ListTile(
                key: Key('assignment-row-${dangKy.hocSinhId}-${dangKy.chieu}'),
                leading: const Icon(Icons.how_to_reg_outlined),
                title: Text(
                  '${dangKy.hoTen ?? 'Học sinh ${dangKy.hocSinhId}'} • '
                  '${_nhanChieu(dangKy.chieu)}',
                ),
                subtitle: Text(
                  'Điểm dừng: ${dangKy.tenDiemDung ?? dangKy.diemDungId}',
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text('Phân công học sinh', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Nếu học sinh đã có đăng ký cùng chiều, đăng ký mới sẽ thay thế '
          'đăng ký cũ.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (_hocSinh.isEmpty || _diemDung.isEmpty)
          const Text('Chưa có học sinh hoặc điểm dừng để phân công.')
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: _DropdownChon<int>(
                  key: const Key('assignment-student'),
                  nhan: 'Học sinh',
                  giaTri: _hocSinhChon,
                  items: _hocSinh
                      .map(
                        (hocSinh) => DropdownMenuItem<int>(
                          value: hocSinh.id,
                          child: Text(hocSinh.hoTen),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _hocSinhChon = value),
                ),
              ),
              SizedBox(
                width: 240,
                child: _DropdownChon<int>(
                  key: const Key('assignment-stop'),
                  nhan: 'Điểm dừng',
                  giaTri: _diemDungChon,
                  items: _diemDung
                      .map(
                        (diem) => DropdownMenuItem<int>(
                          value: diem.id,
                          child: Text(diem.ten),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _diemDungChon = value),
                ),
              ),
              SizedBox(
                width: 220,
                child: _DropdownChon<String>(
                  key: const Key('assignment-chieu'),
                  nhan: 'Chiều',
                  giaTri: _chieuChon,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'DON_SANG',
                      child: Text('Đón sáng (DON_SANG)'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'TRA_CHIEU',
                      child: Text('Trả chiều (TRA_CHIEU)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _chieuChon = value);
                  },
                ),
              ),
              FilledButton.icon(
                key: const Key('assignment-submit'),
                onPressed: _ganHocSinh,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Phân công'),
              ),
            ],
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
        key: const Key('tuyen-add'),
        onPressed: _moTaoTuyen,
        icon: const Icon(Icons.add),
        label: const Text('Thêm tuyến'),
      ),
    );
  }
}

class _TheTuyen extends StatelessWidget {
  const _TheTuyen({
    required this.tuyen,
    required this.dangChon,
    required this.onChon,
    required this.onSua,
    required this.onXoa,
  });

  final Tuyen tuyen;
  final bool dangChon;
  final VoidCallback onChon;
  final VoidCallback onSua;
  final VoidCallback onXoa;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: Key('tuyen-row-${tuyen.id}'),
        selected: dangChon,
        onTap: onChon,
        leading: const CircleAvatar(child: Icon(Icons.route_outlined)),
        title: Text(tuyen.tenTuyen),
        subtitle: Text(
          'Xe: ${tuyen.bienSo ?? tuyen.xeId} • '
          'Tài xế: ${tuyen.tenTaiXe ?? tuyen.taiXeId} • '
          'Bảo mẫu: ${tuyen.tenBaoMau ?? 'Chưa phân công'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('tuyen-edit-${tuyen.id}'),
              tooltip: 'Sửa tuyến',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onSua,
            ),
            IconButton(
              key: Key('tuyen-delete-${tuyen.id}'),
              tooltip: 'Xóa tuyến',
              icon: const Icon(Icons.delete_outline),
              onPressed: onXoa,
            ),
          ],
        ),
      ),
    );
  }
}

class _BangLoi extends StatelessWidget {
  const _BangLoi({required this.thongDiep, required this.onThuLai});

  final String thongDiep;
  final VoidCallback onThuLai;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              thongDiep,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onThuLai, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _DropdownChon<T> extends StatelessWidget {
  const _DropdownChon({
    super.key,
    required this.nhan,
    required this.giaTri,
    required this.items,
    required this.onChanged,
  });

  final String nhan;
  final T? giaTri;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: nhan,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: giaTri,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class TuyenFormData {
  const TuyenFormData({
    required this.tenTuyen,
    required this.xeId,
    required this.taiXeId,
    this.baoMauId,
    this.danhSachDiemDung = const [],
  });

  final String tenTuyen;
  final int xeId;
  final int taiXeId;
  final int? baoMauId;
  final List<DiemDungMoi> danhSachDiemDung;
}

class TuyenFormDialog extends StatefulWidget {
  const TuyenFormDialog({
    super.key,
    this.tuyen,
    required this.danhSachXe,
    required this.danhSachTaiXe,
    required this.danhSachBaoMau,
    required this.onSubmit,
  });

  final Tuyen? tuyen;
  final List<Xe> danhSachXe;
  final List<TaiXe> danhSachTaiXe;
  final List<BaoMau> danhSachBaoMau;
  final Future<Tuyen> Function(TuyenFormData duLieu) onSubmit;

  @override
  State<TuyenFormDialog> createState() => _TuyenFormDialogState();
}

class _TuyenFormDialogState extends State<TuyenFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tenController;
  final List<_DongDiemDung> _dsDiemDung = [];
  int? _xeId;
  int? _taiXeId;
  int? _baoMauId;
  bool _dangLuu = false;
  String? _loi;

  bool get _laSua => widget.tuyen != null;

  @override
  void initState() {
    super.initState();
    _tenController = TextEditingController(text: widget.tuyen?.tenTuyen ?? '');
    _xeId =
        widget.tuyen?.xeId ??
        (widget.danhSachXe.isNotEmpty ? widget.danhSachXe.first.id : null);
    _taiXeId =
        widget.tuyen?.taiXeId ??
        (widget.danhSachTaiXe.isNotEmpty
            ? widget.danhSachTaiXe.first.id
            : null);
    _baoMauId = widget.tuyen?.baoMauId;
    if (!_laSua) _dsDiemDung.add(_DongDiemDung());
  }

  @override
  void dispose() {
    _tenController.dispose();
    for (final dong in _dsDiemDung) {
      dong.dispose();
    }
    super.dispose();
  }

  void _themDiemDung() {
    setState(() {
      _dsDiemDung.add(_DongDiemDung(thuTu: '${_dsDiemDung.length + 1}'));
    });
  }

  void _xoaDiemDung(int index) {
    if (_dsDiemDung.length <= 1) return;
    setState(() {
      _dsDiemDung.removeAt(index).dispose();
    });
  }

  Future<void> _luu() async {
    if (_dangLuu) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_xeId == null || _taiXeId == null) {
      setState(() => _loi = 'Vui lòng chọn xe và tài xế.');
      return;
    }

    final danhSachDiemDung = <DiemDungMoi>[];
    final thuTuDaDung = <int>{};
    if (!_laSua) {
      for (final dong in _dsDiemDung) {
        final thuTu = int.parse(dong.thuTu.text.trim());
        if (!thuTuDaDung.add(thuTu)) {
          setState(() => _loi = 'Thứ tự điểm dừng không được trùng.');
          return;
        }
        danhSachDiemDung.add(
          DiemDungMoi(
            thuTu: thuTu,
            ten: dong.ten.text.trim(),
            viDo: double.parse(dong.viDo.text.trim()),
            kinhDo: double.parse(dong.kinhDo.text.trim()),
            gioDuKien: dong.gio.text.trim().isEmpty
                ? null
                : dong.gio.text.trim(),
          ),
        );
      }
    }

    setState(() {
      _dangLuu = true;
      _loi = null;
    });

    try {
      final tuyen = await widget.onSubmit(
        TuyenFormData(
          tenTuyen: _tenController.text.trim(),
          xeId: _xeId!,
          taiXeId: _taiXeId!,
          baoMauId: _baoMauId,
          danhSachDiemDung: danhSachDiemDung,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(tuyen);
    } on QuanLyApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Không thể lưu tuyến. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  String? _validateThuTu(String? value) {
    final so = int.tryParse(value?.trim() ?? '');
    if (so == null || so <= 0) return 'TT > 0';
    return null;
  }

  String? _validateToaDo(String? value, double nhoNhat, double lonNhat) {
    final so = double.tryParse(value?.trim() ?? '');
    if (so == null || !so.isFinite || so < nhoNhat || so > lonNhat) {
      return 'Không hợp lệ';
    }
    return null;
  }

  String? _validateGio(String? value) {
    final gio = value?.trim() ?? '';
    if (gio.isEmpty) return null;
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(gio)) {
      return 'HH:mm';
    }
    return null;
  }

  Widget _dongDiemDung(int index, _DongDiemDung dong) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    key: Key('tuyen-form-stop-$index-thu-tu'),
                    controller: dong.thuTu,
                    enabled: !_dangLuu,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'TT *'),
                    validator: _validateThuTu,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: Key('tuyen-form-stop-$index-ten'),
                    controller: dong.ten,
                    enabled: !_dangLuu,
                    decoration: const InputDecoration(
                      labelText: 'Tên điểm dừng *',
                    ),
                    validator: (value) {
                      if ((value?.trim() ?? '').isEmpty) {
                        return 'Vui lòng nhập tên điểm dừng';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('tuyen-form-stop-$index-vi-do'),
                    controller: dong.viDo,
                    enabled: !_dangLuu,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Vĩ độ *'),
                    validator: (value) => _validateToaDo(value, -90, 90),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: Key('tuyen-form-stop-$index-kinh-do'),
                    controller: dong.kinhDo,
                    enabled: !_dangLuu,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Kinh độ *'),
                    validator: (value) => _validateToaDo(value, -180, 180),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    key: Key('tuyen-form-stop-$index-gio'),
                    controller: dong.gio,
                    enabled: !_dangLuu,
                    decoration: const InputDecoration(labelText: 'HH:mm'),
                    validator: _validateGio,
                  ),
                ),
                IconButton(
                  key: Key('tuyen-form-remove-stop-$index'),
                  tooltip: 'Xóa điểm dừng',
                  onPressed: _dangLuu || _dsDiemDung.length <= 1
                      ? null
                      : () => _xoaDiemDung(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baoMauHopLe =
        widget.danhSachBaoMau.any((baoMau) => baoMau.id == _baoMauId)
        ? _baoMauId
        : null;

    return AlertDialog(
      title: Text(_laSua ? 'Sửa tuyến' : 'Thêm tuyến'),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('tuyen-form-ten'),
                  controller: _tenController,
                  enabled: !_dangLuu,
                  decoration: const InputDecoration(labelText: 'Tên tuyến *'),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Vui lòng nhập tên tuyến';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DropdownChon<int>(
                        key: const Key('tuyen-form-xe'),
                        nhan: 'Xe *',
                        giaTri: _xeId,
                        items: widget.danhSachXe
                            .map(
                              (xe) => DropdownMenuItem<int>(
                                value: xe.id,
                                child: Text(xe.bienSo),
                              ),
                            )
                            .toList(),
                        onChanged: _dangLuu
                            ? (_) {}
                            : (value) => setState(() => _xeId = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DropdownChon<int>(
                        key: const Key('tuyen-form-tai-xe'),
                        nhan: 'Tài xế *',
                        giaTri: _taiXeId,
                        items: widget.danhSachTaiXe
                            .map(
                              (taiXe) => DropdownMenuItem<int>(
                                value: taiXe.id,
                                child: Text(taiXe.hoTen),
                              ),
                            )
                            .toList(),
                        onChanged: _dangLuu
                            ? (_) {}
                            : (value) => setState(() => _taiXeId = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DropdownChon<int?>(
                  key: const Key('tuyen-form-bao-mau'),
                  nhan: 'Bảo mẫu',
                  giaTri: baoMauHopLe,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Không phân công'),
                    ),
                    ...widget.danhSachBaoMau.map(
                      (baoMau) => DropdownMenuItem<int?>(
                        value: baoMau.id,
                        child: Text(baoMau.hoTen),
                      ),
                    ),
                  ],
                  onChanged: _dangLuu
                      ? (_) {}
                      : (value) => setState(() => _baoMauId = value),
                ),
                if (!_laSua) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Điểm dừng', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        key: const Key('tuyen-form-add-stop'),
                        onPressed: _dangLuu ? null : _themDiemDung,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm điểm dừng'),
                      ),
                    ],
                  ),
                  ..._dsDiemDung.asMap().entries.map(
                    (entry) => _dongDiemDung(entry.key, entry.value),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    'Sửa điểm dừng ở phần chi tiết tuyến sau khi lưu.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_loi != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loi!,
                    key: const Key('tuyen-form-error'),
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
          key: const Key('tuyen-form-cancel'),
          onPressed: _dangLuu ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const Key('tuyen-form-save'),
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

class _DongDiemDung {
  _DongDiemDung({
    String? thuTu,
    String? ten,
    String? viDo,
    String? kinhDo,
    String? gio,
  }) : thuTu = TextEditingController(text: thuTu ?? ''),
       ten = TextEditingController(text: ten ?? ''),
       viDo = TextEditingController(text: viDo ?? ''),
       kinhDo = TextEditingController(text: kinhDo ?? ''),
       gio = TextEditingController(text: gio ?? '');

  final TextEditingController thuTu;
  final TextEditingController ten;
  final TextEditingController viDo;
  final TextEditingController kinhDo;
  final TextEditingController gio;

  void dispose() {
    thuTu.dispose();
    ten.dispose();
    viDo.dispose();
    kinhDo.dispose();
    gio.dispose();
  }
}

class DiemDungFormData {
  const DiemDungFormData({
    required this.thuTu,
    required this.ten,
    required this.viDo,
    required this.kinhDo,
    this.gioDuKien,
  });

  final int thuTu;
  final String ten;
  final double viDo;
  final double kinhDo;
  final String? gioDuKien;
}

class DiemDungFormDialog extends StatefulWidget {
  const DiemDungFormDialog({
    super.key,
    required this.diemDung,
    required this.danhSachHienCo,
    required this.onSubmit,
  });

  final DiemDung diemDung;
  final List<DiemDung> danhSachHienCo;
  final Future<DiemDung> Function(DiemDungFormData duLieu) onSubmit;

  @override
  State<DiemDungFormDialog> createState() => _DiemDungFormDialogState();
}

class _DiemDungFormDialogState extends State<DiemDungFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _thuTuController;
  late final TextEditingController _tenController;
  late final TextEditingController _viDoController;
  late final TextEditingController _kinhDoController;
  late final TextEditingController _gioController;
  bool _dangLuu = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _thuTuController = TextEditingController(
      text: widget.diemDung.thuTu.toString(),
    );
    _tenController = TextEditingController(text: widget.diemDung.ten);
    _viDoController = TextEditingController(
      text: widget.diemDung.viDo.toString(),
    );
    _kinhDoController = TextEditingController(
      text: widget.diemDung.kinhDo.toString(),
    );
    _gioController = TextEditingController(
      text: widget.diemDung.gioDuKien ?? '',
    );
  }

  @override
  void dispose() {
    _thuTuController.dispose();
    _tenController.dispose();
    _viDoController.dispose();
    _kinhDoController.dispose();
    _gioController.dispose();
    super.dispose();
  }

  String? _validateThuTu(String? value) {
    final so = int.tryParse(value?.trim() ?? '');
    if (so == null || so <= 0) return 'TT > 0';
    final trung = widget.danhSachHienCo.any(
      (diem) => diem.id != widget.diemDung.id && diem.thuTu == so,
    );
    if (trung) return 'Thứ tự đã được dùng';
    return null;
  }

  String? _validateToaDo(String? value, double nhoNhat, double lonNhat) {
    final so = double.tryParse(value?.trim() ?? '');
    if (so == null || !so.isFinite || so < nhoNhat || so > lonNhat) {
      return 'Không hợp lệ';
    }
    return null;
  }

  String? _validateGio(String? value) {
    final gio = value?.trim() ?? '';
    if (gio.isEmpty) return null;
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(gio)) {
      return 'HH:mm';
    }
    return null;
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
        DiemDungFormData(
          thuTu: int.parse(_thuTuController.text.trim()),
          ten: _tenController.text.trim(),
          viDo: double.parse(_viDoController.text.trim()),
          kinhDo: double.parse(_kinhDoController.text.trim()),
          gioDuKien: _gioController.text.trim().isEmpty
              ? null
              : _gioController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on QuanLyApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Không thể lưu điểm dừng. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Sửa điểm dừng'),
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
                  key: const Key('diem-dung-form-thu-tu'),
                  controller: _thuTuController,
                  enabled: !_dangLuu,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Thứ tự *'),
                  validator: _validateThuTu,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('diem-dung-form-ten'),
                  controller: _tenController,
                  enabled: !_dangLuu,
                  decoration: const InputDecoration(labelText: 'Tên điểm *'),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Vui lòng nhập tên điểm dừng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('diem-dung-form-vi-do'),
                        controller: _viDoController,
                        enabled: !_dangLuu,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Vĩ độ *'),
                        validator: (value) => _validateToaDo(value, -90, 90),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: const Key('diem-dung-form-kinh-do'),
                        controller: _kinhDoController,
                        enabled: !_dangLuu,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Kinh độ *',
                        ),
                        validator: (value) => _validateToaDo(value, -180, 180),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('diem-dung-form-gio'),
                  controller: _gioController,
                  enabled: !_dangLuu,
                  decoration: const InputDecoration(
                    labelText: 'Giờ dự kiến (HH:mm)',
                  ),
                  validator: _validateGio,
                ),
                if (_loi != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loi!,
                    key: const Key('diem-dung-form-error'),
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
          key: const Key('diem-dung-form-cancel'),
          onPressed: _dangLuu ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const Key('diem-dung-form-save'),
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
