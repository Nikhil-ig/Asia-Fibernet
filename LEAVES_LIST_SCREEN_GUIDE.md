# Leaves List Screen - Complete Implementation Guide

## ✅ What's Been Implemented

A complete, production-ready "Leaves List Screen" with the following features:

### Features
1. **All Leave Requests** - Shows every leave request the technician has submitted
2. **Grouped by Month** - Leaves are organized by month in reverse chronological order (newest first)
3. **Status Filtering** - Color-coded status indicators:
   - 🟢 **Approved** - Green
   - 🟡 **Pending** - Orange/Yellow
   - 🔴 **Rejected** - Red

4. **Leave Type Icons** - Different icons for leave types:
   - 🏥 **Sick Leave** - Health icon (Red)
   - 📅 **Casual Leave** - Calendar icon (Blue)
   - 💰 **Paid Leave** - Money icon (Green)
   - ⏸️ **Unpaid Leave** - Calendar remove icon (Purple)

5. **Detailed Information**:
   - Leave type and status
   - Start and end dates
   - Total number of days
   - Application date and time
   - Reason/remark

6. **Withdraw Functionality** - Pending leaves can be withdrawn with confirmation dialog

7. **Loading States** - Shimmer loading animation while fetching data

8. **Empty States** - User-friendly message with CTA to apply for leave

9. **Error Handling** - Clear error messages with retry button

## 📁 Files Created/Modified

### Created Files:
- `/lib/src/technician/attendance/leaves_list_screen.dart` - Main leaves list screen

### Modified Files:
- `/lib/src/technician/attendance/attendance_screen.dart` - Added "My Leaves" button and fetchAllLeaves method
- `/lib/src/services/apis/attendance_leave_api.dart` - Added fetchAllLeaves() API method

## 🚀 How to Use

### 1. Navigate to Leaves List Screen
From the Attendance screen, you'll see two new buttons:
- **Holiday's List** - Shows all company holidays
- **My Leaves** - Shows all your leave requests (NEW!)

```dart
// The button is automatically added to the attendance screen
// Just tap the "My Leaves" button to open the leaves list screen
```

### 2. In Code - Programmatic Navigation
```dart
import 'package:asia_fibernet/src/technician/attendance/leaves_list_screen.dart';

// Navigate to leaves list
Get.to(() => LeavesListScreen());
```

### 3. Add to App Navigation (Optional)
If you have a sidebar/drawer menu, you can add:

```dart
ListTile(
  leading: Icon(Iconsax.note_text),
  title: Text('My Leaves'),
  onTap: () => Get.to(() => LeavesListScreen()),
)
```

## 🎨 UI/UX Features

### Design Highlights
- **Gradient Headers** - Beautiful gradient backgrounds
- **Status Badges** - Color-coded with icons for quick recognition
- **Month Grouping** - Easy to find leaves by month
- **Shadow Effects** - Professional depth with box shadows
- **Responsive Design** - Works on all screen sizes using flutter_screenutil

### Color Scheme
- **Primary** - Indigo (0xFF6366F1)
- **Success** - Green (0xFF10B981)
- **Warning** - Orange/Yellow (0xFFF59E0B)
- **Error** - Red (0xFFEF4444)

## 📊 Data Flow

```
LeavesListScreen
    ↓
  FutureBuilder
    ↓
  fetchAllLeaves()  [AttendanceController]
    ↓
  fetchAllLeaves()  [AttendanceLeaveAPI]
    ↓
  Backend API (/techAPI/fetch_leaves_tech.php)
    ↓
  List<LeaveModel>
    ↓
  Group by month & sort
    ↓
  Display in UI
```

## 🔧 Backend API Requirements

