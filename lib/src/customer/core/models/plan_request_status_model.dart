// models/plan_request_status_model.dart

class PlanRequestStatusModel {
  final int id;
  final int customerId;
  final String registerMobileNo;
  final String addedDateTime;
  final String status;
  final String? updatedBy;
  final String? updatedOn;
  final String? planRemark;
  final PlanDetails? currentPlan;
  final PlanDetails? requestedPlan;

  PlanRequestStatusModel({
    required this.id,
    required this.customerId,
    required this.registerMobileNo,
    required this.addedDateTime,
    required this.status,
    this.updatedBy,
    this.updatedOn,
    this.planRemark,
    this.currentPlan,
    this.requestedPlan,
  });

  factory PlanRequestStatusModel.fromJson(Map<String, dynamic> json) {
    return PlanRequestStatusModel(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      registerMobileNo: json['register_mobile_no'] as String,
      addedDateTime: json['added_date_time'] as String,
      status: json['status'] as String,
      updatedBy: json['updated_by'] as String?,
      updatedOn: json['updated_on'] as String?,
      planRemark: json['plan_remark'] as String?,
      currentPlan:
          json['current_plan'] != null
              ? PlanDetails.fromJson(
                json['current_plan'] as Map<String, dynamic>,
              )
              : null,
      requestedPlan:
          json['requested_plan'] != null
              ? PlanDetails.fromJson(
                json['requested_plan'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class PlanDetails {
  final int? id;
  final String? planName;
  final String? price;
  final String? speed;
  final String? dataLimit;
  final String? additionalBenefits;
  final String? validity;
  final String? bsnlNetworkCharge;
  final String? otherNetworkCharge;
  final String? isdRate;

  PlanDetails({
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

  factory PlanDetails.fromJson(Map<String, dynamic> json) {
    return PlanDetails(
      id: json['id'] as int?,
      planName: json['plan_name'] as String?,
      price: json['price'] as String?,
      speed: json['speed'] as String?,
      dataLimit: json['data_limit'] as String?,
      additionalBenefits: json['additional_benefits'] as String?,
      validity: json['validity'] as String?,
      bsnlNetworkCharge: json['bsnl_network_charge'] as String?,
      otherNetworkCharge: json['other_network_charge'] as String?,
      isdRate: json['isd_rate'] as String?,
    );
  }
}
