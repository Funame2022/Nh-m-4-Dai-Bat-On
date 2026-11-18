import 'dart:async';
import 'dart:convert';

import 'package:client_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class FakeGpsLocationSource implements GpsLocationSource {
  FakeGpsLocationSource({this.permission = LocationPermission.whileInUse});

  final LocationPermission permission;
  final StreamController<GpsCoordinates> controller =
      StreamController<GpsCoordinates>.broadcast();

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Stream<GpsCoordinates> get positions => controller.stream;

  @override
  Future<LocationPermission> requestPermission() async => permission;
}

class FakeParentGpsConnection implements ParentGpsConnection {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  bool isClosed = false;
  bool get hasListener => _controller.hasListener;

  @override
  Stream<dynamic> get messages => _controller.stream;

  void send(Map<String, Object?> message) =>
      _controller.add(jsonEncode(message));

  @override
  Future<void> close() async {
    isClosed = true;
    await _controller.close();
  }
}

void main() {
  testWidgets('từ chối quyền vị trí thì không gửi tọa độ mẫu', (tester) async {
    final location = FakeGpsLocationSource(
      permission: LocationPermission.deniedForever,
    );
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/chuyen-hom-nay')) {
        return jsonResponse([
          {'id': 7},
        ]);
      }
      if (request.url.path.endsWith('/chuyen/7')) {
        return jsonResponse({
          'chuyenDi': {'id': 7, 'trang_thai': 'DANG_CHAY'},
          'diemDung': [],
          'hocSinh': [],
        });
      }
      fail('Không mong đợi yêu cầu GPS khi quyền vị trí bị từ chối');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: VanHanhScreen(
          token: 'token',
          user: {'vaiTro': 'TAI_XE', 'hoTen': 'Tài xế'},
          gpsLocationSource: location,
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Cần cấp quyền vị trí khi dùng ứng dụng để gửi GPS.'),
      findsOneWidget,
    );
    expect(
      requests.where((request) => request.url.path.endsWith('/vi-tri')),
      isEmpty,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await location.controller.close();
  });

  testWidgets('tài xế gửi tọa độ thật và dừng chia sẻ khi app vào nền', (
    tester,
  ) async {
    final location = FakeGpsLocationSource();
    final gpsRequests = <http.Request>[];
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path.endsWith('/chuyen-hom-nay')) {
        return jsonResponse([
          {'id': 7},
        ]);
      }
      if (request.method == 'GET' && request.url.path.endsWith('/chuyen/7')) {
        return jsonResponse({
          'chuyenDi': {'id': 7, 'trang_thai': 'DANG_CHAY'},
          'diemDung': [],
          'hocSinh': [],
        });
      }
      if (request.method == 'POST' && request.url.path.endsWith('/vi-tri')) {
        gpsRequests.add(request);
        return jsonResponse({'id': 1}, 201);
      }
      fail('Yêu cầu không mong đợi: ${request.method} ${request.url}');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: VanHanhScreen(
          token: 'token',
          user: {'vaiTro': 'TAI_XE', 'hoTen': 'Tài xế'},
          gpsLocationSource: location,
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang chia sẻ GPS'), findsOneWidget);

    location.controller.add(
      const GpsCoordinates(latitude: 10.7755, longitude: 106.695),
    );
    await tester.pumpAndSettle();

    expect(gpsRequests, hasLength(1));
    expect(jsonDecode(gpsRequests.single.body), {
      'viDo': 10.7755,
      'kinhDo': 106.695,
    });

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(location.controller.hasListener, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await location.controller.close();
  });

  testWidgets('phụ huynh chỉ thấy cập nhật của học sinh đang chọn', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/con-cua-toi')) {
        return jsonResponse([
          {
            'id': 1,
            'ho_ten': 'An Nguyễn',
            'ma_hs': 'HS1',
            'ten_lop': '1A',
            'ten_truong': 'Trường A',
            'quan_he': 'Cha/mẹ',
          },
          {
            'id': 2,
            'ho_ten': 'Mai Nguyễn',
            'ma_hs': 'HS2',
            'ten_lop': '2A',
            'ten_truong': 'Trường A',
            'quan_he': 'Cha/mẹ',
          },
        ]);
      }
      if (request.url.path.endsWith('/con/1/theo-doi')) {
        return jsonResponse([_journey(11)]);
      }
      if (request.url.path.endsWith('/con/2/theo-doi')) {
        return jsonResponse([_journey(22)]);
      }
      fail('Không mong đợi yêu cầu ${request.url}');
    });
    final connections = <FakeParentGpsConnection>[];
    final connectedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        home: PhuHuynhScreen(
          token: 'parent-token',
          user: {'hoTen': 'Phụ huynh'},
          client: client,
          gpsConnector: (uri, headers) async {
            expect(headers['Authorization'], 'Bearer parent-token');
            connectedUris.add(uri);
            final connection = FakeParentGpsConnection();
            connections.add(connection);
            return connection;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(connectedUris.single.queryParameters['hocSinhId'], '1');
    expect(find.text('Đang nhận cập nhật trực tiếp'), findsOneWidget);
    connections[0].send({
      'type': 'gps_updated',
      'data': {
        'chuyen_di_id': 22,
        'vi_do': 11.25,
        'kinh_do': 105.75,
        'thoi_diem': DateTime.now().toUtc().toIso8601String(),
      },
    });
    await tester.pump();
    expect(find.textContaining('11.25, 105.75'), findsNothing);

    final selector = tester.widget<PopupMenuButton<int>>(
      find.byKey(const Key('parent-child-selector')),
    );
    expect(
      selector
          .itemBuilder(
            tester.element(find.byKey(const Key('parent-child-selector'))),
          )
          .map((item) => (item as PopupMenuItem<int>).value),
      [1, 2],
    );
    selector.onSelected!(2);
    await tester.pumpAndSettle();

    expect(find.text('Mai Nguyễn (HS2)'), findsOneWidget);
    expect(connectedUris, hasLength(2));
    expect(connectedUris.last.queryParameters['hocSinhId'], '2');
    expect(connections[0].isClosed, isTrue);
    expect(connections[1].hasListener, isTrue);
    connections[1].send({
      'type': 'gps_updated',
      'data': {
        'chuyen_di_id': 22,
        'vi_do': 11.25,
        'kinh_do': 105.75,
        'thoi_diem': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      },
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.textContaining('Tọa độ GPS: 11.25, 105.75'), findsOneWidget);
    expect(find.textContaining('GPS cũ'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(connections.last.isClosed, isTrue);
  });
}

Map<String, Object?> _journey(int id) => {
  'chuyen_di_id': id,
  'chieu': 'DON_SANG',
  'trang_thai': 'DANG_CHAY',
  'ten_tuyen': 'Tuyến A',
  'bien_so': '51A-12345',
  'ten_tai_xe': 'Tài xế A',
  'sdt_tai_xe': '0900000000',
  'vi_do': null,
  'kinh_do': null,
  'cap_nhat_luc': null,
  'lich_su_diem_danh': <Object?>[],
};
