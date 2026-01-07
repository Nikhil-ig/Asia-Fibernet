// models/customer_model.dart

class CustomerModel {
  final int findCustomerId; // Maps to 'ID' from API
  final int
  accountId; // If not provided by this API, you might need a default or make it nullable
  final String contactName;
  final String? workPhone; // ✅ Nullable String — handles null & large numbers
  final String email;
  final String? area; // Maps to 'Address' from API

  CustomerModel({
    required this.findCustomerId,
    required this.accountId, // Consider if this is always available or should be nullable
    required this.contactName,
    this.workPhone, // ✅ Nullable
    required this.email,
    this.area,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Map API keys to model fields
    return CustomerModel(
      findCustomerId: _parseId(
        json['ID'],
      ), // Changed from 'find_customer_id' to 'ID'
      accountId: _parseId(
        json['AccountID'],
      ), // If AccountID isn't in response, provide default or handle
      contactName: _parseString(json['ContactName']) ?? 'Unknown',
      workPhone: _parsePhone(
        json['Workphnumber'] ?? json['Cellphnumber'],
      ), // Key matches
      email: _parseString(json['Email']) ?? 'N/A',
      area: _parseString(json['Address']), // Changed from 'area' to 'Address'
    );
  }

  // === HELPERS === (These can remain the same)
  static int _parseId(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {}
    }
    // Returning 0 as fallback might not be ideal if 0 is a valid ID.
    // Consider returning null and making the field nullable if ID is critical.
    // For accountId, if it's not in the search response, maybe it should be int? accountId
    // For now, keeping logic as is but noting the potential issue.
    return 0; // fallback
  }

  static String? _parseString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  static String? _parsePhone(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toString();
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  // === UI HELPERS === (These can remain the same)
  String get displayName => contactName.isNotEmpty ? contactName : 'Unnamed';
  String get displayPhone => workPhone ?? 'No phone';
  String get displayArea => area ?? 'N/A';
  String get displayEmail => email.isNotEmpty ? email : 'No email';
}
