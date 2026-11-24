import 'package:flutter_test/flutter_test.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';

void main() {
  group('ChuyenDi Model', () {
    test('fromJson and toJson parse correct fields', () {
      final json = {
        'id': 101,
        'tuyen_id': 5,
        'ngay': '2026-11-20',
        'chieu': 'DON_SANG',
        'trang_thai': 'DANG_CHAY',
        'bat_dau_luc': '2026-11-20T06:30:00.000Z',
        'ket_thuc_luc': null,
        'ten_tuyen': 'Tuyến Q1 - Q7',
        'bien_so': '51B-12345',
      };

      final chuyen = ChuyenDi.fromJson(json);

      expect(chuyen.id, 101);
      expect(chuyen.tuyenId, 5);
      expect(chuyen.chieu, ChieuChuyen.donSang);
      expect(chuyen.trangThai, TrangThaiChuyen.dangChay);
      expect(chuyen.laDangChay, isTrue);
      expect(chuyen.laChuaChay, isFalse);
      expect(chuyen.tenTuyen, 'Tuyến Q1 - Q7');
      expect(chuyen.bienSo, '51B-12345');
      expect(chuyen.batDauLuc, isNotNull);

      final out = chuyen.toJson();
      expect(out['id'], 101);
      expect(out['chieu'], 'DON_SANG');
      expect(out['trang_thai'], 'DANG_CHAY');
    });

    test('ChieuChuyen and TrangThaiChuyen fallbacks', () {
      expect(ChieuChuyen.fromString('TRA_CHIEU'), ChieuChuyen.traChieu);
      expect(ChieuChuyen.fromString('TRA'), ChieuChuyen.traChieu);
      expect(ChieuChuyen.fromString('DON'), ChieuChuyen.donSang);
      expect(ChieuChuyen.fromString('DON_SANG'), ChieuChuyen.donSang);
      expect(ChieuChuyen.fromString('OTHER'), ChieuChuyen.donSang);

      expect(TrangThaiChuyen.fromString('HOAN_THANH'), TrangThaiChuyen.hoanThanh);
      expect(TrangThaiChuyen.fromString('UNKNOWN'), TrangThaiChuyen.chuaChay);
    });
  });

  group('HocSinhDiemDanh Model', () {
    test('computes correct TrangThaiHocSinh and copyWith', () {
      final hsChuaLen = HocSinhDiemDanh(
        id: 1,
        maHs: 'HS001',
        hoTen: 'Nguyễn Văn An',
        tenLop: '1A',
        diemDungId: 10,
      );
      expect(hsChuaLen.trangThai, TrangThaiHocSinh.chuaLen);
      expect(hsChuaLen.coDonBaoNghi, isFalse);

      final hsDaLen = hsChuaLen.copyWith(daLenXe: true);
      expect(hsDaLen.trangThai, TrangThaiHocSinh.dangTrenXe);

      final hsDaXuong = hsDaLen.copyWith(daXuongXe: true);
      expect(hsDaXuong.trangThai, TrangThaiHocSinh.daXuong);

      final hsBaoNghi = hsChuaLen.copyWith(lyDoNghi: 'Sốt cao');
      expect(hsBaoNghi.coDonBaoNghi, isTrue);
      expect(hsBaoNghi.trangThai, TrangThaiHocSinh.baoNghi);
    });
  });

  group('ChiTietChuyenDi Model', () {
    test('calculates statistics correctly', () {
      final chiTiet = ChiTietChuyenDi(
        chuyenDi: const ChuyenDi(
          id: 1,
          tuyenId: 1,
          ngay: '2026-11-20',
          chieu: ChieuChuyen.donSang,
          trangThai: TrangThaiChuyen.dangChay,
          tenTuyen: 'Tuyến Test',
          bienSo: '51B-99999',
        ),
        diemDung: const [
          DiemDung(
            id: 1,
            tuyenId: 1,
            thuTu: 1,
            ten: 'Trạm 1',
            viDo: 10.1,
            kinhDo: 106.1,
          ),
          DiemDung(
            id: 2,
            tuyenId: 1,
            thuTu: 2,
            ten: 'Trạm Trường',
            viDo: 10.2,
            kinhDo: 106.2,
          ),
        ],
        hocSinh: const [
          HocSinhDiemDanh(
            id: 1,
            maHs: 'HS01',
            hoTen: 'Học sinh 1',
            tenLop: '1A',
            diemDungId: 1,
            daLenXe: true,
            daXuongXe: true,
          ),
          HocSinhDiemDanh(
            id: 2,
            maHs: 'HS02',
            hoTen: 'Học sinh 2',
            tenLop: '1A',
            diemDungId: 1,
            daLenXe: true,
            daXuongXe: false,
          ),
          HocSinhDiemDanh(
            id: 3,
            maHs: 'HS03',
            hoTen: 'Học sinh 3',
            tenLop: '2B',
            diemDungId: 1,
            lyDoNghi: 'Bệnh',
          ),
        ],
      );

      expect(chiTiet.tongSoHocSinh, 3);
      expect(chiTiet.soHocSinhDaLen, 2);
      expect(chiTiet.soHocSinhDaXuong, 1);
      expect(chiTiet.soHocSinhTrenXe, 1);
      expect(chiTiet.soHocSinhBaoNghi, 1);
      expect(chiTiet.hocSinhChuaHoanTat.length, 1);
      expect(chiTiet.hocSinhChuaHoanTat.first.id, 2);

      // Test immutable local update
      final capNhat = chiTiet.capNhatDiemDanh(hocSinhId: 2, suKien: 'XUONG_XE');
      expect(capNhat.soHocSinhDaXuong, 2);
      expect(capNhat.soHocSinhTrenXe, 0);
      expect(capNhat.hocSinhChuaHoanTat.isEmpty, isTrue);

      // Test copyWith
      final updatedChuyen = chiTiet.copyWith(
        chuyenDi: chiTiet.chuyenDi.copyWith(trangThai: TrangThaiChuyen.hoanThanh),
      );
      expect(updatedChuyen.chuyenDi.trangThai, TrangThaiChuyen.hoanThanh);
    });

    test('KetQuaDiemDanh fromJson parses fields accurately', () {
      final json = {
        'id': 55,
        'chuyen_di_id': 10,
        'hoc_sinh_id': 101,
        'diem_dung_id': 1,
        'su_kien': 'LEN_XE',
        'thoi_diem': '2026-11-20T06:45:00.000Z',
      };
      final kq = KetQuaDiemDanh.fromJson(json);
      expect(kq.id, 55);
      expect(kq.chuyenDiId, 10);
      expect(kq.hocSinhId, 101);
      expect(kq.diemDungId, 1);
      expect(kq.suKien, 'LEN_XE');
      expect(kq.thoiDiem, isNotNull);
    });
  });
}
