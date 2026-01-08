import 'package:flutter/material.dart';

class MyBackgroundWidget extends StatelessWidget {
  final Widget child;
  const MyBackgroundWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Set your background color here
      child: SafeArea(child: child),
    );
  }
}