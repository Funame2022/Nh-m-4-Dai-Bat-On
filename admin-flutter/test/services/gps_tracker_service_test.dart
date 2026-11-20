import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/operations/gps_tracker_service.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage(this._token);
  final String? _token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> writeToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
}

void main() {
  test('GpsTrackerService batDauTracking phat toa do ban dau va dinh ky', () async {
    final List<Map<String, dynamic>> sentGpsPayloads = [];

    final client = MockClient((request) async {
      if (request.url.path.contains('/vi-tri')) {
        sentGpsPayloads.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'chuyen_di_id': 10,
            'vi_do': 10.77,
            'kinh_do': 106.69,
            'thoi_diem': '2026-11-20T07:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final storage = FakeTokenStorage('test-token');
    final vanHanhService = VanHanhService(client: client, storage: storage, baseUrl: 'http://api.test');
    final tracker = GpsTrackerService(
      vanHanhService: vanHanhService,
      chuKy: const Duration(milliseconds: 100),
    );

    const loTrinh = [
      DiemDung(id: 1, tuyenId: 10, thuTu: 1, ten: 'Trạm 1', viDo: 10.77, kinhDo: 106.69),
      DiemDung(id: 2, tuyenId: 10, thuTu: 2, ten: 'Trạm 2', viDo: 10.79, kinhDo: 106.71),
    ];

    tracker.batDauTracking(chuyenId: 10, loTrinh: loTrinh);

    expect(tracker.dangTracking, isTrue);
    expect(tracker.viTriHienTai, isNotNull);
    expect(tracker.viTriHienTai!.viDo, 10.77);

    // Chờ 2 chu kỳ phát GPS
    await Future.delayed(const Duration(milliseconds: 250));

    expect(sentGpsPayloads.length, greaterThanOrEqualTo(2));

    // Thử tạm dừng
    tracker.tamDung();
    expect(tracker.dangTracking, isFalse);
    expect(tracker.dangTamDung, isTrue);

    // Thử tiếp tục
    tracker.tiepTuc();
    expect(tracker.dangTracking, isTrue);
    expect(tracker.dangTamDung, isFalse);

    // Dừng hoàn toàn
    tracker.dungTracking();
    expect(tracker.dangTracking, isFalse);
    tracker.dispose();
  });

  test('GpsTrackerService guiToaDoThuCong cap nhat vi tri ngay lap tuc', () async {
    Map<String, dynamic>? lastPayload;

    final client = MockClient((request) async {
      if (request.url.path.contains('/vi-tri')) {
        lastPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{}', 201, headers: {'content-type': 'application/json'});
      }
      return http.Response('Not Found', 404);
    });

    final storage = FakeTokenStorage('test-token');
    final vanHanhService = VanHanhService(client: client, storage: storage, baseUrl: 'http://api.test');
    final tracker = GpsTrackerService(vanHanhService: vanHanhService);

    await tracker.guiToaDoThuCong(
      chuyenId: 15,
      viDo: 10.8234,
      kinhDo: 106.6234,
    );

    expect(lastPayload, isNotNull);
    expect(lastPayload!['viDo'], 10.8234);
    expect(lastPayload!['kinhDo'], 106.6234);
    expect(tracker.viTriHienTai!.viDo, 10.8234);

    tracker.dispose();
  });
}
