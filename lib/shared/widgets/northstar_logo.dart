import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Northstar Workspace brand mark rendered in crisp vector graphics with
/// optional 3D perspective tilt (hover/drag) and subtle ambient animation.
class NorthstarLogo extends StatefulWidget {
  const NorthstarLogo({
    super.key,
    this.size = 64,
    this.animated = true,
    this.interactive3d = true,
    this.showBackground = true,
  });

  /// Width and height of the square emblem.
  final double size;

  /// Enables subtle float/twinkle animation (automatically disabled under
  /// Flutter test bindings so `pumpAndSettle()` finishes cleanly).
  final bool animated;

  /// Enables interactive 3D pointer hover and touch drag perspective tilt.
  final bool interactive3d;

  /// When true, renders the obsidian glass squircle badge with specular rim
  /// highlights; when false, renders the floating N + orbit + star mark only.
  final bool showBackground;

  @override
  State<NorthstarLogo> createState() => _NorthstarLogoState();
}

class _NorthstarLogoState extends State<NorthstarLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _tilt = Offset.zero;
  bool _isHovered = false;

  bool get _isTestBinding =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.animated && !_isTestBinding) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant NorthstarLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated && !_isTestBinding) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateTiltFromLocal(Offset localPosition) {
    if (!widget.interactive3d) return;
    final half = widget.size / 2;
    if (half <= 0) return;
    final nx = ((localPosition.dx - half) / half).clamp(-1.0, 1.0);
    final ny = ((localPosition.dy - half) / half).clamp(-1.0, 1.0);
    setState(() {
      _tilt = Offset(nx, ny);
    });
  }

  void _resetTilt() {
    if (_tilt == Offset.zero && !_isHovered) return;
    setState(() {
      _tilt = Offset.zero;
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiltX = _tilt.dy * -0.24;
    final tiltY = _tilt.dx * 0.24;

    Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final wave = math.sin(t * 2 * math.pi);
        final twinkleWave = (math.sin(t * 4 * math.pi - math.pi / 2) + 1) / 2;
        final ambientYaw = widget.animated && !_isTestBinding && !_isHovered
            ? wave * 0.045
            : 0.0;
        final ambientPitch = widget.animated && !_isTestBinding && !_isHovered
            ? math.cos(t * 2 * math.pi) * 0.035
            : 0.0;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0022)
          ..rotateX(tiltX + ambientPitch)
          ..rotateY(tiltY + ambientYaw);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _NorthstarPainter(
              showBackground: widget.showBackground,
              twinkle: widget.animated && !_isTestBinding ? twinkleWave : 0.45,
              floatOffset: widget.animated && !_isTestBinding ? wave * 0.014 : 0,
              parallax: _tilt,
            ),
          ),
        );
      },
    );

    if (widget.interactive3d) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onHover: (event) => _updateTiltFromLocal(event.localPosition),
        onExit: (_) => _resetTilt(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => _updateTiltFromLocal(details.localPosition),
          onPanUpdate: (details) =>
              _updateTiltFromLocal(details.localPosition),
          onPanEnd: (_) => _resetTilt(),
          onPanCancel: _resetTilt,
          child: content,
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: content,
    );
  }
}

class _NorthstarPainter extends CustomPainter {
  const _NorthstarPainter({
    required this.showBackground,
    required this.twinkle,
    required this.floatOffset,
    required this.parallax,
  });

  final bool showBackground;
  final double twinkle;
  final double floatOffset;
  final Offset parallax;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100.0;
    canvas.save();
    canvas.scale(s, s);

    if (showBackground) {
      _paintObsidianSquircle(canvas);
    }

    // Parallax shifts give genuine 3D depth separation between planes.
    final nShift = Offset(parallax.dx * 1.4, parallax.dy * 1.4);
    final orbitShift = Offset(
      parallax.dx * 2.5,
      parallax.dy * 2.5 + floatOffset * 100,
    );
    final starShift = Offset(
      parallax.dx * 3.4,
      parallax.dy * 3.4 - floatOffset * 130,
    );

