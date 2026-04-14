import '/features/home/model.dart';
import '/services/api_service.dart';
import '/services/api_end_points.dart';
import 'package:flutter/foundation.dart';

class HomeRepository {
  final ApiService _apiService = ApiService();

  Future<CallResponse?> makeCall({required String ext}) async {
    final Map<String, dynamic> body = {"extension": ext};

    debugPrint("Body: $body");
    try {
      final response = await _apiService.postRequestResponse(
        url: "${ApiEndPoints.baseUrl}${ApiEndPoints.call}",
        body: body,
      );
      debugPrint("API Raw Response Data: ${response?.data}");

      if (response?.statusCode == 200 && response?.data != null) {
        return CallResponse.fromJson(response?.data);
      } else {
        debugPrint("Calling failed with status: ${response?.statusCode}");
      }
    } catch (e, stacktrace) {
      debugPrint("Calling repository exception: $e");
      debugPrint("Stacktrace: $stacktrace");
    }
    return null;
  }
}
