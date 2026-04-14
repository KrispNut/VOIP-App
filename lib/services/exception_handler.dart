import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '/core/constants/app_constants.dart';

class ExceptionHandler {
  static Response? handleDioError(DioException error) {
    if (error.response != null) {
      // --- BACKGROUND RECOVERY GUARD ---
      // If we're in a background CallKit/FCM recovery, suppress all
      // destructive error handling. Just log and return the response.
      if (AppConstants.isInBackgroundRecovery) {
        final errorMsg = _extractErrorMessage(error.response!);
        debugPrint(
          "[APP_LOG] Background recovery active. Suppressing error handler. "
          "Status: ${error.response!.statusCode}, Message: $errorMsg",
        );
        // Attempt silent credential restore if the error is about missing data
        if (_isRecoverableError(error.response!)) {
          debugPrint("[APP_LOG] Recoverable error detected. Triggering silent session restore...");
          AppConstants.restoreSession();
        }
        return error.response;
      }

      _handleResponseError(error.response!);
      final errorMessage = _extractErrorMessage(error.response!);
      if (errorMessage.isNotEmpty) {
        AppConstants.showToast(message: errorMessage, isError: true);
      }
      return error.response;
    } else {
      // No response at all (timeout, connection error, etc.)
      if (AppConstants.isInBackgroundRecovery) {
        debugPrint(
          "[APP_LOG] Background recovery active. Suppressing network error: ${error.type}",
        );
        return null;
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          AppConstants.showToast(
            message: "Connection timeout. Please try again.",
            isError: true,
          );
          break;
        case DioExceptionType.badCertificate:
          AppConstants.showToast(
            message: "Security certificate error.",
            isError: true,
          );
          break;
        case DioExceptionType.cancel:
          break;
        case DioExceptionType.connectionError:
          AppConstants.showToast(
            message: "No internet connection. Please check your network.",
            isError: true,
          );
          break;
        case DioExceptionType.unknown:
        default:
          AppConstants.showToast(
            message: "An unexpected error occurred. Please try again.",
            isError: true,
          );
      }
      return null;
    }
  }

  static void _handleResponseError(Response response) {
    switch (response.statusCode) {
      case 400:
      case 401:
      case 404:
      case 422:
        AppConstants.showToast(
          message: _extractErrorMessage(response),
          isError: true,
        );
        break;
      case 403:
        AppConstants.showToast(
          message: "Forbidden: Access is denied.",
          isError: true,
        );
        break;
      case 500:
      case 503:
        AppConstants.showToast(
          message: "Server Error: Please try again later.",
          isError: true,
        );
        break;
      default:
        AppConstants.showToast(
          message: "Unexpected error: ${response.statusCode}",
          isError: true,
        );
    }
  }

  /// Checks if this error is one we can silently recover from
  /// (e.g., missing extension due to fresh isolate memory).
  static bool _isRecoverableError(Response response) {
    if (response.statusCode == 400) {
      final msg = _extractErrorMessage(response).toLowerCase();
      if (msg.contains('extension') && msg.contains('required')) {
        return true;
      }
    }
    return false;
  }

  static String _extractErrorMessage(Response response) {
    try {
      final data = response.data;
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is Map) {
        return decoded["ErrorMessage"]?.toString() ??
            decoded["message"]?.toString() ??
            decoded["Message"]?.toString() ??
            '';
      }
    } catch (_) {}
    return '';
  }

  static bool isSuccessResponse(Response response) {
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
