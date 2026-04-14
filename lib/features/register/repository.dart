import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:voip_app/features/register/model.dart';
import '/services/api_service.dart';
import '/services/api_end_points.dart';

class RegisterRepository {
  final ApiService _apiService = ApiService();

  Future<LoginResponse?> register({
    required String username,
    required String password,
    required String token,
  }) async {
    Map<String, dynamic> body = {
      "username": username,
      "password": password,
      "device_type": Platform.isAndroid ? "android" : "ios",
      "token": token,
    };

    try {
      Response? response = await _apiService.postRequestResponse(
        url: "${ApiEndPoints.baseUrl}${ApiEndPoints.login}",
        body: body,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // THE FIX MOVES HERE
        final dynamic responseData = response.data;
        final Map<String, dynamic> jsonData = responseData is String
            ? jsonDecode(responseData)
            : responseData;

        print("Login Body: ${response.data}");
        return LoginResponse.fromJson(jsonData);
      } else {
        print("API Error: ${response?.statusCode}");
        return null;
      }
    } catch (e) {
      print("Repository Error: $e");
      return null;
    }
  }
}