Your backend should have an endpoint that returns all leaves:
- **Endpoint**: `fetch_leaves_tech.php`
- **Method**: GET
- **Parameters**: None (uses authenticated user context)
- **Response Format**:
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "technician_id": 123,
      "leave_type": "sick",
      "start_date": "2026-01-15",
      "end_date": "2026-01-17",
      "total_days": 3,
      "reason": "Medical appointment",
      "status": "approved",
      "requested_at": "2026-01-01 10:30:00",
      "updated_at": "2026-01-01 11:00:00"
    }
  ]
}
```

## 📱 Screen Sections

### 1. AppBar
- Gradient background with title "All Leave Requests"
- Back button
- Refresh button

### 2. Month Header
- Calendar icon
- Month and year
- Count of leaves in that month

### 3. Leave Card
- **Header Section** (colored by leave type):
  - Leave type icon and name
  - Date range
  - Status badge

- **Details Section**:
  - Duration (in days)
  - Applied date and time
  - Reason (if provided)
  - Withdraw button (for pending leaves)

### 4. Empty State
- Icon indicating no leaves
- Message explaining the situation
- CTA button to apply for leave

### 5. Error State
- Warning icon
- Error message
- Retry button

## 🎯 Key Methods

### LeavesListScreen

```dart
// Group leaves by month
Map<String, List<LeaveModel>> _groupLeavesByMonth(List<LeaveModel> leaves)

// Get month name from number
String _getMonthName(int month)

// Parse month key from string
DateTime _parseMonthKey(String key)

// Show withdrawal confirmation
void _showWithdrawDialog(LeaveModel leave)

// Build leave card UI
Widget _buildLeaveCard(LeaveModel leave)

// Build shimmer loading effect
Widget _buildLeaveShimmer()
```

### AttendanceController

```dart
// Fetch all leaves from API
Future<List<LeaveModel>> fetchAllLeaves()

// Cancel/withdraw a leave
Future<void> cancelLeave(int leaveId)
```

### AttendanceLeaveAPI

```dart
// API call to fetch all leaves
Future<List<LeaveModel>> fetchAllLeaves()
```

## 🔍 Status Colors & Icons

| Status | Color | Icon | Meaning |
|--------|-------|------|---------|
| Approved | 🟢 Green (#10B981) | tick_circle | Leave is approved |
| Pending | 🟡 Orange (#F59E0B) | clock | Awaiting approval |
| Rejected | 🔴 Red (#EF4444) | close_circle | Leave request rejected |

## 📝 Leave Type Indicators

| Type | Icon | Color | Use Case |
|------|------|-------|----------|
| Sick | 🏥 health | Red | Medical/Health related |
| Casual | 📅 calendar | Blue | Personal reasons |
| Paid | 💰 money | Green | Paid time off |
| Unpaid | ⏸️ calendar_remove | Purple | Unpaid leave |

## ⚙️ Configuration

No additional configuration needed! The screen automatically:
- Fetches all leaves when opened
- Groups and sorts them
- Handles loading, error, and empty states
- Connects to existing AttendanceController

## 🐛 Troubleshooting

### Issue: "No leaves shown"
- **Solution**: Ensure your backend API endpoint is returning data correctly
- **Check**: Verify `fetch_leaves_tech.php` returns proper JSON

### Issue: "Dates not parsing correctly"
- **Solution**: Ensure date format is "YYYY-MM-DD" (ISO format)
- **Check**: Backend should return dates in ISO format

### Issue: "Withdraw button not working"
- **Solution**: Ensure `cancel_leave_tech.php` endpoint is working
- **Check**: Verify leave_id is being sent correctly

## 🚦 Future Enhancements

Possible improvements:
1. Add filter by status (Approved/Pending/Rejected)
2. Add search functionality by leave type or date
3. Add ability to edit pending leaves
4. Add export to PDF
5. Add calendar view of all leaves
6. Add statistics dashboard

## 📞 Support

For issues or questions:
1. Check that all imports are correct
2. Verify AttendanceController is initialized
3. Check backend API logs for errors
4. Ensure proper error handling in your API service

---

**Version**: 1.0.0  
**Last Updated**: January 5, 2026  
**Status**: ✅ Ready for Production
