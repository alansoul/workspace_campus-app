import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';

/// Displays verified campus/Gmail identity and safe account status (admin/existing/new).
class DomainStatusBanner extends StatelessWidget {
  final DomainResolution? resolution;
  final bool isResolving;

  const DomainStatusBanner({
    super.key,
    required this.resolution,
    required this.isResolving,
  });

  @override
  Widget build(BuildContext context) {
    if (isResolving) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 9),
            Text(
              'Checking domain & account status...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    final res = resolution;
    if (res == null) return const SizedBox.shrink();

    if (res.allowed && res.isUniversity && res.universityName != null) {
      return _BadgeBox(
        background: const Color(0xFFE8F0FE),
        borderColor: const Color(0xFFD2E3FC),
        icon: res.isUniversityAdmin
            ? Icons.admin_panel_settings_rounded
            : Icons.verified_user_rounded,
        iconColor: AppColors.primary,
        title: res.universityName!,
        subtitle: _buildAccountStatusText(res),
        badgeText: res.isUniversityAdmin ? 'Admin Account' : 'Campus Verified',
        badgeColor:
            res.isUniversityAdmin ? AppColors.accentIndigo : AppColors.primary,
      );
    }

    if (res.allowed && res.isGmail) {
      return _BadgeBox(
        background: const Color(0xFFF8FAFC),
        borderColor: AppColors.border,
        icon: Icons.alternate_email_rounded,
        iconColor: AppColors.textSecondary,
        title: 'Personal Google Account',
        subtitle: _buildAccountStatusText(res),
        badgeText: 'Individual',
        badgeColor: const Color(0xFF475569),
      );
    }

    if (!res.allowed && (res.errorMessage?.isNotEmpty ?? false)) {
      return Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 17,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Domain not registered yet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    res.errorMessage!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  static String? _buildAccountStatusText(DomainResolution res) {
    if (res.accountExists == null) return null;
    if (res.isUniversityAdmin) {
      return 'University Administrator verified • Ready to sign in';
    }
    if (res.accountExists == true) {
      return res.hasPassword == true
          ? 'Existing account found • Sign in with Password or OTP'
          : 'Account found • Verify via OTP to finish password setup';
    }
    return 'New email • Register to verify and activate account';
  }
}

class _BadgeBox extends StatelessWidget {
  final Color background;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String badgeText;
  final Color badgeColor;

  const _BadgeBox({
    required this.background,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
