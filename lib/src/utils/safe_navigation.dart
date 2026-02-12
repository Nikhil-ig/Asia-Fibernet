import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utilities to safely pop overlays/routes or query view insets without
/// relying on a possibly-deactivated BuildContext or uninitialized GetX
/// internals. Use these instead of calling `Navigator.of(Get.context!).pop()`
/// or `MediaQuery.of(Get.context!).viewInsets` directly.

/// Safely pop a route/dialog/bottom-sheet. If [ctx] is provided it will be
/// preferred; otherwise the function attempts to use the overlay context or
/// Get.context. If a [result] is provided it will be passed to pop().
void safePop([BuildContext? ctx, dynamic result]) {
  final BuildContext? safeCtx = ctx ?? Get.overlayContext ?? Get.context;
  if (safeCtx != null) {
    try {
      if (Navigator.of(safeCtx).canPop()) {
        Navigator.of(safeCtx).pop(result);
        return;
      }
    } catch (_) {}
  }

  // Fallback to Get.back() when Navigator-based pop isn't possible.
  try {
    Get.back(result: result);
  } catch (_) {}
}

/// Safely return the bottom view inset (keyboard) for a context-aware UI.
/// If no context is available, returns 0.0.
double safeViewInsetsBottom([BuildContext? ctx]) {
  final BuildContext? safeCtx = ctx ?? Get.overlayContext ?? Get.context;
  if (safeCtx != null) {
    try {
      return MediaQuery.of(safeCtx).viewInsets.bottom;
    } catch (_) {}
  }
  return 0.0;
}
