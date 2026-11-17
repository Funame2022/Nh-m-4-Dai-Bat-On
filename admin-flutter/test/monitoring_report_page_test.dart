import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/operations/quan_ly_operations_service.dart';
import 'package:xe_truong_admin/screens/monitoring/giam_sat_page.dart';
import 'package:xe_truong_admin/screens/reports/bao_cao_page.dart';

import 'support/fake_monitoring_backend.dart';
import 'support/fake_token_storage.dart';

QuanLyOperationsService taoService(
  http.Client client, {
  String baseUrl = 'http://api.test',
  GiamSatConnector? giamSatConnector,
}) => QuanLyOperationsService(
  client: client,
  storage: FakeTokenStorage('saved-token'),
  baseUrl: baseUrl,
  giamSatConnector:
      giamSatConnector ?? (_, _) => Future.error(StateError('offline')),
);

class FakeGiamSatConnection implements GiamSatConnection {
  final StreamController<dynamic> _messages = StreamController<dynamic>();
  bool closed = false;
  bool get hasListener => _messages.hasListener;

  @override
  Stream<dynamic> get messages => _messages.stream;

  void emit(String message) => _messages.add(message);

  @override
  Future<void> close() async {
    closed = true;
    await _messages.close();
  }
}

Future<void> pumpGiamSat(
  WidgetTester tester,
  FakeMonitoringBackend backend, {
  String baseUrl = 'http://api.test',
  GiamSatConnector? giamSatConnector,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: GiamSatPage(
        service: taoService(
          backend.client,
          baseUrl: baseUrl,
          giamSatConnector: giamSatConnector,
        ),
      ),
    ),
  );
}

Future<void> pumpBaoCao(WidgetTester tester, http.Client client) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: BaoCaoPage(service: taoService(client)),
    ),
  );
}

String ngayIso(DateTime ngay) {
  final nam = ngay.year.toString().padLeft(4, '0');
  final thang = ngay.month.toString().padLeft(2, '0');
  final ngayTrongThang = ngay.day.toString().padLeft(2, '0');
  return '$nam-$thang-$ngayTrongThang';
}

