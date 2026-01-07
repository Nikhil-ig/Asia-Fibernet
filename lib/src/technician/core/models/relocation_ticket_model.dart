// // lib/core/models/relocation_ticket_model.dart
// import 'tickets_model.dart';

// class RelocationTicketModel {
//   final int? id;
//   final int? customerId;
//   final String? customerName;
//   final String? mobileNo;
//   final String? emailId;
//   final String? planPeriod;
//   final String? oldAddress;
//   final String? newAddress;
//   final String? serviceNo;
//   final String? subscribePlan;
//   final String? billingAddress;
//   final String status;
//   final String ticketNo;
//   final String? preferredShiftDate;
//   final String? relocationType;
//   final String? ssaCode;
//   final double? charges;
//   final String createdAt;
//   final String? updatedAt;
//   final String? completionDate;
//   final String? remark;
//   final int? technicianId;
//   final String? assignTo;

//   RelocationTicketModel({
//     this.id,
//     this.customerId,
//     this.customerName,
//     this.mobileNo,
//     this.emailId,
//     this.planPeriod,
//     this.oldAddress,
//     this.newAddress,
//     this.serviceNo,
//     this.subscribePlan,
//     this.billingAddress,
//     required this.status,
//     required this.ticketNo,
//     this.preferredShiftDate,
//     this.relocationType,
//     this.ssaCode,
//     this.charges,
//     required this.createdAt,
//     this.updatedAt,
//     this.completionDate,
//     this.remark,
//     this.technicianId,
//     this.assignTo,
//   });

//   factory RelocationTicketModel.fromJson(Map<String, dynamic> json) {
//     return RelocationTicketModel(
//       id: json['id'] as int?,
//       customerId: json['customer_id'] as int?,
//       customerName: json['customer_name'] as String? ?? "N/A",
//       mobileNo: json['mobile_no'] as String? ?? "N/A",
//       emailId: json['email_id'] as String? ?? "N/A",
//       planPeriod: json['plan_period'] as String? ?? "N/A",
//       oldAddress: json['old_address'] as String? ?? "N/A",
//       newAddress: json['new_address'].trim(),
//       serviceNo: json['service_no'] as String? ?? "N/A",
//       subscribePlan: json['subscribe_plan'] as String? ?? "N/A",
//       billingAddress: json['billing_address'] as String? ?? "N/A",
//       status: json['status'] as String? ?? "N/A",
//       ticketNo: json['ticket_no'] as String? ?? "N/A",
//       preferredShiftDate: json['preferred_shift_date'] as String? ?? "N/A",
//       relocationType: json['relocation_type'] as String? ?? "N/A",
//       ssaCode: json['ssa_code'] as String? ?? "N/A",
//       charges: double.parse(json['charges']),
//       createdAt: json['created_at'] as String? ?? "N/A",
//       updatedAt: json['updated_at'] as String? ?? "N/A",
//       completionDate: json['completion_date'] as String? ?? "N/A",
//       remark: json['remark'] as String? ?? "N/A",
//       technicianId: json['technician_id'] as int?,
//       assignTo: json['assign_to'] as String? ?? "N/A",
//     );
//   }
// }

// // In relocation_ticket_model.dart
// extension RelocationTicketModelX on RelocationTicketModel {
//   TicketModel toTicketModel() {
//     return TicketModel(
//       // id: id,
//       ticketNo: ticketNo,
//       status: status,
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//       customerId: customerId,
//       customerMobileNo: mobileNo,
//       technician: technicianId?.toString() ?? assignTo ?? '',
//       technicianName: assignTo ?? 'Unassigned',
//       assignTo: technicianId ?? 0,
//       description:
//           'Relocation: $relocationType from ${oldAddress ?? 'N/A'} to $newAddress',
//       image: null,
//       // fullImageUrl: null,
//       closedAt: completionDate,
//       closedRemark: remark,
//       editable: true,
//       // isOpen: status.toLowerCase() != 'closed',
//       // Set other fields as needed; use defaults for missing ones
//       // customerName: customerName ?? '',
//       // serviceNo: serviceNo,
//       // plan: subscribePlan ?? '',
//       // address: newAddress,
//     );
//   }
// }
