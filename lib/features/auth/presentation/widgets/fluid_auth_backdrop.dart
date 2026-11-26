import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Soft pastel aurora backdrop + frosted glass container inspired by modern fluid mobile UIs.
class FluidAuthBackdrop extends StatefulWidget {
  final Widget child;

  const FluidAuthBackdrop({super.key, required this.child});

  @override
  State<FluidAuthBackdrop> createState() => _FluidAuthBackdropState();
}

class _FluidAuthBackdropState extends State<FluidAuthBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base soft pastel vertical gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.auroraLavender,
                Color(0xFFF8FAFF),
                AppColors.auroraSky,
              ],
            ),
          ),
        ),
        // Floating ambient pastel orbs (gentle drift)
        AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            final t = _ambientController.value;
            return Stack(
              children: [
                Positioned(
                  top: -90 + (t * 28),
                  left: -70 + (t * 20),
                  child: const _GlowOrb(
                    size: 290,
                    color: AppColors.auroraPink,
                    opacity: 0.85,
                  ),
                ),
                Positioned(
                  top: 120 - (t * 24),
                  right: -85 + (t * 16),
                  child: _GlowOrb(
                    size: 260,
                    color: const Color(0xFFC7D2FE).withValues(alpha: 0.6),
                    opacity: 0.9,
                  ),
                ),
                Positioned(
                  bottom: -100 + (t * 22),
                  left: 30 - (t * 18),
                  child: _GlowOrb(
                    size: 310,
                    color: const Color(0xFFBAE6FD).withValues(alpha: 0.65),
                    opacity: 0.9,
                  ),
                ),
              ],
            );
          },
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Reusable frosted glass card wrapper for auth and bottom onboarding cards.
class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? tintColor;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 28,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor ?? Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4766BE).withValues(alpha: 0.10),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
