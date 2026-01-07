// lib/customer/widgets/delete_complaint_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/apis/api_services.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/sharedpref.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../core/models/customer_view_complaint_model.dart';

class DeleteComplaintDialog extends StatelessWidget {
  final ComplaintViewModel complaint;
  final VoidCallback onConfirm;

  const DeleteComplaintDialog({
    Key? key,
    required this.complaint,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDeleting = false.obs;

    return WillPopScope(
      onWillPop: () async => !isDeleting.value,
      child: AlertDialog(
        title: Text("Cancel Request?", style: AppText.headingMedium),
        content: Text(
          "Are you sure you want to delete this complaint?",
          style: AppText.bodyMedium,
          overflow: TextOverflow.clip,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              "No",
              style: AppText.button.copyWith(
                color: AppColors.textColorSecondary,
              ),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed:
                  isDeleting.value
                      ? null
                      : () => _confirmDelete(context, isDeleting),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child:
                  isDeleting.value
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text("Yes", style: AppText.button),
            ),
          ),
        ],
      ),
    );
  }

  // lib/customer/widgets/delete_complaint_dialog.dart
  Future<void> _confirmDelete(BuildContext context, RxBool isDeleting) async {
    isDeleting.value = true;

    try {
      final int? customerId = AppSharedPref.instance.getUserID();
      final String? mobile = AppSharedPref.instance.getMobileNumber();

      if (customerId == null || mobile == null) {
        BaseApiService().showSnackbar(
          "Error",
          "User information not found. Please log in again.",
          isError: true,
        );
        return;
      }

      final apiServices = ApiServices();
      final isSuccess = await apiServices.closeComplaint(
        customerId: customerId,
        ticketNo: complaint.ticketNo,
        closedRemark: "Complaint canceled by user.",
        mobile: mobile,
        rating: 0,
      );

      if (isSuccess) {
        onConfirm(); // Notify parent to remove from list
        BaseApiService().showSnackbar(
          "Deleted",
          "Your complaint has been canceled.",
        );
      } else {
        BaseApiService().showSnackbar(
          "Error",
          "Failed to cancel complaint. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "An unexpected error occurred: $e",
        isError: true,
      );
    } finally {
      isDeleting.value = false;
      // ✅ Only call Get.back() ONCE here
      if (Get.isDialogOpen == true) {
        Navigator.of(context).pop();
      }
    }
  }
}
