import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final bool obscureText;
  final int? maxLength;
  final bool isEnabled;
  final int maxLines;
  final bool filled; // Toggle between filled and outlined style
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final Color? enabledBorderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double? borderWidth;
  final double? focusedBorderWidth;

  const AppTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.labelText,
    this.hintText,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.obscureText = false,
    this.maxLength,
    this.isEnabled = true,
    this.maxLines = 1,
    this.filled = false, // Set to true for background fill (like original)
    this.contentPadding,
    this.borderRadius,
    this.enabledBorderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderWidth,
    this.focusedBorderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = filled;
    final defaultRadius = borderRadius ?? BorderRadius.circular(12);
    final defaultPadding =
        contentPadding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    final defaultEnabledBorderColor =
        enabledBorderColor ?? AppColors.dividerColor;
    final defaultFocusedBorderColor = focusedBorderColor ?? AppColors.primary;
    final defaultErrorBorderColor = errorBorderColor ?? Colors.red;
    final defaultBorderWidth = borderWidth ?? 1.0;
    final defaultFocusedBorderWidth = focusedBorderWidth ?? 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: AppText.labelMedium.copyWith(
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],

        TextFormField(
          enabled: isEnabled,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          validator: (value) {
            // If it's a 10-digit mobile field, enforce digits + length
            if (maxLength == 10) {
              if (value == null || value.isEmpty) {
                return 'Please enter mobile number';
              }
              final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
              if (digitsOnly.length != 10) {
                return 'Mobile number must be 10 digits';
              }
              return null; // ✅ valid
            }

            // Otherwise, use the user-provided validator (if any)
            if (validator != null) {
              return validator!(value);
            }

            // No validator provided → always valid
            return null;
          },
          inputFormatters:
              (maxLength == 10)
                  ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ]
                  : inputFormatters,

          style: AppText.labelLarge.copyWith(color: AppColors.textColorPrimary),
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText ?? labelText ?? '',
            hintStyle: AppText.bodyMedium.copyWith(
              color:
                  isFilled ? AppColors.backgroundDark : AppColors.textColorHint,
            ),
            prefixIcon: prefixIcon,
            contentPadding: defaultPadding,
            filled: isFilled,
            fillColor: isFilled ? AppColors.inputBackground : null,
            alignLabelWithHint: true,

            // --- Border styling ---
            border: _buildOutlineBorder(
              defaultRadius,
              defaultEnabledBorderColor,
              defaultBorderWidth,
            ),
            enabledBorder: _buildOutlineBorder(
              defaultRadius,
              defaultEnabledBorderColor,
              defaultBorderWidth,
            ),
            focusedBorder: _buildOutlineBorder(
              defaultRadius,
              defaultFocusedBorderColor,
              defaultFocusedBorderWidth,
            ),
            errorBorder: _buildOutlineBorder(
              defaultRadius,
              defaultErrorBorderColor,
              defaultBorderWidth,
            ),
            focusedErrorBorder: _buildOutlineBorder(
              defaultRadius,
              defaultErrorBorderColor,
              defaultFocusedBorderWidth,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildOutlineBorder(
    BorderRadius borderRadius,
    Color color,
    double width,
  ) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
