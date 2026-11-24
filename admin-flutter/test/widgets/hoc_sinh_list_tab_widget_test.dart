import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/screens/operations/widgets/hoc_sinh_list_tab_widget.dart';

void main() {
  final testChiTiet = ChiTietChuyenDi(
    chuyenDi: const ChuyenDi(
      id: 10,
      tuyenId: 1,
      ngay: '2026-11-20',
      chieu: ChieuChuyen.donSang,
      trangThai: TrangThaiChuyen.dangChay,
      tenTuyen: 'Tuyến Q1 - Q3',
      bienSo: '51B-123.45',
    ),
    diemDung: const [
      DiemDung(id: 1, tuyenId: 1, thuTu: 1, ten: 'Trạm Chợ Bến Thành', viDo: 10.77, kinhDo: 106.69),
      DiemDung(id: 2, tuyenId: 1, thuTu: 2, ten: 'Trường THCS Lê Quý Đôn', viDo: 10.78, kinhDo: 106.70),
    ],
    hocSinh: const [
      HocSinhDiemDanh(
        id: 101,
        maHs: 'HS101',
        hoTen: 'Nguyễn Văn An',
        tenLop: '1A',
        diemDungId: 1,
        daLenXe: false,
        daXuongXe: false,
      ),
      HocSinhDiemDanh(
        id: 102,
        maHs: 'HS102',
        hoTen: 'Trần Bảo Ngọc',
        tenLop: '2B',
        diemDungId: 1,
        daLenXe: true,
        daXuongXe: false,
      ),
      HocSinhDiemDanh(
        id: 103,
        maHs: 'HS103',
        hoTen: 'Lê Hoàng Nam',
        tenLop: '2B',
        diemDungId: 2,
        daLenXe: true,
        daXuongXe: true,
      ),
      HocSinhDiemDanh(
        id: 104,
        maHs: 'HS104',
        hoTen: 'Phạm Minh Khôi',
        tenLop: '3C',
        diemDungId: 1,
        lyDoNghi: 'Nghỉ ốm',
        daLenXe: false,
        daXuongXe: false,
      ),
    ],
  );

  Widget createWidget({ChiTietChuyenDi? chiTiet}) {
    return MaterialApp(
      home: Scaffold(
        body: HocSinhListTabWidget(
          chiTiet: chiTiet ?? testChiTiet,
          dangXuLyHocSinh: const {},
          onDiemDanhLenXe: (_) {},
          onDiemDanhXuongXe: (_) {},
        ),
      ),
    );
  }

  testWidgets('Hiển thị thanh tìm kiếm, các chip lọc trạng thái và toàn bộ 4 học sinh ban đầu', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input-tim-kiem-hoc-sinh')), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-tat-ca')), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-chua-len')), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-dang-tren-xe')), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-da-xuong')), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-bao-nghi')), findsOneWidget);

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Bảo Ngọc'), findsOneWidget);
    expect(find.text('Lê Hoàng Nam'), findsOneWidget);
    expect(find.text('Phạm Minh Khôi'), findsOneWidget);
  });

  testWidgets('Tìm kiếm theo tên học sinh', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input-tim-kiem-hoc-sinh')), 'Bảo Ngọc');
    await tester.pumpAndSettle();

    expect(find.text('Trần Bảo Ngọc'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsNothing);
    expect(find.text('Lê Hoàng Nam'), findsNothing);
    expect(find.text('Phạm Minh Khôi'), findsNothing);

    // Bấm nút xóa từ khóa tìm kiếm
    expect(find.byKey(const Key('btn-clear-search-hoc-sinh')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn-clear-search-hoc-sinh')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Bảo Ngọc'), findsOneWidget);
  });

  testWidgets('Tìm kiếm theo lớp', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input-tim-kiem-hoc-sinh')), '2B');
    await tester.pumpAndSettle();

    expect(find.text('Trần Bảo Ngọc'), findsOneWidget);
    expect(find.text('Lê Hoàng Nam'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsNothing);
    expect(find.text('Phạm Minh Khôi'), findsNothing);
  });

  testWidgets('Lọc theo Chip trạng thái (Đang trên xe, Báo nghỉ, Đã xuống, Chưa lên)', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // 1. Lọc Đang trên xe
    await tester.tap(find.byKey(const Key('filter-chip-dang-tren-xe')));
    await tester.pumpAndSettle();

    expect(find.text('Trần Bảo Ngọc'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsNothing);
    expect(find.text('Lê Hoàng Nam'), findsNothing);

    // 2. Lọc Báo nghỉ
    await tester.tap(find.byKey(const Key('filter-chip-bao-nghi')));
    await tester.pumpAndSettle();

    expect(find.text('Phạm Minh Khôi'), findsOneWidget);
    expect(find.text('Trần Bảo Ngọc'), findsNothing);

    // 3. Lọc Chưa lên
    await tester.tap(find.byKey(const Key('filter-chip-chua-len')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Phạm Minh Khôi'), findsNothing);

    // 4. Bấm Đặt lại để quay về Tất cả
    await tester.tap(find.byKey(const Key('btn-reset-filters')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Bảo Ngọc'), findsOneWidget);
    expect(find.text('Lê Hoàng Nam'), findsOneWidget);
    expect(find.text('Phạm Minh Khôi'), findsOneWidget);
  });
}
