import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'auth/auth_service.dart';
import 'auth/token_storage.dart';
import 'config/api_config.dart';
import 'fleet/quan_ly_service.dart';
import 'operations/quan_ly_operations_service.dart';

void main() {
  final client = http.Client();
  const storage = SecureTokenStorage();
  final baseUrl = ApiConfig.baseUrl;

  runApp(
    AdminApp(
      authService: AuthService(
        client: client,
        storage: storage,
        baseUrl: baseUrl,
      ),
      quanLyService: QuanLyService(
        client: client,
        storage: storage,
        baseUrl: baseUrl,
      ),
      operationsService: QuanLyOperationsService(
        client: client,
        storage: storage,
        baseUrl: baseUrl,
      ),
    ),
  );
}
