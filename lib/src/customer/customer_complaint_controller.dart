import 'dart:async';
import 'dart:io';
import 'package:asia_fibernet/src/services/apis/base_api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

import '../theme/colors.dart';
import '../theme/theme.dart';
import 'core/models/customer_view_complaint_model.dart';
import 'core/models/ticket_category_model.dart';
import '../services/apis/api_services.dart';
import '../services/sharedpref.dart';
import '../services/utils/notification_helper.dart';
import 'ui/widgets/delete_complaint_dialog.dart';

// Your original controller would be defined like this, likely in its own file.
// You would then use it within the `ComplaintsScreen`.
class ComplaintController extends GetxController {
  // Example:
  // final complaintsList = <String>[].obs;
  //
  // @override
  // void onInit() {
  //   super.onInit();
  //   fetchComplaints();
  // }
  //
  // void fetchComplaints() {
  //   // Logic to fetch complaints from an API or database
  // }
  final complaints = <ComplaintViewModel>[].obs;
  final RxString selectedFilter = 'All'.obs;

  // With separate loading flags
  final RxBool isComplaintsLoading = true.obs;
  final RxBool isCategoriesLoading = true.obs;
  final Rx<File?> uploadedImage = Rx<File?>(null);
  final ticketCategories = <CategoryData>[].obs;

  // Deletion state

  // Categories state
  final RxList<String> complaintCategories = <String>[].obs;

  final ApiServices apiServices = ApiServices();
  Timer? _pollingTimer;

  List<String> get filterOptions => ['All', 'Open', 'Resolved'];

  List<ComplaintViewModel> get filteredComplaints {
    if (selectedFilter.value == 'All') return complaints;
    return complaints.where((c) {
      if (selectedFilter.value[0] == 'Open') return c.isOpen;
      if (selectedFilter.value == 'Resolved') return c.isResolved;
      return true;
    }).toList();
  }

  final Rx<CategoryData?> selectedCategory = Rx<CategoryData?>(null);
  final Rx<SubCategory?> selectedSubcategory = Rx<SubCategory?>(null);

  // 👇 NEW: Count of open complaints
  int get openComplaintCount {
    return complaints.where((c) => c.isOpen).length;
  }

  // 👇 NEW: Can user submit? Only if < 5 open complaints
  bool get canSubmitNewComplaint {
    return openComplaintCount < 5;
  }

  // 👇 Old: Just tells if ANY complaint is open (still useful for UI hints)
  bool get hasActiveComplaint {
    return complaints.any((c) => c.isOpen);
  }

