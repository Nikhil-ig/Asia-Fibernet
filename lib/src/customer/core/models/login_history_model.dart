// models/login_history_model.dart
class LoginHistoryModel {
  final int id;
  final String ipAddress;
  final String timeZone;
  final String cityName;
  final String device;
  final String brand;
  final String createdAt;

  LoginHistoryModel({
    required this.id,
    required this.ipAddress,
    required this.timeZone,
    required this.cityName,
    required this.device,
    required this.brand,
    required this.createdAt,
  });

  // Factory to create model from JSON
  factory LoginHistoryModel.fromJson(Map<String, dynamic> json) {
    return LoginHistoryModel(
      id: json['id'] as int,
      ipAddress: json['ip_address'] as String,
      timeZone: json['time_zone'] as String,
      cityName: json['city_name'] as String,
      device: json['device'] as String,
      brand: json['brand'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
