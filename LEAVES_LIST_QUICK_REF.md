# 🍃 Leaves List Screen - Quick Reference

## 📍 File Location
```
lib/src/technician/attendance/leaves_list_screen.dart
```

## 🎯 How It Works
1. User taps "My Leaves" button on Attendance screen
2. Screen fetches all leave requests via API
3. Leaves are grouped by month (newest first)
4. Each leave shows: type, dates, status, duration, reason
5. Pending leaves can be withdrawn with confirmation

## 🎨 Visual Features
- Gradient colored headers based on leave type
- Color-coded status badges (Green/Orange/Red)
- Icons for different leave types and statuses
- Month-based grouping with leaf count
- Loading shimmer effect
- Empty state with CTA
- Error state with retry

## 🔌 Integration Points

### In Attendance Screen:
```dart
// This button is automatically added:
GestureDetector(
  onTap: () => Get.to(() => LeavesListScreen()),
  child: Container(
    // Green gradient button
    child: Text("My Leaves"),
  ),
)
```

### From Any Screen:
```dart
Get.to(() => LeavesListScreen());
```

## 📊 Data Structure

```
LeavesListScreen
└── FutureBuilder<List<LeaveModel>>
    └── _groupLeavesByMonth() → Map<String, List<LeaveModel>>
        └── "January 2026"
            ├── LeaveModel #1 (Approved)
            ├── LeaveModel #2 (Pending)
            └── LeaveModel #3 (Rejected)
        └── "December 2025"
            └── LeaveModel #4 (Approved)
```

## 🎯 Key Features

| Feature | Status | Details |
|---------|--------|---------|
| Show all leaves | ✅ | Fetches from API |
| Group by month | ✅ | Reverse chrono order |
| Status colors | ✅ | Green/Orange/Red |
| Leave icons | ✅ | 4 different types |
| Withdraw leave | ✅ | Only pending leaves |
| Loading state | ✅ | Shimmer animation |
| Empty state | ✅ | With CTA button |
| Error handling | ✅ | With retry button |

## 🎨 Color Codes

```dart
// Leave Type Colors
Sick:    Color(0xFFEF4444)   // Red
Casual:  Color(0xFF3B82F6)   // Blue
Paid:    Color(0xFF10B981)   // Green
Unpaid:  Color(0xFF8B5CF6)   // Purple

// Status Colors
Approved: Color(0xFF10B981)  // Green
Pending:  Color(0xFFF59E0B)  // Orange
Rejected: Color(0xFFEF4444)  // Red
```

## 🔧 Methods

### Main Methods
```dart
// Fetch all leaves from API
Future<List<LeaveModel>> fetchAllLeaves()

// Group leaves by month
Map<String, List<LeaveModel>> _groupLeavesByMonth(List<LeaveModel> leaves)

// Show confirmation to withdraw leave
void _showWithdrawDialog(LeaveModel leave)

// Build individual leave card
Widget _buildLeaveCard(LeaveModel leave)
```

## 📱 Screen Layout

```
┌─────────────────────────┐
│  All Leave Requests     │  ← AppBar with back & refresh
│  [Gradient Background]  │
├─────────────────────────┤
│                         │
│  📅 January 2026  [2]  │  ← Month header with count
│ ┌─────────────────────┐ │
│ │🏥 Sick Leave      ✅│  ← Leave card (Approved)
│ │Jan 15 - Jan 17    │ │
│ │Duration: 3 days   │ │
│ │Applied: Jan 01... │ │
│ │Reason: ...       │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │📅 Casual Leave    ⏳│  ← Leave card (Pending)
│ │Jan 08 - Jan 10    │ │
│ │Duration: 2 days   │ │
│ │[Withdraw Button] │ │
│ └─────────────────────┘ │
│                         │
│  📅 December 2025  [1] │  ← Previous month
│ ┌─────────────────────┐ │
│ │💰 Paid Leave      ✅│  ← Leave card (Approved)
│ │...                │ │
│ └─────────────────────┘ │
│                         │
└─────────────────────────┘
```

## 🚀 Usage Examples

### Basic Navigation
```dart
// From any screen
Get.to(() => LeavesListScreen());

// From a button
ElevatedButton(
  onPressed: () => Get.to(() => LeavesListScreen()),
  child: Text("View My Leaves"),
)
```

### In Drawer/Menu
```dart
ListTile(
  leading: Icon(Iconsax.note_text),
  title: Text('My Leaves'),
  subtitle: Text('View all leave requests'),
  onTap: () {
    Get.back(); // Close drawer
    Get.to(() => LeavesListScreen());
  },
)
```

## ✅ Checklist Before Using

- [ ] AttendanceController is initialized with Get.put()
- [ ] BaseApiService is available in GetIt
- [ ] Backend API endpoint `fetch_leaves_tech.php` exists
- [ ] Backend returns leaves in correct JSON format
- [ ] User is authenticated

## 🎯 What Happens When

| Action | Result |
|--------|--------|
| Screen opens | Fetches all leaves from API |
| Leaves loaded | Groups by month, shows list |
| Tap month | Can't expand (single view) |
| Tap withdraw | Shows confirmation dialog |
| Confirm withdraw | Calls API to cancel leave |
| API error | Shows error state with retry |
| No leaves | Shows empty state with CTA |
| Tap refresh | Reloads all leaves |

## 🎮 User Interactions

1. **Open Screen**: Tap "My Leaves" button
2. **View Leaves**: Scroll through grouped months
3. **See Details**: Each card shows full info
4. **Withdraw**: Tap red "Withdraw Request" button (pending only)
5. **Confirm**: Review and confirm withdrawal
6. **Go Back**: Tap back arrow or system back button
7. **Refresh**: Tap refresh icon in AppBar

## 🔗 Dependencies

- `flutter` - UI framework
- `get` - State management & navigation
- `flutter_screenutil` - Responsive sizing
- `iconsax` - Icons
- `intl` - Date formatting

All should already be in your pubspec.yaml

## 📞 Quick Fixes

| Problem | Solution |
|---------|----------|
| "No leaves shown" | Check API endpoint returns data |
| "Dates look weird" | Ensure backend uses YYYY-MM-DD format |
| "Withdraw not working" | Verify cancel_leave endpoint exists |
| "Screen not opening" | Check LeavesListScreen is imported |
| "Loading forever" | Check API connection & authentication |

---

**Ready to use! 🚀**
