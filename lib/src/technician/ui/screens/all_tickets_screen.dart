// screens/tickets/all_tickets_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../services/apis/base_api_service.dart';
import '../../../services/apis/technician_api_service.dart';
import '../../../services/apis/api_services.dart';
import '../../../services/sharedpref.dart';
import '../../../services/background_services/location_tracking_background_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../utils/safe_navigation.dart';
import '../../core/models/tickets_model.dart';
import '../../core/models/ticket_closure_model.dart';
import 'customer_detail_screen.dart';

/// Safely dismiss an overlay (bottom sheet / dialog / snackbar) if present.
/// Prefer closing known overlays via Get to avoid ancestor lookups on
/// potentially deactivated contexts. If nothing known is open, optionally
/// fall back to popping a Navigator route when a valid context is provided.
void _dismissOverlay({BuildContext? ctx}) {
  // Be extra defensive: accessing some GetX getters may throw if
  // internals (like the snackbar controller) haven't been initialized.
  // Read the flags inside try/catch and only call the corresponding
  // close methods if it's safe. Wrap each close call in a try/catch
  // to avoid rethrowing asynchronous or late init errors.
  bool isBottomSheetOpen = false;
  bool isDialogOpen = false;
  bool isSnackbarOpen = false;

  try {
    isBottomSheetOpen = Get.isBottomSheetOpen == true;
  } catch (_) {}
  try {
    isDialogOpen = Get.isDialogOpen == true;
  } catch (_) {}
  try {
    isSnackbarOpen = Get.isSnackbarOpen == true;
  } catch (_) {}

  if (isBottomSheetOpen) {
    // Prefer using the provided context to pop. If none is provided,
    // it's safer to do nothing than to call Get.back() which may touch
    // uninitialized internals asynchronously.
    if (ctx != null) {
      try {
        if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      } catch (_) {}
    }
    return;
  }

  if (isDialogOpen) {
    if (ctx != null) {
      try {
        if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      } catch (_) {}
    }
    return;
  }

  if (isSnackbarOpen) {
    if (ctx != null) {
      try {
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      } catch (_) {}
    } else {
      // As a last resort try Get's close method inside try/catch.
      try {
        Get.closeCurrentSnackbar();
      } catch (_) {}
    }
    return;
  }

  if (ctx != null) {
    try {
      if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
    } catch (_) {}
  }
}

class AllTicketsController extends GetxController {
  final apiServices = TechnicianAPI();
  final _bgService = LocationTrackingBackgroundService();
  final tickets = <TicketModel>[].obs;
  final isLoading = true.obs;
  final RxBool isRelocationActive = false.obs;
  final RxBool isDisconnectionActive = false.obs;
  final searchQuery = ''.obs;
  final TextEditingController remarkCtrl = TextEditingController();

  // Composable Filters
  final RxBool isMyTicketsActive = false.obs;
  final RxString statusFilter = 'All'.obs; // All, Open, Assigned, Closed
  final RxBool isDateFilterActive = false.obs;
  final Rx<DateTime> selectedStartDate =
      DateTime.now().subtract(const Duration(days: 7)).obs;
  final Rx<DateTime> selectedEndDate = DateTime.now().obs;

  // ✅ Ticket Closure Observables
  final RxString selectedCategory = ''.obs;
  final RxString selectedSubcategory = ''.obs;
  final RxBool isSolved = true.obs;
  final RxBool isClosing = false.obs;
  final RxInt closureStep = 1.obs; // ✅ NEW: Track dialog step (1-4)

  // ✅ API service for ticket updates
  late TechnicianAPI technicianAPI;

  // ✅ OTP Timer and Resend State
  Timer? _otpTimer;
  final RxInt otpTimeRemaining = 60.obs;
  final RxBool isOtpTimerActive = true.obs;

  @override
  void onInit() {
    super.onInit();
    technicianAPI = TechnicianAPI();
    fetchTickets();
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    super.onClose();
  }

  void clearAllFilters() {
    isMyTicketsActive.value = false;
    statusFilter.value = 'All';
    isDateFilterActive.value = false;
    isRelocationActive.value = false;
    isDisconnectionActive.value = false;
    searchQuery.value = '';
    BaseApiService().showSnackbar(
      "Filters Cleared",
      "All filters and search have been reset.",
    );
  }

  Future<void> fetchTickets() async {
    isLoading.value = true;
    try {
      if (isRelocationActive.value) {
        final raw =
            await apiServices
                .fetchRelocationTicket(); // Returns List<TicketModel>?
        if (raw != null) {
          // Since fetchRelocationTicket() already returns List<TicketModel>,
          // you don't need to convert again!
          tickets.assignAll(raw);
        } else {
          tickets.assignAll([]);
        }
      } else if (isDisconnectionActive.value) {
        final raw = await apiServices.fetchDisconnectionTickets();
        if (raw != null) {
          tickets.assignAll(raw);
        } else {
          tickets.assignAll([]);
        }
      } else {
        // ... your normal ticket logic (unchanged)
        String apiFilter;
        if (isDateFilterActive.value) {
          apiFilter = 'byDate';
        } else if (isMyTicketsActive.value) {
          if (statusFilter.value == 'Open') {
            apiFilter = 'myOpenTickets';
          } else if (statusFilter.value == 'Closed') {
            apiFilter = 'myClosedTickets';
          } else {
            apiFilter = 'myTickets';
          }
        } else {
          if (statusFilter.value == 'Open') {
            apiFilter = 'openTickets';
          } else if (statusFilter.value == 'Closed') {
            apiFilter = 'closeTickets';
          } else {
            apiFilter = 'all';
          }
        }
        final result = await apiServices.fetchAllTicketsWithFilter(
          filter: apiFilter,
          startDate:
              isDateFilterActive.value
                  ? DateFormat('yyyy-MM-dd').format(selectedStartDate.value)
                  : null,
          endDate:
              isDateFilterActive.value
                  ? DateFormat('yyyy-MM-dd').format(selectedEndDate.value)
                  : null,
        );
        tickets.assignAll(result ?? []);
      }
    } catch (e) {
      BaseApiService().showSnackbar("Error", "Failed to load tickets: $e");
      tickets.assignAll([]);
    } finally {
      isLoading.value = false;
    }
  }

