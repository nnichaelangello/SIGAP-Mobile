import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Consistent styled switch used across the app
class StyledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const StyledSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppConstants.primaryColor,
      activeTrackColor: AppConstants.primaryColor.withValues(alpha: 0.4),
      inactiveThumbColor: Colors.grey.shade300,
      inactiveTrackColor: Colors.grey.shade200,
    );
  }
}
