import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'call_controller.dart';

class CallScreen extends StatelessWidget {
  final String customerName;
  final String customerNumber;

  CallScreen({required this.customerName, required this.customerNumber});
  final CallController _callController = Get.put(
    CallController(),
  ); //Get.find<CallController>();
  final CountDownController _countDownController = CountDownController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button during active call
        if (_callController.callStatus.value == CallStatus.connected) {
          Get.snackbar(
            'Active Call',
            'Please end the call first',
            backgroundColor: Colors.orange,
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: SafeArea(
          child: Obx(
            () =>
                _callController.callStatus.value == CallStatus.connecting
                    ? _buildConnectingUI()
                    : _buildActiveCallUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated connecting icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing animation
                ...List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    width: 120 + (index * 30),
                    height: 120 + (index * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.1 - (index * 0.03)),
                    ),
                  );
                }),

                // Phone icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Icon(Icons.phone, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),

          SizedBox(height: 40),

          Text(
            'Connecting...',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 10),

          Text(
            _callController.currentCall.value.customerName ??
                _callController.currentCall.value.customerNumber ??
                "N/A",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),

          SizedBox(height: 20),

          // Cancel button
          TextButton(
            onPressed: () {
              _callController.endCall();
            },
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallUI() {
    return Column(
      children: [
        // Caller Info Section
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Caller Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF0066CC), Color(0xFF00A86B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 50),
                ),

                SizedBox(height: 20),

                // Caller Name/Number
                Text(
                  _callController.currentCall.value.customerName ?? 'Customer',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  _callController.currentCall.value.customerNumber ?? "N/A",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                SizedBox(height: 20),

                // Call Status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'ON CALL',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Timer Section
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Timer
              CircularCountDownTimer(
                duration: 3600,
                initialDuration: _callController.callDuration.value,
                controller: _countDownController,
                width: 100,
                height: 100,
                ringColor: Colors.white.withOpacity(0.1),
                fillColor: Colors.green,
                backgroundColor: Colors.transparent,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
                textFormat: CountdownTextFormat.MM_SS,
                isReverse: false,
                isReverseAnimation: false,
                isTimerTextShown: true,
                autoStart: true,
                onComplete: () {
                  _callController.endCall();
                },
              ),

              SizedBox(height: 10),

              // Timer Text
              Obx(
                () => Text(
                  _callController.callTimer.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Controls Section
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Primary Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Button
                    _buildControlButton(
                      icon: Icons.mic_off,
                      label: 'Mute',
                      backgroundColor: Colors.grey.shade800,
                      onPressed: () {
                        // Toggle mute
                      },
                    ),

                    // Speaker Button
                    _buildControlButton(
                      icon: Icons.volume_up,
                      label: 'Speaker',
                      backgroundColor: Colors.grey.shade800,
                      onPressed: () {
                        // Toggle speaker
                      },
                    ),

                    // Keypad Button
                    _buildControlButton(
                      icon: Icons.dialpad,
                      label: 'Keypad',
                      backgroundColor: Colors.grey.shade800,
                      onPressed: () {
                        _showKeypad();
                      },
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // End Call Button
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.call_end, size: 30),
                    color: Colors.white,
                    onPressed: () {
                      _callController.endCall();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: IconButton(
            icon: Icon(icon, size: 24),
            color: Colors.white,
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _showKeypad() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Keypad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                ...[
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  '*',
                  '0',
                  '#',
                ].map((digit) => _buildKeypadButton(digit)),
              ],
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Send DTMF tone
          Get.snackbar(
            'DTMF',
            'Tone $digit sent',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: Duration(seconds: 1),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