void main() {
  group('GiamSatPage', () {
    testWidgets(
      'hiển thị dữ liệu ban đầu và không polling khi WebSocket chưa kết nối',
      (tester) async {
        final backend = FakeMonitoringBackend(
          data: taoDuLieuGiamSat(viDo: 10.1, kinhDo: 106.1),
        );

        await pumpGiamSat(tester, backend);
        await tester.pumpAndSettle();

        expect(backend.requestCount, 1);
        expect(find.byKey(const Key('giam-sat-row-1')), findsOneWidget);
        expect(find.textContaining('10.1'), findsOneWidget);
        expect(find.textContaining('Chưa có dữ liệu GPS'), findsOneWidget);
        expect(find.textContaining('GPS cũ'), findsOneWidget);
        expect(find.textContaining('kết nối'), findsOneWidget);

        backend.data = taoDuLieuGiamSat(viDo: 10.9, kinhDo: 106.9);
        await tester.pump(const Duration(seconds: 15));
        await tester.pumpAndSettle();

        expect(backend.requestCount, 1);
        expect(find.textContaining('10.1'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );

    testWidgets('cập nhật vị trí ngay khi nhận sự kiện GPS qua WebSocket', (
      tester,
    ) async {
      final connection = FakeGiamSatConnection();
      Uri? socketUri;
      Map<String, String>? socketHeaders;
      final backend = FakeMonitoringBackend(data: taoDuLieuGiamSat());

      try {
        await pumpGiamSat(
          tester,
          backend,
          giamSatConnector: (uri, headers) async {
            socketUri = uri;
            socketHeaders = headers;
            return connection;
          },
        );
        await tester.pumpAndSettle();

        expect(socketUri?.scheme, 'ws');
        expect(socketUri?.path, '/api/quan-ly/giam-sat/ws');
        expect(socketHeaders?['Authorization'], 'Bearer saved-token');
        expect(connection.hasListener, isTrue);

        final thoiDiem = DateTime.now().toUtc().add(const Duration(minutes: 1));
        connection.emit(
          jsonEncode({
            'type': 'gps_updated',
            'data': {
              'chuyen_di_id': 1,
              'vi_do': 10.9876,
              'kinh_do': 106.5432,
              'thoi_diem': thoiDiem.toIso8601String(),
            },
          }),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('10.9876'), findsOneWidget);
        expect(find.textContaining('106.5432'), findsOneWidget);
        expect(find.text('Đang nhận cập nhật trực tiếp.'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
      expect(connection.closed, isTrue);
    });

    testWidgets('hiển thị thời điểm GPS theo múi giờ của thiết bị', (
      tester,
    ) async {
      const thoiDiemUtc = '2026-11-17T10:20:40.000Z';
      final thoiDiemDiaPhuong = DateTime.parse(thoiDiemUtc).toLocal();
      final backend = FakeMonitoringBackend(
        data: taoDuLieuGiamSat()..[0]['vi_tri_cap_nhat_luc'] = thoiDiemUtc,
      );

      await pumpGiamSat(tester, backend);
      await tester.pumpAndSettle();

      final ngay = thoiDiemDiaPhuong.day.toString().padLeft(2, '0');
      final thang = thoiDiemDiaPhuong.month.toString().padLeft(2, '0');
      final gio = thoiDiemDiaPhuong.hour.toString().padLeft(2, '0');
      final phut = thoiDiemDiaPhuong.minute.toString().padLeft(2, '0');
      final giay = thoiDiemDiaPhuong.second.toString().padLeft(2, '0');

      expect(
        find.text(
          'GPS: $ngay/$thang/${thoiDiemDiaPhuong.year} $gio:$phut:$giay',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('không polling khi request ban đầu còn pending', (
      tester,
    ) async {
      final backend = FakeMonitoringBackend(
        data: taoDuLieuGiamSat(),
        autoRespond: false,
      );

      await pumpGiamSat(tester, backend);
      await tester.pump();
      expect(backend.requestCount, 1);

      await tester.pump(const Duration(seconds: 15));
      expect(backend.requestCount, 1);

      backend.completeNext();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('giam-sat-row-1')), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
      expect(backend.requestCount, 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('dispose hủy timer và không gọi thêm', (tester) async {
      final backend = FakeMonitoringBackend(data: taoDuLieuGiamSat());

      await pumpGiamSat(tester, backend);
      await tester.pumpAndSettle();
      expect(backend.requestCount, 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(backend.requestCount, 1);
    });
  });

  group('BaoCaoPage', () {
    testWidgets(
      'hiển thị KPI, hai biểu đồ 5 chuyến/3 hoàn thành và đổi ngày có clamp',
      (tester) async {
        final now = DateTime.now();
        final ngayMoi = now.day == 10 ? 11 : 10;
        late Uri lanGoiCuoi;

        http.Response jsonResponse(Object body) => http.Response(
          jsonEncode(body),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );

        final client = MockClient((request) async {
          lanGoiCuoi = request.url;
          final ngay = request.url.queryParameters['ngay'];
          if (ngay != null &&
              ngay.endsWith('-${ngayMoi.toString().padLeft(2, '0')}')) {
            return jsonResponse({
              'tong_xe': 7,
              'tong_tuyen': 4,
              'tong_hoc_sinh': 50,
              'tong_chuyen_ngay': 2,
              'chuyen_hoan_thanh': 5,
              'so_bao_nghi': 9,
              'so_da_len_xe': 41,
            });
          }
          return jsonResponse({
            'tong_xe': 3,
            'tong_tuyen': 2,
            'tong_hoc_sinh': 40,
            'tong_chuyen_ngay': 5,
            'chuyen_hoan_thanh': 3,
            'so_bao_nghi': 2,
            'so_da_len_xe': 35,
          });
        });

        await pumpBaoCao(tester, client);
        await tester.pumpAndSettle();

        expect(lanGoiCuoi.queryParameters['ngay'], ngayIso(now));
        expect(find.byType(BarChart), findsNWidgets(2));
        expect(find.byKey(const Key('bao-cao-chart-chuyen')), findsOneWidget);
        expect(find.byKey(const Key('bao-cao-chart-hoc-sinh')), findsOneWidget);
        expect(find.text('Hoàn thành: 3'), findsOneWidget);
        expect(find.text('Chưa hoàn thành: 2'), findsOneWidget);
        expect(find.text('Đã lên xe: 35'), findsOneWidget);
        expect(find.text('Báo nghỉ: 2'), findsOneWidget);

        final bieuDoChuyen = tester.widget<BarChart>(
          find.descendant(
            of: find.byKey(const Key('bao-cao-chart-chuyen')),
            matching: find.byType(BarChart),
          ),
        );
        expect(
          bieuDoChuyen.data.barGroups.single.barRods
              .map((rod) => rod.toY)
              .toList(),
          [3.0, 2.0],
        );

        final bieuDoHocSinh = tester.widget<BarChart>(
          find.descendant(
            of: find.byKey(const Key('bao-cao-chart-hoc-sinh')),
            matching: find.byType(BarChart),
          ),
        );
        expect(
          bieuDoHocSinh.data.barGroups.single.barRods
              .map((rod) => rod.toY)
              .toList(),
          [35.0, 2.0],
        );

        expect(
          find.descendant(
            of: find.byKey(const Key('bao-cao-kpi-xe')),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('bao-cao-kpi-tuyen')),
            matching: find.text('2'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('bao-cao-kpi-hoc-sinh')),
            matching: find.text('40'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('bao-cao-chon-ngay')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('$ngayMoi').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        final ngayMongDoi = DateTime(now.year, now.month, ngayMoi);
        expect(lanGoiCuoi.queryParameters['ngay'], ngayIso(ngayMongDoi));
        expect(find.text('Hoàn thành: 5'), findsOneWidget);
        expect(find.text('Chưa hoàn thành: 0'), findsOneWidget);

        final bieuDoChuyenSau = tester.widget<BarChart>(
          find.descendant(
            of: find.byKey(const Key('bao-cao-chart-chuyen')),
            matching: find.byType(BarChart),
          ),
        );
        expect(
          bieuDoChuyenSau.data.barGroups.single.barRods
              .map((rod) => rod.toY)
              .toList(),
          [5.0, 0.0],
        );

        expect(
          find.descendant(
            of: find.byKey(const Key('bao-cao-kpi-xe')),
            matching: find.text('7'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
