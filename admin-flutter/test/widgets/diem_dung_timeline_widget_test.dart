import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/screens/operations/widgets/diem_dung_timeline_widget.dart';

void main() {
  final testChiTiet = ChiTietChuyenDi(
    chuyenDi: const ChuyenDi(
      id: 1,
      tuyenId: 10,
      ngay: '2026-11-20',
      chieu: ChieuChuyen.donSang,
      trangThai: TrangThaiChuyen.dangChay,
      tenTuyen: 'Tuyến Q1 - Q7',
      bienSo: '51B-123.45',
    ),
    diemDung: const [
      DiemDung(
        id: 1,
        tuyenId: 10,
        thuTu: 1,
        ten: 'Trạm 1 - Chợ Bến Thành',
        viDo: 10.77,
        kinhDo: 106.69,
        gioDuKien: '06:30',
      ),
      DiemDung(
        id: 2,
        tuyenId: 10,
        thuTu: 2,
        ten: 'Trạm 2 - Cầu Kênh Tẻ',
        viDo: 10.75,
        kinhDo: 106.70,
        gioDuKien: '06:50',
      ),
      DiemDung(
        id: 3,
        tuyenId: 10,
        thuTu: 3,
        ten: 'Trạm 3 - Trường Tiểu học Sao Mai',
        viDo: 10.73,
        kinhDo: 106.72,
        gioDuKien: '07:15',
      ),
    ],
    hocSinh: const [
      HocSinhDiemDanh(
        id: 101,
        maHs: 'HS101',
        hoTen: 'Trần Minh Anh',
        tenLop: '1A',
        diemDungId: 1,
        daLenXe: true,
      ),
      HocSinhDiemDanh(
        id: 102,
        maHs: 'HS102',
        hoTen: 'Lê Bảo Châu',
        tenLop: '1A',
        diemDungId: 1,
        lyDoNghi: 'Nghỉ ốm',
      ),
      HocSinhDiemDanh(
        id: 103,
        maHs: 'HS103',
        hoTen: 'Nguyễn Văn Đạt',
        tenLop: '2B',
        diemDungId: 2,
        daLenXe: false,
      ),
    ],
  );

  Widget createWidget({
    ChiTietChuyenDi? chiTiet,
    OnChonDiemDung? onDiemDanhTaiTram,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DiemDungTimelineWidget(
          chiTiet: chiTiet ?? testChiTiet,
          onDiemDanhTaiTram: onDiemDanhTaiTram,
        ),
      ),
    );
  }

  testWidgets('Hiển thị các trạm dừng dọc tuyến với huy hiệu điểm đầu, trường học', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline-card-1')), findsOneWidget);
    expect(find.byKey(const Key('timeline-card-2')), findsOneWidget);
    expect(find.byKey(const Key('timeline-card-3')), findsOneWidget);

    expect(find.text('Trạm 1 - Chợ Bến Thành'), findsOneWidget);
    expect(find.text('Điểm đầu'), findsOneWidget);
    expect(find.text('Trường học'), findsOneWidget);
    expect(find.textContaining('06:30'), findsOneWidget);
    expect(find.textContaining('06:50'), findsOneWidget);
  });

  testWidgets('Bấm vào card trạm dừng để mở rộng danh sách học sinh tại trạm', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Trước khi mở rộng, tên học sinh chưa xuất hiện
    expect(find.text('Trần Minh Anh (1A)'), findsNothing);

    // Bấm vào trạm 1 để mở rộng
    await tester.tap(find.byKey(const Key('timeline-card-1')));
    await tester.pumpAndSettle();

    // Sau khi mở rộng, thấy tên học sinh tại trạm 1
    expect(find.text('Trần Minh Anh (1A)'), findsOneWidget);
    expect(find.text('Lê Bảo Châu (1A)'), findsOneWidget);
    expect(find.text('Đang trên xe'), findsOneWidget);
    expect(find.text('Nghỉ có phép'), findsOneWidget);
  });

  testWidgets('Bấm nút Điểm danh tại trạm gọi onDiemDanhTaiTram', (tester) async {
    DiemDung? diemDuocChon;
    await tester.pumpWidget(createWidget(
      onDiemDanhTaiTram: (d) => diemDuocChon = d,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn-diem-danh-tram-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-diem-danh-tram-1')));
    await tester.pumpAndSettle();

    expect(diemDuocChon, isNotNull);
    expect(diemDuocChon!.id, 1);
    expect(diemDuocChon!.ten, 'Trạm 1 - Chợ Bến Thành');
  });

  testWidgets('Hiển thị thông báo khi tuyến chưa có điểm dừng nào', (tester) async {
    final emptyChiTiet = ChiTietChuyenDi(
      chuyenDi: testChiTiet.chuyenDi,
      diemDung: const [],
      hocSinh: const [],
    );

    await tester.pumpWidget(createWidget(chiTiet: emptyChiTiet));
    await tester.pumpAndSettle();

    expect(find.text('Tuyến này chưa thiết lập điểm dừng đón/trả.'), findsOneWidget);
  });
}
