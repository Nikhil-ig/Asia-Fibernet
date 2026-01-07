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
import '../../../services/apis/base_api_service.dart';
import '../../../services/apis/technician_api_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../core/models/tech_dashboard_model.dart';
import '../../attendance/attendance_screen.dart';
import 'notifications_screen.dart';
import 'technician_profile_screen.dart';
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
  late TooltipBehavior _tooltipBehavior;

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
    _tooltipBehavior = TooltipBehavior(enable: true);
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
        FadeInUp(
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

class TechnicianTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final TechnicianAPI api;
  final VoidCallback onUpdated;

  const TechnicianTicketCard({
    super.key,
    required this.ticket,
    required this.api,
    required this.onUpdated,
  });

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

  void _autoAdvanceStage(BuildContext context) async {
    final datas = List<Map<String, dynamic>>.from(ticket['datas'] ?? []);
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
      final success = await api.updateLiveTicketStatus(
        ticketNo: ticket['ticket_no'],
        customerId: ticket['customer_id'] ?? 0,
        currentStage: nextStageId,
        status: nextStatus,
        lat: lat,
        long: long,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Stage updated to: $nextStatus')),
        );
        onUpdated();
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

  @override
  Widget build(BuildContext context) {
    final ticketNo = ticket['ticket_no'] ?? 'N/A';
    final technician = ticket['technician'] ?? '—';
    final status = ticket['status'] ?? 'Unknown';
    final createdAt = ticket['created_at'] ?? '';

    final datas = List<Map<String, dynamic>>.from(ticket['datas'] ?? []);
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
    final buttonText = isCompleted ? 'Job Completed' : 'Mark as Next Step';

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
                  child: Text(
                    '$ticketNo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 8),
            Text(
              'Technician: $technician',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Created: ${formatDate(createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 16),

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
                          latest['status'] ?? '—',
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

            // Auto-advance button
            Center(
              child: ElevatedButton.icon(
                onPressed:
                    isCompleted ? null : () => _autoAdvanceStage(context),
                icon: Icon(
                  isCompleted ? Icons.check : Icons.arrow_forward,
                  size: 18,
                ),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCompleted ? Colors.green.shade200 : AppColors.primary,
                  foregroundColor:
                      isCompleted ? Colors.green.shade800 : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}
