import 'package:dio/dio.dart';
import '/services/exception_handler.dart';

class ApiService {
  // Singleton Pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 35),
        receiveTimeout: const Duration(seconds: 35),
        responseType: ResponseType.json,
      ),
    );
  }

  Future<Response?> getRequestResponse(
    String url, {
    bool applyAuth = true,
  }) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'X-Tunnel-Skip-Anti-Phishing-Page': 'true'}),
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        ExceptionHandler.handleDioError(e);
        return e.response;
      } else {
        ExceptionHandler.handleDioError(e);
        return null;
      }
    }
  }

  Future<Response?> postRequestResponse({
    required String url,
    Map<String, dynamic>? body,
    bool applyAuth = true,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Tunnel-Skip-Anti-Phishing-Page': 'true',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        ExceptionHandler.handleDioError(e);
        return e.response;
      } else {
        ExceptionHandler.handleDioError(e);
        return null;
      }
    }
  }

  static bool handleResponseStatus(Response response) {
    return ExceptionHandler.isSuccessResponse(response);
  }
}