  @override
  void onInit() {
    super.onInit();
    fetchTicketCategories();
    fetchComplaints();
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchComplaints();
    });
  }

  Future<void> fetchComplaints() async {
    isComplaintsLoading.value = true;
    try {
      final int? customerId = AppSharedPref.instance.getUserID();
      if (customerId == null) {
        BaseApiService().showSnackbar("Error", "User not logged in");
        Get.offAllNamed('/');
        return;
      }

      final result = await apiServices.viewComplaint(customerId);
      if (result != null) {
        for (var newComplaint in result) {
          final existing = complaints.firstWhereOrNull(
            (c) => c.id == newComplaint.id,
          );
          if (existing != null && existing.status != newComplaint.status) {
            _notifyStatusChange(newComplaint);
          }
        }
        complaints.assignAll(result);
      }
    } catch (e) {
      BaseApiService().showSnackbar("Error", "Failed to load complaints: $e");
    } finally {
      isComplaintsLoading.value = false;
    }
  }

  Future<void> fetchTicketCategories() async {
    isCategoriesLoading.value = true;
    try {
      final response = await apiServices.getTicketCategory();
      if (response != null) {
        ticketCategories.value = response.data;
      } else {
        BaseApiService().showSnackbar("Error", "Could not load categories");
      }
    } catch (e, stackTrace) {
      developer.log(
        "Failed to load ticket categories: $e",
        error: e,
        stackTrace: stackTrace,
      );
      BaseApiService().showSnackbar(
        "Error",
        "Failed to load categories. Please check your connection.",
      );
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> refreshComplaints() async {
    await fetchComplaints();
  }

  void setSelectedFilter(String filter) {
    selectedFilter.value = filter;
  }

  // 👇 UPDATED: Block submission if 5+ open complaints
  Future<void> addComplaint({
    required String category,
    required String subCategory,
    String? description,
    File? image,
  }) async {
    // ✅ BLOCK if 5 or more open complaints
    if (!canSubmitNewComplaint) {
      BaseApiService().showSnackbar(
        "Limit Reached",
        "You can only have up to 5 open complaints at a time. Please wait until some are resolved.",
        isError: true,
      );
      return;
    }

    final String? mobile = await AppSharedPref.instance.getMobileNumber();
    if (mobile == null) {
      BaseApiService().showSnackbar("Error", "Mobile number not found");
      return;
    }

    final success = await apiServices.raiseComplaint(
      mobile: mobile,
      title: category,
      subCategory: subCategory,
      description: description!,
      image: image,
    );

    if (success) {
      await fetchComplaints();
      NotificationHelper.showNotification(
        title: "Complaint Submitted",
        body:
            "Your request has been successfully submitted. We'll review it shortly.",
      );
      uploadedImage.value = null;
      Get.back();
      BaseApiService().showSnackbar(
        "Success",
        "Your complaint has been submitted!",
      );
    }
  }

  Future<bool> closeComplaint({
    required ComplaintViewModel complaint,
    required String resolution,
    required int rating,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final updated = complaint.copyWith(status: "closed");
    complaints.remove(complaint);
    complaints.insert(0, updated);

    NotificationHelper.showNotification(
      title: "Complaint Resolved",
      body:
          "Your complaint #${complaint.ticketNo} has been closed. Thank you for your feedback!",
    );

    BaseApiService().showSnackbar(
      "Success",
      "Complaint closed and technician rated!",
    );
    return true;
  }

  void markForDeletion(ComplaintViewModel complaint) {
    if (!complaint.isOpen) {
      BaseApiService().showSnackbar(
        "Cannot Delete",
        "Only open complaints can be canceled.",
        isError: true,
      );
      return;
    }
    Get.dialog(
      DeleteComplaintDialog(
        complaint: complaint,
        onConfirm: () {
          complaints.remove(complaint);
          fetchComplaints(); // if you want server sync
        },
      ),
    );
  }

  void _notifyStatusChange(ComplaintViewModel complaint) {
    String? title, body;

    if (complaint.isOpen) {
      title = "Complaint Accepted";
      body = "Your complaint has been accepted and assigned to a technician.";
    } else if (complaint.isResolved) {
      title = "Complaint Resolved";
      body = "Great news! Your complaint has been successfully resolved.";
    }

    if (title != null && body != null) {
      NotificationHelper.showNotification(title: title, body: body);
    }
  }

  Widget _buildRatingDisplay(int starRating) {
    // Even though checked before, defensive check
    if (starRating <= 0 || starRating > 5) {
      // print("Invalid star rating: $starRating"); // Debug log
      return const SizedBox.shrink(); // Or handle gracefully
    }

    final int clampedRating = starRating.clamp(1, 5);

    return Container(
      width: double.infinity,
      // Ensure padding is correct
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color:
            AppColors.backgroundLight ??
            Theme.of(Get.context!).colorScheme.surfaceVariant, // Fallback color
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        // Ensure border color is visible or remove if not needed
        border: Border(
          top: BorderSide(
            color: (AppColors.dividerColor ?? Colors.grey).withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            // Ensure color is set and visible
            color: AppColors.warning ?? Colors.amber, // Fallback amber
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '$clampedRating/5',
            style: AppText.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Rated", // Consider "Technician Rated"
            style: AppText.bodySmall.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
          // Optional Star Bar (uncomment if preferred)
          // const SizedBox(width: 8),
          // Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: List.generate(5, (index) {
          //     return Icon(
          //       index < clampedRating ? Icons.star : Icons.star_border,
          //       color: AppColors.warning ?? Colors.amber,
          //       size: 16,
          //     );
          //   }),
          // ),
        ],
      ),
    );
  }
}

// --- Helper Widget for Star Rating ---
class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingUpdate; // Nullable for display-only mode
  final double size;
  final bool isEnabled; // New flag to enable/disable interaction

  const _StarRating({
    Key? key,
    required this.rating,
    this.onRatingUpdate,
    this.size = 32.0,
    this.isEnabled = true, // Default to enabled
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: index < rating ? AppColors.warning : Colors.grey,
            size: size,
          ),
          onPressed:
              isEnabled && onRatingUpdate != null
                  ? () => onRatingUpdate!(index + 1)
                  : null, // Disable if not enabled or no callback
          splashRadius: 20, // Smaller splash for better spacing
        );
      }),
    );
  }
}

