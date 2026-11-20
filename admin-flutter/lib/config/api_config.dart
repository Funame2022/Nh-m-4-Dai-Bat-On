class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nh-m-4-dai-bat-on.onrender.com',
  );

  static const String thongDiepChuaCauHinh =
      'Chưa cấu hình API_BASE_URL. Chạy ứng dụng với '
      '--dart-define=API_BASE_URL=<địa chỉ máy chủ>.';
}
