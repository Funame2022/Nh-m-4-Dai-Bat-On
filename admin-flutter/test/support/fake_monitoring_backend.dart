import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeMonitoringBackend {
  FakeMonitoringBackend({required this.data, this.autoRespond = true});

  List<Map<String, dynamic>> data;
  bool autoRespond;
  int requestCount = 0;
  final List<Completer<http.Response>> _pending = [];

  http.Client get client => MockClient((_) {
    requestCount += 1;
    if (autoRespond) {
      return Future.value(_json(data));
    }
    final completer = Completer<http.Response>();
    _pending.add(completer);
    return completer.future;
  });

  void completeNext([List<Map<String, dynamic>>? duLieuMoi]) {
    final completer = _pending.removeAt(0);
    completer.complete(_json(duLieuMoi ?? data));
  }

  http.Response _json(Object body) => http.Response(
    jsonEncode(body),
    statusCodeFor(body),
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );

  int statusCodeFor(Object body) => 200;
}

List<Map<String, dynamic>> taoDuLieuGiamSat({
  double viDo = 10.1,
  double kinhDo = 106.1,
}) {
  final bayGio = DateTime.now();
  return [
    {
      'id': 1,
      'tuyen_id': 5,
      'ngay': '2026-11-17',
      'chieu': 'DON_SANG',
      'trang_thai': 'DANG_CHAY',
      'ten_tuyen': 'Tuyến 01',
      'bien_so': '51B-111.11',
      'vi_do': viDo,
      'kinh_do': kinhDo,
      'vi_tri_cap_nhat_luc': bayGio.toIso8601String(),
    },
    {
      'id': 2,
      'tuyen_id': 6,
      'ngay': '2026-11-17',
      'chieu': 'TRA_CHIEU',
      'trang_thai': 'CHUA_CHAY',
      'ten_tuyen': 'Tuyến 02',
      'bien_so': '51B-222.22',
      'vi_do': null,
      'kinh_do': null,
      'vi_tri_cap_nhat_luc': null,
    },
    {
      'id': 3,
      'tuyen_id': 7,
      'ngay': '2026-11-17',
      'chieu': 'DON_SANG',
      'trang_thai': 'HOAN_THANH',
      'ten_tuyen': 'Tuyến 03',
      'bien_so': '51B-333.33',
      'vi_do': 10.3,
      'kinh_do': 106.3,
      'vi_tri_cap_nhat_luc': bayGio
          .subtract(const Duration(minutes: 5))
          .toIso8601String(),
    },
  ];
}
