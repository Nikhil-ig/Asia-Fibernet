import 'package:flutter/widgets.dart';

extension EmptySpace on num {
  /// Give the Gap/Space by using [10.height]
  SizedBox get height => SizedBox(height: toDouble());

  /// Give the Gap/Space by using [10.width]
  SizedBox get width => SizedBox(width: toDouble());
}
