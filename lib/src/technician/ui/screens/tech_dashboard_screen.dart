// screens/dashboard/dashboard_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:asia_fibernet/src/services/apis/api_services.dart';
import 'package:asia_fibernet/src/services/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asia_fibernet/src/customer/core/models/ticket_category_model.dart';
import 'package:asia_fibernet/src/technician/core/models/find_customer_detail_model.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/apis/technician_api_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../core/models/tech_dashboard_model.dart';
import '../../attendance/attendance_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

// Model for recent tickets (simplified)
class RecentTicket {
  final String ticketNo;
  final String category;
  final String status;
  final String createdAt;

  RecentTicket({
    required this.ticketNo,
    required this.category,
    required this.status,
    required this.createdAt,
  });
}

class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  final TechnicianAPI _api = TechnicianAPI();
  AttendanceController attendanceController = AttendanceController();
  TechDashboardModel? _dashboard;
  List<RecentTicket> _recentTickets = [];
  bool _loading = true;
  int _notificationCount = 0;

  // Store today's tickets from new API
  List<Map<String, dynamic>> _todayTickets = [];

  // Stage definitions (0 to 5)
  final List<Map<String, dynamic>> _stages = [
    {'id': 0, 'label': 'Assigned', 'status': 'Assigned'},
    {'id': 1, 'label': 'Accept Job', 'status': 'Accept Job'},
    {'id': 2, 'label': 'On the Way', 'status': 'On the way'},
    {
      'id': 3,
      'label': 'Reached Customer',
      'status': 'Reached customer location',
    },
    {'id': 4, 'label': 'Work in Progress', 'status': 'Work in progress'},
    {'id': 5, 'label': 'Completed', 'status': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadTodayTickets(); // Load today's tickets
  }

  Future<void> _loadDashboard() async {
    try {
      final result = await _api.getDashboard();
      attendanceController.loadEvents();
      if (result == null) {
        BaseApiService().showSnackbar("Error", "Failed to load dashboard data");
      }
      setState(() {
        _dashboard = result;
        _loading = false;
      });

      if (result != null) {
        _recentTickets = [
          RecentTicket(
            ticketNo: 'TKT-001234',
            category: 'Call Drops',
            status: 'Closed',
            createdAt: '2025-08-28',
          ),
          RecentTicket(
            ticketNo: 'TKT-001235',
            category: 'No Internet',
            status: 'Open',
            createdAt: '2025-08-29',
          ),
          RecentTicket(
            ticketNo: 'TKT-001236',
            category: 'Slow Speed',
            status: 'Closed',
            createdAt: '2025-08-30',
          ),
        ];
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      BaseApiService().showSnackbar("Error", "Exception: $e");
    }
  }

  // NEW: Fetch today's tickets
  Future<void> _loadTodayTickets() async {
    try {
      final response =
          await _api
              .fetchTodayTickets(); // Ensure this method exists in TechnicianAPI
      if (response != null && response['status'] == 'success') {
        setState(() {
          _todayTickets = List<Map<String, dynamic>>.from(
            response['data'] ?? [],
          );
        });
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to load today's tickets: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await _loadDashboard();
              await _loadTodayTickets();
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: FadeIn(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      "Dashboard",
                      style: AppText.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  centerTitle: true,
                  pinned: true,
                  foregroundColor: Colors.white,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    FadeInRight(
                      duration: const Duration(milliseconds: 800),
                      child: Badge(
                        label: Text(
                          _notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        alignment: Alignment.topRight.add(
                          const Alignment(-.5, .3),
                        ),
                        largeSize: 25,
                        smallSize: 25,
                        child: IconButton(
                          icon: const Icon(Iconsax.notification, size: 24),
                          onPressed: () => Get.to(() => NotificationScreen()),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.1, 0.9],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child:
                        _loading
                            ? _buildShimmerDashboard()
                            : _dashboard == null
                            ? Center(
                              child: Text(
                                "Failed to load dashboard",
                                style: AppText.bodyMedium,
                              ),
                            )
                            : _buildDashboardContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDashboardContent() {
    final data = _dashboard?.data;
    _notificationCount = data?.notifications.totalNotifications ?? 0;
    if (data == null) {
      return Center(
        child: Text("No dashboard data available", style: AppText.bodyMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Card
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: GestureDetector(
            onTap: () => Get.to(() => const SettingsScreen()),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.profile_2user,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 154, 249, 159),
                                    const Color.fromARGB(255, 37, 175, 44),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.contactName,
                              style: AppText.headingMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColorPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: ${data.accountId ?? 'N/A'} • ${data.city}, ${data.state}",
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                              ),
                            ),
                            Text(
                              data.email ?? "N/A",
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              data.workphnumber ?? "N/A",
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.textColorSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 800),
          child: _buildPunchCard(),
        ),
        const SizedBox(height: 20),

        // Today's Tickets Section Header
        Text(
          "Today's Tickets",
          style: AppText.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
        ),

        // Today's Tickets List
        if (_todayTickets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "No tickets assigned for today",
              style: AppText.bodyMedium.copyWith(color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: 20),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayTickets.length,
            itemBuilder: (context, index) {
              return TechnicianTicketCard(
                ticket: _todayTickets[index],
                api: _api,
                // stages: _stages,
                onUpdated: _loadTodayTickets, // Only refresh tickets
              );
            },
          ),

        // const SizedBox(height: 20),

        // Stats Grid
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.allTickets),
          child: FadeInUp(
            delay: const Duration(milliseconds: 500),
            duration: const Duration(milliseconds: 1000),
            child: GridView.count(
              padding: EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                _statCard(
                  "Open Tickets",
                  data.tickets.openTickets ?? '0',
                  Iconsax.clock,
                  AppColors.warning,
                ),
                _statCard(
                  "Closed Tickets",
                  data.tickets.closedTickets ?? '0',
                  Iconsax.tick_circle,
                  AppColors.success,
                ),
                _statCard(
                  "Total Tickets",
                  data.tickets.totalTickets.toString(),
                  Iconsax.receipt,
                  AppColors.info,
                ),
                _statCard(
                  "Avg Rating",
                  "${data.ratings.avgRating?.substring(0, math.min(3, data.ratings.avgRating?.length ?? 0)) ?? 'N/A'} ⭐",
                  Iconsax.star,
                  AppColors.accent1,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- WIDGETS BELOW REMAIN UNCHANGED ---
  Widget _miniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppText.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
        ),
        Text(
          label,
          style: AppText.bodySmall.copyWith(
            color: AppColors.textColorSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppText.bodySmall.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerDashboard() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: List.generate(
            4,
            (index) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final data = _dashboard?.data;
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundLight.withOpacity(0.8),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child:
                  data != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.profile_2user,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data.contactName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.workphnumber ?? 'N/A',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      )
                      : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
            ),
            _drawerItem(Iconsax.home, "Dashboard", () => Get.back()),
            _drawerItem(
              Iconsax.receipt,
              "All Tickets",
              () => Get.toNamed(AppRoutes.allTickets),
            ),
            _drawerItem(
              Iconsax.activity,
              "Raise Ticket",
              () => Get.toNamed(AppRoutes.allCustomers),
            ),
            _drawerItem(
              Iconsax.calendar,
              "Attendance",
              () => Get.toNamed(AppRoutes.attendance),
            ),
            _drawerItem(
              Iconsax.strongbox,
              "Expenses",
              () => Get.toNamed(AppRoutes.expenses),
            ),
            _drawerItem(
              Iconsax.setting,
              "Settings",
              () => Get.to(() => const SettingsScreen()),
            ),
            const Divider(color: AppColors.dividerColor),
            _drawerItem(Iconsax.logout, "Logout", () async {
              await ApiServices().logOutDialog();
            }, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: AppText.bodyMedium.copyWith(
          color: color ?? AppColors.textColorPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('open')) return AppColors.warning;
    if (s.contains('assign')) return AppColors.info;
    if (s.contains('close') || s.contains('resolve')) return AppColors.success;
    return AppColors.textColorSecondary;
  }

  IconData _getStatusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('open')) return Iconsax.clock;
    if (s.contains('assign')) return Iconsax.user_tick;
    if (s.contains('close') || s.contains('resolve'))
      return Iconsax.tick_circle;
    return Iconsax.info_circle;
  }

  String _formatDate(String dateTimeStr) {
    try {
      final DateTime date = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _exportToPdf() async {
    final data = _dashboard?.data;
    if (data == null) {
      BaseApiService().showSnackbar(
        "Error",
        "No data to export",
        isError: true,
      );
      return;
    }
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Technician Dashboard Report",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Technician: ${data.contactName}"),
                pw.Text("ID: ${data.accountId ?? 'N/A'}"),
                pw.Text("City: ${data.city}"),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Stats",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text("Open Tickets: ${data.tickets.openTickets ?? '0'}"),
                pw.Text("Closed Tickets: ${data.tickets.closedTickets ?? '0'}"),
                pw.Text("Total Tickets: ${data.tickets.totalTickets}"),
                pw.Text("Average Rating: ${data.ratings.avgRating ?? 'N/A'} ⭐"),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Recent Tickets",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                ..._recentTickets.map(
                  (t) => pw.Text("${t.ticketNo} - ${t.category} (${t.status})"),
                ),
              ],
            ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Widget _buildPunchCard() {
    return Obx(() {
      final today = DateTime.now();
      final todayKey = DateTime.utc(today.year, today.month, today.day);
      final todayEvents = attendanceController.events[todayKey] ?? [];
      final todayAttendance = todayEvents.firstWhere(
        (e) => e.type == 'attendance',
        orElse:
            () => AttendanceEvent(
              type: 'attendance',
              status: 'Not Punched',
              punchIn: null,
              punchOut: null,
            ),
      );

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Today's Status",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPunchStatus(
                        "Punch In",
                        todayAttendance.punchIn ?? "--:--",
                        Iconsax.login_1,
                        todayAttendance.punchIn != null
                            ? Color(0xFF10B981)
                            : AppColors.textColorSecondary,
                      ),
                      Container(
                        width: 1.w,
                        height: 40.h,
                        color: Colors.grey[200],
                      ),
                      _buildPunchStatus(
                        "Punch Out",
                        todayAttendance.punchOut ?? "--:--",
                        Iconsax.logout,
                        todayAttendance.punchOut != null &&
                                todayAttendance.punchOut != 'On Duty'
                            ? Color(0xFF10B981)
                            : todayAttendance.punchOut == 'On Duty'
                            ? Color(0xFF3B82F6)
                            : Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (todayAttendance.punchIn == null)
                        _buildPunchButton(
                          "Punch IN",
                          Iconsax.login_1,
                          Color(0xFF10B981),
                          () => attendanceController.punchInOut(),
                          "Start your day",
                        )
                      else if (todayAttendance.punchOut == null)
                        _buildPunchButton(
                          "Punch OUT",
                          Iconsax.logout,
                          Color(0xFFEF4444),
                          () => attendanceController.punchInOut(),
                          "End your day",
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPunchButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Obx(
      () => Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: attendanceController.isPunching.value ? null : onPressed,
            icon: Icon(icon, size: 20.w, color: Colors.white),
            label: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPunchStatus(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24.w, color: color),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textColorSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          time,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorPrimary,
          ),
        ),
      ],
    );
  }
}

// ================================================
// TechnicianTicketCard Widget (Reusable)
// ================================================

class TechnicianTicketCard extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final TechnicianAPI api;
  final VoidCallback onUpdated;

  const TechnicianTicketCard({
    super.key,
    required this.ticket,
    required this.api,
    required this.onUpdated,
  });

  @override
  State<TechnicianTicketCard> createState() => _TechnicianTicketCardState();
}

class _TechnicianTicketCardState extends State<TechnicianTicketCard> {
  FindCustomerDetail? customerDetail;
  bool isLoadingCustomer = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerDetails();
  }

  Future<void> _loadCustomerDetails() async {
    final customerId = widget.ticket['customer_id'];
    if (customerId == null) return;

    setState(() {
      isLoadingCustomer = true;
    });

    try {
      final detail = await widget.api.fetchCustomerById(customerId);
      if (mounted) {
        setState(() {
          customerDetail = detail;
          isLoadingCustomer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingCustomer = false;
        });
      }
    }
  }

  // Map status text → stage ID
  int _getStatusId(String? status) {
    if (status == null) return -1;
    final s = status.toLowerCase().trim();
    if (s == 'assigned') return 0;
    if (s.contains('accept')) return 1;
    if (s.contains('on the way')) return 2;
    if (s.contains('reached')) return 3;
    if (s.contains('progress')) return 4;
    if (s.contains('completed')) return 5;
    return -1;
  }

  // Map stage ID → required status string for API
  String _getStatusTextForStage(int stage) {
    switch (stage) {
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
        return 'Work in progress';
    }
  }

  // Open location on Google Maps
  Future<void> _openLocationOnMap(double latitude, double longitude) async {
    try {
      // Check if latitude and longitude are valid (not 0.00)
      if (latitude == 0.0 && longitude == 0.0) {
        BaseApiService().showSnackbar(
          "Invalid Location",
          "No valid location data available",
          isError: true,
        );
        return;
      }

      // Create Google Maps URL
      final url =
          'https://www.google.com/maps/search/$latitude,$longitude/@$latitude,$longitude,15z';

      // Try to launch the URL
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        BaseApiService().showSnackbar(
          "Error",
          "Could not open map application",
          isError: true,
        );
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to open location: $e",
        isError: true,
      );
    }
  }

  void _autoAdvanceStage(BuildContext context) async {
    final datas = List<Map<String, dynamic>>.from(widget.ticket['datas'] ?? []);
    final latest = datas.isNotEmpty ? datas.last : {};
    final currentStatus = latest['status']?.toString();
    final currentStageId = _getStatusId(currentStatus);

    // If already completed, do nothing
    if (currentStageId == 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Job already completed!')));
      return;
    }

    // If at stage 4 (Work in Progress), show final step options
    if (currentStageId == 4) {
      _showFinalStepDialog(context);
      return;
    }

    // Advance to next stage (max 5)
    final nextStageId = (currentStageId + 1).clamp(0, 5);
    final nextStatus = _getStatusTextForStage(nextStageId);

    // Get coordinates (fallback if needed)
    final lat = (latest['lat'] ?? latest['latitude'] ?? '12.9716').toString();
    final long =
        (latest['long'] ?? latest['longitude'] ?? '77.5946').toString();

    // Show updating snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Updating stage...')));

    try {
      final success = await widget.api.updateLiveTicketStatus(
        ticketNo: widget.ticket['ticket_no'],
        customerId: widget.ticket['customer_id'] ?? 0,
        currentStage: nextStageId,
        status: nextStatus,
        lat: lat,
        long: long,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Stage updated to: $nextStatus')),
        );
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update stage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showFinalStepDialog(BuildContext context) {
    String selectedOption = 'resolved'; // Default selection
    int? selectedCategory; // For category dropdown
    int? selectedSubCategory; // For sub-category dropdown
    String? selectedDescription; // For description dropdown

    // Fetch category list
    List<CategoryData> categoryList = [];

    // Load categories asynchronously
    Future<void> _loadCategories() async {
      try {
        final response = await ApiServices().getTicketCategory();
        if (response != null) {
          categoryList = response.data;
        }
      } catch (e) {
        if (context.mounted) {
          BaseApiService().showSnackbar("Error", "Failed to load categories");
        }
      }
    }

    // Load categories before showing dialog
    _loadCategories().then((_) {
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.90,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.done_all,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Job',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textColorPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add issue details first, then choose action',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textColorSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== STEP 1: Issue Details Section =====
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Step 1: Issue Details',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Fill all details below',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Category Dropdown
                            _buildCustomDropdown(
                              label: 'Category *',
                              hint: 'Select category...',
                              value: selectedCategory,
                              items:
                                  categoryList
                                      .map(
                                        (cat) => DropdownMenuItem(
                                          value: cat.categoryId,
                                          child: Text(cat.categoryName),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value;
                                  selectedSubCategory = null;
                                  selectedDescription = null;
                                });
                              },
                              icon: Icons.category,
                            ),
                            const SizedBox(height: 16),
                            // SubCategory Dropdown
                            _buildCustomDropdown(
                              label: 'Sub Category *',
                              hint: 'Select sub category...',
                              value: selectedSubCategory,
                              isEnabled: selectedCategory != null,
                              items:
                                  selectedCategory != null
                                      ? (categoryList
                                          .firstWhere(
                                            (cat) =>
                                                cat.categoryId ==
                                                selectedCategory,
                                          )
                                          .subcategories
                                          .map(
                                            (subCat) => DropdownMenuItem(
                                              value: subCat.subcategoryId,
                                              child: Text(
                                                subCat.subcategoryName,
                                              ),
                                            ),
                                          )
                                          .toList())
                                      : [],
                              onChanged: (value) {
                                if (selectedCategory != null && value != null) {
                                  setState(() {
                                    selectedSubCategory = value;
                                    selectedDescription = null;
                                  });
                                }
                              },
                              icon: Icons.subdirectory_arrow_right,
                            ),
                            const SizedBox(height: 16),
                            // Description Text Field
                            _buildDescriptionField(
                              label: 'Description *',
                              hint:
                                  selectedSubCategory == null
                                      ? 'Select sub category first'
                                      : 'Enter issue description...',
                              isEnabled: selectedSubCategory != null,
                              onChanged: (value) {
                                setState(() {
                                  selectedDescription =
                                      value.isEmpty ? null : value;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            // ===== STEP 2: Action Selection =====
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Step 2: Choose Action',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'After filling details, select action',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select Action',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Resolved Option Card
                            _buildStatusCard(
                              title: 'Mark as Resolved ✅',
                              subtitle: 'Complete the job and close the ticket',
                              isSelected: selectedOption == 'resolved',
                              onTap:
                                  selectedCategory != null &&
                                          selectedSubCategory != null &&
                                          selectedDescription != null
                                      ? () {
                                        setState(
                                          () => selectedOption = 'resolved',
                                        );
                                      }
                                      : null,
                              icon: Icons.check_circle_outline,
                              isEnabled:
                                  selectedCategory != null &&
                                  selectedSubCategory != null &&
                                  selectedDescription != null,
                            ),
                            const SizedBox(height: 12),
                            // Reassign Option Card
                            _buildStatusCard(
                              title: 'Reassign with Details 🔄',
                              subtitle: 'Add issue details and reassign',
                              isSelected: selectedOption == 'reassign',
                              onTap:
                                  selectedCategory != null &&
                                          selectedSubCategory != null &&
                                          selectedDescription != null
                                      ? () {
                                        setState(
                                          () => selectedOption = 'reassign',
                                        );
                                      }
                                      : null,
                              icon: Icons.sync,
                              isEnabled:
                                  selectedCategory != null &&
                                  selectedSubCategory != null &&
                                  selectedDescription != null,
                            ),
                            const SizedBox(height: 8),
                            // Info Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedCategory == null ||
                                              selectedSubCategory == null ||
                                              selectedDescription == null
                                          ? '⏳ Fill all details above first'
                                          : '✅ All details filled! Choose action below',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
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
                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: AppColors.textColorPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  selectedCategory == null ||
                                          selectedSubCategory == null ||
                                          selectedDescription == null
                                      ? null
                                      : () {
                                        Navigator.of(ctx).pop();
                                        if (selectedOption == 'resolved') {
                                          _completeJob(
                                            context,
                                            selectedCategory,
                                            selectedSubCategory,
                                            selectedDescription,
                                          );
                                        } else {
                                          _reassignJobWithDetails(
                                            context,
                                            selectedCategory,
                                            selectedSubCategory,
                                            selectedDescription,
                                          );
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    selectedOption == 'resolved'
                                        ? Colors.green
                                        : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                selectedOption == 'resolved'
                                    ? 'Resolve'
                                    : 'Reassign',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
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
        },
      );
    });
  }

  // Helper widget for Status Card
  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback? onTap,
    required IconData icon,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : isEnabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : isEnabled
                  ? Colors.transparent
                  : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : isEnabled
                        ? Colors.grey.shade100
                        : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? AppColors.primary
                        : isEnabled
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isEnabled
                              ? AppColors.textColorPrimary
                              : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isEnabled
                              ? AppColors.textColorSecondary
                              : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Custom Dropdown
  Widget _buildCustomDropdown({
    required String label,
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem> items,
    required dynamic Function(dynamic) onChanged,
    required IconData icon,
    bool isEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isEnabled ? Colors.white : Colors.grey.shade50,
          ),
          child: DropdownButton(
            value: value,
            hint: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  hint,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
            isExpanded: true,
            underline: const SizedBox(),
            disabledHint: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade300),
                const SizedBox(width: 8),
                Text(
                  hint,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
            items: items,
            onChanged: isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  // Helper widget for Description Field
  Widget _buildDescriptionField({
    required String label,
    required String hint,
    required Function(String) onChanged,
    required bool isEnabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          enabled: isEnabled,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 8,
                top: 12,
                bottom: 12,
              ),
              child: Icon(
                Icons.description_outlined,
                color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade300,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: isEnabled ? Colors.white : Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Future<void> _completeJob(
    BuildContext context,
    int? categoryId,
    int? subCategoryId,
    String? description,
  ) async {
    if (categoryId == null || subCategoryId == null || description == null) {
      BaseApiService().showSnackbar("Error", "Please fill all required fields");
      return;
    }

    final datas = List<Map<String, dynamic>>.from(widget.ticket['datas'] ?? []);
    final latest = datas.isNotEmpty ? datas.last : {};
    final lat = (latest['lat'] ?? latest['latitude'] ?? '12.9716').toString();
    final long =
        (latest['long'] ?? latest['longitude'] ?? '77.5946').toString();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Completing job...'),
        backgroundColor: Colors.green,
      ),
    );

    try {
      final success = await widget.api.updateTicketWorkStatus(
        ticketNo: widget.ticket['ticket_no'],
        customerId: widget.ticket['customer_id'] ?? 0,
        currentStage: 5,
        status: 'Completed',
        lat: lat,
        long: long,
        closureCategory: categoryId.toString(),
        closureSubcategory: subCategoryId.toString(),
        closureRemark: description,
      );

      if (success != null && success is Map && success['status'] == 'error') {
        // API returned an error response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${success['message'] ?? 'Failed to complete job'}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job completed and ticket closed!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to complete job'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reassignJobWithDetails(
    BuildContext context,
    int? categoryId,
    int? subCategoryId,
    String? description,
  ) async {
    if (categoryId == null || subCategoryId == null || description == null) {
      BaseApiService().showSnackbar("Error", "Please fill all required fields");
      return;
    }

    final datas = List<Map<String, dynamic>>.from(widget.ticket['datas'] ?? []);
    final latest = datas.isNotEmpty ? datas.last : {};
    final lat = (latest['lat'] ?? latest['latitude'] ?? '12.9716').toString();
    final long =
        (latest['long'] ?? latest['longitude'] ?? '77.5946').toString();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Reassigning job and closing ticket...'),
        backgroundColor: Colors.orange,
      ),
    );

    try {
      final success = await widget.api.updateTicketWorkStatus(
        ticketNo: widget.ticket['ticket_no'],
        customerId: widget.ticket['customer_id'] ?? 0,
        currentStage: 5, // Move to Completed stage to close ticket
        status: 'Completed',
        lat: lat,
        long: long,
        closureCategory: categoryId.toString(),
        closureSubcategory: subCategoryId.toString(),
        closureRemark: description,
      );

      if (success != null && success is Map && success['status'] == 'error') {
        // API returned an error response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${success['message'] ?? 'Failed to reassign job'}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job reassigned with details and ticket closed!'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to reassign job, Error: $success'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketNo = widget.ticket['ticket_no'] ?? 'N/A';
    final status = widget.ticket['status'] ?? 'Unknown';
    final priority = widget.ticket['priority'] ?? 'Medium';
    // final customerId = widget.ticket['customer_id'] ?? 'N/A';
    final customerId =
        widget.ticket['OLT_IP'] ?? widget.ticket['customer_id'] ?? '';

    final datas = List<Map<String, dynamic>>.from(widget.ticket['datas'] ?? []);
    final latest = datas.isNotEmpty ? datas.last : {};

    String formatDate(String? dt) {
      if (dt == null) return '—';
      try {
        return DateFormat(
          'dd MMM, hh:mm a',
        ).format(DateTime.parse(dt.replaceAll(' ', 'T')));
      } catch (e) {
        return dt;
      }
    }

    // Determine button label
    final currentStageId = _getStatusId(latest['status']);
    final isCompleted = currentStageId == 5;
    final isFinalStep = currentStageId == 4;
    final buttonText =
        isCompleted
            ? 'Job Completed'
            : isFinalStep
            ? 'Complete Job'
            : 'Mark as Next Step';

    return Card(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$ticketNo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer : $customerId',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            GestureDetector(
              onTap: () {
                // Open location on map using ticket coordinates
                final lat =
                    double.tryParse(
                      latest['latitude']?.toString() ??
                          latest['lat']?.toString() ??
                          '0.00',
                    ) ??
                    0.0;
                final long =
                    double.tryParse(
                      latest['longitude']?.toString() ??
                          latest['long']?.toString() ??
                          '0.00',
                    ) ??
                    0.0;
                _openLocationOnMap(lat, long);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Customer: ${customerDetail?.contactName ?? 'Customer'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Address: ${customerDetail?.address ?? 'N/A'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          // maxLines: 2,
                          overflow: TextOverflow.clip,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getPriorityColor(priority).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: _getPriorityColor(priority),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Status History Timeline
            if (datas.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Timeline (${datas.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: datas.length,
                      separatorBuilder:
                          (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                      itemBuilder: (context, idx) {
                        final statusData = datas[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(statusData['status']),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      statusData['status'] ?? '—',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      formatDate(statusData['date_time']),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // if (statusData['lat'] != null &&
                              //     statusData['lat'] != '0.00')
                              //   Tooltip(
                              //     message:
                              //         'Lat: ${statusData['lat']}, Long: ${statusData['long']}',
                              //     child: Container(
                              //       padding: const EdgeInsets.all(4),
                              //       decoration: BoxDecoration(
                              //         color: Colors.blue.shade100,
                              //         borderRadius: BorderRadius.circular(4),
                              //       ),
                              //       child: const Icon(
                              //         Icons.location_on,
                              //         size: 14,
                              //         color: Colors.blue,
                              //       ),
                              //     ),
                              //   ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Latest status
            if (latest.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(latest['status']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current: ${latest['status'] ?? '—'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          formatDate(latest['date_time']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons Row
            Column(
              spacing: 10,
              children: [
                // ElevatedButton.icon(
                //   onPressed: () {
                //     final lat =
                //         double.tryParse(
                //           latest['latitude']?.toString() ??
                //               latest['lat']?.toString() ??
                //               '0.00',
                //         ) ??
                //         0.0;
                //     final long =
                //         double.tryParse(
                //           latest['longitude']?.toString() ??
                //               latest['long']?.toString() ??
                //               '0.00',
                //         ) ??
                //         0.0;
                //     _openLocationOnMap(lat, long);
                //   },
                //   icon: const Icon(Icons.location_on, size: 18),
                //   label: const Text('Location'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.blue,
                //     foregroundColor: Colors.white,
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 16,
                //       vertical: 12,
                //     ),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     elevation: 2,
                //   ),
                // ),
                SizedBox(width: double.infinity),
                // Auto-advance button
                ElevatedButton.icon(
                  onPressed:
                      isCompleted ? null : () => _autoAdvanceStage(context),
                  icon: Icon(
                    isCompleted
                        ? Icons.check
                        : isFinalStep
                        ? Icons.done_all
                        : Icons.arrow_forward,
                    size: 18,
                  ),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCompleted
                            ? Colors.green.shade200
                            : isFinalStep
                            ? Colors.green
                            : AppColors.primary,
                    foregroundColor:
                        isCompleted
                            ? Colors.green.shade800
                            : isFinalStep
                            ? Colors.white
                            : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _getStatusColor(String? status) {
  if (status == null) return Colors.grey;
  final s = status.toLowerCase();
  if (s.contains('assigned')) return Colors.blue;
  if (s.contains('accept')) return Colors.cyan;
  if (s.contains('way')) return Colors.orange;
  if (s.contains('reached')) return Colors.purple;
  if (s.contains('progress')) return Colors.deepOrange;
  if (s.contains('completed') || s.contains('resolved')) return Colors.green;
  return Colors.grey;
}

Color _getPriorityColor(String? priority) {
  if (priority == null) return Colors.grey;
  final p = priority.toLowerCase().trim();
  if (p == 'high') return Colors.red;
  if (p == 'medium') return Colors.orange;
  if (p == 'low') return Colors.green;
  return Colors.grey;
}
