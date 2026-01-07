import 'package:flutter/widgets.dart';

extension TextString on String {
  Text get text => Text(this);

  Text get isBold {
    return Text(
      this,
      style: const TextStyle().copyWith(fontWeight: FontWeight.bold),
    );
  }

  // Text color(Color? color) {
  //   return Text(this,
  //       style: const TextStyle().copyWith(color: color ?? MyTheme.textColor));
  // }
}

extension BoldText on Text {
  TextStyle get isBold {
    return const TextStyle().copyWith(fontWeight: FontWeight.bold);
  }
}

// external MakeText1 on Widget{
//      TextStyle get make Text(this,
//         style: const TextStyle().copyWith(fontWeight: FontWeight.bold))
//   }
