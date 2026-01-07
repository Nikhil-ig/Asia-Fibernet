// lib/models/bsnl_plan_model.dart

/// Represents a BSNL service plan with comprehensive details from real API.
class BsnlPlan {
  final int? id;
  final String? planName;
  final double? price;
  final String? speed;
  final String? dataLimit;
  final String? additionalBenefits; // <-- Renamed from 'benefits' to match API
  final String? validity; // <-- Keep as String, API sends "1 months", etc.
  final double? bsnlNetworkCharge;
  final double? otherNetworkCharge;
  final double? isdRate;

  BsnlPlan({
    this.id,
    this.planName,
    this.price,
    this.speed,
    this.dataLimit,
    this.additionalBenefits,
    this.validity,
    this.bsnlNetworkCharge,
    this.otherNetworkCharge,
    this.isdRate,
  });

  /// Factory to create BsnlPlan from JSON (real API format)
  factory BsnlPlan.fromJson(Map<String, dynamic> json) {
    return BsnlPlan(
      id: json['id'] is int ? json['id'] : null,
      planName: json['plan_name'] is String ? json['plan_name'] : null,
      price:
          json['price'] != null
              ? (double.tryParse(json['price'].toString()) ?? null)
              : null,
      speed: json['speed'] is String ? json['speed'] : null,
      dataLimit: json['data_limit'] is String ? json['data_limit'] : null,
      additionalBenefits:
          json['additional_benefits'] is String
              ? json['additional_benefits']
              : null,
      validity: json['validity'] is String ? json['validity'] : null,
      bsnlNetworkCharge:
          json['bsnl_network_charge'] != null
              ? (double.tryParse(json['bsnl_network_charge'].toString()) ??
                  null)
              : null,
      otherNetworkCharge:
          json['other_network_charge'] != null
              ? (double.tryParse(json['other_network_charge'].toString()) ??
                  null)
              : null,
      isdRate:
          json['isd_rate'] != null
              ? (double.tryParse(json['isd_rate'].toString()) ?? null)
              : null,
    );
  }

  /// Convert to JSON (if needed for caching or sending back)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'price': price?.toString(),
      'speed': speed,
      'data_limit': dataLimit,
      'additional_benefits': additionalBenefits,
      'validity': validity,
      'bsnl_network_charge': bsnlNetworkCharge?.toString(),
      'other_network_charge': otherNetworkCharge?.toString(),
      'isd_rate': isdRate?.toString(),
    };
  }

  /// Formatted price with ₹ symbol
  String get formattedPrice =>
      price != null ? '₹${price!.toStringAsFixed(2)}' : 'Price N/A';

  /// Speed as is (API already formats it)
  String get formattedSpeed => speed ?? 'Speed N/A';

  /// Data limit as provided
  String get formattedDataLimit => dataLimit ?? 'Data N/A';

  /// Validity as string (API sends "1 months", "6 Months", etc.)
  String get formattedValidity => validity ?? 'Validity N/A';

  /// Split additionalBenefits into list for UI display (if needed)
  List<String> get benefitsList {
    if (additionalBenefits == null) return [];
    return additionalBenefits!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Short summary for list tiles
  String get summary =>
      '${planName ?? 'Plan'} - ${formattedPrice} (${formattedValidity})';

  /// Copy with for immutable updates
  BsnlPlan copyWith({
    int? id,
    String? planName,
    double? price,
    String? speed,
    String? dataLimit,
    String? additionalBenefits,
    String? validity,
    double? bsnlNetworkCharge,
    double? otherNetworkCharge,
    double? isdRate,
  }) {
    return BsnlPlan(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      price: price ?? this.price,
      speed: speed ?? this.speed,
      dataLimit: dataLimit ?? this.dataLimit,
      additionalBenefits: additionalBenefits ?? this.additionalBenefits,
      validity: validity ?? this.validity,
      bsnlNetworkCharge: bsnlNetworkCharge ?? this.bsnlNetworkCharge,
      otherNetworkCharge: otherNetworkCharge ?? this.otherNetworkCharge,
      isdRate: isdRate ?? this.isdRate,
    );
  }

  @override
  String toString() {
    return 'BsnlPlan{id: $id, planName: $planName, price: $price, speed: $speed, '
        'validity: $validity, isdRate: $isdRate}';
  }
}

/// Extension methods for List<BsnlPlan> — updated for real fields
extension BsnlPlanListExtensions on List<BsnlPlan> {
  /// Filter by plan name (case-insensitive)
  List<BsnlPlan> filterByPlanName(String? query) {
    if (query == null || query.trim().isEmpty) return this;
    final lowerQuery = query.toLowerCase().trim();
    return where((plan) {
      final name = plan.planName?.toLowerCase() ?? '';
      return name.contains(lowerQuery);
    }).toList();
  }

  /// Sort by price ascending
  List<BsnlPlan> sortByPrice() {
    final sorted = List<BsnlPlan>.from(this);
    sorted.sort((a, b) {
      final aPrice = a.price ?? double.infinity;
      final bPrice = b.price ?? double.infinity;
      return aPrice.compareTo(bPrice);
    });
    return sorted;
  }

  /// Group by validity (e.g., "1 Month", "6 Months")
  Map<String, List<BsnlPlan>> groupByValidity() {
    Map<String, List<BsnlPlan>> groups = {};
    for (var plan in this) {
      final key = plan.validity ?? 'Unknown';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(plan);
    }
    return groups;
  }
}