  List<TicketModel> get filteredTickets {
    if (searchQuery.isEmpty) return tickets;
    final query = searchQuery.value.toLowerCase();
    return tickets.where((t) {
      return t.ticketNo.toLowerCase().contains(query) ||
          (t.technician?.toLowerCase() ?? '').contains(query) ||
          t.createdAt.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> showDateFilterDialog(context) async {
    await Get.dialog(
      Obx(
        () => AlertDialog(
          title: Text("Filter by Date", style: AppText.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Iconsax.calendar, color: AppColors.primary),
                title: Text("Start Date"),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(selectedStartDate.value),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedStartDate.value,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) selectedStartDate.value = picked;
                },
              ),
              ListTile(
                leading: Icon(Iconsax.calendar, color: AppColors.primary),
                title: Text("End Date"),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(selectedEndDate.value),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedEndDate.value,
                    firstDate: selectedStartDate.value,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) selectedEndDate.value = picked;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                isDateFilterActive.value = true;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                "Apply Filter",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void clearDateFilter() {
    isDateFilterActive.value = false;
    selectedStartDate.value = DateTime.now().subtract(const Duration(days: 7));
    selectedEndDate.value = DateTime.now();
  }

  void showTicketDetails(
    BuildContext context,
    TicketModel ticket,
    int customerId,
  ) async {
    Get.bottomSheet(
      ignoreSafeArea: true,
      _buildTicketDetailsBottomSheet(context, null),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
    final fullTicket = await apiServices.fetchTicketByTicketNo(ticket.ticketNo);
    if (Get.isBottomSheetOpen == true) {
      _dismissOverlay(ctx: context);
    }
    if (fullTicket != null) {
      Get.bottomSheet(
        _buildTicketDetailsBottomSheet(
          context,
          fullTicket,
          customerId,
          ticket.assignTo,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      );
    }
  }

  // ===== Helper Methods (Private) =====

  Widget _buildTicketDetailsBottomSheet(
    context,
    TicketModel? ticket, [
    int? customerId,
    int? assignTo,
  ]) {
    if (ticket == null) {
      return _buildSkeletonLoader();
    }
    return Container(
      constraints: BoxConstraints(maxHeight: Get.size.height * .85),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ticket Details",
                    style: AppText.headingMedium.copyWith(
                      color: AppColors.textColorPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Iconsax.close_circle,
                      color: AppColors.textColorSecondary,
                    ),
                    onPressed: () {
                      // Use a stable overlay/context if available — the
                      // `context` parameter passed into this builder may be
                      // the parent page context rather than the bottom-sheet's
                      // active context. Prefer Get.overlayContext and fall
                      // back to the provided context. Attempt a safe pop and
                      // use the defensive helper if that fails.
                      final safeCtx = Get.overlayContext ?? context;
                      try {
                        Navigator.of(safeCtx).pop();
                      } catch (_) {
                        _dismissOverlay(ctx: safeCtx);
                      }
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        if (ticket.customerId != null) {
                          Get.to(
                            () => const CustomerDetailsScreen(),
                            arguments: {'customerId': ticket.customerId},
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              border: Border.all(color: AppColors.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailRow(
                                  Iconsax.receipt,
                                  "Ticket No",
                                  ticket.ticketNo,
                                ),
                                SizedBox(height: 12),
                                _detailRow(
                                  Iconsax.status,
                                  "Status",
                                  ticket.status,
                                  valueColor: _getStatusColor(ticket.status),
                                ),
                                SizedBox(height: 12),
                                _detailRow(
                                  Iconsax.calendar,
                                  "Created",
                                  _formatDate(ticket.createdAt),
                                ),
                                if (ticket.updatedAt != null) ...[
                                  SizedBox(height: 12),
                                  _detailRow(
                                    Iconsax.refresh,
                                    "Updated",
                                    _formatDate(ticket.updatedAt!),
                                  ),
                                ],
                                // if (ticket.customerMobileNo != null) ...[
                                //   SizedBox(height: 12),
                                //   _detailRow(
                                //     Iconsax.call,
                                //     "Customer",
                                //     ticket.customerMobileNo!,
                                //   ),
                                // ],
                                if (ticket.technicianName != null) ...[
                                  SizedBox(height: 12),
                                  _detailRow(
                                    Iconsax.user,
                                    "Assigned To",
                                    ticket.technicianName!,
                                  ),
                                ],
                                if (ticket.closedAt != null) ...[
                                  SizedBox(height: 12),
                                  _detailRow(
                                    Iconsax.tick_circle,
                                    "Closed On",
                                    _formatDate(ticket.closedAt!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGradientStart,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                              border: Border.all(color: AppColors.dividerColor),
                            ),
                            child: Center(
                              child: Text(
                                "View Details",
                                style: AppText.labelMedium.copyWith(
                                  color: AppColors.backgroundLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    if (ticket.assignTo == AppSharedPref.instance.getUserID())
                      ElevatedButton(
                        onPressed: () async {
                          // Start background location tracking when calling customer
                          try {
                            final ticketDate = DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.now());
                            await _bgService.startTracking(
                              ticketDate: ticketDate,
                              intervalSeconds: 60,
                            );
                          } catch (e) {
                            print('⚠️ Failed to start tracking: $e');
                          }

                          // 📞 Show beautiful call request popup
                          _showCallRequestPopup(context, ticket, apiServices);
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(child: Text("Make Call")),
                        ),
                      ),
                    if (ticket.description != null)
                      _section("Issue Description", ticket.description!),
                    SizedBox(height: 16),
                    if (ticket.image != null)
                      _buildImagePreview(ticket.fullImageUrl!),
                    SizedBox(height: 20),
                    if (ticket.isOpen) ...[
                      Text(
                        "Resolution Details",
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: remarkCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Describe how the issue was resolved...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                      SizedBox(height: 20),
                      // if (ticket.closedAt == null)
                      if (assignTo == AppSharedPref.instance.getUserID())
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading.value
                                      ? null
                                      : () {
                                        print("Back");

                                        _sendOtpAndClose(
                                          context,
                                          ticket,
                                          remarkCtrl.text.trim(),
                                        );
                                        final safeCtx =
                                            Get.overlayContext ?? context;
                                        try {
                                          Navigator.of(safeCtx).pop();
                                        } catch (_) {
                                          _dismissOverlay(ctx: safeCtx);
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child:
                                  isLoading.value
                                      ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Iconsax.tick_circle,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Resolved",
                                            style: AppText.button.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                    ] else ...[
                      if (ticket.closedRemark != null)
                        _section("Resolution Note", ticket.closedRemark!),
                    ],
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorPrimary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attached Image",
            style: AppText.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: AppColors.dividerColor,
                  child: Center(child: Text("Image not available")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textColorSecondary),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppText.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textColorPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('open')) return AppColors.warning;
    if (s.contains('assign')) return AppColors.info;
    if (s.contains('close') || s.contains('resolve')) return AppColors.success;
    return AppColors.textColorSecondary;
  }

  String _formatDate(String dateTimeStr) {
    try {
      final DateTime date = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _sendOtpAndClose(
    context,
    TicketModel ticket,
    String remark,
  ) async {
    final String? mobile = AppSharedPref.instance.getMobileNumber();
    if (mobile == null) {
      BaseApiService().showSnackbar(
        "Error",
        "Mobile number not found",
        isError: true,
      );
      return;
    }

    // Start background location tracking for ticket closure
    try {
      final ticketDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _bgService.startTracking(
        ticketDate: ticketDate,
        intervalSeconds: 60,
      );
    } catch (e) {
      print('⚠️ Failed to start tracking: $e');
    }

    // If the ticket was created more than 4 hours ago, skip OTP verification
    // and directly attempt to close the ticket using the close API.
    try {
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(ticket.createdAt);
      } catch (e) {
        // If parsing fails, assume it's recent (so we fall back to OTP flow).
        createdAt = DateTime.now();
      }

      final age = DateTime.now().difference(createdAt);
      // if (age >= const Duration(hours: 4)) {
      if (true) {
        // Direct close path
        isLoading.value = true;
        try {
          final success = await apiServices.closeComplaint(
            ticketNo: ticket.ticketNo,
            closedRemark: remark,
          );
          isLoading.value = false;

          if (success == true) {
            // Dismiss details sheet/dialog and refresh list
            _dismissOverlay(ctx: context);
            BaseApiService().showSnackbar(
              "Success",
              "Ticket closed successfully.",
            );
            await fetchTickets();
            _dismissOverlay(ctx: context);
            return;
          } else {
            BaseApiService().showSnackbar(
              "Error",
              "Failed to close ticket. Please try again.",
              isError: true,
            );
            return;
          }
        } catch (e) {
          isLoading.value = false;
          BaseApiService().showSnackbar(
            "Error",
            "Failed to close ticket. Please try again. ($e)",
            isError: true,
          );
          return;
        }
      }
    } catch (e) {
      // If anything goes wrong with the age check, log and continue to OTP flow
      debugPrint('⚠️ _sendOtpAndClose age-check error: $e');
    }

    // Send OTP for ticket close before showing verification sheet
    try {
      // final api = ApiServices();
      final resp = await apiServices.generateOtpForTicketClose(
        mobileNo: ticket.customerMobileNo!,
        ticketNo: ticket.ticketNo,
        gateway: 'text',
      );

      if (resp == null || resp['status'] != 'success') {
        BaseApiService().showSnackbar(
          "Error",
          resp != null && resp['message'] != null
              ? resp['message']
              : "Failed to send OTP. Please try again.",
          isError: true,
        );
        return;
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to send OTP. Please try again.",
        isError: true,
      );
      return;
    }

    // Capture a stable overlay/context before popping the current dialog so
    // we don't try to lookup an ancestor from a deactivated context.
    // Prefer the Navigator overlay context if available; avoid using
    // Get.context here to prevent accessing Get internals when not ready.
    final safeOverlayContext =
        Navigator.of(context).overlay?.context ?? context;

    try {
      Navigator.of(safeOverlayContext).pop();
    } catch (_) {
      _dismissOverlay(ctx: safeOverlayContext);
    }

    // Schedule after this frame so the element tree is stable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOtpVerificationSheet(safeOverlayContext, ticket);
    });
  }

  void _showOtpVerificationSheet(context, TicketModel ticket) {
    final otpCtrl = TextEditingController();
    final isLoading = false.obs;

    // Reset timer state
    otpTimeRemaining.value = 60;
    isOtpTimerActive.value = true;
    _otpTimer?.cancel();
    _startOtpTimer();

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Verify Closure",
                        style: AppText.headingMedium.copyWith(
                          color: AppColors.textColorPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Iconsax.close_circle,
                          color: AppColors.textColorSecondary,
                        ),
                        onPressed: () {
                          _otpTimer?.cancel();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.requiresOtpVerification()) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "An OTP has been sent to the customer. Enter it to confirm closure.",
                                  style: AppText.bodyMedium.copyWith(
                                    color: AppColors.textColorPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Enter OTP",
                          style: AppText.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            hintText: "000000",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.dividerColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.dividerColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            counterText: "",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isLoading.value
                                    ? null
                                    : () async {
                                      // If OTP is required for this ticket, verify it first
                                      if (ticket.requiresOtpVerification()) {
                                        final otp = otpCtrl.text;
                                        if (otp.length != 6) {
                                          BaseApiService().showSnackbar(
                                            "Invalid OTP",
                                            "Please enter a 6-digit OTP",
                                            isError: true,
                                          );
                                          return;
                                        }

                                        final mobile =
                                            AppSharedPref.instance
                                                .getMobileNumber();
                                        if (mobile == null) {
                                          BaseApiService().showSnackbar(
                                            "Error",
                                            "Mobile number not found",
                                            isError: true,
                                          );
                                          return;
                                        }

                                        try {
                                          final verifyResp = await apiServices
                                              .verifyOtpForTicketClose(
                                                ticketNo: ticket.ticketNo,
                                                otp: otp,
                                                mobile: mobile,
                                              );

                                          if (verifyResp == null ||
                                              verifyResp['status'] !=
                                                  'success') {
                                            final errorMsg =
                                                verifyResp != null &&
                                                        verifyResp['message'] !=
                                                            null
                                                    ? verifyResp['message']
                                                    : "OTP verification failed. Please try again.";

                                            // Clear OTP field on error
                                            otpCtrl.clear();

                                            BaseApiService().showSnackbar(
                                              "Invalid OTP",
                                              errorMsg,
                                              isError: true,
                                            );
                                            return;
                                          }
                                        } catch (e) {
                                          otpCtrl.clear();
                                          BaseApiService().showSnackbar(
                                            "Error",
                                            "OTP verification failed. Please try again.",
                                            isError: true,
                                          );
                                          return;
                                        }
                                      }

                                      isLoading.value = true;
                                      try {
                                        final success = await apiServices
                                            .closeComplaint(
                                              ticketNo: ticket.ticketNo,
                                              closedRemark:
                                                  remarkCtrl.text.trim().isEmpty
                                                      ? "I have checked and resolved the issue"
                                                      : remarkCtrl.text.trim(),
                                            );
                                        if (success) {
                                          // Stop background location tracking
                                          try {
                                            await _bgService.stopTracking();
                                          } catch (e) {
                                            print(
                                              '⚠️ Failed to stop tracking: $e',
                                            );
                                          }

                                          _otpTimer?.cancel();
                                          BaseApiService().showSnackbar(
                                            "Success",
                                            "Ticket closed successfully!",
                                          );
                                          _dismissOverlay(ctx: context);
                                          fetchTickets();
                                        }
                                      } catch (e) {
                                        BaseApiService().showSnackbar(
                                          "Error",
                                          "Failed to close ticket. Please try again.",
                                          isError: true,
                                        );
                                      } finally {
                                        _dismissOverlay(ctx: context);
                                        isLoading.value = false;
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child:
                                isLoading.value
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Iconsax.shield_tick, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          "Verify & Close",
                                          style: AppText.button.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (ticket.requiresOtpVerification())
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive OTP? ",
                                style: AppText.bodyMedium.copyWith(
                                  color: AppColors.textColorSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    isOtpTimerActive.value
                                        ? null
                                        : () => _showResendOtpOptions(
                                          context,
                                          ticket,
                                        ),
                                child: Text(
                                  isOtpTimerActive.value
                                      ? "Resend in ${otpTimeRemaining.value}s"
                                      : "Resend OTP",
                                  style: AppText.bodyMedium.copyWith(
                                    color:
                                        isOtpTimerActive.value
                                            ? AppColors.textColorSecondary
                                            : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            BaseApiService().showSnackbar(
                              "Send",
                              "New OTP has been sent to customer",
                            );
                          },
                          child: Text(
                            "Send Request to Close",
                            style: AppText.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
  }

  /// Start OTP countdown timer (60 seconds)
  void _startOtpTimer() {
    _otpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (otpTimeRemaining.value > 0) {
        otpTimeRemaining.value--;
      } else {
        isOtpTimerActive.value = false;
        timer.cancel();
      }
    });
  }

  /// Show resend OTP modal with SMS/WhatsApp options
  void _showResendOtpOptions(BuildContext context, TicketModel ticket) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Resend OTP",
          style: AppText.headingMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Choose how you want to receive the OTP",
          style: AppText.bodyMedium.copyWith(
            color: AppColors.textColorSecondary,
          ),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _dismissOverlay(ctx: context);
                    _resendOtp(ticket, 'text');
                  },
                  icon: Icon(Iconsax.sms),
                  label: Text("Send via SMS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _dismissOverlay(ctx: context);
                    _resendOtp(ticket, 'whatsapp');
                  },
                  icon: Icon(Iconsax.message),
                  label: Text("Send via WhatsApp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _dismissOverlay(ctx: context);
                  },
                  child: Text("Cancel"),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Resend OTP with selected gateway
  Future<void> _resendOtp(TicketModel ticket, String gateway) async {
    try {
      final resp = await apiServices.generateOtpForTicketClose(
        ticketNo: ticket.ticketNo,
        gateway: gateway,
        mobileNo: ticket.customerMobileNo!,
        resend: true,
      );

      if (resp != null && resp['status'] == 'success') {
        // Reset timer
        otpTimeRemaining.value = 60;
        isOtpTimerActive.value = true;
        _otpTimer?.cancel();
        _startOtpTimer();

        final gatewayName = gateway == 'whatsapp' ? 'WhatsApp' : 'SMS';
        BaseApiService().showSnackbar("Success", "OTP resent via $gatewayName");
      } else {
        BaseApiService().showSnackbar(
          "Error",
          resp != null && resp['message'] != null
              ? resp['message']
              : "Failed to resend OTP. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to resend OTP. Please try again.",
        isError: true,
      );
    }
  }

  Widget _buildSkeletonLoader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 120, height: 24, color: Colors.grey[300]),
              Container(width: 24, height: 24, color: Colors.grey[300]),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Column(
              children: List.generate(
                5,
                (_) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(width: 16, height: 16, color: Colors.grey[300]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(height: 16, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 20,
            color: Colors.grey[300],
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 48,
            color: Colors.grey[300],
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  /// ✅ Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are denied forever.';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// ✅ Auto-advance ticket stage to next level
  Future<void> autoAdvanceStage(
    BuildContext context,
    TicketModel ticket,
  ) async {
    try {
      // Get current stage from ticket status
      int currentStage = _parseStageFromStatus(ticket.status);

      // If already completed (stage 5), show message
      if (currentStage == 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Job already completed!')),
        );
        return;
      }

      // Advance to next stage (max 5)
      final nextStage = (currentStage + 1).clamp(0, 5);
      final nextStatus = _getStatusTextForStage(nextStage);

      // Get current location
      final position = await getCurrentLocation();
      final lat = position.latitude.toString();
      final long = position.longitude.toString();

      // Show updating snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updating stage...')));

      debugPrint('🔵 AUTO-ADVANCE STAGE');
      debugPrint('Ticket: ${ticket.ticketNo}');
      debugPrint('Current Stage: $currentStage');
      debugPrint('Next Stage: $nextStage');
      debugPrint('Location: $lat, $long');

      // Call API to update stage
      final success = await technicianAPI.updateLiveTicketStatus(
        ticketNo: ticket.ticketNo,
        customerId: int.tryParse(ticket.customerId.toString()) ?? 0,
        currentStage: nextStage,
        status: nextStatus,
        lat: lat,
        long: long,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Stage updated to: $nextStatus'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchTickets(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update stage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Auto-advance error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// ✅ Parse stage ID from status text
  int _parseStageFromStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('assigned')) return 0;
    if (s.contains('accept')) return 1;
    if (s.contains('way')) return 2;
    if (s.contains('reach')) return 3;
    if (s.contains('progress')) return 4;
    if (s.contains('complete') || s.contains('close')) return 5;
    return 0;
  }

  /// ✅ Get status text for stage ID
  String _getStatusTextForStage(int stageId) {
    switch (stageId) {
      case 0:
        return 'Assigned';
      case 1:
        return 'Accept Job';
      case 2:
        return 'On the way';
      case 3:
        return 'Reached customer location';
      case 4:
        return 'Work in progress';
      case 5:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  // ===== CALL REQUEST POPUP =====

  void _showCallRequestPopup(
    BuildContext context,
    TicketModel ticket,
    TechnicianAPI apiServices,
  ) {
    final isLoading = true.obs;
    final callStatus = 'sending'.obs; // sending, success, error
    final errorMessage = ''.obs;
    bool _didStart = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        // Ensure the call request is sent once after the dialog is built.
        if (!_didStart) {
          _didStart = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sendCallRequest(
              apiServices,
              ticket,
              callStatus,
              errorMessage,
              isLoading,
              dialogCtx: dialogContext,
            );
          });
        }

        return Obx(() {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.98)],
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with animation
                  if (callStatus.value == 'sending')
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.2),
                                  AppColors.primary.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else if (callStatus.value == 'success')
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.2),
                            Colors.green.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 60,
                          color: Colors.green.shade600,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.error_rounded,
                          size: 60,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    callStatus.value == 'sending'
                        ? '📞 Sending Call Request'
                        : callStatus.value == 'success'
                        ? '✅ Call Initiated Successfully'
                        : '❌ Call Request Failed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          callStatus.value == 'sending'
                              ? AppColors.textColorPrimary
                              : callStatus.value == 'success'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    callStatus.value == 'sending'
                        ? 'Requesting call with customer...'
                        : callStatus.value == 'success'
                        ? 'The customer will receive a call shortly'
                        : errorMessage.value.isNotEmpty
                        ? errorMessage.value
                        : 'Failed to send call request. Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textColorSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer Info (visible in all states)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Iconsax.call,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ticket',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textColorSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket.ticketNo,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColorPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 12,
                        //     vertical: 8,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: AppColors.primary.withOpacity(0.1),
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   child: Text(
                        //     ticket.customerMobileNo ?? 'N/A',
                        //     style: TextStyle(
                        //       fontSize: 12,
                        //       fontWeight: FontWeight.bold,
                        //       color: AppColors.primary,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  if (callStatus.value == 'error')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _dismissOverlay(ctx: context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: AppColors.textColorPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Dismiss',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              callStatus.value = 'sending';
                              errorMessage.value = '';
                              isLoading.value = true;
                              _sendCallRequest(
                                apiServices,
                                ticket,
                                callStatus,
                                errorMessage,
                                isLoading,
                                dialogCtx: context,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (callStatus.value == 'success')
                    ElevatedButton(
                      onPressed: () {
                        _dismissOverlay(ctx: context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Call Initiated',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );

    // The request is started from inside the dialog builder using the
    // dialog context to ensure safe pops; do not start it here.
  }

  Future<void> _sendCallRequest(
    TechnicianAPI apiServices,
    TicketModel ticket,
    RxString callStatus,
    RxString errorMessage,
    RxBool isLoading, {
    BuildContext? dialogCtx,
  }) async {
    try {
      final callResult = await apiServices.callCustomer(
        mobileNo: ticket.customerMobileNo ?? '',
      );

      if (callResult != null && callResult['success'] == true) {
        debugPrint('✅ Call request sent successfully');
        callStatus.value = 'success';

        // Auto-close after 5 seconds
        await Future.delayed(const Duration(seconds: 5));
        // Prefer using the provided dialog context to close the dialog safely.
        if (dialogCtx != null) {
          try {
            if (Navigator.of(dialogCtx).canPop()) Navigator.of(dialogCtx).pop();
          } catch (_) {}
        }
      } else {
        debugPrint('❌ Call request failed: ${callResult?['message']}');
        errorMessage.value =
            callResult?['message'] ?? 'Failed to initiate call';
        callStatus.value = 'error';
      }
    } catch (e) {
      debugPrint('❌ Error sending call request: $e');
      errorMessage.value = 'Error: ${e.toString()}';
      callStatus.value = 'error';
    } finally {
      isLoading.value = false;
    }
  }
}

// ====== SCREEN WIDGET ======
class AllTicketsScreen extends StatelessWidget {
  const AllTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllTicketsController());
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: AppBar(
              iconTheme: IconThemeData(color: AppColors.backgroundLight),
              title: Text(
                "All Tickets",
                style: AppText.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Iconsax.filter, color: Colors.white),
                  onPressed: () => _showFilterDialog(context, controller),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Iconsax.refresh, color: Colors.white),
                  onPressed: controller.fetchTickets,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => controller.searchQuery.value = value,
                decoration: InputDecoration(
                  hintText: "Search by ticket no., tech name, or date...",
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Icon(
                      Iconsax.search_normal,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: Obx(
                    () =>
                        controller.searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Iconsax.close_circle,
                                color: AppColors.error,
                                size: 20,
                              ),
                              onPressed:
                                  () => controller.searchQuery.value = '',
                            )
                            : SizedBox(),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
            ),
          ),
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Obx(() {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: "All",
                      isActive:
                          !controller.isMyTicketsActive.value &&
                          controller.statusFilter.value == 'All' &&
                          !controller.isDateFilterActive.value &&
                          !controller.isRelocationActive.value &&
                          !controller.isDisconnectionActive.value,
                      onTap: () {
                        controller.isMyTicketsActive.value = false;
                        controller.statusFilter.value = 'All';
                        controller.isDateFilterActive.value = false;
                        controller.isRelocationActive.value = false;
                        controller.isDisconnectionActive.value = false;
                        controller.fetchTickets();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: "My Tickets",
                      isActive: controller.isMyTicketsActive.value,
                      onTap: () {
                        controller.isMyTicketsActive.toggle();
                        controller.isRelocationActive.value = false;
                        controller.isDisconnectionActive.value = false;
                        controller.fetchTickets();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: "Relocation",
                      isActive: controller.isRelocationActive.value,
                      onTap: () {
                        controller.isRelocationActive.value =
                            !controller.isRelocationActive.value;
                        controller.isDisconnectionActive.value = false;
                        controller.isMyTicketsActive.value = false;
                        controller.fetchTickets();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: "Disconnect",
                      isActive: controller.isDisconnectionActive.value,
                      onTap: () {
                        controller.isDisconnectionActive.value =
                            !controller.isDisconnectionActive.value;
                        controller.isRelocationActive.value = false;
                        controller.isMyTicketsActive.value = false;
                        controller.fetchTickets();
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
          // Status & Date Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Obx(() {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusFilterChip(
                    label: "Open",
                    isActive: controller.statusFilter.value == 'Open',
                    onTap: () {
                      controller.statusFilter.value = 'Open';
                      controller.fetchTickets();
                    },
                  ),
                  if (!controller.isMyTicketsActive.value)
                    _buildStatusFilterChip(
                      label: "Assigned",
                      isActive: controller.statusFilter.value == 'Assigned',
                      onTap: () {
                        controller.statusFilter.value = 'Assigned';
                        controller.fetchTickets();
                      },
                    ),
                  _buildStatusFilterChip(
                    label: "Closed",
                    isActive: controller.statusFilter.value == 'Closed',
                    onTap: () {
                      controller.statusFilter.value = 'Closed';
                      controller.fetchTickets();
                    },
                  ),
                  _buildStatusFilterChip(
                    label: "By Date",
                    isActive: controller.isDateFilterActive.value,
                    onTap: () => _showDateRangePicker(context, controller),
                  ),
                ],
              );
            }),
          ),
          // Ticket Counter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() {
              final count = controller.filteredTickets.length;
              return Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Showing ",
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                        TextSpan(
                          text: "$count",
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: " tickets",
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  if (controller.searchQuery.isNotEmpty)
                    _buildClearButton(
                      "Clear Search",
                      () => controller.searchQuery.value = '',
                    ),
                  if (controller.isDateFilterActive.value)
                    _buildClearButton(
                      "Clear Date",
                      () => controller.clearDateFilter(),
                    ),
                ],
              );
            }),
          ),
          // Tickets List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return _buildShimmerLoading();
              final filtered = controller.filteredTickets;
              if (filtered.isEmpty) return _buildEmptyState(controller);
              return RefreshIndicator(
                onRefresh: controller.fetchTickets,
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];
                    if (ticket.ticketType == 'relocation') {
                      return _buildRelocationTicketCard(context, ticket);
                    } else if (ticket.ticketType == 'disconnection') {
                      return _buildDisconnectionTicketCard(context, ticket);
                    } else {
                      return _buildTicketCard(context, controller, ticket);
                    }
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.close_circle, size: 14, color: Colors.redAccent),
          SizedBox(width: 4),
          Text(
            label,
            style: AppText.bodySmall.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.dividerColor,
            width: 1.5,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ]
                  : [],
        ),
        child: Text(
          label,
          style: AppText.bodyMedium.copyWith(
            color: isActive ? Colors.white : AppColors.textColorPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.dividerColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'By Date' && isActive) ...[
              Icon(Iconsax.calendar, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppText.bodySmall.copyWith(
                color:
                    isActive ? AppColors.primary : AppColors.textColorSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(
    context,
    AllTicketsController controller,
  ) async {
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: controller.selectedStartDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedStartDate != null) {
      controller.selectedStartDate.value = pickedStartDate;
      final DateTime? pickedEndDate = await showDatePicker(
        context: context,
        initialDate: controller.selectedEndDate.value,
        firstDate: pickedStartDate,
        lastDate: DateTime.now(),
      );
      if (pickedEndDate != null) {
        controller.selectedEndDate.value = pickedEndDate;
        controller.isDateFilterActive.value = true;
      }
    }
    controller.fetchTickets();
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 140,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 20,
                        color: Colors.grey[300],
                      ),
                      Container(width: 80, height: 24, color: Colors.grey[300]),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(width: 150, height: 16, color: Colors.grey[300]),
                  SizedBox(height: 8),
                  Container(width: 120, height: 16, color: Colors.grey[300]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AllTicketsController controller) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.receipt_search,
                size: 80,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No tickets found",
              textAlign: TextAlign.center,
              style: AppText.headingMedium.copyWith(
                color: AppColors.textColorPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try adjusting your filter or search term.",
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(
                color: AppColors.textColorSecondary,
              ),
            ),
            SizedBox(height: 32),
            if (controller.searchQuery.isNotEmpty ||
                controller.isDateFilterActive.value)
              ElevatedButton(
                onPressed: () {
                  controller.searchQuery.value = '';
                  controller.clearDateFilter();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.refresh, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Clear All Filters",
                      style: AppText.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(context, AllTicketsController controller) {
    Get.dialog(
      Obx(
        () => AlertDialog(
          title: Text(
            "Filter Tickets",
            style: AppText.headingMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List<String>.from([
                  'All',
                  'My Tickets',
                  'Open',
                  'Assigned',
                  'Closed',
                  'By Date',
                ]).map((filterName) {
                  bool isActive = false;
                  IconData iconData = Iconsax.filter;
                  if (filterName == 'My Tickets') {
                    isActive = controller.isMyTicketsActive.value;
                  } else if (filterName == 'All') {
                    isActive =
                        !controller.isMyTicketsActive.value &&
                        controller.statusFilter.value == 'All' &&
                        !controller.isDateFilterActive.value;
                  } else if (filterName == 'Open' ||
                      filterName == 'Assigned' ||
                      filterName == 'Closed') {
                    isActive = controller.statusFilter.value == filterName;
                  } else if (filterName == 'By Date') {
                    isActive = controller.isDateFilterActive.value;
                  }
                  if (filterName == 'All') iconData = Iconsax.slider_horizontal;
                  if (filterName == 'My Tickets') iconData = Iconsax.user;
                  if (filterName == 'Open') iconData = Iconsax.clock;
                  if (filterName == 'Assigned') iconData = Iconsax.user_tick;
                  if (filterName == 'Closed') iconData = Iconsax.tick_circle;
                  if (filterName == 'By Date') iconData = Iconsax.calendar;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isActive ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        iconData,
                        color:
                            isActive
                                ? AppColors.primary
                                : AppColors.textColorSecondary,
                      ),
                      title: Text(
                        filterName,
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.textColorPrimary,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      trailing:
                          isActive
                              ? Icon(Icons.check, color: AppColors.success)
                              : null,
                      onTap: () {
                        _dismissOverlay(ctx: context);
                        if (filterName == 'My Tickets') {
                          controller.isMyTicketsActive.toggle();
                        } else if (filterName == 'All') {
                          controller.isMyTicketsActive.value = false;
                          controller.statusFilter.value = 'All';
                          controller.isDateFilterActive.value = false;
                        } else if (filterName == 'Open' ||
                            filterName == 'Assigned' ||
                            filterName == 'Closed') {
                          controller.statusFilter.value = filterName;
                        } else if (filterName == 'By Date') {
                          _showDateRangePicker(context, controller);
                        }
                        controller.fetchTickets();
                      },
                    ),
                  );
                }),
                if (controller.isDateFilterActive.value)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Active Date Filter:",
                            style: AppText.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "From: ${DateFormat('MMM dd, yyyy').format(controller.selectedStartDate.value)}",
                            style: AppText.bodySmall,
                          ),
                          Text(
                            "To: ${DateFormat('MMM dd, yyyy').format(controller.selectedEndDate.value)}",
                            style: AppText.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _dismissOverlay(ctx: context);
                              controller.isDateFilterActive.value = false;
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.calendar_remove,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Clear Date Filter",
                                  style: AppText.bodySmall.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _dismissOverlay(ctx: context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.fetchTickets();
                _dismissOverlay(ctx: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ===== TICKET CARDS =====

  Widget _buildTicketCard(
    BuildContext context,
    AllTicketsController controller,
    TicketModel ticket,
  ) {
    final statusColor = controller._getStatusColor(ticket.status);
    final statusIcon = _getStatusIcon(ticket.status);
    return InkWell(
      onTap: () {
        if (ticket.ticketType == 'relocation' ||
            ticket.ticketType == 'disconnection') {
          _showSpecialTicketDetailsBottomSheet(context, ticket);
        } else {
          if (ticket.customerId != null) {
            controller.showTicketDetails(context, ticket, ticket.customerId!);
          } else {
            BaseApiService().showSnackbar(
              "Error",
              "Customer ID not available.",
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.06),
          //     blurRadius: 15,
          //     offset: Offset(0, 3),
          //   ),
          // ],
          boxShadow: [
            BoxShadow(
              color: ticket.priorityColor.withOpacity(0.4),
              blurRadius: 12,
              // offset: Offset(0, 4),
            ),
          ],
          border: Border.fromBorderSide(
            BorderSide(color: ticket.priorityColor, width: 2),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.ticketNo,
                      style: AppText.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        SizedBox(width: 8),
                        Text(
                          ticket.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.calendar,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller._formatDate(ticket.createdAt),
                      style: AppText.bodyMedium.copyWith(
                        color: AppColors.textColorPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (ticket.assignTo != null &&
                  ticket.technician != null &&
                  ticket.technician!.isNotEmpty) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Iconsax.user,
                        size: 16,
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Technician: ${ticket.technician}",
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.textColorPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (ticket.assignTo == AppSharedPref.instance.getUserID()) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Iconsax.user_tick,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Assigned to: Tech ID ${ticket.assignTo}",
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.textColorPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // ✅ Close Ticket Button
                // SizedBox(height: 12),
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton.icon(
                //     onPressed: () => _showTicketClosureDialog(context, ticket),
                //     icon: Icon(Iconsax.tick_circle),
                //     label: Text('Close Ticket'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.success,
                //       foregroundColor: Colors.white,
                //       padding: EdgeInsets.symmetric(vertical: 10),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelocationTicketCard(BuildContext context, TicketModel ticket) {
    final statusColor = _getRelocationStatusColor(ticket.status);
    final isAssigned = ticket.assignTo != null;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 10),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.purple.withOpacity(0.03),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purpleAccent.shade400,
                        Colors.purple.shade600,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Relocation Ticket",
                                  style: AppText.labelMedium.copyWith(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  ticket.ticketNo,
                                  style: AppText.labelSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade900,
                                    // fontSize: 20,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.location,
                                  size: 14,
                                  color: Colors.purple,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "RELOCATION",
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.document_text,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Service Number",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    ticket.serviceNo ?? "N/A",
                                    style: TextStyle(
                                      color: Colors.grey.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "ACTIVE",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Iconsax.call,
                          size: 18,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Contact Number",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ticket.mobileNo ?? "N/A",
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                if (ticket.oldAddress?.isNotEmpty == true) ...[
                  Expanded(
                    child: _buildAddressCard(
                      icon: Iconsax.location_minus,
                      title: "Old Address",
                      address: ticket.oldAddress!,
                      color: Colors.orange.shade500,
                    ),
                  ),
                  SizedBox(width: 12),
                ],
                Expanded(
                  child: _buildAddressCard(
                    icon: Iconsax.location_add,
                    title: "New Address",
                    address: ticket.newAddress ?? "N/A",
                    color: Colors.green.shade500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Iconsax.calendar,
                        title: "Preferred Date",
                        value: ticket.preferredShiftDate ?? "N/A",
                        iconColor: Colors.purple.shade600,
                      ),
                      SizedBox(width: 16),
                      _buildDetailItem(
                        icon: Iconsax.category,
                        title: "Relocation Type",
                        value: ticket.relocationType ?? "N/A",
                        iconColor: Colors.blue.shade600,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "STATUS",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      ticket.status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Iconsax.arrow_right_3,
                                size: 16,
                                color: statusColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isAssigned) ...[
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Iconsax.user,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ASSIGNED TO",
                                        style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        ticket.assignTo.toString(),
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Iconsax.share,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  label: Text(
                    "Share",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed:
                      () =>
                          _showSpecialTicketDetailsBottomSheet(context, ticket),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.purple.withOpacity(0.3),
                  ),
                  icon: Icon(Iconsax.eye, size: 16, color: Colors.white),
                  label: Text(
                    "View Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectionTicketCard(
    BuildContext context,
    TicketModel ticket,
  ) {
    return _buildTicketCard(context, Get.find<AllTicketsController>(), ticket);
  }

  // ===== HELPER WIDGETS =====

  Widget _buildAddressCard({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Container(
              //   width: 36,
              //   height: 36,
              //   decoration: BoxDecoration(
              //     color: color.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Icon(icon, size: 18, color: color),
              // ),
              // SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      address,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            // Container(
            //   width: 36,
            //   height: 36,
            //   decoration: BoxDecoration(
            //     color: iconColor.withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            //   child: Icon(icon, size: 18, color: iconColor),
            // ),
            // SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpecialTicketDetailsBottomSheet(
    BuildContext context,
    TicketModel ticket,
  ) {
    final bool isRelocation = ticket.ticketType == 'relocation';
    final bool isDisconnection = ticket.ticketType == 'disconnection';
    final String title =
        isRelocation ? "Relocation Details" : "Disconnection Details";
    final Color headerColor = isRelocation ? Colors.purple : Colors.redAccent;

    Color getStatusColor(String status) {
      final s = status.toLowerCase();
      if (s == 'assigned') return AppColors.info;
      if (s.contains('close') || s.contains('complete')) {
        return AppColors.success;
      }
      if (s == 'pending') return AppColors.warning;
      return AppColors.textColorSecondary;
    }

    final statusColor = getStatusColor(ticket.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppText.headingSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        try {
                          Navigator.of(context).pop();
                        } catch (_) {}
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: EdgeInsets.all(8),
                      ),
                      icon: Icon(
                        Iconsax.close_circle,
                        size: 24,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              headerColor.withOpacity(0.08),
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: headerColor.withOpacity(0.1),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: headerColor.withOpacity(0.05),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ticket Number",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        ticket.ticketNo,
                                        style: TextStyle(
                                          color: Colors.grey.shade900,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        ticket.status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(color: Colors.grey.shade200, height: 1),
                            SizedBox(height: 16),
                            if (isRelocation)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailItemCompact(
                                      icon: Iconsax.document_text,
                                      title: "Service No",
                                      value: ticket.serviceNo ?? "N/A",
                                      iconColor: Colors.blue.shade600,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDetailItemCompact(
                                      icon: Iconsax.call,
                                      title: "Mobile",
                                      value: ticket.mobileNo ?? "N/A",
                                      iconColor: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              )
                            else if (isDisconnection)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailItemCompact(
                                      icon: Iconsax.document_text,
                                      title: "Voucher No",
                                      value:
                                          ticket.disconnectionVoucherNo ??
                                          "N/A",
                                      iconColor: Colors.orange.shade600,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDetailItemCompact(
                                      icon: Iconsax.device_message,
                                      title: "MAC ID",
                                      value: ticket.macId ?? "N/A",
                                      iconColor: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Customer Information",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (ticket.customerName?.isNotEmpty == true) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Iconsax.user,
                                      size: 20,
                                      color: headerColor,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Customer Name",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          ticket.customerName!,
                                          style: TextStyle(
                                            color: Colors.grey.shade900,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                            ],
                            if (ticket.customerMobileNo?.isNotEmpty ==
                                true) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Iconsax.call,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Contact Number",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          ticket.customerMobileNo!,
                                          style: TextStyle(
                                            color: Colors.grey.shade900,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      if (isRelocation) ...[
                        Text(
                          "Address Details",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (ticket.oldAddress?.isNotEmpty == true) ...[
                          _buildAddressSection(
                            icon: Iconsax.location_minus,
                            title: "Current Address",
                            address: ticket.oldAddress!,
                            color: Colors.orange.shade600,
                          ),
                          SizedBox(height: 12),
                        ],
                        _buildAddressSection(
                          icon: Iconsax.location_add,
                          title: "New Address",
                          address: ticket.newAddress!,
                          color: Colors.green.shade600,
                        ),
                      ],
                      if (isDisconnection) ...[
                        Text(
                          "Disconnection Details",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (ticket.itemName != null)
                                _buildServiceDetail(
                                  icon: Iconsax.d_cube_scan,
                                  title: "Item Name",
                                  value: ticket.itemName!,
                                ),
                              if (ticket.itemId != null)
                                _buildServiceDetail(
                                  icon: Iconsax.code,
                                  title: "Item ID",
                                  value: ticket.itemId!,
                                ),
                              if (ticket.macId != null)
                                _buildServiceDetail(
                                  icon: Iconsax.device_message,
                                  title: "MAC ID",
                                  value: ticket.macId!,
                                ),
                              if (ticket.storeName != null)
                                _buildServiceDetail(
                                  icon: Iconsax.building,
                                  title: "Store",
                                  value: ticket.storeName!,
                                ),
                              if (ticket.refundRequired != null)
                                _buildServiceDetail(
                                  icon: Iconsax.dollar_circle,
                                  title: "Refund Required",
                                  value:
                                      ticket.refundRequired == 1 ? "Yes" : "No",
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      Text(
                        isRelocation ? "Service Details" : "Request Details",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (isRelocation &&
                                ticket.preferredShiftDate != null)
                              _buildServiceDetail(
                                icon: Iconsax.calendar,
                                title: "Preferred Date",
                                value: ticket.preferredShiftDate!,
                              ),
                            if (isRelocation && ticket.charges != null)
                              _buildServiceDetail(
                                icon: Iconsax.dollar_circle,
                                title: "Charges",
                                value: "₹${ticket.charges}",
                              ),
                            if (isDisconnection)
                              _buildServiceDetail(
                                icon: Iconsax.calendar,
                                title: "Request Date",
                                value: _formatDateTime(ticket.createdAt),
                              ),
                            if (ticket.updatedAt != null)
                              _buildServiceDetail(
                                icon: Iconsax.refresh,
                                title: "Last Updated",
                                value: _formatDateTime(ticket.updatedAt!),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Assignment Details",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.user_tick,
                                size: 24,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Assigned To",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    ticket.technician ?? "Not assigned",
                                    style: TextStyle(
                                      color: Colors.grey.shade900,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ticket.remark?.isNotEmpty == true) ...[
                        SizedBox(height: 20),
                        Text(
                          "Remarks",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Iconsax.note_text,
                                size: 20,
                                color: Colors.amber.shade700,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ticket.remark!,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.share,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Share",
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: headerColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.call, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Contact",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItemCompact({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      address,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetail({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade900,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  Color _getRelocationStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'assigned') return AppColors.info;
    if (s.contains('close') || s.contains('complete')) return AppColors.success;
    return AppColors.warning;
  }

  IconData _getStatusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('open')) return Iconsax.clock;
    if (s.contains('assign')) return Iconsax.user_tick;
    if (s.contains('close') || s.contains('resolve')) {
      return Iconsax.tick_circle;
    }
    return Iconsax.info_circle;
  }

  /// ✅ Get status color for widget (for displaying ticket data)
  Color _getStatusColorForWidget(String status) {
    final s = status.toLowerCase();
    if (s.contains('open')) return AppColors.warning;
    if (s.contains('assign')) return AppColors.info;
    if (s.contains('close') ||
        s.contains('resolve') ||
        s.contains('complete')) {
      return AppColors.success;
    }
    return AppColors.textColorSecondary;
  }

  /// ✅ Show ticket closure dialog with step-by-step wizard
  void _showTicketClosureDialog(BuildContext context, TicketModel ticket) {
    final controller = Get.find<AllTicketsController>();

    // Initialize state
    controller.selectedCategory.value = '';
    controller.selectedSubcategory.value = '';
    controller.remarkCtrl.clear();
    controller.isSolved.value = true;
    controller.isClosing.value = false;
    controller.closureStep.value = 1; // Start at step 1

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Obx(
              () => Row(
                children: [
                  Text('Close Ticket', style: AppText.headingSmall),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Step ${controller.closureStep.value}/4',
                      style: AppText.labelSmall.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============ STEP 1: Original Complaint Category ============
                    if (controller.closureStep.value == 1) ...[
                      Text(
                        'Original Complaint Category',
                        style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category:',
                              style: AppText.labelSmall.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              ticket.category ?? 'Not specified',
                              style: AppText.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Sub-Category:',
                              style: AppText.labelSmall.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              ticket.subCategory ?? 'Not specified',
                              style: AppText.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Description:',
                              style: AppText.labelSmall.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              ticket.description ?? 'Not specified',
                              style: AppText.bodyMedium.copyWith(
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              color: Colors.blue,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select closure category below',
                                style: AppText.labelSmall.copyWith(
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ============ STEP 2: Select Closure Category & Subcategory ============
                    if (controller.closureStep.value == 2) ...[
                      Text(
                        'Select Closure Category *',
                        style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                controller.selectedCategory.isEmpty
                                    ? Colors.grey.shade300
                                    : AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: SizedBox(),
                          value:
                              controller.selectedCategory.isEmpty
                                  ? null
                                  : controller.selectedCategory.value,
                          hint: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Choose category...'),
                          ),
                          items:
                              TicketClosureOptions.categories.keys
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(cat),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedCategory.value = value;
                              controller.selectedSubcategory.value = '';
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Visibility(
                        visible: controller.selectedCategory.isNotEmpty,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Issue Type *',
                              style: AppText.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      controller.selectedSubcategory.isEmpty
                                          ? Colors.grey.shade300
                                          : AppColors.primary,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                underline: SizedBox(),
                                value:
                                    controller.selectedSubcategory.isEmpty
                                        ? null
                                        : controller.selectedSubcategory.value,
                                hint: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Choose type...'),
                                ),
                                items:
                                    (TicketClosureOptions.categories[controller
                                                .selectedCategory
                                                .value] ??
                                            [])
                                        .map(
                                          (subcat) => DropdownMenuItem(
                                            value: subcat,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              child: Text(subcat),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.selectedSubcategory.value =
                                        value;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ============ STEP 3: Enter Closure Remarks ============
                    if (controller.closureStep.value == 3) ...[
                      Text(
                        'Enter Closure Remarks *',
                        style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Category: ${controller.selectedCategory.value}',
                        style: AppText.labelSmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Type: ${controller.selectedSubcategory.value}',
                        style: AppText.labelSmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: controller.remarkCtrl,
                        maxLines: 4,
                        minLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Describe what you did to resolve this issue...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.all(12),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],

                    // ============ STEP 4: Final - Issue Solved & Reassign ============
                    if (controller.closureStep.value == 4) ...[
                      Text(
                        'Is Issue Solved?',
                        style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              controller.isSolved.value
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                          border: Border.all(
                            color:
                                controller.isSolved.value
                                    ? AppColors.success
                                    : AppColors.warning,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.isSolved.value
                                      ? '✓ YES - Close as Completed'
                                      : '✗ NO - Reassign Ticket',
                                  style: AppText.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        controller.isSolved.value
                                            ? AppColors.success
                                            : AppColors.warning,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  controller.isSolved.value
                                      ? 'Mark ticket as completed'
                                      : 'Send to another technician',
                                  style: AppText.labelSmall.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            CupertinoSwitch(
                              value: controller.isSolved.value,
                              onChanged:
                                  (val) => controller.isSolved.value = val,
                              activeColor: AppColors.success,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary:',
                              style: AppText.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Category: ${controller.selectedCategory.value}',
                              style: AppText.labelSmall,
                            ),
                            Text(
                              'Type: ${controller.selectedSubcategory.value}',
                              style: AppText.labelSmall,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Stage: ${controller.isSolved.value ? '5 - Completed' : '4 - Work in Progress/Reassign'}',
                              style: AppText.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    controller.isSolved.value
                                        ? AppColors.success
                                        : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _dismissOverlay(ctx: context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Obx(
                () => TextButton(
                  onPressed:
                      controller.closureStep.value == 1
                          ? () => controller.closureStep.value = 2
                          : (controller.closureStep.value == 2 &&
                              controller.selectedCategory.isNotEmpty &&
                              controller.selectedSubcategory.isNotEmpty)
                          ? () => controller.closureStep.value = 3
                          : (controller.closureStep.value == 3 &&
                              controller.remarkCtrl.text.trim().isNotEmpty)
                          ? () => controller.closureStep.value = 4
                          : null,
                  child: Text(
                    controller.closureStep.value < 4 ? 'Next' : 'Confirm',
                    style: TextStyle(
                      color:
                          controller.closureStep.value < 4
                              ? (controller.closureStep.value == 2 &&
                                      (controller.selectedCategory.isEmpty ||
                                          controller
                                              .selectedSubcategory
                                              .isEmpty))
                                  ? Colors.grey
                                  : (controller.closureStep.value == 3 &&
                                      controller.remarkCtrl.text.trim().isEmpty)
                                  ? Colors.grey
                                  : AppColors.primary
                              : AppColors.primary,
                    ),
                  ),
                ),
              ),
              Obx(
                () => ElevatedButton.icon(
                  onPressed:
                      controller.isClosing.value ||
                              controller.closureStep.value != 4
                          ? null
                          : () =>
                              _submitTicketClosure(context, ticket, controller),
                  icon:
                      controller.isClosing.value
                          ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(Iconsax.tick_circle),
                  label: Text(
                    controller.isClosing.value ? 'Closing...' : 'Submit',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        controller.isSolved.value
                            ? AppColors.success
                            : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// ✅ Submit ticket closure with API call
  Future<void> _submitTicketClosure(
    BuildContext context,
    TicketModel ticket,
    AllTicketsController controller,
  ) async {
    // ✅ Validation
    if (controller.selectedCategory.isEmpty) {
      BaseApiService().showSnackbar('Error', 'Please select a category');
      return;
    }
    if (controller.selectedSubcategory.isEmpty) {
      BaseApiService().showSnackbar('Error', 'Please select an issue type');
      return;
    }
    if (controller.remarkCtrl.text.trim().isEmpty) {
      BaseApiService().showSnackbar('Error', 'Please enter closure remarks');
      return;
    }

    controller.isClosing.value = true;

    try {
      // ✅ Prepare closure remark with category + subcategory
      final closureRemark =
          '${controller.selectedCategory.value} > ${controller.selectedSubcategory.value}: ${controller.remarkCtrl.text.trim()}';

      // ✅ Determine status based on issue solved toggle
      final status = controller.isSolved.value ? 'Completed' : 'Reassigned';
      final currentStage = controller.isSolved.value ? 5 : 4;

      // 📍 Get current location
      final position = await controller.getCurrentLocation();

      debugPrint('🟢 SUBMITTING TICKET CLOSURE');
      debugPrint('Ticket No: ${ticket.ticketNo}');
      debugPrint('Category: ${controller.selectedCategory.value}');
      debugPrint('Subcategory: ${controller.selectedSubcategory.value}');
      debugPrint('Status: $status');
      debugPrint('Stage: $currentStage');
      debugPrint('Location: ${position.latitude}, ${position.longitude}');

      // ✅ Call API
      final result = await controller.technicianAPI.updateTicketWorkStatus(
        ticketNo: ticket.ticketNo,
        customerId: int.tryParse(ticket.customerId.toString()) ?? 0,
        currentStage: currentStage,
        status: status,
        lat: position.latitude.toString(),
        long: position.longitude.toString(),
        closureCategory: controller.selectedCategory.value,
        closureSubcategory: controller.selectedSubcategory.value,
        closureRemark: closureRemark,
      );

      debugPrint('API Response: $result');

      if (result != null && result is Map<String, dynamic>) {
        final apiStatus = result['status'] ?? '';
        if (apiStatus == 'success' ||
            apiStatus == '1' ||
            result['code'] == 200) {
          BaseApiService().showSnackbar(
            'Success',
            controller.isSolved.value
                ? 'Ticket closed successfully! ✓'
                : 'Ticket reassigned successfully! 📤',
            isError: false,
          );

          // ✅ Close dialog and refresh tickets
          safePop(context);
          await Future.delayed(Duration(milliseconds: 300));
          await controller.fetchTickets();

          // ✅ Optional: Navigate to ticket details to show update
          if (context.mounted && controller.isSolved.value) {
            safePop(context);
          }
        } else {
          BaseApiService().showSnackbar(
            'Error',
            result['message'] ?? 'Failed to update ticket status',
          );
        }
      } else {
        BaseApiService().showSnackbar('Error', 'Invalid API response');
      }
    } catch (e) {
      debugPrint('❌ Error closing ticket: $e');
      BaseApiService().showSnackbar('Error', 'Error: ${e.toString()}');
    } finally {
      controller.isClosing.value = false;
    }
  }

  /// ✅ Display API Response Ticket Data
  /// Shows ticket data from API response in a beautiful detail sheet
  void showApiResponseTicketData(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Convert API response to TicketModel
    final ticket = TicketModel.fromJson(data);

    Get.bottomSheet(
      ignoreSafeArea: true,
      _buildApiResponseTicketDetails(context, ticket, data),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  /// ✅ Build API Response Ticket Details UI
  Widget _buildApiResponseTicketDetails(
    BuildContext context,
    TicketModel ticket,
    Map<String, dynamic> rawData,
  ) {
    return Container(
      constraints: BoxConstraints(maxHeight: Get.size.height * .90),
      padding: EdgeInsets.only(bottom: safeViewInsetsBottom(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ticket Details",
                        style: AppText.headingMedium.copyWith(
                          color: AppColors.textColorPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        ticket.ticketNo,
                        style: AppText.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Iconsax.close_circle,
                      color: AppColors.textColorSecondary,
                    ),
                    onPressed: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== MAIN INFO CARD =====
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Row
                          _apiDetailRow(
                            Iconsax.status,
                            "Status",
                            ticket.status,
                            valueColor: _getStatusColorForWidget(ticket.status),
                          ),
                          SizedBox(height: 12),
                          // Priority Row
                          if (ticket.priority != null)
                            _apiDetailRow(
                              Iconsax.flag,
                              "Priority",
                              ticket.priority ?? 'N/A',
                              valueColor: _getPriorityColor(ticket.priority),
                            ),
                          if (ticket.priority != null) SizedBox(height: 12),
                          // Category Row
                          if (ticket.category != null)
                            _apiDetailRow(
                              Iconsax.category,
                              "Category",
                              ticket.category ?? 'N/A',
                            ),
                          if (ticket.category != null) SizedBox(height: 12),
                          // Sub-Category Row
                          if (ticket.subCategory != null)
                            _apiDetailRow(
                              Iconsax.bookmark,
                              "Sub-Category",
                              ticket.subCategory ?? 'N/A',
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // ===== DESCRIPTION CARD =====
                    if (ticket.description != null &&
                        ticket.description!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.note,
                                  size: 18,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Description",
                                  style: AppText.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              ticket.description ?? 'N/A',
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 16),

                    // ===== TECHNICIAN INFO CARD =====
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _apiDetailRow(
                            Iconsax.user_octagon,
                            "Technician",
                            ticket.technicianName ?? 'Not assigned',
                          ),
                          if (ticket.technicianId != null) ...[
                            SizedBox(height: 10),
                            _apiDetailRow(
                              Iconsax.user,
                              "Tech ID",
                              ticket.technicianId.toString(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // ===== TIMELINE CARD =====
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _apiDetailRow(
                            Iconsax.calendar_add,
                            "Created",
                            _formatFullDateTime(ticket.createdAt),
                          ),
                          SizedBox(height: 10),
                          _apiDetailRow(
                            Iconsax.refresh,
                            "Updated",
                            _formatFullDateTime(
                              ticket.updatedAt ?? ticket.createdAt,
                            ),
                          ),
                          if (ticket.closedAt != null &&
                              ticket.closedAt!.isNotEmpty) ...[
                            SizedBox(height: 10),
                            _apiDetailRow(
                              Iconsax.tick_circle,
                              "Closed",
                              _formatFullDateTime(ticket.closedAt!),
                              valueColor: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // ===== CLOSURE REMARKS CARD =====
                    if (ticket.closedRemark != null &&
                        ticket.closedRemark!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.tick_circle,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Closure Remark",
                                  style: AppText.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              ticket.closedRemark ?? 'N/A',
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 16),

                    // ===== JSON RAW DATA (Debug) =====
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Raw API Data",
                            style: AppText.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: SelectableText(
                              _prettyPrintJson(rawData),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // ===== ACTION BUTTONS =====
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              try {
                                Navigator.of(context).pop();
                              } catch (_) {}
                            },
                            icon: Icon(Iconsax.close_circle),
                            label: Text('Close'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Copy JSON to clipboard
                              final jsonString = _prettyPrintJson(rawData);
                              // You can use: Clipboard.setData(ClipboardData(text: jsonString));
                              BaseApiService().showSnackbar(
                                'Info',
                                'API Response copied (check debug console)',
                                isError: false,
                              );
                              debugPrint(jsonString);
                            },
                            icon: Icon(Iconsax.copy),
                            label: Text('Copy JSON'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Helper: API Detail Row
  Widget _apiDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: valueColor ?? AppColors.primary),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.labelSmall.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: AppText.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textColorPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ Helper: Format DateTime
  String _formatFullDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('dd MMM, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// ✅ Helper: Get Priority Color
  Color _getPriorityColor(String? priority) {
    if (priority == null) return Colors.grey;
    final p = priority.toLowerCase();
    if (p == 'high') return Colors.red;
    if (p == 'medium') return Colors.orange;
    if (p == 'low') return Colors.green;
    return Colors.grey;
  }

  /// ✅ Helper: Pretty Print JSON
  String _prettyPrintJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    _printJsonValue(json, buffer, 0);
    return buffer.toString();
  }

  void _printJsonValue(dynamic value, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;
    if (value is Map) {
      buffer.write('{\n');
      final entries = value.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('$indentStr  "${entry.key}": ');
        _printJsonValue(entry.value, buffer, indent + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.write('\n');
      }
      buffer.write('$indentStr}');
    } else if (value is List) {
      buffer.write('[\n');
      for (int i = 0; i < value.length; i++) {
        buffer.write('$indentStr  ');
        _printJsonValue(value[i], buffer, indent + 1);
        if (i < value.length - 1) buffer.write(',');
        buffer.write('\n');
      }
      buffer.write('$indentStr]');
    } else if (value is String) {
      buffer.write('"$value"');
    } else if (value == null) {
      buffer.write('null');
    } else {
      buffer.write(value);
    }
  }
}
