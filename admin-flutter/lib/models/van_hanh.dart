import 'package:flutter/foundation.dart';

/// Chiều của chuyến đi xe buýt trường
enum ChieuChuyen {
  donSang('DON_SANG', 'Đón sáng (Nhà ➔ Trường)'),
  traChieu('TRA_CHIEU', 'Trả chiều (Trường ➔ Nhà)');

  const ChieuChuyen(this.ma, this.ten);
  final String ma;
  final String ten;

  static ChieuChuyen fromString(String? val) {
    if (val == 'TRA_CHIEU' || val == 'TRA') return ChieuChuyen.traChieu;
    return ChieuChuyen.donSang;
  }
}

/// Trạng thái chuyến đi
enum TrangThaiChuyen {
  chuaChay('CHUA_CHAY', 'Chưa chạy'),
  dangChay('DANG_CHAY', 'Đang chạy'),
  hoanThanh('HOAN_THANH', 'Hoàn thành');

  const TrangThaiChuyen(this.ma, this.ten);
  final String ma;
  final String ten;

  static TrangThaiChuyen fromString(String? val) {
    switch (val) {
      case 'DANG_CHAY':
        return TrangThaiChuyen.dangChay;
      case 'HOAN_THANH':
        return TrangThaiChuyen.hoanThanh;
      default:
        return TrangThaiChuyen.chuaChay;
    }
  }
}

/// Trạng thái của học sinh trên chuyến đi
enum TrangThaiHocSinh {
  baoNghi('Nghỉ có phép'),
  chuaLen('Chưa lên xe'),
  dangTrenXe('Đang trên xe'),
  daXuong('Đã xuống xe');

  const TrangThaiHocSinh(this.moTa);
  final String moTa;
}

/// Thông tin chuyến đi tóm tắt trong ngày
@immutable
class ChuyenDi {
  const ChuyenDi({
    required this.id,
    required this.tuyenId,
    required this.ngay,
    required this.chieu,
    required this.trangThai,
    this.batDauLuc,
    this.ketThucLuc,
    required this.tenTuyen,
    required this.bienSo,
  });

  final int id;
  final int tuyenId;
  final String ngay;
  final ChieuChuyen chieu;
  final TrangThaiChuyen trangThai;
  final DateTime? batDauLuc;
  final DateTime? ketThucLuc;
  final String tenTuyen;
  final String bienSo;

  bool get laChuaChay => trangThai == TrangThaiChuyen.chuaChay;
  bool get laDangChay => trangThai == TrangThaiChuyen.dangChay;
  bool get laHoanThanh => trangThai == TrangThaiChuyen.hoanThanh;

