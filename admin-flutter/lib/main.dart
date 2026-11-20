import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'auth/auth_interceptor.dart';
import 'auth/auth_service.dart';
import 'auth/token_storage.dart';
import 'config/api_config.dart';
import 'fleet/quan_ly_service.dart';
import 'operations/quan_ly_operations_service.dart';
import 'operations/van_hanh_service.dart';

void main() {
  final rawClient = http.Client();
  const storage = SecureTokenStorage();
  final baseUrl = ApiConfig.baseUrl;

  final authService = AuthService(
    client: rawClient,
    storage: storage,
    baseUrl: baseUrl,
  );

  // Interceptor tự động bắt mã 401 trên các API yêu cầu xác thực và thông báo hết hạn
  final interceptedClient = AuthHttpInterceptor(
    inner: rawClient,
    storage: storage,
    onSessionExpired: authService.notifySessionExpired,
  );

  final vanHanhService = VanHanhService(
    client: interceptedClient,
    storage: storage,
    baseUrl: baseUrl,
    onTokenExpired: () async => authService.notifySessionExpired(),
  );

  runApp(
    AdminApp(
      authService: authService,
      quanLyService: QuanLyService(
        client: interceptedClient,
        storage: storage,
        baseUrl: baseUrl,
      ),
      operationsService: QuanLyOperationsService(
        client: interceptedClient,
        storage: storage,
        baseUrl: baseUrl,
      ),
      vanHanhService: vanHanhService,
    ),
  );
}
