import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:xe_truong_admin/screens/routes/map_picker_screen.dart';

void main() {
  testWidgets('kéo bản đồ cập nhật tọa độ và trả về vị trí', (tester) async {
    Object? ketQua;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('mo-ban-do'),
                onPressed: () async {
                  ketQua = await MapPickerScreen.mo(context);
                },
                child: const Text('Mở bản đồ'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('mo-ban-do')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final banDo = find.byKey(const Key('map-picker-map'));
    expect(banDo, findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('map-picker-coordinates'))).data,
      '10.776900, 106.700900',
    );

    final truocKhiKeo = tester
        .widget<Text>(find.byKey(const Key('map-picker-coordinates')))
        .data;
    await tester.drag(banDo, const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('map-picker-coordinates'))).data,
      isNot(truocKhiKeo),
    );

    await tester.tap(find.byKey(const Key('map-picker-confirm')));
    await tester.pumpAndSettle();

    expect(ketQua, isNotNull);
  });

  testWidgets('tọa độ giả 1,1 được thay bằng trung tâm TP.HCM', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MapPickerScreen(initial: LatLng(1, 1))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<Text>(find.byKey(const Key('map-picker-coordinates'))).data,
      '10.776900, 106.700900',
    );
  });
}
