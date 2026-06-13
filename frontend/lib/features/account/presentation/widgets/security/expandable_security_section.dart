import 'package:flutter/material.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/common/styled_icon_container.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/common/styled_switch.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/section_header.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/security/auth_method_tile.dart';

/// Generic expandable security section (used for App Lock and Key Access)
class ExpandableSecuritySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final bool isLockEnabled;
  final ValueChanged<bool> onLockToggle;
  final bool isBiometricEnabled;
  final ValueChanged<bool> onBiometricToggle;
  final bool isPinEnabled;
  final ValueChanged<bool> onPinToggle;
  final String lockLabel;

  const ExpandableSecuritySection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.isLockEnabled,
    required this.onLockToggle,
    required this.isBiometricEnabled,
    required this.onBiometricToggle,
    required this.isPinEnabled,
    required this.onPinToggle,
    this.lockLabel = 'Aktifkan Kunci',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    StyledIconContainer(icon: icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildContent(),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          // Toggle Aktifkan Kunci
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lockLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                StyledSwitch(value: isLockEnabled, onChanged: onLockToggle),
              ],
            ),
          ),

          // Content jika enabled
          if (isLockEnabled) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                      title: 'Metode Autentikasi', isSmall: true),
                  const SizedBox(height: 12),
                  AuthMethodTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Sidik Jari',
                    value: isBiometricEnabled,
                    onChanged: onBiometricToggle,
                  ),
                  const SizedBox(height: 10),
                  AuthMethodTile(
                    icon: Icons.dialpad_rounded,
                    title: 'PIN Angka',
                    value: isPinEnabled,
                    onChanged: onPinToggle,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
