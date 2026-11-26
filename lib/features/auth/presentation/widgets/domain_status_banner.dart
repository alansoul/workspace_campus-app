import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';

/// Displays verified campus badge, Gmail individual pill, or unregistered warning.
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Verifying institution domain...',
              style: TextStyle(
                fontSize: 12.5,
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
        icon: Icons.verified_user_rounded,
        iconColor: AppColors.primary,
        title: res.universityName!,
        badgeText: 'Campus Verified',
        badgeColor: AppColors.primary,
      );
    }

    if (res.allowed && res.isGmail) {
      return const _BadgeBox(
        background: Color(0xFFF8FAFC),
        borderColor: AppColors.border,
        icon: Icons.alternate_email_rounded,
        iconColor: AppColors.textSecondary,
        title: 'Personal Google Account',
        badgeText: 'Individual',
        badgeColor: Color(0xFF475569),
      );
    }

    if (!res.allowed && (res.errorMessage?.isNotEmpty ?? false)) {
      return Container(
        padding: const EdgeInsets.all(12),
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
              size: 18,
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
                      fontSize: 12.5,
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
}

class _BadgeBox extends StatelessWidget {
  final Color background;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 10.5,
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
