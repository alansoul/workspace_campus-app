import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';

/// Live animated checklist showing password rules + optional confirmation match.
class PasswordStrengthChecklist extends StatelessWidget {
  final String password;
  final String? confirmPassword;

  const PasswordStrengthChecklist({
    super.key,
    required this.password,
    this.confirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final req = PasswordRequirements.evaluate(password);
    final showMatch = confirmPassword != null;
    final matches =
        showMatch && password.isNotEmpty && password == confirmPassword;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _RuleRow(
            satisfied: req.hasMinLength,
            label: 'At least 8 characters',
          ),
          const SizedBox(height: 6),
          _RuleRow(
            satisfied: req.hasUppercase,
            label: 'One uppercase letter (recommended)',
          ),
          const SizedBox(height: 6),
          _RuleRow(
            satisfied: req.hasNumberOrSymbol,
            label: 'One number or symbol (recommended)',
          ),
          if (showMatch) ...[
            const SizedBox(height: 6),
            _RuleRow(
              satisfied: matches,
              label: 'Passwords match',
            ),
          ],
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final bool satisfied;
  final String label;

  const _RuleRow({required this.satisfied, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: satisfied
                ? AppColors.success
                : Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(
              color: satisfied ? AppColors.success : AppColors.border,
            ),
          ),
          child: Icon(
            satisfied ? Icons.check_rounded : Icons.circle,
            size: satisfied ? 12 : 5,
            color: satisfied ? Colors.white : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400,
              color:
                  satisfied ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
