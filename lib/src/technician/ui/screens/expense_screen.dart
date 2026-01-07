// screens/expense/expense_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/apis/technician_api_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import 'package:intl/intl.dart'; // For date formatting

class ExpenseItem {
  final int id;
  final String title;
  final String status;
  final String category;
  final double amount;
  final String date;
  final String image;
  final String? description;
  final String? remark;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.status,
    required this.category,
    required this.amount,
    required this.date,
    required this.image,
    this.description,
    this.remark,
  });

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as int? ?? -1,
      title: map['expense_title'] as String? ?? 'N/A',
      status: map['status'] as String? ?? 'Unknown',
      category: map['expense_category'] as String? ?? 'General',
      amount: (num.parse(map['amount']) as num?)?.toDouble() ?? 0.0,
      date: map['expense_date'] as String? ?? 'N/A',
      image: "${BaseApiService.api}techAPI/${map['image']}" as String? ?? '',
      description: map['description'] as String?,
      remark: map['remark'] as String?,
    );
  }
}

class ExpenseController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();

  var expenses = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var isSubmitting = false.obs;

  var title = ''.obs;
  var description = ''.obs;
  var amount = ''.obs;
  var date = ''.obs;
  var remark = ''.obs;
  var selectedCategory = 'Travel'.obs;
  var selectedPaymentMode = 'Cash'.obs;
  var selectedStatus = 'Pending'.obs;
  var imageFile = Rx<File?>(null);
  var imageBase64 = RxString('');

  static const List<String> expenseCategories = [
    'Travel',
    'Food',
    'Accommodation',
    'Transport',
    'Stationery',
    'Other',
  ];

  static const List<String> paymentModes = ['Cash', 'Card', 'Online', 'Other'];

  @override
  void onInit() {
    super.onInit();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _api.fetchExpenses();
      if (response != null) {
        expenses.assignAll(response);
      } else {
        errorMessage.value = 'Failed to load expenses.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addExpense() async {
    if (title.value.isEmpty ||
        amount.value.isEmpty ||
        date.value.isEmpty ||
        imageBase64.value.isEmpty) {
      BaseApiService().showSnackbar(
        "Error",
        "Please fill all required fields and select an image.",
        isError: true,
      );
      return;
    }

    final parsedAmount = double.tryParse(amount.value);
    if (parsedAmount == null || parsedAmount <= 0) {
      BaseApiService().showSnackbar(
        "Error",
        "Please enter a valid amount.",
        isError: true,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final result = await _api.addExpense(
        expenseTitle: title.value.trim(),
        amount: parsedAmount,
        expenseDate: date.value,
        image: imageBase64.value,
        paymentMode: selectedPaymentMode.value,
        expenseCategory: selectedCategory.value,
        description:
            description.value.isEmpty ? null : description.value.trim(),
        remark: remark.value.isEmpty ? null : remark.value.trim(),
      );

      if (result) {
        clearAddExpenseForm();
        fetchExpenses();
        Navigator.pop(Get.context!);
      } else {
        BaseApiService().showSnackbar(
          "Error",
          'Failed to add expense.',
          isError: true,
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  void selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          date.value.isNotEmpty ? DateTime.parse(date.value) : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textColorPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      date.value =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    }
  }

  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
      imageBase64.value = base64Encode(imageFile.value!.readAsBytesSync());
    }
  }

  void clearAddExpenseForm() {
    title.value = '';
    description.value = '';
    amount.value = '';
    date.value = '';
    remark.value = '';
    selectedCategory.value = 'Travel';
    selectedPaymentMode.value = 'Cash';
    imageFile.value = null;
    imageBase64.value = '';
  }
}

class ExpenseScreen extends StatelessWidget {
  ExpenseScreen({super.key});

  final ExpenseController controller = Get.put(
    ExpenseController(),
    permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Enhanced App Bar with Glass Morphism Effect
            SliverAppBar(
              // expandedHeight: 10.h,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              iconTheme: IconThemeData(color: AppColors.backgroundLight),
              title: Text(
                'Expense Tracker',
                style: AppText.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedOpacity(
                  opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    'Expense Tracker',
                    style: AppText.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.9),
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background Pattern
                      Positioned(
                        right: -30.w,
                        top: -30.h,
                        child: Container(
                          width: 150.w,
                          height: 150.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20.w,
                        bottom: -20.h,
                        child: Container(
                          width: 100.w,
                          height: 100.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 60.h,
                          left: 24.w,
                          right: 24.w,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expense Tracker',
                              style: AppText.headingLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 32.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Track and manage your expenses efficiently',
                              style: AppText.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              elevation: 0,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.r),
                  bottomRight: Radius.circular(40.r),
                ),
              ),
            ),
          ];
        },
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundLight.withOpacity(0.1),
                AppColors.backgroundLight,
              ],
            ),
          ),
          child: Column(
            children: [
              // Stats Section with Glass Morphism
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Obx(() => _buildStatsSection()),
              ),

              // Header with Filter Option
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.sp,
                  vertical: 8.sp,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Expenses',
                      style: AppText.headingMedium.copyWith(
                        color: AppColors.textColorPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${controller.expenses.length} items',
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.all(6.sp),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 18.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expenses List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildLoadingState();
                  }

                  if (controller.errorMessage.value.isNotEmpty) {
                    return _buildErrorWidget();
                  }

                  if (controller.expenses.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.sp,
                      vertical: 8.sp,
                    ),
                    itemCount: controller.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = controller.expenses[index];
                      return _buildExpenseCard(context, expense, index);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildStatsSection() {
    final totalAmount = controller.expenses.fold<double>(0.0, (sum, item) {
      return sum + ((num.parse(item['amount']) as num?)?.toDouble() ?? 0.0);
    });

    final pendingCount =
        controller.expenses
            .where((e) => (e['status'] as String?)?.toLowerCase() == 'pending')
            .length;
    final approvedCount =
        controller.expenses
            .where((e) => (e['status'] as String?)?.toLowerCase() == 'approved')
            .length;

    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            '₹${totalAmount.toStringAsFixed(2)}',
            Icons.currency_rupee_rounded,
            AppColors.primary,
            totalAmount.toString(),
          ),
          _buildStatItem(
            'Pending',
            pendingCount.toString(),
            Icons.pending_actions_rounded,
            AppColors.warning,
            pendingCount.toString(),
          ),
          _buildStatItem(
            'Approved',
            approvedCount.toString(),
            Icons.verified_rounded,
            AppColors.success,
            approvedCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    String tooltip,
  ) {
    return Tooltip(
      message: '$title: $value',
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(height: 12.sp),
          Text(
            value,
            style: AppText.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textColorPrimary,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            title,
            style: AppText.labelSmall.copyWith(
              color: AppColors.textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(context, Map<String, dynamic> expense, int index) {
    final status = expense['status'] as String? ?? 'Pending';
    final amount = (num.parse(expense['amount']) as num?)?.toDouble() ?? 0.0;
    final category = expense['expense_category'] as String? ?? 'General';

    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            final controller = Get.put(
              ExpenseDetailBottomSheetController(expense['id']),
              tag: expense['id'].toString(), // unique instance per id
            );

            controller.loadExpense();

            showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              ),
              context: context,
              isScrollControlled: true,
              // backgroundColor: Colors.transparent,
              builder:
                  (context) =>
                      ExpenseDetailBottomSheet(expenseId: expense['id']),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: Row(
                children: [
                  // Category Icon with Gradient
                  Container(
                    padding: EdgeInsets.all(14.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getCategoryColor(category).withOpacity(0.2),
                          _getCategoryColor(category).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: _getCategoryColor(category).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 22.sp,
                    ),
                  ),

                  SizedBox(width: 16.sp),

                  // Expense Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                expense['expense_title'] as String? ?? 'N/A',
                                style: AppText.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textColorPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.sp,
                                vertical: 6.sp,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getStatusColor(status).withOpacity(0.1),
                                    _getStatusColor(status).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: AppText.labelSmall.copyWith(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 6.sp),

                        Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 14.sp,
                              color: AppColors.textColorSecondary,
                            ),
                            SizedBox(width: 4.sp),
                            Text(
                              category,
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8.sp),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14.sp,
                              color: AppColors.textColorSecondary,
                            ),
                            SizedBox(width: 4.sp),
                            Text(
                              _formatDate(expense['created_at']),
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                              ),
                            ),
                            Spacer(),
                            Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: AppText.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.h,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 16.sp),
          Text(
            'Loading expenses...',
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: EdgeInsets.all(32.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64.sp,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: 24.sp),
          Text(
            'Oops! Something went wrong',
            style: AppText.headingSmall.copyWith(
              color: AppColors.textColorPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.sp),
          Text(
            controller.errorMessage.value,
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.sp),
          ElevatedButton(
            onPressed: controller.fetchExpenses,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: Text(
              'Try Again',
              style: AppText.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(32.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.sp),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 80.sp,
              color: AppColors.primary.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24.sp),
          Text(
            'No expenses yet',
            style: AppText.headingSmall.copyWith(
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.sp),
          Text(
            'Start tracking your expenses by adding your first one',
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.sp),
          Text(
            'Tap the + button below to get started',
            style: AppText.bodySmall.copyWith(
              color: AppColors.textColorSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showAddExpenseBottomSheet(Get.context!),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      child: Container(
        width: 60.r,
        height: 60.r,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, size: 28.sp),
      ),
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    showModalBottomSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseBottomSheet(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textColorSecondary;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'travel':
        return Colors.blue.shade600;
      case 'food':
        return Colors.orange.shade600;
      case 'accommodation':
        return Colors.purple.shade600;
      case 'transport':
        return Colors.green.shade600;
      case 'stationery':
        return Colors.brown.shade600;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'stationery':
        return Icons.description_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }
}

class AddExpenseBottomSheet extends StatelessWidget {
  AddExpenseBottomSheet({super.key});

  final ExpenseController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Gradient
              Container(
                padding: EdgeInsets.all(20.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Expense',
                          style: AppText.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          'Fill in the expense details',
                          style: AppText.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(Get.context!),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.sp),
                  child: Form(
                    child: Column(
                      children: [
                        _buildInputField(
                          icon: Icons.title_rounded,
                          label: 'Title',
                          hintText: 'Enter expense title',
                          onChanged: (value) => controller.title.value = value,
                        ),

                        _buildInputField(
                          icon: Icons.description_rounded,
                          label: 'Description',
                          hintText: 'Enter description (optional)',
                          maxLines: 2,
                          onChanged:
                              (value) => controller.description.value = value,
                        ),

                        _buildInputField(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Amount',
                          hintText: '0.00',
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefix: Text('₹ '),
                          onChanged: (value) => controller.amount.value = value,
                        ),

                        Obx(() => _buildDateField()),

                        SizedBox(height: 8.sp),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                icon: Icons.category_rounded,
                                label: 'Category',
                                value: controller.selectedCategory.value,
                                items: ExpenseController.expenseCategories,
                                onChanged:
                                    (value) =>
                                        controller.selectedCategory.value =
                                            value!,
                              ),
                            ),
                            SizedBox(width: 12.sp),
                            Expanded(
                              child: _buildDropdownField(
                                icon: Icons.payment_rounded,
                                label: 'Payment Mode',
                                value: controller.selectedPaymentMode.value,
                                items: ExpenseController.paymentModes,
                                onChanged:
                                    (value) =>
                                        controller.selectedPaymentMode.value =
                                            value!,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.sp),

                        _buildImageSection(),

                        SizedBox(height: 24.sp),

                        Obx(() => _buildSubmitButton()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String hintText,
    required Function(String) onChanged,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefix,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 18.sp, color: AppColors.primary),
              ),
              SizedBox(width: 8.sp),
              Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.sp),
                prefix: prefix,
              ),
              maxLines: maxLines,
              keyboardType: keyboardType,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 18.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 8.sp),
              Text(
                'Date',
                style: AppText.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          GestureDetector(
            onTap: () => controller.selectDate(Get.context!),
            child: Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(
                    controller.date.value.isEmpty
                        ? 'Select date'
                        : controller.date.value,
                    style: AppText.bodyMedium.copyWith(
                      color:
                          controller.date.value.isEmpty
                              ? Colors.grey.shade500
                              : AppColors.textColorPrimary,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 18.sp, color: AppColors.primary),
              ),
              SizedBox(width: 8.sp),
              Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              items:
                  items.map((item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(border: InputBorder.none),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.image_rounded,
                  size: 18.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 8.sp),
              Text(
                'Receipt Image',
                style: AppText.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          GestureDetector(
            onTap: controller.pickImage,
            child: Container(
              height: 140.h,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      controller.imageFile.value != null
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.grey.shade50,
              ),
              child:
                  controller.imageFile.value != null
                      ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: Image.file(
                              controller.imageFile.value!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8.sp,
                            right: 8.sp,
                            child: Container(
                              padding: EdgeInsets.all(6.sp),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 16.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 48.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12.sp),
                          Text(
                            'Tap to add receipt image',
                            style: AppText.bodyMedium.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            'Required for verification',
                            style: AppText.labelSmall.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed:
            controller.isSubmitting.value
                ? null
                : () => controller.addExpense(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 2,
        ),
        child:
            controller.isSubmitting.value
                ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 20.sp, color: Colors.white),
                    SizedBox(width: 8.sp),
                    Text(
                      'Add Expense',
                      style: AppText.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// Add this method to your ExpenseController class
// Future<Map<String, dynamic>?> fetchExpenseDetails(int expenseId) async {
//   try {
//     final response = await _api.fetchExpenseDetails(expenseId);
//     return response;
//   } catch (e) {
//     BaseApiService().showSnackbar(
//       "Error",
//       "Failed to load expense details",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: AppColors.error,
//       colorText: Colors.white,
//     );
//     return null;
//   }
// }

// // Add this to your ExpenseAPI service
// Future<Map<String, dynamic>?> fetchExpenseDetails(int expenseId) async {
//   final body = {'id': expenseId};

//   try {
//     final res = await _apiClient.post(_fetchExpenseDetails, body: body);

//     if (res.statusCode == 200) {
//       final json = jsonDecode(res.body) as Map<String, dynamic>;
//       if (json['status'] == 'success' && json.containsKey('data')) {
//         return json['data'];
//       }
//     }
//   } catch (e) {
//     developer.log('Exception in fetchExpenseDetails: $e');
//   }
//   return null;
// }

// Beautiful Expense Detail Bottom Sheet

// Beautiful Expense Detail Bottom Sheet
// Inside expense_screen.dart or a new file
class ExpenseDetailBottomSheetController extends GetxController {
  final int expenseId;
  final TechnicianAPI _api = TechnicianAPI();

  ExpenseDetailBottomSheetController(this.expenseId);

  var expense = Rxn<ExpenseItem>();
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadExpense();
  }

  Future<void> loadExpense() async {
    isLoading.value = true;
    try {
      final data = await _api.fetchExpenseDetails(expenseId);
      if (data != null) {
        expense.value = ExpenseItem.fromMap(data);
      }
    } finally {
      isLoading.value = false;
    }
  }
}

// lib/screens/expense/expense_screen.dart
class ExpenseDetailBottomSheet extends StatelessWidget {
  final int expenseId; // 👈 Accept ID, not raw data
  final ExpenseController controller = Get.find();

  ExpenseDetailBottomSheet({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpenseDetailBottomSheetController>(
      init: ExpenseDetailBottomSheetController(expenseId),
      builder: (ctrl) {
        return Obx(() {
          if (controller.isLoading.value) {
            return _buildSkeletonLoader();
          }

          if (ctrl.expense.value == null) {
            return _buildSkeletonLoader();
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),
                topRight: Radius.circular(32.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24.sp),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.sp),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          _getCategoryIcon(ctrl.expense.value!.category),
                          size: 24.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16.sp),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ctrl.expense.value?.title ?? "Loading...",
                              style: AppText.headingMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.sp),
                            Text(
                              ctrl.expense.value?.category ?? "",
                              style: AppText.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: Obx(() {
                    if (ctrl.isLoading.value) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (ctrl.expense.value == null) {
                      return Center(child: Text("Failed to load details"));
                    }
                    final e = ctrl.expense.value;
                    final imageUrl = e!.image;
                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24.sp),
                        child: Column(
                          children: [
                            // Amount Card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20.sp),
                              margin: EdgeInsets.only(bottom: 24.sp),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.1),
                                    AppColors.primary.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: AppText.bodyMedium.copyWith(
                                      color: AppColors.textColorSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 8.sp),
                                  Text(
                                    '₹${e.amount.toStringAsFixed(2)}',
                                    style: AppText.headingLarge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 12.sp),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.sp,
                                      vertical: 8.sp,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getStatusColor(
                                            e.status,
                                          ).withOpacity(0.15),
                                          _getStatusColor(
                                            e.status,
                                          ).withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: _getStatusColor(
                                          e.status,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      e.status.toUpperCase(),
                                      style: AppText.labelSmall.copyWith(
                                        color: _getStatusColor(e.status),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Details
                            Container(
                              padding: EdgeInsets.all(20.sp),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    icon: Icons.calendar_month_rounded,
                                    label: 'Expense Date',
                                    value: _formatDate(e.date),
                                    iconColor: Colors.blue.shade600,
                                  ),
                                  _buildDivider(),
                                  // _buildDetailRow(
                                  //   icon: Icons.payment_rounded,
                                  //   label: 'Payment Mode',
                                  //   value: _formatPaymentMode(e.paymentMode),
                                  //   iconColor: Colors.green.shade600,
                                  // ),
                                  _buildDivider(),
                                  _buildDetailRow(
                                    icon: Icons.category_rounded,
                                    label: 'Category',
                                    value: e.category,
                                    iconColor: AppColors.primary,
                                  ),
                                  _buildDivider(),
                                  _buildDetailRow(
                                    icon: Icons.description_rounded,
                                    label: 'Description',
                                    value: e.description ?? 'Not provided',
                                    iconColor: Colors.orange.shade600,
                                  ),
                                  _buildDivider(),
                                  _buildDetailRow(
                                    icon: Icons.note_rounded,
                                    label: 'Remark',
                                    value: e.remark ?? 'Not provided',
                                    iconColor: Colors.purple.shade600,
                                  ),
                                  _buildDivider(),
                                  // _buildDetailRow(
                                  //   icon: Icons.update_rounded,
                                  //   label: 'Last Updated',
                                  //   value: _formatDateTime(e.updatedAt),
                                  //   iconColor: Colors.teal.shade600,
                                  // ),
                                ],
                              ),
                            ),
                            // Image
                            SizedBox(height: 24.sp),
                            Container(
                              padding: EdgeInsets.all(20.sp),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6.sp),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.receipt_long_rounded,
                                          size: 18.sp,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(width: 8.sp),
                                      Text(
                                        'Receipt Image',
                                        style: AppText.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.sp),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Image.network(
                                      imageUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                height: 200,
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child: Icon(Icons.error),
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 40.sp),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        });
      },
    );
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.sp),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.sp, color: iconColor),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.labelSmall.copyWith(
                  color: AppColors.textColorSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.sp),
              Text(
                value,
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.textColorPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Padding(
    padding: EdgeInsets.symmetric(vertical: 16.sp),
    child: Divider(height: 1, color: Colors.grey.shade200),
  );

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textColorSecondary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'stationery':
        return Icons.description_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _formatDate(String date) {
    try {
      return DateFormat('MMMM dd, yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      return DateFormat(
        'MMM dd, yyyy \'at\' hh:mm a',
      ).format(DateTime.parse(dateTime));
    } catch (e) {
      return dateTime;
    }
  }

  String _formatPaymentMode(String mode) =>
      mode[0].toUpperCase() + mode.substring(1);
}
