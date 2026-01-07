// lib/services/call_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CallService {
  final String url;
  final String apiKey;
  final String agentLoginId;

  CallService({
    required this.url,
    required this.apiKey,
    required this.agentLoginId,
  });

  /// Sends click-to-call request to the telephony provider.
  /// Returns decoded JSON on success or throws an exception.
  Future<Map<String, dynamic>> startClickToCall({
    required String customerNumber,
    required String serviceNumber,
    required String referenceState,
  }) async {
    var uri = Uri.parse(url);
    var request = http.MultipartRequest('POST', uri);

    request.fields['apiKey'] = apiKey;
    request.fields['agentloginid'] = agentLoginId;
    request.fields['customernumber'] = customerNumber;
    // keep the original field name 'servienumber' if the provider expects that
    request.fields['servienumber'] = serviceNumber;
    request.fields['referencestate'] = referenceState;
    request.fields['format'] = 'json';

    var response = await request.send();
    var text = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('API returned ${response.statusCode}: $text');
    }

    final jsonBody = json.decode(text) as Map<String, dynamic>;
    return jsonBody;
  }
}
