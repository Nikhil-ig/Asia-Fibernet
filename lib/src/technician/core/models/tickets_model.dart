// models/ticket_model.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/apis/base_api_service.dart';

class TicketModel {
  // === Core Fields (common across all ticket types) ===
  final String ticketNo;
  final String createdAt;
  final String status;
  final String? technician;
  final int? assignTo;
  final bool editable;

  // === Priority (newly added) ===
  final String? priority; // e.g., 'High', 'Medium', 'Low'

  // === Detailed Fields (from full ticket API) ===
  final int? customerId;
  final String? customerMobileNo;
  final String? customerName;
  final String? image;
  final String? updatedAt;
  final String? description;
  final String? category;
  final String? subCategory;
  final String? closedRemark;
  final String? closedAt;
  final String? technicianName;

  // === New: Ticket Type (complaint | relocation | disconnection) ===
  final String? ticketType;

  // === Relocation-Specific Fields (nullable) ===
  final String? serviceNo;
  final String? mobileNo;
  final String? oldAddress;
  final String? newAddress;
  final String? relocationType;
  final String? preferredShiftDate;
  final String? charges;
  final String? emailId;
  final String? planPeriod;
  final String? billingAddress;
  final String? subscribePlan;
  final String? ssaCode;
  final int? technicianId;
  final String? remark;
  final String? completionDate;

  // === Disconnection-Specific Fields (nullable) ===
  final String? disconnectionVoucherNo;
  final String? contactMobile;
  final String? otherPhoneNumber;
  final String? storeName;
  final String? itemId;
  final String? itemName;
  final String? macId;
  final String? itemStatus;
  final int? refundRequired;
  final String? itemImagePath;

  // Private constructor
  TicketModel._({
    required this.ticketNo,
    required this.createdAt,
    required this.status,
    this.technician,
    this.assignTo,
    required this.editable,
    this.priority, // added
    this.customerId,
    this.customerMobileNo,
    this.customerName,
    this.image,
    this.updatedAt,
    this.description,
    this.category,
    this.subCategory,
    this.closedRemark,
    this.closedAt,
    this.technicianName,
    this.ticketType,
    // Relocation
    this.serviceNo,
    this.mobileNo,
    this.oldAddress,
    this.newAddress,
    this.relocationType,
    this.preferredShiftDate,
    this.charges,
    this.emailId,
    this.planPeriod,
    this.billingAddress,
    this.subscribePlan,
    this.ssaCode,
    this.technicianId,
    this.remark,
    this.completionDate,
    // Disconnection
    this.disconnectionVoucherNo,
    this.contactMobile,
    this.otherPhoneNumber,
    this.storeName,
    this.itemId,
    this.itemName,
    this.macId,
    this.itemStatus,
    this.refundRequired,
    this.itemImagePath,
  });

  // ===== FACTORY CONSTRUCTORS =====

  /// Standard complaint ticket
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel._(
      customerId: json['customer_id'] is int ? json['customer_id'] : null,
      ticketNo: (json['ticket_no'] as String?)?.trim() ?? 'N/A',
      createdAt: (json['created_at'] as String?)?.trim() ?? 'N/A',
      status: (json['status'] as String?)?.trim() ?? 'Unknown',
      technician: json['technician'] as String?,
      assignTo: _parseAssignTo(json['assign_to']),
      editable: _parseEditable(json['editable']),
      priority: (json['priority'] as String?)?.trim(), // added
      customerMobileNo: json['customer_mobile_no'] as String?,
      customerName: json['customer_name'] as String?,
      image: json['image'] as String?,
      updatedAt: json['updated_at'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      subCategory: json['sub_category'] as String?,
      closedRemark: json['closed_remark'] as String?,
      closedAt: json['closed_at'] as String?,
      technicianName: json['technician_name'] as String?,
      ticketType: 'complaint',
    );
  }

