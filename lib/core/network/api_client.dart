import 'package:dio/dio.dart';


Dio createApiClient() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 30),
  ),
);