  factory ChuyenDi.fromJson(Map<String, dynamic> json) {
    return ChuyenDi(
      id: (json['id'] as num).toInt(),
      tuyenId: (json['tuyen_id'] ?? json['tuyenId'] as num?)?.toInt() ?? 0,
      ngay: (json['ngay'] ?? '').toString(),
      chieu: ChieuChuyen.fromString(json['chieu'] as String?),
      trangThai: TrangThaiChuyen.fromString(
        json['trang_thai'] ?? json['trangThai'] as String?,
      ),
      batDauLuc: json['bat_dau_luc'] != null
          ? DateTime.tryParse(json['bat_dau_luc'].toString())
          : (json['batDauLuc'] != null
              ? DateTime.tryParse(json['batDauLuc'].toString())
              : null),
      ketThucLuc: json['ket_thuc_luc'] != null
          ? DateTime.tryParse(json['ket_thuc_luc'].toString())
          : (json['ketThucLuc'] != null
              ? DateTime.tryParse(json['ketThucLuc'].toString())
              : null),
      tenTuyen: (json['ten_tuyen'] ?? json['tenTuyen'] ?? 'Tuyến xe').toString(),
      bienSo: (json['bien_so'] ?? json['bienSo'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tuyen_id': tuyenId,
    'ngay': ngay,
    'chieu': chieu.ma,
    'trang_thai': trangThai.ma,
    'bat_dau_luc': batDauLuc?.toIso8601String(),
    'ket_thuc_luc': ketThucLuc?.toIso8601String(),
    'ten_tuyen': tenTuyen,
    'bien_so': bienSo,
  };

  ChuyenDi copyWith({
    int? id,
    int? tuyenId,
    String? ngay,
    ChieuChuyen? chieu,
    TrangThaiChuyen? trangThai,
    DateTime? batDauLuc,
    DateTime? ketThucLuc,
    String? tenTuyen,
    String? bienSo,
  }) {
    return ChuyenDi(
      id: id ?? this.id,
      tuyenId: tuyenId ?? this.tuyenId,
      ngay: ngay ?? this.ngay,
      chieu: chieu ?? this.chieu,
      trangThai: trangThai ?? this.trangThai,
      batDauLuc: batDauLuc ?? this.batDauLuc,
      ketThucLuc: ketThucLuc ?? this.ketThucLuc,
      tenTuyen: tenTuyen ?? this.tenTuyen,
      bienSo: bienSo ?? this.bienSo,
    );
  }
}

/// Điểm dừng dọc theo tuyến
@immutable
class DiemDung {
  const DiemDung({
    required this.id,
    required this.tuyenId,
    required this.thuTu,
    required this.ten,
    required this.viDo,
    required this.kinhDo,
    this.gioDuKien,
  });

  final int id;
  final int tuyenId;
  final int thuTu;
  final String ten;
  final double viDo;
  final double kinhDo;
  final String? gioDuKien;

  factory DiemDung.fromJson(Map<String, dynamic> json) {
    return DiemDung(
      id: (json['id'] as num).toInt(),
      tuyenId: (json['tuyen_id'] ?? json['tuyenId'] as num?)?.toInt() ?? 0,
      thuTu: (json['thu_tu'] ?? json['thuTu'] as num?)?.toInt() ?? 1,
      ten: (json['ten'] ?? '').toString(),
      viDo: (json['vi_do'] ?? json['viDo'] as num?)?.toDouble() ?? 0.0,
      kinhDo: (json['kinh_do'] ?? json['kinhDo'] as num?)?.toDouble() ?? 0.0,
      gioDuKien: (json['gio_du_kien'] ?? json['gioDuKien'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tuyen_id': tuyenId,
    'thu_tu': thuTu,
    'ten': ten,
    'vi_do': viDo,
    'kinh_do': kinhDo,
    'gio_du_kien': gioDuKien,
  };
}

/// Học sinh gắn với chuyến đi kèm trạng thái điểm danh
@immutable
class HocSinhDiemDanh {
  const HocSinhDiemDanh({
    required this.id,
    required this.maHs,
    required this.hoTen,
    this.anhUrl,
    required this.tenLop,
    this.diemDungId,
    this.lyDoNghi,
    this.daLenXe = false,
    this.daXuongXe = false,
  });

  final int id;
  final String maHs;
  final String hoTen;
  final String? anhUrl;
  final String tenLop;
  final int? diemDungId;
  final String? lyDoNghi;
  final bool daLenXe;
  final bool daXuongXe;

  bool get coDonBaoNghi => lyDoNghi != null && lyDoNghi!.trim().isNotEmpty;

  TrangThaiHocSinh get trangThai {
    if (coDonBaoNghi) return TrangThaiHocSinh.baoNghi;
    if (daXuongXe) return TrangThaiHocSinh.daXuong;
    if (daLenXe) return TrangThaiHocSinh.dangTrenXe;
    return TrangThaiHocSinh.chuaLen;
  }

  factory HocSinhDiemDanh.fromJson(Map<String, dynamic> json) {
    return HocSinhDiemDanh(
      id: (json['id'] as num).toInt(),
      maHs: (json['ma_hs'] ?? json['maHs'] ?? '').toString(),
      hoTen: (json['ho_ten'] ?? json['hoTen'] ?? '').toString(),
      anhUrl: (json['anh_url'] ?? json['anhUrl'])?.toString(),
      tenLop: (json['ten_lop'] ?? json['tenLop'] ?? '').toString(),
      diemDungId: (json['diem_dung_id'] ?? json['diemDungId'] as num?)?.toInt(),
      lyDoNghi: (json['ly_do_nghi'] ?? json['lyDoNghi'])?.toString(),
      daLenXe: json['da_len_xe'] == true || json['daLenXe'] == true,
      daXuongXe: json['da_xuong_xe'] == true || json['daXuongXe'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ma_hs': maHs,
    'ho_ten': hoTen,
    'anh_url': anhUrl,
    'ten_lop': tenLop,
    'diem_dung_id': diemDungId,
    'ly_do_nghi': lyDoNghi,
    'da_len_xe': daLenXe,
    'da_xuong_xe': daXuongXe,
  };

  HocSinhDiemDanh copyWith({
    int? id,
    String? maHs,
    String? hoTen,
    String? anhUrl,
    String? tenLop,
    int? diemDungId,
    String? lyDoNghi,
    bool? daLenXe,
    bool? daXuongXe,
  }) {
    return HocSinhDiemDanh(
      id: id ?? this.id,
      maHs: maHs ?? this.maHs,
      hoTen: hoTen ?? this.hoTen,
      anhUrl: anhUrl ?? this.anhUrl,
      tenLop: tenLop ?? this.tenLop,
      diemDungId: diemDungId ?? this.diemDungId,
      lyDoNghi: lyDoNghi ?? this.lyDoNghi,
      daLenXe: daLenXe ?? this.daLenXe,
      daXuongXe: daXuongXe ?? this.daXuongXe,
    );
  }
}

/// Toàn bộ chi tiết chuyến đi gồm trạm dừng và danh sách học sinh
@immutable
class ChiTietChuyenDi {
  const ChiTietChuyenDi({
    required this.chuyenDi,
    required this.diemDung,
    required this.hocSinh,
  });

  final ChuyenDi chuyenDi;
  final List<DiemDung> diemDung;
  final List<HocSinhDiemDanh> hocSinh;

  int get tongSoHocSinh => hocSinh.length;
  int get soHocSinhBaoNghi => hocSinh.where((h) => h.coDonBaoNghi).length;
  int get soHocSinhDaLen => hocSinh.where((h) => h.daLenXe).length;
  int get soHocSinhDaXuong => hocSinh.where((h) => h.daXuongXe).length;
  int get soHocSinhTrenXe =>
      hocSinh.where((h) => h.daLenXe && !h.daXuongXe).length;

  /// Học sinh chưa hoàn tất điểm danh (không báo nghỉ và chưa đủ cả 2 bước lên & xuống)
  List<HocSinhDiemDanh> get hocSinhChuaHoanTat => hocSinh
      .where((h) => !h.coDonBaoNghi && (!h.daLenXe || !h.daXuongXe))
      .toList();

  /// Học sinh theo một điểm dừng cụ thể
  List<HocSinhDiemDanh> dsHocSinhTheoDiem(int? diemDungId) {
    if (diemDungId == null) return const [];
    return hocSinh.where((h) => h.diemDungId == diemDungId).toList();
  }

  /// Cập nhật trạng thái điểm danh tại chỗ mà không cần tải lại toàn bộ API
  ChiTietChuyenDi capNhatDiemDanh({
    required int hocSinhId,
    required String suKien,
  }) {
    final dsMoi = hocSinh.map((h) {
      if (h.id != hocSinhId) return h;
      if (suKien == 'LEN_XE') {
        return h.copyWith(daLenXe: true);
      } else if (suKien == 'XUONG_XE') {
        return h.copyWith(daXuongXe: true);
      }
      return h;
    }).toList();

    return ChiTietChuyenDi(
      chuyenDi: chuyenDi,
      diemDung: diemDung,
      hocSinh: dsMoi,
    );
  }

  ChiTietChuyenDi copyWith({
    ChuyenDi? chuyenDi,
    List<DiemDung>? diemDung,
    List<HocSinhDiemDanh>? hocSinh,
  }) {
    return ChiTietChuyenDi(
      chuyenDi: chuyenDi ?? this.chuyenDi,
      diemDung: diemDung ?? this.diemDung,
      hocSinh: hocSinh ?? this.hocSinh,
    );
  }

  factory ChiTietChuyenDi.fromJson(Map<String, dynamic> json) {
    final chuyenDiJson = json['chuyenDi'] ?? json['chuyen_di'] ?? {};
    final dsDiemDungJson = json['diemDung'] ?? json['diem_dung'] ?? [];
    final dsHocSinhJson = json['hocSinh'] ?? json['hoc_sinh'] ?? [];

    return ChiTietChuyenDi(
      chuyenDi: ChuyenDi.fromJson(chuyenDiJson as Map<String, dynamic>),
      diemDung: (dsDiemDungJson as List)
          .map((d) => DiemDung.fromJson(d as Map<String, dynamic>))
          .toList(),
      hocSinh: (dsHocSinhJson as List)
          .map((h) => HocSinhDiemDanh.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Kết quả trả về sau khi gọi API điểm danh
@immutable
class KetQuaDiemDanh {
  const KetQuaDiemDanh({
    required this.id,
    required this.chuyenDiId,
    required this.hocSinhId,
    this.diemDungId,
    required this.suKien,
    this.thoiDiem,
  });

  final int id;
  final int chuyenDiId;
  final int hocSinhId;
  final int? diemDungId;
  final String suKien;
  final DateTime? thoiDiem;

  factory KetQuaDiemDanh.fromJson(Map<String, dynamic> json) {
    return KetQuaDiemDanh(
      id: (json['id'] as num).toInt(),
      chuyenDiId: (json['chuyen_di_id'] ?? json['chuyenDiId'] as num?)?.toInt() ?? 0,
      hocSinhId: (json['hoc_sinh_id'] ?? json['hocSinhId'] as num?)?.toInt() ?? 0,
      diemDungId: (json['diem_dung_id'] ?? json['diemDungId'] as num?)?.toInt(),
      suKien: (json['su_kien'] ?? json['suKien'] ?? '').toString(),
      thoiDiem: json['thoi_diem'] != null
          ? DateTime.tryParse(json['thoi_diem'].toString())
          : (json['thoiDiem'] != null
              ? DateTime.tryParse(json['thoiDiem'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chuyen_di_id': chuyenDiId,
    'hoc_sinh_id': hocSinhId,
    'diem_dung_id': diemDungId,
    'su_kien': suKien,
    'thoi_diem': thoiDiem?.toIso8601String(),
  };
}
