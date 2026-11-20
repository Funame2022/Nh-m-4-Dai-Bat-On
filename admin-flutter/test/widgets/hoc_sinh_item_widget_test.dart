import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/screens/operations/widgets/hoc_sinh_item_widget.dart';

void main() {
  Widget createWidget({
    required HocSinhDiemDanh hocSinh,
    String? tenDiemDung,
    VoidCallback? onDiemDanhLenXe,
    VoidCallback? onDiemDanhXuongXe,
    VoidCallback? onTap,
    bool dangXuLy = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HocSinhItemWidget(
          hocSinh: hocSinh,
          tenDiemDung: tenDiemDung,
          onDiemDanhLenXe: onDiemDanhLenXe,
          onDiemDanhXuongXe: onDiemDanhXuongXe,
          onTap: onTap,
          dangXuLy: dangXuLy,
        ),
      ),
    );
  }

  testWidgets('Hiển thị thông tin học sinh chưa lên xe và nút LÊN XE hoạt động', (tester) async {
    bool daBamLenXe = false;
    const hs = HocSinhDiemDanh(
      id: 1,
      maHs: 'HS001',
      hoTen: 'Nguyễn Văn An',
      tenLop: '3A',
      diemDungId: 10,
      daLenXe: false,
      daXuongXe: false,
    );

    await tester.pumpWidget(createWidget(
      hocSinh: hs,
      tenDiemDung: 'Trạm Cây xăng Hàng Xanh',
      onDiemDanhLenXe: () => daBamLenXe = true,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hoc-sinh-card-1')), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Lớp 3A'), findsOneWidget);
    expect(find.text('HS001'), findsOneWidget);
    expect(find.text('Trạm Cây xăng Hàng Xanh'), findsOneWidget);
    expect(find.text('Chưa lên xe'), findsOneWidget);

    final btnLenXe = find.byKey(const Key('btn-len-xe-1'));
    expect(btnLenXe, findsOneWidget);
    expect(find.text('LÊN XE'), findsOneWidget);

    await tester.tap(btnLenXe);
    await tester.pumpAndSettle();

    expect(daBamLenXe, isTrue);
  });

  testWidgets('Hiển thị học sinh đang trên xe và nút XUỐNG XE hoạt động', (tester) async {
    bool daBamXuongXe = false;
    const hs = HocSinhDiemDanh(
      id: 2,
      maHs: 'HS002',
      hoTen: 'Lê Hoàng Long',
      tenLop: '4B',
      daLenXe: true,
      daXuongXe: false,
    );

    await tester.pumpWidget(createWidget(
      hocSinh: hs,
      onDiemDanhXuongXe: () => daBamXuongXe = true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lê Hoàng Long'), findsOneWidget);
    expect(find.text('Đang trên xe'), findsOneWidget);

    final btnXuongXe = find.byKey(const Key('btn-xuong-xe-2'));
    expect(btnXuongXe, findsOneWidget);
    expect(find.text('XUỐNG XE'), findsOneWidget);

    await tester.tap(btnXuongXe);
    await tester.pumpAndSettle();

    expect(daBamXuongXe, isTrue);
  });

  testWidgets('Hiển thị học sinh đã xuống xe và nhãn Hoàn tất', (tester) async {
    const hs = HocSinhDiemDanh(
      id: 3,
      maHs: 'HS003',
      hoTen: 'Phạm Quỳnh Anh',
      tenLop: '5C',
      daLenXe: true,
      daXuongXe: true,
    );

    await tester.pumpWidget(createWidget(hocSinh: hs));
    await tester.pumpAndSettle();

    expect(find.text('Phạm Quỳnh Anh'), findsOneWidget);
    expect(find.text('Đã xuống xe'), findsOneWidget);
    expect(find.text('Hoàn tất'), findsOneWidget);
    expect(find.byKey(const Key('btn-len-xe-3')), findsNothing);
    expect(find.byKey(const Key('btn-xuong-xe-3')), findsNothing);
  });

  testWidgets('Hiển thị học sinh báo nghỉ có phép kèm lý do, không hiện nút điểm danh', (tester) async {
    const hs = HocSinhDiemDanh(
      id: 4,
      maHs: 'HS004',
      hoTen: 'Đỗ Tuấn Kiệt',
      tenLop: '2D',
      lyDoNghi: 'Gia đình về quê',
    );

    await tester.pumpWidget(createWidget(hocSinh: hs));
    await tester.pumpAndSettle();

    expect(find.text('Đỗ Tuấn Kiệt'), findsOneWidget);
    expect(find.text('Nghỉ có phép'), findsOneWidget);
    expect(find.text('Lý do nghỉ: Gia đình về quê'), findsOneWidget);
    expect(find.byKey(const Key('btn-len-xe-4')), findsNothing);
    expect(find.byKey(const Key('btn-xuong-xe-4')), findsNothing);
  });

  testWidgets('Hiển thị vòng tròn xoay khi đang xử lý API (dangXuLy = true)', (tester) async {
    const hs = HocSinhDiemDanh(
      id: 5,
      maHs: 'HS005',
      hoTen: 'Hoàng Mai Phương',
      tenLop: '1A',
      daLenXe: false,
    );

    await tester.pumpWidget(createWidget(
      hocSinh: hs,
      dangXuLy: true,
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('btn-len-xe-5')), findsNothing);
  });
}
