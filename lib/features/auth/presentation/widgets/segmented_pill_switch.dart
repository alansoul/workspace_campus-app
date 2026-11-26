import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Smooth two-option pill switcher with sliding thumb highlight.
class SegmentedPillSwitch<T> extends StatelessWidget {
  final T value;
  final T leftValue;
  final T rightValue;
  final String leftLabel;
  final String rightLabel;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final ValueChanged<T> onChanged;
  final double height;
  final Color activeColor;

  const SegmentedPillSwitch({
    super.key,
    required this.value,
    required this.leftValue,
    required this.rightValue,
    required this.leftLabel,
    required this.rightLabel,
    required this.onChanged,
    this.leftIcon,
    this.rightIcon,
    this.height = 46,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = value == leftValue;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: isLeft ? 0 : pillWidth,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: leftLabel,
                      icon: leftIcon,
                      isActive: isLeft,
                      activeColor: activeColor,
                      onTap: () => onChanged(leftValue),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: rightLabel,
                      icon: rightIcon,
                      isActive: !isLeft,
                      activeColor: activeColor,
                      onTap: () => onChanged(rightValue),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
