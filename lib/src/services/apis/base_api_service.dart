// services/base_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../sharedpref.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

typedef RequestInterceptor =
    Future<Map<String, dynamic>?> Function(
      String endpoint,
      Map<String, dynamic>? body,
      Map<String, String>? headers,
    );

typedef ResponseInterceptor = Future<http.Response> Function(http.Response res);

class BaseApiService {
  static const String api = "https://asiafibernet.in/af/api/";
  static const String apiTech = "https://asiafibernet.in/af/api/techAPI/";

  final String baseUrl;
  final Duration _timeout = const Duration(seconds: 15);
  final int _maxRetries = 1;

  // Interceptors
  RequestInterceptor? onRequest;
  ResponseInterceptor? onResponse;

  // Snackbar throttling
  DateTime? _lastSnackbarTime;
  String? _lastSnackbarMessage;

  BaseApiService([this.baseUrl = api]);

  // ————————————————————————
  // 🔧 Core HTTP Methods
  // ————————————————————————

  Uri buildUrl(String endpoint, {Map<String, String>? queryParameters}) {
    final uri = Uri.parse("$baseUrl$endpoint");
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }
    return uri;
  }

  Future<http.Response> _sendRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool ignoreToken = false,
    Map<String, String>? queryParameters,
  }) async {
    final token = await AppSharedPref.instance.getToken();
    final isGuest = AppSharedPref.instance.getRole() == "Guest";

    if (!ignoreToken && !isGuest && token == null) {
      unauthorized();
      throw Exception('Unauthorized: No token');
    }

    final finalHeaders = <String, String>{
      if (!ignoreToken && token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?headers,
    };

    var requestBody =
        body is String ? body : (body != null ? jsonEncode(body) : null);

    // ✅ Request Interceptor
    if (onRequest != null) {
      final intercepted = await onRequest!(endpoint, body, finalHeaders);
      if (intercepted != null) {
        requestBody = jsonEncode(intercepted);
      }
    }

    final url = buildUrl(endpoint, queryParameters: queryParameters);

    http.Response? response;
    int attempt = 0;

    while (attempt <= _maxRetries) {
      try {
        switch (method.toUpperCase()) {
          case 'POST':
            response = await http
                .post(url, headers: finalHeaders, body: requestBody)
                .timeout(_timeout);
            break;
          case 'GET':
            response = await http
                .get(url, headers: finalHeaders)
                .timeout(_timeout);
            break;
          case 'PUT':
            response = await http
                .put(url, headers: finalHeaders, body: requestBody)
                .timeout(_timeout);
            break;
          case 'DELETE':
            response = await http
                .delete(url, headers: finalHeaders)
                .timeout(_timeout);
            break;
          default:
            throw UnsupportedError('HTTP method $method not supported');
        }
        break; // Success → exit retry loop
      } on SocketException catch (e) {
        attempt++;
        if (attempt > _maxRetries) rethrow;
        developer.log('Retry $attempt for $endpoint due to network error: $e');
        await Future.delayed(const Duration(seconds: 1));
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt > _maxRetries) {
          logApiDebug(
            endpoint: endpoint,
            method: method,
            error: 'Timeout after ${_timeout.inSeconds}s',
          );
          throw e;
        }
        developer.log('Retry $attempt for $endpoint due to timeout');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (response == null) throw Exception('Unexpected null response');

    // ✅ Response Interceptor
    if (onResponse != null) {
      response = await onResponse!(response);
    }

    logApiDebug(
      endpoint: endpoint,
      method: method,
      statusCode: response.statusCode,
      requestBody: requestBody,
      responseBody: response.body,
    );

    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool ignoreToken = false,
  }) => _sendRequest(
    'POST',
    endpoint,
    headers: headers,
    body: body,
    ignoreToken: ignoreToken,
  );

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    bool ignoreToken = false,
  }) => _sendRequest(
    'GET',
    endpoint,
    headers: headers,
    queryParameters: queryParameters,
    ignoreToken: ignoreToken,
  );

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) => _sendRequest('PUT', endpoint, headers: headers, body: body);

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) => _sendRequest('DELETE', endpoint, headers: headers);

  // ————————————————————————
  // 🧰 Helpers
  // ————————————————————————
  /// Converts any file to a Base64 string with the correct MIME prefix.
  ///
  /// 🧩 Features:
  /// - Auto-detects MIME type (image, pdf, text, audio, video, etc.)
  /// - Default fallback: `application/octet-stream`
  /// - Never crashes — returns `null` safely if file invalid or unreadable.
  /// - Clean developer logging for debugging.
  Future<String?> fileToBase64(File? file, [String? overrideType]) async {
    if (file == null) {
      developer.log("fileToBase64: File is null — skipping encoding.");
      return null;
    }

    try {
      // ✅ Ensure file actually exists
      if (!await file.exists()) {
        developer.log("fileToBase64: File not found at ${file.path}");
        return null;
      }

      // ✅ Read file bytes
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        developer.log("fileToBase64: File is empty (${file.path})");
        return null;
      }

      // ✅ Detect MIME type automatically
      String? mimeType;
      if (overrideType != null && overrideType.trim().isNotEmpty) {
        // If manually provided (like 'pdf' or 'image/png')
        if (overrideType.contains('/')) {
          mimeType = overrideType; // e.g. 'application/pdf'
        } else {
          mimeType = lookupMimeType('dummy.$overrideType');
        }
      } else {
        mimeType = lookupMimeType(file.path);
      }

      mimeType ??= 'application/octet-stream'; // default fallback

      print(mimeType);

      // ✅ Encode and prepend MIME type
      final base64Data = base64Encode(bytes);
      // final result = "data:$mimeType;base64,$base64Data";
      final result = "$base64Data";

      developer.log(
        "fileToBase64: ✅ Encoded ${p.basename(file.path)} "
        "(${bytes.lengthInBytes} bytes, mime: $mimeType)",
      );

      return result;
    } catch (e, stack) {
      developer.log(
        "fileToBase64: ❌ Exception while encoding ${file.path}: $e",
        stackTrace: stack,
      );
      return null;
    }
  }

  String generateTicketNo() {
    final now = DateTime.now();
    final timePart = _formatDateTime(now);
    final randPart = (now.millisecondsSinceEpoch % 1000).toString().padLeft(
      3,
      '0',
    );
    return 'TKT-$timePart-$randPart';
  }

  String generateTicketNoByTech() {
    final now = DateTime.now();
    final timePart = _formatDateTime(now);
    final randPart = (now.millisecondsSinceEpoch % 1000).toString().padLeft(
      3,
      '0',
    );
    return 'TKT-T-$timePart-$randPart';
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.year % 100}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}-${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}";
  }

  // ————————————————————————
  // 📦 Response Handlers (for ApiServices)
  // ————————————————————————

  T? handleResponse<T>(
    http.Response res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (res.statusCode == 200) {
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' || json['status'] == 'exists') {
          return fromJson(json);
        } else {
          showSnackbar(
            "Error",
            json['message'] ?? "Unknown error",
            isError: true,
          );
        }
      } catch (e) {
        showSnackbar("Error", "Invalid response format", isError: true);
        developer.log("JSON decode error: $e in response: ${res.body}");
      }
    } else {
      handleHttpError(res.statusCode);
    }
    return null;
  }

  List<T>? handleListResponse<T>(
    http.Response res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (res.statusCode == 200) {
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          final data = json['data'] as List;
          return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
        } else {
          showSnackbar(
            "Error",
            json['message'] ?? "No data found.",
            isError: true,
          );
        }
      } catch (e) {
        showSnackbar("Error", "Invalid list response", isError: true);
        developer.log("List JSON decode error: $e in response: ${res.body}");
      }
    } else {
      handleHttpError(res.statusCode);
    }
    return null;
  }

  bool handleSuccessResponse(http.Response res, String successMsg) {
    if (res.statusCode == 200) {
      try {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          showSnackbar("Success", successMsg, isError: false);
          return true;
        } else {
          showSnackbar("Error", json['message'] ?? "Operation failed");
        }
      } catch (e) {
        showSnackbar("Error", "Invalid success response");
      }
    } else {
      handleHttpError(res.statusCode);
    }
    return false;
  }

  // ————————————————————————
  // 🛑 Error & UI
  // ————————————————————————

  void showSnackbar(
    String title,
    String message, {
    bool? isError,
    TextButton? mainButton,
  }) {
    isError = title == 'Error';
    // 🚫 Prevent snackbar spam
    final now = DateTime.now();
    if (_lastSnackbarMessage == message &&
        _lastSnackbarTime != null &&
        now.difference(_lastSnackbarTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastSnackbarMessage = message;
    _lastSnackbarTime = now;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red : Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      mainButton: mainButton,
    );
  }

  String? prependBaseUrl(String? path) {
    if (path != null && path.isNotEmpty) {
      // Check if the path already starts with 'http://' or 'https://'
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      // Otherwise, prepend the base URL
      // return '${BaseApiService.api}$path';
      return '$api$path';
    }
    return null;
  }

  void handleHttpError(int statusCode) {
    String msg = "Request failed.";
    switch (statusCode) {
      case 401:
        msg = "Session expired. Please log in again.";
        unauthorized();
        return;
      case 400:
        msg = "Invalid request.";
        break;
      case 404:
        msg = "Resource not found.";
        break;
      case 500:
        msg = "Server error.";
        break;
      default:
        msg = "Error: $statusCode";
    }
    showSnackbar("Error", msg);
  }

  void unauthorized() {
    showSnackbar("Unauthorized", "Please log in again.");
    AppSharedPref.instance.clearAllUserData();
    Get.offAllNamed('/login');
  }

  // ————————————————————————
  // 📝 Logging
  // ————————————————————————

  void logApiDebug({
    required String endpoint,
    required String method,
    int? statusCode,
    String? requestBody,
    String? responseBody,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== API DEBUG ===');
    buffer.writeln('URL: $baseUrl$endpoint');
    buffer.writeln('Method: $method');
    buffer.writeln('Time: ${DateTime.now().toIso8601String()}');
    if (requestBody != null) {
      buffer.writeln(
        'Request: ${requestBody.length > 500 ? "<large payload>" : requestBody}',
      );
    }
    if (statusCode != null) buffer.writeln('Status: $statusCode');
    if (responseBody != null) {
      buffer.writeln(
        'Response: ${responseBody}',
        // 'Response: ${responseBody}',
      );
    }
    if (error != null) {
      buffer.writeln('❌ ERROR: $error');
      if (stackTrace != null) buffer.writeln('Stack: $stackTrace');
    }
    buffer.writeln('=================');
    developer.log(buffer.toString(), name: 'API');
  }
}
