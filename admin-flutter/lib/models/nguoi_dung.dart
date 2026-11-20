class NguoiDung {
  const NguoiDung({
    required this.id,
    required this.email,
    required this.hoTen,
    required this.vaiTro,
    this.sdt,
  });

  final int id;
  final String email;
  final String hoTen;
  final String vaiTro;
  final String? sdt;

  bool get laQuanLy => vaiTro == 'QUAN_LY';
  bool get laTaiXe => vaiTro == 'TAI_XE';
  bool get laBaoMau => vaiTro == 'BAO_MAU';
  bool get laNhanVienVanHanh => laTaiXe || laBaoMau;
  bool get coQuyenAdminApp => laQuanLy || laTaiXe || laBaoMau;

  String get tenVaiTro {
    switch (vaiTro) {
      case 'QUAN_LY':
        return 'Quản lý';
      case 'TAI_XE':
        return 'Tài xế';
      case 'BAO_MAU':
        return 'Bảo mẫu';
      case 'PHU_HUYNH':
        return 'Phụ huynh';
      default:
        return vaiTro;
    }
  }

  factory NguoiDung.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final hoTen = json['hoTen'] ?? json['ho_ten'];
    final vaiTro = json['vaiTro'] ?? json['vai_tro'];

    if (id is! num || hoTen is! String || vaiTro is! String) {
      throw const FormatException('Thiếu thông tin người dùng');
    }

    return NguoiDung(
      id: id.toInt(),
      email: json['email'] is String ? json['email'] as String : '',
      hoTen: hoTen,
      vaiTro: vaiTro,
      sdt: json['sdt'] is String ? json['sdt'] as String : null,
    );
  }
}
