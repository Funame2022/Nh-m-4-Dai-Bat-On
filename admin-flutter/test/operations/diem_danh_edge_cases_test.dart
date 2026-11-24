import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xe_truong_admin/models/van_hanh.dart';
import 'package:xe_truong_admin/operations/van_hanh_service.dart';

import '../support/fake_token_storage.dart';

void main() {
  group('Kiểm thử các ca biên và lỗi ngoại lệ (Edge Cases)', () {
    test('Lỗi kết nối Socket / Timeout khi điểm danh ném VanHanhApiException mã 0', () async {
      final storage = FakeTokenStorage('valid-token');
      final client = MockClient((_) async => throw http.ClientException('Connection refused'));

      final service = VanHanhService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      );

      expect(
        () => service.diemDanh(
          chuyenId: 1,
          hocSinhId: 101,
          suKien: 'LEN_XE',
        ),
        throwsA(
          isA<VanHanhApiException>()
              .having((e) => e.statusCode, 'statusCode', 0)
              .having((e) => e.message, 'message', contains('Lỗi kết nối máy chủ')),
        ),
      );
    });

    test('Lỗi dữ liệu phản hồi điểm danh không đúng định dạng (Malformed JSON)', () async {
      final storage = FakeTokenStorage('valid-token');
      final client = MockClient((_) async => http.Response('Internal Server Error HTML', 200));

      final service = VanHanhService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      );

      expect(
        () => service.diemDanh(
          chuyenId: 1,
          hocSinhId: 101,
          suKien: 'LEN_XE',
        ),
        throwsA(
          isA<VanHanhApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('không hợp lệ')),
        ),
      );
    });

    test('Lỗi chưa cấu hình hoặc rỗng baseUrl', () async {
      final storage = FakeTokenStorage('valid-token');
      final client = MockClient((_) async => http.Response('{}', 200));

      final service = VanHanhService(
        client: client,
        storage: storage,
        baseUrl: '', // rỗng
      );

      expect(service.daCauHinh, isFalse);
      expect(
        () => service.layDanhSachChuyenHomNay(),
        throwsA(isA<VanHanhApiException>()),
      );
    });

    test('Kết thúc chuyến với cờ boQua = true gửi query parameter boQua=true', () async {
      final storage = FakeTokenStorage('valid-token');
      late http.Request capturedRequest;

      final client = MockClient((req) async {
        capturedRequest = req;
        return http.Response(
          jsonEncode({
            'id': 10,
            'tuyen_id': 2,
            'ngay': '2026-11-20',
            'chieu': 'DON_SANG',
            'trang_thai': 'DA_HOAN_THANH',
            'ten_tuyen': 'Tuyến 1',
            'bien_so': '51B-11111',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = VanHanhService(
        client: client,
        storage: storage,
        baseUrl: 'http://api.test',
      );

      final chuyen = await service.ketThucChuyen(10, boQua: true);

      expect(capturedRequest.url.queryParameters['boQua'], 'true');
      expect(chuyen.trangThai, TrangThaiChuyen.hoanThanh);
    });
  });
}