  /// From Relocation JSON
  factory TicketModel.fromRelocationJson(Map<String, dynamic> json) {
    return TicketModel._(
      ticketNo: (json['ticket_no'] as String?)?.trim() ?? 'N/A',
      createdAt: (json['created_at'] as String?)?.trim() ?? 'N/A',
      status: (json['status'] as String?)?.trim() ?? 'Pending',
      assignTo: _parseAssignTo(json['assign_to']),
      editable: false,
      priority: (json['priority'] as String?)?.trim(), // added
      customerId: json['customer_id'] is int ? json['customer_id'] : null,
      customerName: json['customer_name'] as String?,
      customerMobileNo: json['mobile_no'] as String?,
      mobileNo: json['mobile_no'] as String?,
      serviceNo: json['service_no'] as String?,
      oldAddress: json['old_address'] as String?,
      newAddress: json['new_address'] as String?,
      relocationType: json['relocation_type'] as String?,
      preferredShiftDate: json['preferred_shift_date'] as String?,
      charges: json['charges'] as String?,
      emailId: json['email_id'] as String?,
      planPeriod: json['plan_period'] as String?,
      billingAddress: json['billing_address'] as String?,
      subscribePlan: json['subscribe_plan'] as String?,
      ssaCode: json['ssa_code'] as String?,
      technicianId:
          json['technician_id'] is int
              ? json['technician_id']
              : (json['technician_id'] is String
                  ? int.tryParse(json['technician_id'] as String)
                  : null),
      remark: json['remark'] as String?,
      completionDate: json['completion_date'] as String?,
      technician: json['assign_to'] as String?,
      ticketType: 'relocation',
    );
  }

  /// From Disconnection JSON
  factory TicketModel.fromDisconnectionJson(Map<String, dynamic> json) {
    final String ticketNo =
        (json['ticket_no'] as String?)?.trim() ??
        (json['disconnection_voucher_no'] as String?)?.trim() ??
        'N/A';

    return TicketModel._(
      ticketNo: ticketNo,
      createdAt: (json['created_at'] as String?)?.trim() ?? 'N/A',
      status: (json['status'] as String?)?.trim() ?? 'Pending',
      assignTo: _parseAssignTo(json['technician_id']),
      editable: false,
      priority: (json['priority'] as String?)?.trim(), // added
      customerId: json['customer_id'] is int ? json['customer_id'] : null,
      customerName: json['customer_name'] as String?,
      customerMobileNo: json['contact_mobile'] as String?,
      contactMobile: json['contact_mobile'] as String?,
      otherPhoneNumber: json['other_phone_number'] as String?,
      disconnectionVoucherNo: json['disconnection_voucher_no'] as String?,
      storeName: json['store_name'] as String?,
      itemId: json['item_id'] as String?,
      itemName: json['item_name'] as String?,
      macId: json['mac_id'] as String?,
      itemStatus: json['item_status'] as String?,
      refundRequired:
          json['refund_required'] is int ? json['refund_required'] : null,
      itemImagePath: json['item_image_path'] as String?,
      technician: json['assign_to'] as String?,
      ticketType: 'disconnection',
    );
  }

  // ===== Helper: Full image URL =====
  String? get fullImageUrl {
    final path = image ?? itemImagePath;
    if (path == null) return null;
    if (path.isEmpty || path.startsWith('http')) return path;
    return '${BaseApiService.api}$path';
  }

  // ===== Priority Color Helper (as hex string) =====

  Color get priorityColor {
    final p = (priority ?? '').toLowerCase().trim();
    switch (p) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ===== Helpers =====
  bool get isClosed {
    final s = status.toLowerCase();
    return s == 'closed' || s == 'resolved' || s == 'completed';
  }

  bool get isOpen => !isClosed;

  bool requiresOtpVerification({int hoursThreshold = 4}) {
    if (isClosed) return false;
    try {
      final DateTime createdAtDateTime = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).parse(createdAt);
      final DateTime now = DateTime.now();
      return now.difference(createdAtDateTime).inHours >= hoursThreshold;
    } catch (e) {
      return false;
    }
  }

  // ===== Private Helpers =====
  static int? _parseAssignTo(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  static bool _parseEditable(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  @override
  String toString() {
    return 'TicketModel(type: $ticketType, ticketNo: $ticketNo, status: $status, priority: $priority)';
  }
}
