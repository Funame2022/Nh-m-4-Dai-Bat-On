class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String thongDiepChuaCauHinh =
      'Chưa cấu hình API_BASE_URL. Chạy ứng dụng với '
      '--dart-define=API_BASE_URL=<địa chỉ máy chủ>.';
}
