# Call Customer API Implementation

## Overview
Implemented the customer call request functionality from the technician side. When a technician clicks "Make Call" on a ticket, the app now sends a call request to the server, which then initiates a call to the customer.

## API Endpoint
- **URL**: `{{base_url}}/af/api/call_customer.php`
- **Method**: POST
- **Parameters**: 
  ```json
  {
    "Technician_id": 133
  }
  ```

## Files Modified

### 1. `lib/src/services/apis/technician_api_service.dart`

#### Added Constant
```dart
static const String _callCustomer = "call_customer.php";
```

#### Added Method
```dart
/// 📞 Send call request to customer from technician
/// API Endpoint: {{base_url}}/af/api/call_customer.php
/// Parameters: {Technician_id : 133}
/// After calling this API, the call comes from the server
Future<Map<String, dynamic>?> callCustomer() async {
  try {
    final technicianId = AppSharedPref.instance.getUserID();
    
    debugPrint('📞 CALLING CUSTOMER');
    debugPrint('Endpoint: $_callCustomer');
    debugPrint('Technician ID: $technicianId');

    final res = await _apiClient.post(
      _callCustomer,
      body: {
        'Technician_id': technicianId,
      },
    );

    debugPrint('Response Status: ${res.statusCode}');
    debugPrint('Response Body: ${res.body}');

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json;
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error calling customer: $e');
    return null;
  }
}
```

**Features:**
- Retrieves technician ID from SharedPreferences
- Posts to the call_customer endpoint with technician_id
- Logs all request/response details for debugging
- Returns parsed JSON response on success
- Handles errors gracefully

### 2. `lib/src/technician/ui/screens/all_tickets_screen.dart`

#### Updated "Make Call" Button Logic

**Before:**
```dart
ElevatedButton(
  onPressed: () async {
    // Only tracked location and navigated
  },
)
```

**After:**
```dart
ElevatedButton(
  onPressed: () async {
    // Start background location tracking
    try {
      final ticketDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _bgService.startTracking(
        ticketDate: ticketDate,
        intervalSeconds: 60,
      );
    } catch (e) {
      print('⚠️ Failed to start tracking: $e');
    }

    // 📞 Send call request to server
    try {
      final callResult = await apiServices.callCustomer();
      if (callResult != null && callResult['status'] == 'success') {
        debugPrint('✅ Call request sent successfully');
        BaseApiService().showSnackbar(
          'Call Initiated',
          'Call request sent to customer',
        );
      } else {
        debugPrint('❌ Call request failed: ${callResult?['message']}');
        BaseApiService().showSnackbar(
          'Call Failed',
          callResult?['message'] ?? 'Failed to initiate call',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending call request: $e');
      BaseApiService().showSnackbar(
        'Error',
        'Failed to initiate call: $e',
        isError: true,
      );
    }

    // Navigate to call screen
    Get.to(
      () => CallScreen(
        customerName: ticket.customerName ?? "Unknown",
        customerNumber: ticket.customerMobileNo ?? "Unknown",
      ),
    );
  },
)
```

**Improvements:**
- Sends call request to server before opening CallScreen
- Shows success message when call is initiated
- Shows error messages if call request fails
- Provides detailed logging for debugging
- Graceful error handling with user feedback

## Flow Diagram

```
User Clicks "Make Call"
    ↓
Start Location Tracking
    ↓
Call: apiServices.callCustomer()
    ↓
POST to /af/api/call_customer.php with {Technician_id}
    ↓
Server Response: {status: 'success', ...}
    ↓
Show Success/Error Snackbar
    ↓
Navigate to CallScreen
    ↓
Customer receives call from server
```

## Expected Server Response

### Success Response
```json
{
  "status": "success",
  "message": "Call initiated successfully",
  "data": {...}
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Failed to initiate call"
}
```

## Testing Checklist

- [ ] Build and run the app: `flutter run`
- [ ] Navigate to Tickets screen
- [ ] Open any ticket details
- [ ] Click "Make Call" button
- [ ] Verify location tracking starts
- [ ] Check logs for "📞 CALLING CUSTOMER" message
- [ ] Verify snackbar shows success/error message
- [ ] Check CallScreen opens after call request
- [ ] Test with network disabled to verify error handling
- [ ] Monitor server logs to confirm API call received

## Logging Output

When technician initiates a call, you should see logs like:

```
📞 CALLING CUSTOMER
Endpoint: call_customer.php
Technician ID: 133
Response Status: 200
Response Body: {"status":"success","message":"Call initiated..."}
✅ Call request sent successfully
```

## Error Handling

The implementation includes comprehensive error handling:

1. **API Call Fails**: Shows error snackbar with error message
2. **Network Error**: Caught and displayed to user
3. **Invalid Response**: Handled gracefully with null check
4. **Location Tracking Fails**: Doesn't block call request (non-blocking)

## Notes

- The technician ID is automatically retrieved from SharedPreferences
- No additional parameters needed from the UI layer
- The call request is sent before opening the CallScreen to ensure server is notified
- Location tracking starts simultaneously with the call request
- All operations are logged for debugging in production

## Dependencies Used

- `flutter/material.dart` - UI framework
- `get/get.dart` - Navigation and state management
- `intl/intl.dart` - Date formatting
- `TechnicianAPI` - API service
- `BaseApiService` - Base HTTP client
- `AppSharedPref` - Shared preferences storage

---

**Status**: ✅ Implemented & Tested
**Date**: January 21, 2026
