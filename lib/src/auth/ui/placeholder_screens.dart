import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/Ai-powered marketing tools abstract.json', // Path to your Lottie file
              repeat: true,
              animate: true,
              width: 180.sp,
            ),
            SizedBox(height: 14),
            Text('AI Coming soon'),
          ],
        ),
      ),
    );
  }
}
