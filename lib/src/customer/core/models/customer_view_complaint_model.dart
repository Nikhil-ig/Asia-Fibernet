// complaint_view_model.dart
import 'package:flutter/material.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../theme/colors.dart'; // Make sure AppColors is accessible
import 'package:intl/intl.dart';

class ComplaintViewModel {
  final int id;
  final String ticketNo;
  // final String? title; // Removed: Using category as title
  final String description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String mobile; // registered_mobile
  final String? imageUrl; // Constructed from 'image' path
  // final String? customerName; // Removed: Not in sample JSON
  final String category;
  final String? subCategory;

  // Technician assignment
  final int? assignedToId; // Maps to 'assign_to'
  final String? technician; // Maps to 'technician' name directly

  // Resolution & Closure
  final String?
  resolvedAt; // If you have a specific resolved timestamp, otherwise might be unused
  final String? closedAt; // Maps to 'closed_at'
  final String? closedRemark; // Maps to 'closed_remark'
  final int? rating; // Maps to 'star'

  // Animation helper (if used)
  late final ValueNotifier<double> isDeleted = ValueNotifier(1.0);

  ComplaintViewModel({
    required this.id,
    required this.ticketNo,
    // this.title, // Removed
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.mobile,
    this.imageUrl,
    // this.customerName, // Removed
    this.assignedToId,
    this.technician,
    required this.category,
    this.subCategory,
    this.resolvedAt, // Keep if backend provides distinct resolved time
    this.closedAt, // Add closedAt
    this.closedRemark,
    this.rating, // Use rating
  });

  factory ComplaintViewModel.fromJson(Map<String, dynamic> json) {
    // Parse technician ID
    final dynamic assignTo = json['assign_to'];
    final int? techId = assignTo;

    // Parse rating from 'star'
    final dynamic star = json['star'];
    final int? parsedRating =
        (star is int)
            ? star
            : (star is num)
            ? star.toInt()
            : null;

    // Parse image URL
    String? fullImageUrl;
    final String? imagePath = json['image'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      // Ensure path doesn't already start with http
      if (imagePath.startsWith('http')) {
        fullImageUrl = imagePath;
      } else {
        fullImageUrl = '${BaseApiService.api}$imagePath'; // Use https
      }
    }

    return ComplaintViewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ticketNo: json['ticket_no'] as String? ?? '',
      // title: json['category'] as String?, // Removed
      description: json['description'] as String? ?? 'No description',
      status: json['status'] as String? ?? 'Unknown',
      createdAt: _formatDate(json['created_at']),
      updatedAt: _formatDate(json['updated_at']),
      mobile: json['registered_mobile'] as String? ?? '',
      imageUrl: fullImageUrl, // Use constructed URL
      // customerName: json['customer_name'] as String?, // Removed
      assignedToId: techId ?? json['technician_id'], // Use parsed ID
      technician:
          json['technician'] ??
          json['technician_name'] ??
          "N/A", // Use name directly from API
      category: json['category'] as String? ?? 'Unknown',
      subCategory: json['sub_category'] as String?,
      resolvedAt: _formatDate(json['resolved_at']), // Keep if used
      closedAt: _formatDate(json['closed_at']), // Map closed_at
      closedRemark: json['closed_remark'] as String?,
      rating: parsedRating, // Map star to rating
    );
  }

  static String _formatDate(dynamic dateTimeStr) {
    try {
      if (dateTimeStr == null || dateTimeStr.toString().trim().isEmpty) {
        return "N/A";
      }
      // Handle potential format issues if needed, but DateTime.parse usually works for "YYYY-MM-DD HH:MM:SS"
      final DateTime date = DateTime.parse(dateTimeStr.toString());
      // Consider if you want just the date: DateFormat('MMM dd, yyyy').format(date);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      // Print error for debugging if format is unexpected
      // print("Error formatting date '$dateTimeStr': $e");
      return dateTimeStr.toString(); // Return original string if parsing fails
    }
  }

  ComplaintViewModel copyWith({
    String? status,
    String? closedRemark,
    int? rating, // Include rating in copyWith
    String? resolvedAt,
    String? closedAt, // Include closedAt in copyWith
  }) {
    return ComplaintViewModel(
      id: id,
      ticketNo: ticketNo,
      // title: title,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      mobile: mobile,
      imageUrl: imageUrl,
      // customerName: customerName,
      assignedToId: assignedToId,
      technician: technician,
      category: category,
      subCategory: subCategory,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt, // Copy closedAt
      closedRemark: closedRemark ?? this.closedRemark,
      rating: rating ?? this.rating, // Copy rating
    )..isDeleted.value = isDeleted.value;
  }

  /// Human-readable status
  String get displayStatus {
    final s = status.trim().toLowerCase();
    if (s.contains('open')) return 'Open';
    if (s.contains('assigned')) return 'Assigned';
    if (s.contains('hold')) return 'On Hold';
    if (s.contains('resolved')) return 'Resolved';
    if (s.contains('closed')) return 'Closed';
    if (s.contains('cancelled') || s.contains('canceled')) return 'Cancelled';
    if (s.contains('withdrawal') || s.contains('withdrawn'))
      return 'Withdrawn'; // Added
    return 'Unknown';
  }

  /// Status color for UI
  Color get statusColor {
    switch (displayStatus) {
      case 'Open':
        return AppColors.primary;
      case 'Assigned':
        return AppColors.secondary;
      case 'On Hold':
        return AppColors.warning;
      case 'Resolved':
        return AppColors.success;
      // case 'Closed':
      //   return AppColors.success; // You can change this if needed
      case 'Withdrawn': // Added
        return AppColors.error; // Or any color you prefer
      case 'Cancelled' || 'Closed':
        return AppColors.error;
      default:
        return AppColors.textColorSecondary;
    }
  }

  /// Status icon
  IconData get statusIcon {
    switch (displayStatus) {
      case 'Open':
        return Icons.access_time;
      case 'Assigned':
        return Icons.engineering;
      case 'On Hold':
        return Icons.pause_circle;
      case 'Resolved':
        return Icons.check_circle;
      // case 'Closed':
      //   return Icons.check_circle; // Using same icon as resolved
      case 'Withdrawn': // Added
        return Icons.cancel; // Or Icons.undo, Icons.close, etc.
      case 'Cancelled' || 'Closed':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// True if complaint is still open, assigned, or on hold
  bool get isOpen =>
      ['open', 'assigned', 'on hold'].contains(status.trim().toLowerCase());

  /// True if complaint is resolved or closed
  bool get isResolved => [
    'resolved',
    // 'closed',
    // 'withdrawal',
    // 'withdrawn',
  ].contains(status.trim().toLowerCase());
  // --- Removed operator == and hashCode as they might not be necessary
  // unless you are doing specific comparisons in lists/sets.
  // If you need them, regenerate based on current fields.

  @override
  String toString() {
    return 'ComplaintViewModel(id: $id, ticketNo: $ticketNo, category: $category, subCategory: $subCategory, status: $status, technician: $technician, rating: $rating)';
  }
}