// --- The Rating Dialog Function ---
Future<void> showRatingDialog(context, ComplaintViewModel complaint) async {
  // Ensure the complaint is closed/resolved before showing
  if (!complaint.isResolved) {
    BaseApiService().showSnackbar(
      "Not Allowed",
      "You can only rate closed complaints.",
      isError: true,
    );
    return;
  }

  // Controllers for rating input
  final rating = (complaint.rating ?? 0).obs; // Initialize with existing or 0
  final commentCtrl = TextEditingController(text: complaint.closedRemark);
  final isSubmitting = false.obs;

  // Function to submit the rating
  Future<void> _submitRating(context) async {
    if (rating.value <= 0) {
      BaseApiService().showSnackbar(
        "Rating Required",
        "Please select a star rating.",
        isError: true,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final apiService =
          Get.find<ApiServices>(); // Ensure ApiServices is registered
      final success = await apiService.rateComplaint(
        ticketNo: complaint.ticketNo,
        star: rating.value,
        // Use current time or complaint closed time if available
        insertedOn: DateTime.now().toIso8601String(),
        rateDescription: commentCtrl.text.trim(),
        technicianId: complaint.assignedToId!,
      );

      if (success) {
        // Get.back(); // Close the bottom sheet
        Navigator.pop(context);
        Get.find<ComplaintController>()
            .fetchComplaints(); // ✅ Uses existing instance
        BaseApiService().showSnackbar(
          "Success",
          "Thank you for your feedback!",
        );
        // Optional: Update the local complaint model or refresh list
        // Get.find<ComplaintController>()?.fetchComplaints(); // Example
      } else {
        // Error message likely shown by rateComplaint itself
      }
    } catch (e) {
      print("Error submitting rating: $e");
      BaseApiService().showSnackbar(
        "Error",
        "An unexpected error occurred.",
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Get.bottomSheet(
    Container(
      constraints: BoxConstraints(
        maxHeight: Get.mediaQuery.size.height * 0.9, // Prevent overflow
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(
              Get.context!,
            ).viewInsets.bottom, // Adjust for keyboard
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Shrink to fit content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Drag Handle ---
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // --- 2. Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rate Your Experience",
                    style: AppText.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textColorHint,
                    ),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- 3. Complaint Info Card ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.dividerColor.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.ticketNo,
                    style: AppText.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${complaint.category} - ${complaint.subCategory ?? 'N/A'}",
                    style: AppText.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(complaint.createdAt, style: AppText.bodySmall),
                  if (complaint.technician != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.engineering,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Technician: ${complaint.technician}",
                            style: AppText.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- 4. Rating Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "How was your service?",
                    style: AppText.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Obx(
                      () => _StarRating(
                        rating: rating.value,
                        onRatingUpdate: (newRating) => rating.value = newRating,
                        size: 40.0, // Larger stars
                        isEnabled:
                            !(complaint.rating != null &&
                                complaint.rating! >
                                    0), // Disable while submitting
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 5. Comment Box ---
                  Text(
                    "Comments (Optional)",
                    style: AppText.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    enabled: !isSubmitting.value, // Disable while submitting
                    decoration: InputDecoration(
                      hintText: "Share details of your experience...",
                      hintStyle: TextStyle(color: AppColors.textColorHint),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: AppText.bodyMedium.copyWith(
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 6. Submit Button ---
            if (!(complaint.rating != null && complaint.rating! > 0))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52, // Consistent button height
                    child: ElevatedButton(
                      onPressed:
                          () =>
                              isSubmitting.value
                                  ? null
                                  : _submitRating(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child:
                          isSubmitting.value
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                "Submit Rating",
                                style: AppText.button.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12), // Bottom spacing
          ],
        ),
      ),
    ),
    isScrollControlled: true, // Important for keyboard handling
    backgroundColor: Colors.transparent, // Make background transparent
  );
}

// --- How to Use ---
// In your _buildComplaintCard or onTap handler:
/*
InkWell(
  onTap: () {
    if (complaint.isResolved) {
      showRatingDialog(complaint); // Show this dialog
    } else {
      _showComplaintDetails(complaint); // Show details for open ones
    }
  },
  // ... rest of your card
)
*/
