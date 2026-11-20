import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/operations/gps_tracker_service.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';
import 'package:xe_truong_admin/screens/operations/widgets/gps_live_status_widget.dart';

class FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => 'fake-token';
  @override
  Future<void> writeToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
}

void main() {
  testWidgets('GpsLiveStatusWidget hien thi toa do thoi gian thuc va ho tro tam dung/tiep tuc', (tester) async {
    final client = MockClient((_) async => http.Response('{}', 201));
    final storage = FakeTokenStorage();
    final service = VanHanhService(client: client, storage: storage, baseUrl: 'http://api.test');
    final tracker = GpsTrackerService(vanHanhService: service);

    tracker.batDauTracking(
      chuyenId: 10,
      viTriBanDau: ViTriGps(
        viDo: 10.7769,
        kinhDo: 106.7009,
        thoiDiem: DateTime(2026, 11, 20, 7, 0, 0),
        tocDo: 30,
      ),
    );

    bool daBamGuiNgay = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GpsLiveStatusWidget(
            gpsTracker: tracker,
            onGuiNgay: () => daBamGuiNgay = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card-gps-live-status')), findsOneWidget);
    expect(find.text('GPS LIVE TRACKING'), findsOneWidget);
    expect(find.textContaining('10.77690° N, 106.70090° E'), findsOneWidget);
    expect(find.textContaining('Tốc độ: 30 km/h'), findsOneWidget);
    expect(find.text('Tạm dừng'), findsOneWidget);

    // Bấm nút Tạm dừng
    await tester.tap(find.byKey(const Key('btn-toggle-gps-tracking')));
    await tester.pumpAndSettle();

    expect(tracker.dangTracking, isFalse);
    expect(find.text('Tiếp tục phát'), findsOneWidget);

    // Bấm nút Gửi vị trí ngay
    expect(find.byKey(const Key('btn-gui-vi-tri-ngay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn-gui-vi-tri-ngay')));
    await tester.pumpAndSettle();

    expect(daBamGuiNgay, isTrue);

    tracker.dispose();
  });
}