    // 1. Back half of the orbital crescent (sweeping behind the N right stem).
    canvas.save();
    canvas.translate(orbitShift.dx, orbitShift.dy);
    _paintOrbitBack(canvas);
    canvas.restore();

    // 2. Stylized 3D metallic-white "N".
    canvas.save();
    canvas.translate(nShift.dx, nShift.dy);
    _paintStylizedN(canvas);
    canvas.restore();

    // 3. Front half of the orbital crescent (passing cleanly over the N).
    canvas.save();
    canvas.translate(orbitShift.dx, orbitShift.dy);
    _paintOrbitFront(canvas);
    canvas.restore();

    // 4. Four-point North Star in the upper-right quadrant.
    canvas.save();
    canvas.translate(starShift.dx, starShift.dy);
    _paintNorthStar(canvas);
    canvas.restore();

    canvas.restore();
  }

  void _paintObsidianSquircle(Canvas canvas) {
    const rect = Rect.fromLTWH(2, 2, 96, 96);
    final squircle = RRect.fromRectAndRadius(rect, const Radius.circular(26));

    // Outer ambient shadow.
    canvas.drawRRect(
      squircle.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Base dark glass fill.
    final basePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.18, -0.25),
        radius: 1.05,
        colors: [
          Color(0xFF1F2636),
          Color(0xFF0E121C),
          Color(0xFF05070B),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(squircle, basePaint);

    // Subtle glass rim outline.
    canvas.drawRRect(
      squircle.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66FFFFFF),
            Color(0x1E94A3B8),
            Color(0x1494A3B8),
            Color(0x52FFFFFF),
          ],
          stops: [0.0, 0.25, 0.75, 1.0],
        ).createShader(rect),
    );

    // Top & bottom specular rim highlights matching the signature obsidian icon.
    final topRimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00FFFFFF), Color(0xCCFFFFFF), Color(0x00FFFFFF)],
      ).createShader(const Rect.fromLTWH(30, 1.8, 40, 3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawOval(const Rect.fromLTWH(33, 1.7, 34, 1.8), topRimPaint);

    final bottomRimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00FFFFFF), Color(0xB8FFFFFF), Color(0x00FFFFFF)],
      ).createShader(const Rect.fromLTWH(30, 96.2, 40, 3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawOval(const Rect.fromLTWH(34, 96.4, 32, 1.7), bottomRimPaint);
  }

  void _paintStylizedN(Canvas canvas) {
    // Soft ambient shadow cast onto the obsidian surface.
    final leftStem = RRect.fromRectAndCorners(
      const Rect.fromLTWH(28, 30, 10.6, 40),
      topLeft: const Radius.circular(5.2),
      topRight: const Radius.circular(5.2),
      bottomLeft: const Radius.circular(3.5),
      bottomRight: const Radius.circular(3.5),
    );

    final rightStem = RRect.fromRectAndCorners(
      const Rect.fromLTWH(59.4, 30, 10.6, 40),
      topLeft: const Radius.circular(4.8),
      topRight: const Radius.circular(4.8),
      bottomLeft: const Radius.circular(5.2),
      bottomRight: const Radius.circular(5.2),
    );

    final diagPath = Path()
      ..moveTo(29.8, 34.4)
      ..quadraticBezierTo(33.8, 28.5, 39.2, 32.8)
      ..lineTo(68.2, 65.4)
      ..quadraticBezierTo(65.0, 71.2, 59.0, 67.4)
      ..close();

    // Back shadow pass.
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.save();
    canvas.translate(0, 2.2);
    canvas.drawRRect(leftStem, shadowPaint);
    canvas.drawRRect(rightStem, shadowPaint);
    canvas.drawPath(diagPath, shadowPaint);
    canvas.restore();

    // Left vertical pillar (pearl white top fading cleanly to slate gray base).
    canvas.drawRRect(
      leftStem,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFEAEEF5),
            Color(0xFF94A0B4),
            Color(0xFF475163),
          ],
          stops: [0.0, 0.36, 0.78, 1.0],
        ).createShader(leftStem.outerRect),
    );

    // Right vertical pillar (dark recessed top fading into luminous white base).
    canvas.drawRRect(
      rightStem,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF394150),
            Color(0xFF7B879B),
            Color(0xFFE4E9F2),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.38, 0.74, 1.0],
        ).createShader(rightStem.outerRect),
    );

    // Folded diagonal ribbon connecting left top to right bottom.
    canvas.drawPath(
      diagPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF3F6FA),
            Color(0xFFD5DCE8),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ).createShader(const Rect.fromLTWH(28, 30, 42, 40)),
    );

    // Subtle sculpted fold highlight along the upper-left curve of the N.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28.8, 30.8, 5.2, 18),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEEFFFFFF), Color(0x00FFFFFF)],
        ).createShader(const Rect.fromLTWH(28, 30, 8, 18)),
    );
  }

  void _paintOrbitBack(Canvas canvas) {
    // Upper-right back segment passing behind the right stem of the N.
    final backArc = Path()
      ..moveTo(49.5, 41.2)
      ..cubicTo(61.0, 32.0, 71.2, 32.4, 69.2, 40.8)
      ..cubicTo(67.6, 46.8, 59.5, 53.2, 50.5, 59.0)
      ..cubicTo(57.8, 51.8, 63.4, 44.8, 64.2, 39.8)
      ..cubicTo(64.8, 35.6, 58.2, 36.2, 49.5, 41.2)
      ..close();

    canvas.drawPath(
      backArc,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFCFD8E6),
            Color(0xFFFFFFFF),
            Color(0xFFD8E1EE),
          ],
        ).createShader(const Rect.fromLTWH(48, 32, 23, 28)),
    );
  }

  void _paintOrbitFront(Canvas canvas) {
    // Sweeping diagonal crescent in front of the lower-left stem & diagonal bar.
    final frontArc = Path()
      ..moveTo(31.2, 54.0)
      ..cubicTo(20.0, 62.8, 19.6, 68.5, 27.6, 68.2)
      ..cubicTo(37.6, 67.8, 53.0, 58.5, 65.8, 46.8)
      ..cubicTo(68.8, 44.0, 69.8, 40.4, 67.4, 37.8)
      ..cubicTo(65.4, 36.0, 62.6, 37.2, 62.8, 39.6)
      ..cubicTo(63.2, 43.2, 52.8, 52.8, 39.2, 59.8)
      ..cubicTo(29.8, 64.6, 24.4, 64.6, 24.8, 60.6)
      ..cubicTo(25.2, 58.2, 27.8, 56.0, 31.2, 54.0)
      ..close();

    // Drop shadow over the N ribbon.
    canvas.drawPath(
      frontArc.shift(const Offset(0, 1.4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );

    canvas.drawPath(
      frontArc,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
            Color(0xFFFFFFFF),
          ],
        ).createShader(const Rect.fromLTWH(18, 36, 54, 34)),
    );
  }

  void _paintNorthStar(Canvas canvas) {
    const center = Offset(72.5, 26.8);
    final pulse = 1.0 + twinkle * 0.12;
    final r = 10.6 * pulse;
    final inner = 1.9 * pulse;

    // Warm starlight bloom halo.
    canvas.drawCircle(
      center,
      r * 1.15,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22 + twinkle * 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );

    final star = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(
        center.dx + inner * 0.35,
        center.dy - inner * 0.35,
        center.dx + r,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + inner * 0.35,
        center.dy + inner * 0.35,
        center.dx,
        center.dy + r,
      )
      ..quadraticBezierTo(
        center.dx - inner * 0.35,
        center.dy + inner * 0.35,
        center.dx - r,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - inner * 0.35,
        center.dy - inner * 0.35,
        center.dx,
        center.dy - r,
      )
      ..close();

    canvas.drawPath(
      star,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFF8EB),
            Color(0xFFE9EEF7),
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _NorthstarPainter oldDelegate) {
    return oldDelegate.showBackground != showBackground ||
        oldDelegate.twinkle != twinkle ||
        oldDelegate.floatOffset != floatOffset ||
        oldDelegate.parallax != parallax;
  }
}
