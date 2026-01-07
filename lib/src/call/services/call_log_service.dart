// lib/services/call_log_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CallLog {
  final String customerNumber;
  final String serviceNumber;
  final String status; // connected / failed / missed / ended
  final int durationSeconds;
  final DateTime timestamp;
  final String? message;

  CallLog({
    required this.customerNumber,
    required this.serviceNumber,
    required this.status,
    required this.durationSeconds,
    required this.timestamp,
    this.message,
  });

  Map<String, dynamic> toMap() => {
    'customerNumber': customerNumber,
    'serviceNumber': serviceNumber,
    'status': status,
    'durationSeconds': durationSeconds,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
  };

  static CallLog fromMap(Map<String, dynamic> m) => CallLog(
    customerNumber: m['customerNumber'],
    serviceNumber: m['serviceNumber'],
    status: m['status'],
    durationSeconds: m['durationSeconds'],
    timestamp: DateTime.parse(m['timestamp']),
    message: m['message'],
  );
}

class CallLogService {
  static const _key = 'call_logs';

  Future<void> addLog(CallLog log) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    final List<Map<String, dynamic>> list =
        raw == null ? [] : List<Map<String, dynamic>>.from(json.decode(raw));
    list.insert(0, log.toMap()); // newest first
    await sp.setString(_key, json.encode(list));
  }

  Future<List<CallLog>> getLogs() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return [];
    final List<dynamic> decoded = json.decode(raw);
    return decoded
        .map((e) => CallLog.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> clearLogs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
