// complaints_screen.dart
import 'dart:io';
import 'dart:developer' as developer;
import 'package:asia_fibernet/src/call/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/apis/base_api_service.dart';
import '../../../customer_complaint_controller.dart';
import '../../../../services/apis/api_services.dart';
import '../../../core/models/customer_view_complaint_model.dart';
import '../../../core/models/technician_model.dart';
import '../../../core/models/ticket_category_model.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../widgets/delete_complaint_dialog.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  late ComplaintController controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<ComplaintController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: controller.refreshComplaints,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Obx(() {
                    if (controller.hasActiveComplaint) {
                      final complaint = controller.complaints.firstWhere(
                        (c) => c.isOpen,
                        orElse: () => controller.complaints.first,
                      );
                      return _buildActiveComplaintBanner(
                        complaint,
                      ).animate().slideX(begin: -0.5, duration: 400.ms);
                    }
                    return const SizedBox.shrink();
                  }),
                  // const SizedBox(height: 28),
                  // _buildQuickHelpSection(),
                  const SizedBox(height: 28),
                  _buildComplaintsListHeader(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            Obx(() {
              if (controller.isComplaintsLoading.value) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSkeletonItem(),
                      childCount: 3,
                    ),
                  ),
                );
              } else if (controller.filteredComplaints.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              } else {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final complaint = controller.filteredComplaints[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildComplaintCard(complaint),
                      );
                    }, childCount: controller.filteredComplaints.length),
                  ),
                );
              }
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        if (controller.canSubmitNewComplaint) {
          // 👈 CHANGED: Use canSubmitNewComplaint
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 22),
            label: Text(
              "Raise Complaint",
              style: AppText.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: () => _showRaiseComplaintDialog(),
          );
        } else {
          // Optional: Show disabled button or message
          return Padding(
            padding: const EdgeInsets.only(bottom: 120),
            child: Tooltip(
              message: "You can only have up to 5 open complaints",
              child: FloatingActionButton.extended(
                backgroundColor: Colors.grey[400],
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                icon: const Icon(Icons.add, color: Colors.white70, size: 22),
                label: Text(
                  "Raise Complaint",
                  style: AppText.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                onPressed: null, // Disabled
              ),
            ),
          );
        }
        // return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildActiveComplaintBanner(ComplaintViewModel complaint) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.priority_high,
                  color: AppColors.warning,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "ACTIVE REQUEST",
                style: AppText.labelMedium.copyWith(
                  color: AppColors.warning,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            complaint.category,
            style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (complaint.subCategory != null) ...[
            const SizedBox(height: 8),
            Text(
              complaint.subCategory!,
              style: AppText.labelSmall.copyWith(
                color: AppColors.textColorSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (complaint.description != '') ...[
            const SizedBox(height: 8),
            Text(
              complaint.description,
              style: AppText.bodySmall.copyWith(
                color: AppColors.textColorSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // const SizedBox(height: 16),
          // LinearProgressIndicator(
          //   value: 0.7,
          //   backgroundColor: AppColors.inputBackground,
          //   minHeight: 8,
          //   borderRadius: BorderRadius.circular(10),
          //   valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          // ),
          // const SizedBox(height: 8),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       "Estimated resolution: 24 hours",
          //       style: AppText.bodySmall.copyWith(
          //         color: AppColors.textColorSecondary,
          //       ),
          //     ),
          //     Text(
          //       "70% completed",
          //       style: AppText.labelSmall.copyWith(
          //         color: AppColors.primary,
          //         fontWeight: FontWeight.w700,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  // Widget _buildQuickHelpSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text("Quick Help", style: AppText.headingSmall),
  //           IconButton(
  //             icon: Icon(
  //               Icons.info_outline_rounded,
  //               color: AppColors.primary,
  //               size: 24,
  //             ),
  //             onPressed: () {
  //               BaseApiService().showSnackbar(
  //                 "Quick Help",
  //                 "Tap on any issue to quickly create a complaint",
  //                 snackPosition: SnackPosition.BOTTOM,
  //                 backgroundColor: AppColors.primary,
  //                 colorText: Colors.white,
  //                 borderRadius: 12,
  //                 margin: const EdgeInsets.all(16),
  //                 animationDuration: 300.ms,
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       _buildQuickHelpGrid(),
  //     ],
  //   );
  // }

  // Widget _buildQuickHelpGrid() {
  //   final quickHelpItems = [
  //     {
  //       'icon': Icons.wifi_tethering_rounded,
  //       'label': 'Connection Issues',
  //       'color': AppColors.secondary,
  //       'gradient': [Color(0xFF1976D2), Color(0xFF42A5F5)],
  //     },
  //     {
  //       'icon': Icons.speed_rounded,
  //       'label': 'Slow Speed',
  //       'color': Color(0xFF7B1FA2),
  //       'gradient': [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
  //     },
  //     {
  //       'icon': Icons.payment_rounded,
  //       'label': 'Billing Help',
  //       'color': Color(0xFF0097A7),
  //       'gradient': [Color(0xFF0097A7), Color(0xFF4DD0E1)],
  //     },
  //     {
  //       'icon': Icons.router_rounded,
  //       'label': 'Device Setup',
  //       'color': Color(0xFF689F38),
  //       'gradient': [Color(0xFF689F38), Color(0xFF9CCC65)],
  //     },
  //   ];
  //   return GridView.count(
  //     shrinkWrap: true,
  //     padding: EdgeInsets.zero,
  //     physics: const NeverScrollableScrollPhysics(),
  //     crossAxisCount: 2,
  //     childAspectRatio: 1.6,
  //     mainAxisSpacing: 16,
  //     crossAxisSpacing: 16,
  //     children:
  //         quickHelpItems.map((item) {
  //           return Material(
  //             color: Colors.transparent,
  //             child: InkWell(
  //               borderRadius: BorderRadius.circular(20),
  //               onTap: () => _onQuickHelpTap(item['label'] as String),
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                   gradient: LinearGradient(
  //                     begin: Alignment.topLeft,
  //                     end: Alignment.bottomRight,
  //                     colors: (item['gradient'] as List<Color>),
  //                   ),
  //                   borderRadius: BorderRadius.circular(20),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: (item['color'] as Color).withOpacity(0.3),
  //                       blurRadius: 12,
  //                       offset: const Offset(0, 4),
  //                     ),
  //                   ],
  //                 ),
  //                 padding: const EdgeInsets.all(16),
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Container(
  //                       width: 48,
  //                       height: 48,
  //                       decoration: BoxDecoration(
  //                         color: Colors.white.withOpacity(0.2),
  //                         shape: BoxShape.circle,
  //                       ),
  //                       child: Icon(
  //                         item['icon'] as IconData,
  //                         color: Colors.white,
  //                         size: 24,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //                     Text(
  //                       item['label'] as String,
  //                       style: AppText.labelMedium.copyWith(
  //                         fontWeight: FontWeight.w600,
  //                         color: Colors.white,
  //                       ),
  //                       overflow: TextOverflow.ellipsis,
  //                       maxLines: 1,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           );
  //         }).toList(),
  //   );
  // }

  Widget _buildComplaintsListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("My Complaints", style: AppText.headingMedium),
        _buildFilterDropdown(),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedFilter.value,
            icon: Icon(
              Icons.filter_list_rounded,
              size: 22,
              color: AppColors.primary,
            ),
            elevation: 2,
            style: AppText.labelMedium.copyWith(
              color: AppColors.textColorPrimary,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.setSelectedFilter(newValue);
              }
            },
            items:
                controller.filterOptions.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: AppText.labelMedium),
                  );
                }).toList(),
          ),
        ),
      );
    });
  }

  // In complaints_screen.dart

  Widget _buildComplaintCard(ComplaintViewModel complaint) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // --- Main Complaint Card (Your existing code) ---
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showComplaintDetails(complaint), // Keep details tap
            child: Container(
              decoration: BoxDecoration(
                color:
                    complaint.displayStatus == 'Withdrawn'
                        ? AppColors.error.withOpacity(
                          0.05,
                        ) // Different color for withdrawn
                        : AppColors.cardBackground,
                borderRadius:
                    complaint.isResolved
                        ? BorderRadius.vertical(top: Radius.circular(24))
                        : BorderRadius.all(Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket Number & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: complaint.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: complaint.statusColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          complaint.ticketNo,
                          style: AppText.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: complaint.statusColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: complaint.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              complaint.statusIcon,
                              size: 16,
                              color: complaint.statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              complaint.displayStatus,
                              style: AppText.labelSmall.copyWith(
                                color: complaint.statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Icon + Title + Subtitle
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: complaint.statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          complaint.statusIcon,
                          color: complaint.statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.category,
                              style: AppText.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (complaint.subCategory != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                complaint.subCategory!,
                                style: AppText.labelSmall.copyWith(
                                  color: AppColors.textColorSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              complaint.createdAt,
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    complaint.description,
                    style: AppText.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Conditionally show delete button if open
                  if (complaint.isOpen) _buildDeleteButton(complaint),
                ],
              ),
            ),
          ),
          // --- END: Main Complaint Card ---

          // --- START: Technician Rating Display (NEW) ---
          // Show rating only if the complaint is closed and a rating exists
          if (complaint.isResolved && complaint.rating != null)
            _buildRatingDisplay(context, complaint.rating!, complaint),
          // --- END: Technician Rating Display ---
        ],
      ),
    );
  }

  /// Builds an attractive display for the technician's rating.
  /// Appears below the main complaint card if the ticket is closed and rated.
  Widget _buildRatingDisplay(context, int starRating, complaint) {
    // Ensure rating is within 1-5
    final int clampedRating = starRating.clamp(0, 5);

    return GestureDetector(
      onTap: () {
        if (complaint.isResolved) {
          showRatingDialog(context, complaint); // Show this dialog
        } else {
          _showComplaintDetails(complaint); // Show details for open ones
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground, // Subtle background
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.dividerColor.withOpacity(
                0.5,
              ), // Subtle top border
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Shrink to fit content
          children: [
            const Icon(
              Icons.star, // Filled star icon for display
              color: AppColors.warning, // Standard amber/yellow for stars
              size: 21,
            ),
            const SizedBox(width: 6),
            Text(
              '$clampedRating/5', // Display rating out of 5
              style: AppText.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(width: 8),
            // Optional: Add descriptive text
            Text(
              "Rated", // Or "Technician Rated", etc.
              style: AppText.bodySmall.copyWith(
                color: AppColors.textColorSecondary,
              ),
            ),

            // Optional: Show full star bar for visual representation
            // Uncomment the section below if you prefer a visual bar
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return Icon(
                  index < clampedRating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                  size: 18,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- END: Modified Code ---
  Widget _buildDeleteButton(ComplaintViewModel complaint) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: () {
            Get.dialog(
              DeleteComplaintDialog(
                complaint: complaint,
                onConfirm: () {
                  controller.complaints.remove(complaint);
                  // Optional: controller.fetchComplaints();
                },
              ),
            );
          },
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: AppColors.error,
          ),
          label: Text(
            "Close Request",
            style: AppText.labelSmall.copyWith(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error.withOpacity(0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.inputBackground,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 200, height: 18, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 150, height: 14, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(width: 250, height: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.support_agent_rounded,
          size: 120,
          color: AppColors.textColorHint.withOpacity(0.2),
        ),
        const SizedBox(height: 24),
        Text(
          "No Complaints Yet",
          style: AppText.headingSmall.copyWith(
            color: AppColors.textColorHint,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Looks like everything is working fine! If you need help, tap the button below.",
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _showRaiseComplaintDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: Text("Create New Request", style: AppText.button),
        ),
      ],
    );
  }

  void _showComplaintDetails(ComplaintViewModel complaint) {
    // ✅ Fixed: Properly check if assigned
    final bool isAssigned = complaint.status == "Assigned";
    final bool isResolved = complaint.displayStatus == 'Resolved';
    final bool isClosed = complaint.displayStatus == 'Closed';
    final bool isCancelled = complaint.displayStatus == 'Cancelled';

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.mediaQuery.size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 30),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[400]),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Title & Ticket
            Text("Complaint Details", style: AppText.headingMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: complaint.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: complaint.statusColor, width: 1.5),
              ),
              child: Text(
                complaint.ticketNo,
                style: AppText.bodySmall.copyWith(
                  color: complaint.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Timeline
                    _buildSectionTitle("Progress Timeline"),
                    const SizedBox(height: 16),
                    _buildStatusTimeline(complaint, isAssigned),

                    // Issue Details
                    const SizedBox(height: 28),
                    _buildSectionTitle("Issue Details"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.inputBackground,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.category,
                            style: AppText.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (complaint.subCategory != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              complaint.subCategory!,
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            complaint.description,
                            style: AppText.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // Image (if any)
                    if (complaint.imageUrl != null) ...[
                      const SizedBox(height: 28),
                      _buildSectionTitle("Attached Media"),
                      const SizedBox(height: 12),
                      _buildImagePreview(complaint.imageUrl!),
                    ],

                    // Technician (if assigned)
                    // if (isAssigned) ...[
                    //   const SizedBox(height: 28),
                    //   _buildSectionTitle("Assigned Technician"),
                    //   // const SizedBox(height: 12),
                    //   // _buildTechnicianCard(complaint),
                    // ],

                    // Closed Remark (if closed)
                    if (isClosed || isResolved || isCancelled) ...[
                      const SizedBox(height: 28),
                      _buildSectionTitle("Resolution"),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          "This complaint has been ${complaint.displayStatus.toLowerCase()}.",
                          style: AppText.bodyMedium.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Close Button
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: Get.back,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: AppColors.primary,
            //       foregroundColor: Colors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(16),
            //       ),
            //       elevation: 2,
            //     ),
            //     child: Text(
            //       "Close",
            //       style: AppText.button.copyWith(color: Colors.white),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTechnicianCard(ComplaintViewModel complaint) {
    final api = Get.find<ApiServices>();
    final Rx<TechnicianModel?> technician = Rxn<TechnicianModel>();
    final RxBool loading = true.obs;

    // ✅ Extract tech ID directly (already int)
    final techId = complaint.assignedToId;
    print("techId: ${complaint.assignedToId}");

    // Fetch technician details
    Future<void> fetchTech() async {
      if (techId == null) {
        loading(false);
        return;
      }

      try {
        final data = await api.fetchTechnicianById(techId);
        developer.log('Fetching technician with ID in Page: $techId');
        technician.value = data;
      } catch (e) {
        developer.log('Failed to fetch technician: $e');
        BaseApiService().showSnackbar(
          "Error",
          "Could not load technician details.",
          isError: true,
        );
      } finally {
        loading(false);
      }
    }

    // ✅ Use `once` to fetch only once
    fetchTech();

    return Obx(() {
      if (loading.value) {
        return _buildLoadingTechnicianCard();
      }

      final tech = technician.value;
      if (tech == null) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_off_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Technician details not available",
                  style: AppText.bodyMedium.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          //   colors: [
          //     AppColors.secondary.withOpacity(0.08),
          //     AppColors.primary.withOpacity(0.05),
          //   ],
          // ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.textColorHint.withOpacity(0.5),
            width: 1.5,
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: AppColors.secondary.withOpacity(0.15),
          //     blurRadius: 16,
          //     offset: Offset(0, 6),
          //   ),
          // ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Image with decorative border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      tech.profileImageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withOpacity(0.2),
                                  AppColors.secondary.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.backgroundLight,
                              size: 22,
                            ),
                          ),
                      loadingBuilder: (ctx, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.secondary.withOpacity(0.05),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Verified Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tech.name,
                              style: AppText.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textColorPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Container(
                          //   padding: EdgeInsets.symmetric(
                          //     horizontal: 10,
                          //     vertical: 5,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     gradient: LinearGradient(
                          //       colors: [
                          //         AppColors.success.withOpacity(0.9),
                          //         AppColors.success.withOpacity(0.7),
                          //       ],
                          //     ),
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Icon(
                          //         Icons.verified_rounded,
                          //         color: Colors.white,
                          //         size: 14,
                          //       ),
                          //       // SizedBox(width: 4),
                          //       // Text(
                          //       //   'Verified',
                          //       //   style: AppText.labelSmall.copyWith(
                          //       //     color: Colors.white,
                          //       //     fontSize: 10,
                          //       //     fontWeight: FontWeight.w600,
                          //       //   ),
                          //       // ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                      // // SizedBox(height: 4),
                      // Text(
                      //   tech.companyName,
                      //   style: AppText.bodySmall.copyWith(
                      //     color: AppColors.success,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      // SizedBox(height: 8),

                      // Location
                      //   Row(
                      //     children: [
                      //       Container(
                      //         width: 32,
                      //         height: 32,
                      //         decoration: BoxDecoration(
                      //           color: AppColors.primary.withOpacity(0.1),
                      //           shape: BoxShape.circle,
                      //         ),
                      //         child: Icon(
                      //           Icons.location_on_rounded,
                      //           size: 16,
                      //           color: AppColors.primary,
                      //         ),
                      //       ),
                      //       // SizedBox(width: 8),
                      //       // Expanded(
                      //       //   child: Text(
                      //       //     '${tech.city}, ${tech.state}',
                      //       //     style: AppText.bodyMedium.copyWith(
                      //       //       color: AppColors.textColorSecondary,
                      //       //     ),
                      //       //     maxLines: 1,
                      //       //     overflow: TextOverflow.ellipsis,
                      //       //   ),
                      //       // ),
                      //     ],
                      //   ),
                    ],
                  ),
                ),
              ],
            ),

            // SizedBox(height: 16),

            // Contact Information & Call Button
            // Container(
            //   padding: EdgeInsets.all(12),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(color: AppColors.inputBackground),
            //   ),
            //   child: Row(
            //     children: [
            //       // Phone Info
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               "Contact Number",
            //               style: AppText.labelSmall.copyWith(
            //                 color: AppColors.textColorSecondary,
            //                 fontWeight: FontWeight.w600,
            //               ),
            //             ),
            //             SizedBox(height: 4),
            //             Text(
            //               tech.workPhone.toString(),
            //               style: AppText.bodyMedium.copyWith(
            //                 color: AppColors.textColorPrimary,
            //                 fontWeight: FontWeight.w600,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),

            //       // Call Button
            //       Container(
            //         decoration: BoxDecoration(
            //           shape: BoxShape.circle,
            //           gradient: LinearGradient(
            //             colors: [AppColors.primary, AppColors.primaryDark],
            //           ),
            //           boxShadow: [
            //             BoxShadow(
            //               color: AppColors.primary.withOpacity(0.4),
            //               blurRadius: 8,
            //               offset: Offset(0, 3),
            //             ),
            //           ],
            //         ),
            //         child: IconButton(
            //           onPressed: () {
            //             Get.bottomSheet(
            //               Container(
            //                 padding: EdgeInsets.all(24),
            //                 decoration: BoxDecoration(
            //                   color: Colors.white,
            //                   borderRadius: BorderRadius.vertical(
            //                     top: Radius.circular(28),
            //                   ),
            //                 ),
            //                 child: Column(
            //                   mainAxisSize: MainAxisSize.min,
            //                   children: [
            //                     // Drag handle
            //                     Center(
            //                       child: Container(
            //                         width: 48,
            //                         height: 5,
            //                         decoration: BoxDecoration(
            //                           color: Colors.grey[300],
            //                           borderRadius: BorderRadius.circular(3),
            //                         ),
            //                       ),
            //                     ),
            //                     SizedBox(height: 20),

            //                     Text(
            //                       "Contact Technician",
            //                       style: AppText.headingSmall.copyWith(
            //                         fontWeight: FontWeight.w700,
            //                       ),
            //                     ),
            //                     SizedBox(height: 20),

            //                     // Technician Info
            //                     Container(
            //                       padding: EdgeInsets.all(16),
            //                       decoration: BoxDecoration(
            //                         color: AppColors.inputBackground,
            //                         borderRadius: BorderRadius.circular(20),
            //                       ),
            //                       child: Row(
            //                         children: [
            //                           Container(
            //                             width: 56,
            //                             height: 56,
            //                             decoration: BoxDecoration(
            //                               shape: BoxShape.circle,
            //                               gradient: LinearGradient(
            //                                 colors: [
            //                                   AppColors.primary.withOpacity(
            //                                     0.2,
            //                                   ),
            //                                   AppColors.secondary.withOpacity(
            //                                     0.1,
            //                                   ),
            //                                 ],
            //                               ),
            //                             ),
            //                             child: Icon(
            //                               Icons.person_rounded,
            //                               color: AppColors.primary,
            //                               size: 28,
            //                             ),
            //                           ),
            //                           SizedBox(width: 16),
            //                           Expanded(
            //                             child: Column(
            //                               crossAxisAlignment:
            //                                   CrossAxisAlignment.start,
            //                               children: [
            //                                 Text(
            //                                   tech.name,
            //                                   style: AppText.labelLarge
            //                                       .copyWith(
            //                                         fontWeight: FontWeight.w700,
            //                                       ),
            //                                 ),
            //                                 SizedBox(height: 4),
            //                                 Text(
            //                                   tech.companyName,
            //                                   style: AppText.bodySmall.copyWith(
            //                                     color:
            //                                         AppColors
            //                                             .textColorSecondary,
            //                                   ),
            //                                 ),
            //                               ],
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                     SizedBox(height: 20),

            //                     // Call Button
            //                     SizedBox(
            //                       width: double.infinity,
            //                       height: 56,
            //                       child: ElevatedButton.icon(
            //                         onPressed:
            //                         // () => launchUrl(
            //                         //   Uri.parse('tel:${tech.workPhone}'),
            //                         // ),
            //                         () {
            //                           Get.to(
            //                             CallScreen(
            //                               phoneNumber:
            //                                   tech.workPhone.toString(),
            //                             ),
            //                           );
            //                         },
            //                         icon: const Icon(
            //                           Icons.call_rounded,
            //                           size: 24,
            //                         ),
            //                         label: Text(
            //                           "Call",
            //                           style: AppText.button.copyWith(
            //                             fontWeight: FontWeight.w700,
            //                           ),
            //                         ),
            //                         style: ElevatedButton.styleFrom(
            //                           backgroundColor: AppColors.success,
            //                           foregroundColor: Colors.white,
            //                           shape: RoundedRectangleBorder(
            //                             borderRadius: BorderRadius.circular(16),
            //                           ),
            //                           elevation: 4,
            //                         ),
            //                       ),
            //                     ),
            //                     SizedBox(height: 12),

            //                     // Close Button
            //                     TextButton(
            //                       onPressed: Get.back,
            //                       child: Text(
            //                         "Cancel",
            //                         style: AppText.bodyMedium.copyWith(
            //                           color: AppColors.textColorSecondary,
            //                         ),
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //               isScrollControlled: true,
            //             );
            //           },
            //           icon: Icon(
            //             Icons.call_rounded,
            //             color: Colors.white,
            //             size: 22,
            //           ),
            //           style: ButtonStyle(
            //             backgroundColor: MaterialStateProperty.all(
            //               Colors.transparent,
            //             ),
            //             shadowColor: MaterialStateProperty.all(
            //               Colors.transparent,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingTechnicianCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 120,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () => _showFullScreenImage(imageUrl),
        child: Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  value:
                      progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                  color: AppColors.primary,
                ),
              ),
            );
          },
          errorBuilder:
              (ctx, err, st) => Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: Colors.grey,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showFullScreenImage(imageUrl),
                        child: Text(
                          "Retry",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Failed to load image",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed:
                                          () => _showFullScreenImage(imageUrl),
                                      child: Text("Retry"),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: Colors.white),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildStatusTimeline(ComplaintViewModel complaint, bool isAssigned) {
    final steps = [
      {
        'status': 'Open',
        'icon': Icons.access_time_rounded,
        'color': AppColors.success, //AppColors.primary,
        'time': complaint.createdAt,
        'label': 'Request Received',
      },
      {
        'status': 'Assigned',
        'icon': Icons.engineering_rounded,
        'color':
            isAssigned
                ? AppColors
                    .success // AppColors.secondary
                : Colors.grey,
        'time': isAssigned ? complaint.updatedAt : 'Pending',
        'label': 'Technician Assigned',
      },
      {
        'status': 'Resolved',
        'icon': Icons.check_circle_rounded,
        'color': complaint.isResolved ? AppColors.success : Colors.grey,
        'time': complaint.isResolved ? complaint.updatedAt : 'Pending',
        'label': 'Issue Resolved',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBackground, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children:
            steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted =
                  complaint.displayStatus != 'Open' ||
                  step['status'] == 'Open' ||
                  (step['status'] == 'Assigned' && isAssigned);

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          shape: BoxShape.circle,
                          boxShadow:
                              complaint.displayStatus == step['status'] ||
                                      complaint.isResolved
                                  ? [
                                    BoxShadow(
                                      color: step['color'] as Color,
                                      // spreadRadius: ,
                                      blurRadius: 20,
                                    ),
                                  ]
                                  : [],
                        ),

                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isCompleted
                                    ? step['color'] as Color
                                    : Colors.grey)
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isCompleted
                                      ? step['color'] as Color
                                      : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color:
                                isCompleted
                                    ? step['color'] as Color
                                    : Colors.grey,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['label'].toString(),
                              style: AppText.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['time'].toString(),
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                              ),
                            ),
                            if (step['label'] == 'Request Received')
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.inputBackground,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      complaint.category,
                                      style: AppText.labelSmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // if (complaint.subCategory != null) ...[
                                    //   const SizedBox(height: 8),
                                    //   Text(
                                    //     complaint.subCategory!,
                                    //     style: AppText.bodySmall.copyWith(
                                    //       color: AppColors.textColorSecondary,
                                    //       fontWeight: FontWeight.w500,
                                    //     ),
                                    //   ),
                                    // ],
                                    // const SizedBox(height: 12),
                                    // Text(
                                    //   complaint.description,
                                    //   style: AppText.bodyMedium,
                                    // ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 4),
                            if (step['label'].toString() ==
                                "Technician Assigned")
                              if (isAssigned) _buildTechnicianCard(complaint),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (index < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 22,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              isCompleted
                                  ? (step['color'] as Color).withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.3),
                              isCompleted
                                  ? (step['color'] as Color).withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppText.labelLarge.copyWith(
        color: AppColors.textColorPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _onQuickHelpTap(String issue) {
    final Map<String, String> defaultTitles = {
      'Connection Issues': 'Internet Not Working',
      'Slow Speed': 'Speed is Too Slow',
      'Billing Help': 'Billing Issue',
      'Device Setup': 'Router Not Working',
    };
    final Map<String, String> defaultDescriptions = {
      'Connection Issues':
          'No internet connectivity. Restarted router but no effect.',
      'Slow Speed': 'Speed dropped significantly from plan speed.',
      'Billing Help': 'Charged extra or renewal issue.',
      'Device Setup': 'Router not connecting or setup issue.',
    };
    final title = defaultTitles[issue] ?? "General Issue";
    final description =
        defaultDescriptions[issue] ?? "Need assistance with $issue.";
    _showRaiseComplaintDialog(title: title, description: description);
  }

  void _showRaiseComplaintDialog({String? title, String? description}) {
    controller.fetchTicketCategories();
    final TextEditingController descCtrl = TextEditingController(
      text: description,
    );
    final FocusNode descFocusNode = FocusNode();
    final double bottomSheetHeight = MediaQuery.of(context).size.height * 0.85;

    final Rx<CategoryData?> selectedCategory = Rx<CategoryData?>(null);
    final Rx<SubCategory?> selectedSubcategory = Rx<SubCategory?>(null);
    final Rx<File?> selectedImage = Rx<File?>(null);

    if (controller.canSubmitNewComplaint) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: bottomSheetHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            "Raise a Complaint",
                            style: AppText.headingMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          "Category",
                          style: AppText.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          if (controller.isCategoriesLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final categories = controller.ticketCategories;
                          if (categories.isEmpty) {
                            return Text(
                              "No categories available",
                              style: AppText.bodyMedium,
                            );
                          }
                          final items =
                              categories.map<DropdownMenuItem<CategoryData>>((
                                cat,
                              ) {
                                return DropdownMenuItem<CategoryData>(
                                  value: cat,
                                  child: Text(
                                    cat.categoryName,
                                    style: AppText.bodyMedium,
                                  ),
                                );
                              }).toList();
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.textColorHint.withOpacity(0.4),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<CategoryData>(
                                value: selectedCategory.value,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                style: AppText.bodyMedium.copyWith(
                                  color: AppColors.textColorPrimary,
                                ),
                                onChanged: (CategoryData? newValue) {
                                  if (newValue != null) {
                                    selectedCategory.value = newValue;
                                    selectedSubcategory.value = null;
                                  }
                                },
                                items: items,
                                hint: Text(
                                  "Select a Category",
                                  style: AppText.bodyMedium.copyWith(
                                    color: AppColors.textColorHint,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        Obx(() {
                          final cat = selectedCategory.value;
                          if (cat == null) {
                            return const SizedBox.shrink();
                          }
                          final subcategories = cat.subcategories;
                          if (subcategories.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final subItems =
                              subcategories.map<DropdownMenuItem<SubCategory>>((
                                sub,
                              ) {
                                return DropdownMenuItem<SubCategory>(
                                  value: sub,
                                  child: Text(
                                    sub.subcategoryName,
                                    style: AppText.bodyMedium,
                                  ),
                                );
                              }).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sub Category",
                                style: AppText.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColorPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.textColorHint.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<SubCategory>(
                                    value: selectedSubcategory.value,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                    style: AppText.bodyMedium.copyWith(
                                      color: AppColors.textColorPrimary,
                                    ),
                                    onChanged: (SubCategory? newValue) {
                                      selectedSubcategory.value = newValue;
                                    },
                                    items: subItems,
                                    hint: Text(
                                      "Select SubCategory",
                                      style: AppText.bodyMedium.copyWith(
                                        color: AppColors.textColorHint,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 20),
                        Text(
                          "Description",
                          style: AppText.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descCtrl,
                          focusNode: descFocusNode,
                          maxLines: 4,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText: "Describe your issue in detail",
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
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
                              vertical: 14,
                            ),
                          ),
                          style: AppText.bodyMedium.copyWith(
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => _buildImageUploadSection(
                            context,
                            selectedImage.value,
                            (file) => selectedImage.value = file,
                            () => selectedImage.value = null,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedCategory.value == null) {
                                BaseApiService().showSnackbar(
                                  "Required",
                                  "Please select a category",
                                  isError: true,
                                );
                                return;
                              }
                              if (selectedSubcategory.value == null) {
                                BaseApiService().showSnackbar(
                                  "Required",
                                  "Please select a subcategory",
                                  isError: true,
                                );
                                return;
                              }
                              if (descCtrl.text.isEmpty) {
                                BaseApiService().showSnackbar(
                                  "Required",
                                  "Please add a description",
                                  isError: true,
                                );
                                return;
                              }
                              controller.addComplaint(
                                category: selectedCategory.value!.categoryName,
                                subCategory:
                                    selectedSubcategory.value!.subcategoryName,
                                description: descCtrl.text,
                                image: selectedImage.value,
                              );
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: Text(
                              "Submit Complaint",
                              style: AppText.button.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      BaseApiService().showSnackbar(
        "Complaint Limit Reached",
        "You can only have up to 5 open complaints at a time. Please wait until some are resolved.",
        isError: true,
      );
    }
  }
}

Widget _buildImageUploadSection(
  context,
  File? image,
  Function(File) onImageSelected,
  VoidCallback onClearImage,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Attach Image (Optional)",
        style: AppText.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textColorPrimary,
        ),
      ),
      const SizedBox(height: 8),
      if (image == null)
        Row(
          children: [
            Expanded(
              child: _buildImageOptionButton(
                icon: Icons.camera_alt_rounded,
                label: "Take Photo",
                onTap: () async {
                  final file = await _pickImage(ImageSource.camera);
                  if (file != null) onImageSelected(file);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageOptionButton(
                icon: Icons.photo_library_rounded,
                label: "Choose from Gallery",
                onTap: () async {
                  final file = await _pickImage(ImageSource.gallery);
                  if (file != null) onImageSelected(file);
                },
              ),
            ),
          ],
        )
      else
        Column(
          children: [
            GestureDetector(
              onTap: () => _showEnhancedImagePreview(context, image),
              child: Hero(
                tag: 'complaint_image_${image.path}',
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textColorHint),
                    image: DecorationImage(
                      image: FileImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed:
                                () => _showEnhancedImagePreview(context, image),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text("Change"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final file = await _pickImage(ImageSource.gallery);
                      if (file != null) onImageSelected(file);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text("Remove"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onClearImage,
                  ),
                ),
              ],
            ),
          ],
        ),
    ],
  );
}

Widget _buildImageOptionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textColorHint),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppText.bodySmall.copyWith(
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showEnhancedImagePreview(context, File image) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.95),
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'complaint_image_${image.path}',
                      child: Image.file(
                        image,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.error_outline_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<File?> _pickImage(ImageSource source) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) return File(picked.path);
    return null;
  } catch (e) {
    BaseApiService().showSnackbar(
      "Error",
      "Failed to pick image: ${e.toString()}",
      isError: true,
    );
    return null;
  }
}

// Dummy OTP Screen
class _TechnicianOtpScreen extends StatelessWidget {
  final ComplaintViewModel complaint;
  final VoidCallback onVerified;

  const _TechnicianOtpScreen({
    required this.complaint,
    required this.onVerified,
  });

  @override
  Widget build(BuildContext context) {
    final otpController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text("Verify Technician", style: AppText.headingSmall),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textColorPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Enter OTP sent to technician", style: AppText.bodyLarge),
            const SizedBox(height: 24),
            Pinput(
              controller: otpController,
              length: 6,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: AppText.headingSmall,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: AppText.headingSmall,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (otpController.text == "123456") {
                    BaseApiService().showSnackbar("Success", "OTP Verified!");
                    onVerified();
                  } else {
                    BaseApiService().showSnackbar(
                      "Error",
                      "Invalid OTP. Try 123456",
                      isError: true,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text("Verify OTP", style: AppText.button),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "💡 Tip: Use 123456 to simulate verification (Production: Use real OTP)",
              style: AppText.bodySmall.copyWith(
                color: AppColors.textColorSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy Rating Bar
class _RatingBar extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingUpdate;

  const _RatingBar({required this.rating, required this.onRatingUpdate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 36,
          ),
          onPressed: () => onRatingUpdate(index + 1),
        );
      }),
    );
  }
}
