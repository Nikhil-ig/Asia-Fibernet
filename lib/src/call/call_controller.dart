import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_screen.dart';

class CallController extends GetxController {
  var callStatus = CallStatus.idle.obs;
  var isCalling = false.obs;
  var callDuration = 0.obs;
  var callTimer = '00:00'.obs;
  var currentCall = Call().obs;

  final String url =
      'https://my.office24by7.com/v1/communication/API/clickToCall';
  final String apiKey =
      'dc0e6bb8-da5a-44c0-a57d-2fedaad2417e';
  final String agentId = 'Asiafibernet2';

  Timer? _callTimer;
  var _elapsedSeconds = 0;
  StreamSubscription<PhoneState>? _phoneStateSubscription;

  @override
  void onInit() {
    super.onInit();
    _initPhoneStateListener();
  }

  @override
  void onClose() {
    _phoneStateSubscription?.cancel();
    _stopCallTimer();
    super.onClose();
  }

  Future<void> _initPhoneStateListener() async {
    await Permission.phone.request();

    try {
      _phoneStateSubscription = PhoneState.stream.listen((event) {
        _handlePhoneState(event);
      });
    } catch (e) {
      print('Error initializing phone state: $e');
    }
  }

  void _handlePhoneState(PhoneState event) {
    switch (event.status) {
      case PhoneStateStatus.CALL_STARTED:
        if (callStatus.value == CallStatus.connecting) {
          callStatus.value = CallStatus.connected;
          _startCallTimer();
          Get.snackbar(
            'Call Connected',
            'You are now connected with the customer',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
        }
        break;

      case PhoneStateStatus.CALL_ENDED:
        if (callStatus.value == CallStatus.connected) {
          endCall();
        }
        break;

      default:
        break;
    }
  }

  Future<void> makeCall({
    required String customerNumber,
    String? serviceNumber,
    String? customerName,
    String? referenceState,
    Map<String, dynamic>? customerData,
  }) async {
    if (callStatus.value != CallStatus.idle) {
      Get.snackbar(
        'Busy',
        'Already on another call',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isCalling.value = true;
    callStatus.value = CallStatus.connecting;

    currentCall.value = Call(
      customerNumber: customerNumber,
      serviceNumber: serviceNumber ?? '08071511XXX',
      customerName: customerName,
      referenceState: referenceState ?? 'test321',
      startTime: DateTime.now(),
    );

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['agentloginid'] = agentId;
      request.fields['customernumber'] = customerNumber;
      request.fields['servicenumber'] =
          serviceNumber ?? '08071511XXX';
      request.fields['referencestate'] = referenceState ?? 'test321';
      request.fields['format'] = 'json';

      if (customerData != null) {
        request.fields['customerdata'] = json.encode(customerData);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        if (jsonResponse['status'] == 'success' ||
            jsonResponse['success'] == true) {
          Get.snackbar(
            'Success',
            'Call initiated successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );

          Get.to(() => CallScreen(
            customerName: customerName ?? 'Unknown Customer',
            customerNumber: customerNumber ?? 'Unknown Number',
          ));
        } else {
          throw Exception(jsonResponse['message'] ?? 'Call initiation failed');
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      callStatus.value = CallStatus.idle;
      Get.snackbar(
        'Call Failed',
        'Failed to initiate call: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isCalling.value = false;
    }
  }

  Future<void> quickCall(String customerNumber, {String? customerName}) async {
    await makeCall(customerNumber: customerNumber, customerName: customerName);
  }

  void endCall() {
    if (callStatus.value == CallStatus.connected) {
      currentCall.value.endTime = DateTime.now();
      currentCall.value.duration = callTimer.value;

      Get.snackbar(
        'Call Ended',
        'Duration: ${callTimer.value}',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }

    callStatus.value = CallStatus.ended;
    _stopCallTimer();

    Future.delayed(Duration(seconds: 2), () {
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      if (Get.currentRoute == '/call') {
        Get.back();
      }
      callStatus.value = CallStatus.idle;
    });
  }

  void _startCallTimer() {
    _elapsedSeconds = 0;
    callTimer.value = '00:00';

    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (callStatus.value == CallStatus.connected) {
        _elapsedSeconds++;
        final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
        callTimer.value = '$minutes:$seconds';
      } else {
        timer.cancel();
      }
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  Color getCallStatusColor() {
    switch (callStatus.value) {
      case CallStatus.connecting:
        return Colors.orange;
      case CallStatus.connected:
        return Colors.green;
      case CallStatus.ended:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String getCallStatusText() {
    switch (callStatus.value) {
      case CallStatus.idle:
        return 'Ready';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Ended';
      default:
        return 'Unknown';
    }
  }

  bool get isOnCall =>
      callStatus.value == CallStatus.connected ||
      callStatus.value == CallStatus.connecting;

  // Future<void> fetchRelocationTickets() async {
  //   try {
  //     var response = await http.get(Uri.parse('YOUR_API_URL_HERE'));
  //     if (response.statusCode == 200) {
  //       var data = json.decode(response.body);
  //     } else {
  //       throw Exception('Failed to load tickets');
  //     }
  //   } catch (e) {
  //     Get.snackbar(
  //       'Error',
  //       'Failed to fetch relocation tickets: $e',
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   }
  // }
}

class Call {
  String? customerNumber;
  String? serviceNumber;
  String? customerName;
  String? referenceState;
  DateTime? startTime;
  DateTime? endTime;
  String? duration;
  Map<String, dynamic>? customerData;

  Call({
    this.customerNumber,
    this.serviceNumber,
    this.customerName,
    this.referenceState,
    this.startTime,
    this.endTime,
    this.duration,
    this.customerData,
  });
}

enum CallStatus { idle, connecting, connected, ended }
