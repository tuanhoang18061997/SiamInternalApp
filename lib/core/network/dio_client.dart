import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../../presentation/providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(authTokenProvider);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      handler.next(response);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        return handler.resolve(error.response!);
      }
      return handler.next(error);
    },
  ));

  return dio;
});
