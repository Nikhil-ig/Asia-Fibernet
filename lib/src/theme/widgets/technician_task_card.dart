import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class TechnicianTaskCard extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TechnicianTaskCard({super.key, required this.ticket});

  @override
  State<TechnicianTaskCard> createState() => _TechnicianTaskCardState();
}

class _TechnicianTaskCardState extends State<TechnicianTaskCard> {
  bool _isExpanded = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'accept job':
        return Colors.cyan;
      case 'on the way':
        return Colors.orange;
      case 'reached customer location':
        return Colors.purple;
      case 'work in progress':
        return Colors.deepOrange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return '—';
    try {
      final parsed = DateTime.parse(dt.replaceAll(' ', 'T'));
      return DateFormat('dd MMM, hh:mm a').format(parsed);
    } catch (e) {
      return dt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final datas = List<Map<String, dynamic>>.from(widget.ticket['datas'] ?? []);
    final technician = widget.ticket['technician'] ?? 'Unknown';
    final ticketNo = widget.ticket['ticket_no'] ?? 'N/A';
    final status = widget.ticket['status'] ?? 'unknown';
    final createdAt = widget.ticket['created_at'];

    // Show only the latest (last) status by default
    final latestStep = datas.isNotEmpty ? datas.last : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand/collapse icon
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '$ticketNo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.replaceAll('-', ' ').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Technician: $technician',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 16),

            // Latest status (always visible)
            if (latestStep != null) ...[
              _buildTimelineItem(latestStep, isLatest: true),
              const SizedBox(height: 12),
            ],

            // Expandable full timeline
            // Expandable full timeline — SAFE & SCROLL-FREE
            if (_isExpanded && datas.length > 1)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: Colors.grey.shade300,
                      height: 20,
                      thickness: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activity Log',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...datas.reversed
                        .skip(1)
                        .map((step) => _buildTimelineItem(step))
                        .toList()
                        .reversed
                        .toList(),
                  ],
                ),
              ),
            // Created At Footer
            if (createdAt != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Created: ${_formatDateTime(createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    Map<String, dynamic> step, {
    bool isLatest = false,
  }) {
    final stepStatus = step['status'] ?? '—';
    final lat = step['lat'] ?? step['latitude'];
    final long = step['long'] ?? step['longitude'];
    final time = _formatDateTime(step['date_time']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator dot
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Container(
              width: isLatest ? 12 : 8,
              height: isLatest ? 12 : 8,
              decoration: BoxDecoration(
                color:
                    isLatest
                        ? _getStatusColor(stepStatus)
                        : _getStatusColor(stepStatus).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepStatus,
                  style: TextStyle(
                    fontWeight: isLatest ? FontWeight.w700 : FontWeight.w600,
                    fontSize: isLatest ? 14 : 13,
                    color: isLatest ? Colors.black87 : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                // if (lat != null &&
                //     long != null &&
                //     lat is String &&
                //     lat != '0.00')
                //   Padding(
                //     padding: const EdgeInsets.only(top: 4),
                //     child: Text.rich(
                //       TextSpan(
                //         children: [
                //           const TextSpan(
                //             text: '📍 ',
                //             style: TextStyle(color: Colors.grey),
                //           ),
                //           TextSpan(
                //             text: 'Lat: $lat, Long: $long',
                //             style: const TextStyle(
                //               fontSize: 11,
                //               color: Colors.grey,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
