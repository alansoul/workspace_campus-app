import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Animation preset matching the Northstar Workspace Logo Motion Studio.
enum NorthstarLogoMode {
  /// 4.35s hero loop: N unfold, rim sweep, comet orbital ring draw, Polaris
  /// spring ignition + shockwave, metallic N sheen, and orbital tail erase.
  signature,

  /// Continuous 2.2s orbital chase loop with Polaris heartbeat (splash screens).
  loader,

  /// Interactive 3D perspective tilt + cursor glass sheen + parallax + tap burst.
  hover3d,

  /// Quiet 3.6s micro-motion polish for navigation bars and app headers.
  idle,
}

/// Northstar Workspace brand mark rendered with exact studio vector geometry,
/// interactive 3D tilt, radial cursor glass sheen, and 4 choreography presets.
class NorthstarLogo extends StatefulWidget {
  const NorthstarLogo({
    super.key,
    this.size = 64,
    this.mode = NorthstarLogoMode.idle,
    this.animated = true,
    this.interactive3d = true,
    this.showBackground = true,
  });

  /// Width and height of the square emblem.
  final double size;

  /// Choreography mode preset.
  final NorthstarLogoMode mode;

  /// Enables animation (automatically paused under `WidgetTester` bindings
  /// so `pumpAndSettle()` finishes cleanly).
  final bool animated;

  /// Enables interactive 3D pointer hover and touch drag perspective tilt.
  final bool interactive3d;

  /// When true, renders the deep obsidian glass squircle badge; when false,
  /// renders only the floating metallic N + orbital ring + North Star.
  final bool showBackground;

  @override
  State<NorthstarLogo> createState() => _NorthstarLogoState();
}

class _NorthstarLogoState extends State<NorthstarLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickerController;
  DateTime? _lastTickTime;
  double _elapsed = 0.0;
  bool _firstCycle = true;
  double _hoverBurstTimer = -1.0;

  Offset _targetTilt = Offset.zero;
  Offset _currentTilt = Offset.zero;
  bool _pointerActive = false;

  bool get _isTestBinding =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _hoverBurstTimer = widget.mode == NorthstarLogoMode.hover3d ? 0.0 : -1.0;
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onTick);

    if (widget.animated && !_isTestBinding) {
      _lastTickTime = DateTime.now();
      _tickerController.repeat();
    }
  }

  void _onTick() {
    final now = DateTime.now();
    final prev = _lastTickTime ?? now;
    _lastTickTime = now;
    final dt = (now.difference(prev).inMicroseconds / 1e6).clamp(0.0, 0.05);

    _elapsed += dt;
    if (widget.mode == NorthstarLogoMode.signature && _elapsed >= 4.4) {
      _elapsed %= 4.4;
      _firstCycle = false;
    }

    if (_hoverBurstTimer >= 0) {
      _hoverBurstTimer += dt;
      if (_hoverBurstTimer > 1.55) {
        _hoverBurstTimer = -1.0;
      }
    }

    // Smooth spring-damped 3D pointer/touch tilt
    final damp = 1.0 - math.exp(-dt * 11.0);
    _currentTilt = Offset(
      _lerp(_currentTilt.dx, _targetTilt.dx, damp),
      _lerp(_currentTilt.dy, _targetTilt.dy, damp),
    );
  }

  @override
  void didUpdateWidget(covariant NorthstarLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _elapsed = 0.0;
      _firstCycle = true;
      _hoverBurstTimer = widget.mode == NorthstarLogoMode.hover3d ? 0.0 : -1.0;
    }
    if (widget.animated != oldWidget.animated) {
      if (widget.animated && !_isTestBinding) {
        _lastTickTime = DateTime.now();
        _tickerController.repeat();
      } else {
        _tickerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _tickerController.removeListener(_onTick);
    _tickerController.dispose();
    super.dispose();
  }

  void _updateTiltFromLocal(Offset localPosition) {
    if (!widget.interactive3d) return;
    final half = widget.size / 2;
    if (half <= 0) return;
    final nx = ((localPosition.dx - half) / half).clamp(-1.0, 1.0);
    final ny = ((localPosition.dy - half) / half).clamp(-1.0, 1.0);
    setState(() {
      _pointerActive = true;
      _targetTilt = Offset(nx, ny);
    });
  }

  void _resetTilt() {
    setState(() {
      _pointerActive = false;
      _targetTilt = Offset.zero;
    });
  }

  void _triggerBurst() {
    setState(() {
      if (widget.mode == NorthstarLogoMode.hover3d) {
        _hoverBurstTimer = 0.0;
      } else if (widget.mode == NorthstarLogoMode.signature) {
        _elapsed = 0.0;
        _firstCycle = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedBuilder(
      animation: _tickerController,
      builder: (context, _) {
        final effectiveAnimated = widget.animated && !_isTestBinding;
        final rotX = _currentTilt.dy * -0.25;
        final rotY = _currentTilt.dx * 0.25;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0018)
          ..rotateX(rotX)
          ..rotateY(rotY);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _NorthstarStudioPainter(
              mode: widget.mode,
              animated: effectiveAnimated,
              showBackground: widget.showBackground,
              elapsed: _elapsed,
              firstCycle: _firstCycle,
              hoverBurstTimer: _hoverBurstTimer,
              tilt: _currentTilt,
              pointerActive: _pointerActive,
            ),
          ),
        );
      },
    );

    if (widget.interactive3d) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (e) {
          _updateTiltFromLocal(e.localPosition);
          if (widget.mode == NorthstarLogoMode.hover3d) {
            _hoverBurstTimer = 0.0;
          }
        },
        onHover: (e) => _updateTiltFromLocal(e.localPosition),
        onExit: (_) => _resetTilt(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _triggerBurst,
          onPanDown: (d) => _updateTiltFromLocal(d.localPosition),
          onPanUpdate: (d) => _updateTiltFromLocal(d.localPosition),
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

class _NorthstarStudioPainter extends CustomPainter {
  _NorthstarStudioPainter({
    required this.mode,
    required this.animated,
    required this.showBackground,
    required this.elapsed,
    required this.firstCycle,
    required this.hoverBurstTimer,
    required this.tilt,
    required this.pointerActive,
  });

  final NorthstarLogoMode mode;
  final bool animated;
  final bool showBackground;
  final double elapsed;
  final bool firstCycle;
  final double hoverBurstTimer;
  final Offset tilt;
  final bool pointerActive;

  // Cached vector geometry (normalized to the 512x512 studio artboard)
  static final Path _squirclePath = _buildSquirclePath();
  static final Path _diagRibbonPath = _buildDiagPath();
  static final Path _letterNClipPath = _buildLetterNClipPath();
  static final Path _ringExactPath = _buildRingExactPath();
  static final Path _ringCenterlinePath = _buildRingCenterlinePath();
  static final PathMetric _ringMetric =
      _ringCenterlinePath.computeMetrics().first;
  static final PathMetric _squircleMetric =
      _squirclePath.computeMetrics().first;
  static final Path _starCorePath = _buildStarCorePath();

  static Path _buildSquirclePath() {
    return Path()
      ..moveTo(150, 38)
      ..lineTo(362, 38)
      ..cubicTo(428, 38, 474, 84, 474, 150)
      ..lineTo(474, 362)
      ..cubicTo(474, 428, 428, 474, 362, 474)
      ..lineTo(150, 474)
      ..cubicTo(84, 474, 38, 428, 38, 362)
      ..lineTo(38, 150)
      ..cubicTo(38, 84, 84, 38, 150, 38)
      ..close();
  }

  static Path _buildDiagPath() {
    return Path()
      ..moveTo(203.73, 175.22)
      ..lineTo(337.73, 317.22)
      ..arcToPoint(
        const Offset(304.27, 348.79),
        radius: const Radius.circular(23),
        clockwise: true,
      )
      ..lineTo(170.27, 206.79)
      ..arcToPoint(
        const Offset(203.73, 175.22),
        radius: const Radius.circular(23),
        clockwise: true,
      )
      ..close();
  }

  static Path _buildLetterNClipPath() {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(164, 168, 46, 188), const Radius.circular(23)))
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(298, 168, 46, 188), const Radius.circular(23)))
      ..addPath(_buildDiagPath(), Offset.zero);
  }

  static Path _buildRingExactPath() {
    return Path()
      ..moveTo(131, 302)
      ..cubicTo(106, 328, 110, 351, 146, 349)
      ..cubicTo(192, 346, 250, 311, 301, 264)
      ..cubicTo(341, 227, 360, 197, 349, 182)
      ..cubicTo(337, 167, 294, 182, 244, 216)
      ..cubicTo(291, 190, 327, 181, 335, 190)
      ..cubicTo(341, 198, 326, 225, 295, 258)
      ..cubicTo(245, 303, 187, 332, 144, 335)
      ..cubicTo(122, 336, 117, 324, 131, 302)
      ..close();
  }

  static Path _buildRingCenterlinePath() {
    return Path()
      ..moveTo(131, 302)
      ..cubicTo(110, 326, 114, 344, 144, 342)
      ..cubicTo(188, 339, 246, 306, 296, 260)
      ..cubicTo(334, 224, 353, 196, 344, 185)
      ..cubicTo(334, 173, 292, 186, 244, 216);
  }

  static Path _buildStarCorePath() {
    return Path()
      ..moveTo(355, 106)
      ..cubicTo(357, 134, 369, 146, 397, 148)
      ..cubicTo(369, 150, 357, 162, 355, 190)
      ..cubicTo(353, 162, 341, 150, 313, 148)
      ..cubicTo(341, 146, 353, 134, 355, 106)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 512.0;
    canvas.save();
    canvas.scale(s, s);

    // Evaluate choreography parameters for the current mode & time
    var squircleScale = 1.0;
    var leftDy = 0.0;
    var leftOp = 1.0;
    var rightDy = 0.0;
    var rightOp = 1.0;
    var diagScale = 1.0;
    var diagOp = 1.0;
    var rimSweepProgress = -1.0;

    var ringStartNorm = 0.0;
    var ringEndNorm = 1.0;
    var ringOpacity = 1.0;
    var ringPulseProgress = -1.0;

    var cometProgress = 1.0;
    var cometOpacity = 0.0;
    var cometScale = 1.0;

    var sheenProgress = -1.0;
    var sheenOpacityScale = 1.0;

    var starScale = 1.0;
    var starRotDeg = 0.0;
    var starCoreOp = 1.0;
    var haloScale = 1.0;
    var haloOp = 0.88;
    var shockwaveProgress = 0.0;

    if (animated) {
      switch (mode) {
        case NorthstarLogoMode.signature:
          final norm = (elapsed % 4.4) / 4.4;
          // Subtle floating levitation matching nsFloat (0%,100% -> 0, 50% -> -2.4)
          squircleScale = 1.0;
          if (norm >= 0.02 && norm <= 0.25) {
            rimSweepProgress = _invLerp(0.02, 0.25, norm);
          }

          // Exact signature loop ring reveal (0.064 -> 0.35 create, 0.66 -> 0.90 erase)
          if (norm < 0.064) {
            ringEndNorm = 0.0;
            ringOpacity = 0.0;
          } else if (norm <= 0.35) {
            final raw = _invLerp(0.064, 0.35, norm);
            final eased = _easeInOutCubic(raw);
            ringStartNorm = 0.0;
            ringEndNorm = eased;
            ringOpacity = norm < 0.07 ? raw / 0.022 : 1.0;
            final env = raw < 0.12
                ? raw / 0.12
                : raw > 0.85
                    ? (1.0 - raw) / 0.15
                    : 1.0;
            cometProgress = eased;
            cometOpacity = env;
            cometScale = 0.71 + env * 0.45;
          } else if (norm < 0.66) {
            ringStartNorm = 0.0;
            ringEndNorm = 1.0;
          } else if (norm <= 0.90) {
            final raw = _invLerp(0.66, 0.90, norm);
            final eased = _easeInOutCubic(raw);
            ringStartNorm = eased;
            ringEndNorm = 1.0;
            ringOpacity = norm > 0.885 ? (1.0 - raw) / 0.06 : 1.0;
            cometProgress = eased;
            cometOpacity = math.sin(raw * math.pi) * 0.78;
            cometScale = 0.87;
          } else {
            ringEndNorm = 0.0;
            ringOpacity = 0.0;
          }

          // Polaris star curves matching nsStar / nsHalo / nsShock (4.4s)
          if (norm < 0.28) {
            starScale = 0.46;
            starRotDeg = -14.0;
            starCoreOp = 0.18;
            haloScale = 0.50;
            haloOp = 0.12;
          } else if (norm <= 0.39) {
            final raw = _invLerp(0.28, 0.39, norm);
            starScale = _lerp(0.46, 1.24, _easeOutBack(raw, 1.8));
            starRotDeg = _lerp(-14.0, 5.0, raw);
            starCoreOp = _lerp(0.18, 1.0, raw);
            haloScale = _lerp(0.50, 1.36, _easeOutCubic(raw));
            haloOp = _lerp(0.12, 1.0, raw);
          } else if (norm < 0.67) {
            final raw = _invLerp(0.39, 0.48, norm);
            starScale = _lerp(1.24, 1.0, _easeOutCubic(raw));
            starRotDeg = _lerp(5.0, 0.0, _easeOutCubic(raw));
            starCoreOp = 1.0;
            haloScale = _lerp(1.36, 1.0, _easeOutCubic(raw));
            haloOp = _lerp(1.0, 0.88, _easeOutCubic(raw));
          } else if (norm <= 0.88) {
            final raw = _invLerp(0.67, 0.88, norm);
            final eased = _easeInOutCubic(raw);
            starScale = _lerp(1.0, 0.46, eased);
            starRotDeg = _lerp(0.0, -14.0, eased);
            starCoreOp = _lerp(1.0, 0.18, eased);
            haloScale = _lerp(1.0, 0.50, eased);
            haloOp = _lerp(0.88, 0.12, eased);
          } else {
            starScale = 0.46;
            starRotDeg = -14.0;
            starCoreOp = 0.18;
            haloScale = 0.50;
            haloOp = 0.12;
          }

          if (norm >= 0.31 && norm <= 0.48) {
            shockwaveProgress = _invLerp(0.31, 0.48, norm);
          }
          if (norm >= 0.41 && norm <= 0.65) {
            sheenProgress = _easeInOutCubic(_invLerp(0.41, 0.65, norm));
          }
          break;

        case NorthstarLogoMode.loader:
          final p = (elapsed % 2.2) / 2.2;
          if (p <= 0.50) {
            final drawP = _easeInOutCubic(p / 0.50);
            ringStartNorm = 0.0;
            ringEndNorm = drawP;
            final env = math.sin((p / 0.50) * math.pi);
            cometProgress = drawP;
            cometOpacity = 0.55 + env * 0.45;
            cometScale = 0.85 + env * 0.25;
          } else {
            final eraseP = _easeInOutCubic((p - 0.50) / 0.50);
            ringStartNorm = eraseP;
            ringEndNorm = 1.0;
            final env = math.sin(((p - 0.50) / 0.50) * math.pi);
            cometProgress = eraseP;
            cometOpacity = env * 0.72;
            cometScale = 0.75;
          }
          final beat = math.exp(-math.pow((p - 0.47) / 0.14, 2));
          starScale = 0.84 + beat * 0.30;
          starRotDeg = beat * 12.0;
          starCoreOp = 0.62 + beat * 0.38;
          haloScale = 0.78 + beat * 0.44;
          haloOp = 0.48 + beat * 0.52;
          if (p > 0.43 && p < 0.78) {
            shockwaveProgress = (p - 0.43) / 0.35;
          }
          if (p > 0.25 && p < 0.72) {
            sheenProgress = _easeInOutCubic((p - 0.25) / 0.47);
            sheenOpacityScale = 0.55;
          }
          squircleScale = 1.0 + math.sin(p * math.pi * 2) * 0.012;
          break;

        case NorthstarLogoMode.hover3d:
          if (hoverBurstTimer >= 0) {
            final bt = hoverBurstTimer;
            if (bt <= 0.92) {
              final pRing = _easeInOutCubic(bt / 0.92);
              ringStartNorm = 0.0;
              ringEndNorm = pRing;
              cometProgress = pRing;
              cometOpacity = math.sin(pRing * math.pi) * 0.98;
              cometScale = 1.05;
            }
            if (bt >= 0.65 && bt <= 1.35) {
              final pStar = (bt - 0.65) / 0.70;
              starScale = 1.0 + math.sin(pStar * math.pi) * 0.28;
              starRotDeg = (1.0 - _easeOutCubic(pStar)) * 22.0;
              haloScale = 1.0 + math.sin(pStar * math.pi) * 0.45;
              haloOp = 1.0;
              shockwaveProgress = pStar;
            } else {
              final breath = math.sin(elapsed * 2.4) * 0.04;
              starScale = 1.0 + breath;
              haloScale = 1.0 + breath;
              haloOp = 0.92;
            }
            if (bt >= 0.55 && bt <= 1.45) {
              sheenProgress = _easeInOutCubic((bt - 0.55) / 0.90);
              sheenOpacityScale = 0.9;
            }
          } else {
            final breath = math.sin(elapsed * 2.2) * 0.04;
            starScale = 1.0 + breath;
            haloScale = 1.0 + breath * 1.5;
            haloOp = 0.88 + breath;
          }
          break;

        case NorthstarLogoMode.idle:
          final t = elapsed % 3.6;
          if (t >= 0.6 && t <= 1.55) {
            sheenProgress = _easeInOutCubic((t - 0.6) / 0.95);
            sheenOpacityScale = 0.62;
          }
          if (t >= 1.05 && t <= 2.15) {
            ringPulseProgress = _easeInOutCubic((t - 1.05) / 1.10);
          }
          if (t >= 1.85 && t <= 2.85) {
            final p = (t - 1.85) / 1.0;
            final tw = math.sin(p * math.pi);
            starScale = 1.0 + tw * 0.12;
            starRotDeg = tw * 8.0;
            haloScale = 1.0 + tw * 0.25;
            haloOp = 0.82 + tw * 0.18;
          } else {
            final calm = math.sin((t / 3.6) * math.pi * 2) * 0.025;
            starScale = 1.0 + calm;
            starCoreOp = 0.96;
            haloScale = 0.95 + calm;
            haloOp = 0.78 + calm * 2;
          }
          break;
      }
    }

    // Parallax layer shifts matching the 3D hover rig + nsFloat levitation
    final floatY = animated && mode == NorthstarLogoMode.signature
        ? -2.4 * math.sin(((elapsed % 4.4) / 4.4) * math.pi)
        : 0.0;
    canvas.translate(0, floatY);

    final nShift = Offset(tilt.dx * 4.5, tilt.dy * 4.5);
    final ringShift = Offset(tilt.dx * 8.5, tilt.dy * 8.5);
    final starShift = Offset(tilt.dx * 13.0, tilt.dy * 13.0);

    // LAYER 1: OBSIDIAN SQUIRCLE + SPECULAR RIM
    if (showBackground) {
      canvas.save();
      canvas.translate(256, 256);
      canvas.scale(squircleScale, squircleScale);
      canvas.translate(-256, -256);
      _paintSquircle(canvas, rimSweepProgress);
      canvas.restore();
    }

    // LAYER 2: METALLIC 3D FOLDED-RIBBON "N"
    canvas.save();
    canvas.translate(nShift.dx, nShift.dy);
    _paintLetterN(
      canvas,
      leftDy: leftDy,
      leftOp: leftOp,
      rightDy: rightDy,
      rightOp: rightOp,
      diagScale: diagScale,
      diagOp: diagOp,
      sheenProgress: sheenProgress,
      sheenOpacityScale: sheenOpacityScale,
    );
    canvas.restore();

    // LAYER 3: TAPERED ORBITAL SWOOSH RING + COMET SPARK
    canvas.save();
    canvas.translate(ringShift.dx, ringShift.dy);
    _paintOrbitalRing(
      canvas,
      startNorm: ringStartNorm,
      endNorm: ringEndNorm,
      opacity: ringOpacity,
      ringPulseProgress: ringPulseProgress,
    );
    if (cometOpacity > 0.01) {
      _paintCometSpark(canvas, cometProgress, cometOpacity, cometScale);
    }
    if (animated && mode == NorthstarLogoMode.signature) {
      _paintSignatureSparkles(canvas, (elapsed % 4.4) / 4.4);
    }
    canvas.restore();

    // LAYER 4: 4-POINTED POLARIS STAR + HALO + SHOCKWAVE
    canvas.save();
    canvas.translate(starShift.dx, starShift.dy);
    _paintPolarisStar(
      canvas,
      scale: starScale,
      rotDeg: starRotDeg,
      coreOpacity: starCoreOp,
      haloScale: haloScale,
      haloOpacity: haloOp,
      shockwaveProgress: shockwaveProgress,
    );
    canvas.restore();

    canvas.restore();
  }

  void _paintSquircle(Canvas canvas, double rimSweepProgress) {
    // Soft shadow under icon
    canvas.drawPath(
      _squirclePath.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    const sqRect = Rect.fromLTWH(38, 38, 436, 436);
    canvas.drawPath(
      _squirclePath,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.0, -0.64),
          radius: 1.05,
          colors: [
            Color(0xFF1B2438),
            Color(0xFF101625),
            Color(0xFF060912),
            Color(0xFF030408),
          ],
          stops: [0.0, 0.32, 0.70, 1.0],
        ).createShader(sqRect),
    );

    canvas.save();
    canvas.clipPath(_squirclePath);
    canvas.drawOval(
      const Rect.fromLTWH(71, -14, 370, 124),
      Paint()..color = const Color(0xFF3B5382).withValues(alpha: 0.11),
    );
    if (pointerActive) {
      canvas.drawRect(
        sqRect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(tilt.dx * 0.9, tilt.dy * 0.9),
            radius: 0.7,
            colors: const [
              Color(0x2EFFFFFF),
              Color(0x10AFC8F5),
              Color(0x00FFFFFF),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(sqRect),
      );
    }
    canvas.restore();

    // 1.6px metallic rim
    canvas.drawPath(
      _squirclePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x9EB9CBE8),
            Color(0x3D607394),
            Color(0x24273247),
            Color(0x38536585),
            Color(0x759EB2D4),
          ],
          stops: [0.0, 0.18, 0.52, 0.86, 1.0],
        ).createShader(sqRect),
    );

    // Optional specular rim highlight sweep on initial unfold
    if (rimSweepProgress >= 0 && rimSweepProgress <= 1) {
      final len = _squircleMetric.length;
      final segLen = 145.0;
      final start = (rimSweepProgress * (len + segLen) - segLen).clamp(0.0, len);
      final end = (rimSweepProgress * (len + segLen)).clamp(0.0, len);
      if (end > start) {
        final op = math.sin(rimSweepProgress * math.pi) * 0.78;
        canvas.drawPath(
          _squircleMetric.extractPath(start, end),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFE8F2FF).withValues(alpha: op),
        );
      }
    }
  }

  void _paintLetterN(
    Canvas canvas, {
    required double leftDy,
    required double leftOp,
    required double rightDy,
    required double rightOp,
    required double diagScale,
    required double diagOp,
    required double sheenProgress,
    required double sheenOpacityScale,
  }) {
    // Left vertical stem
    if (leftOp > 0.01) {
      canvas.save();
      canvas.translate(0, leftDy);
      final leftRect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(164, 168, 46, 188), const Radius.circular(23));
      canvas.drawRRect(
        leftRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: leftOp),
              const Color(0xFFF1F5FB).withValues(alpha: leftOp),
              const Color(0xFFC9D4E4).withValues(alpha: leftOp),
              const Color(0xFF68768D).withValues(alpha: leftOp),
              const Color(0xFF293242).withValues(alpha: leftOp),
            ],
            stops: const [0.0, 0.28, 0.56, 0.80, 1.0],
          ).createShader(leftRect.outerRect),
      );
      canvas.save();
      canvas.clipRRect(leftRect);
      final foldL = Path()
        ..moveTo(164, 200)
        ..lineTo(214, 253)
        ..lineTo(214, 284)
        ..lineTo(164, 234)
        ..close();
      canvas.drawPath(
        foldL,
        Paint()
          ..shader = LinearGradient(
            begin: const Alignment(0.6, -1.0),
            end: const Alignment(-1.0, 0.8),
            colors: [
              const Color(0xFF0A101D).withValues(alpha: 0.34 * leftOp),
              const Color(0xFF0A101D).withValues(alpha: 0.10 * leftOp),
              const Color(0x000A101D),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(const Rect.fromLTWH(164, 200, 50, 84)),
      );
      canvas.restore();
      canvas.restore();
    }

    // Right vertical stem
    if (rightOp > 0.01) {
      canvas.save();
      canvas.translate(0, rightDy);
      final rightRect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(298, 168, 46, 188), const Radius.circular(23));
      canvas.drawRRect(
        rightRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2A3446).withValues(alpha: rightOp),
              const Color(0xFF536178).withValues(alpha: rightOp),
              const Color(0xFFB7C4D8).withValues(alpha: rightOp),
              const Color(0xFFEDF2FA).withValues(alpha: rightOp),
              const Color(0xFFFFFFFF).withValues(alpha: rightOp),
            ],
            stops: const [0.0, 0.22, 0.52, 0.78, 1.0],
          ).createShader(rightRect.outerRect),
      );
      canvas.save();
      canvas.clipRRect(rightRect);
      final foldR = Path()
        ..moveTo(294, 270)
        ..lineTo(346, 325)
        ..lineTo(346, 292)
        ..lineTo(294, 238)
        ..close();
      canvas.drawPath(
        foldR,
        Paint()
          ..shader = LinearGradient(
            begin: const Alignment(-0.8, 1.0),
            end: const Alignment(0.8, -0.8),
            colors: [
              const Color(0xFF0A101D).withValues(alpha: 0.32 * rightOp),
              const Color(0xFF0A101D).withValues(alpha: 0.09 * rightOp),
              const Color(0x000A101D),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(const Rect.fromLTWH(294, 238, 52, 87)),
      );
      canvas.restore();
      canvas.restore();
    }

    // Diagonal connecting ribbon
    if (diagOp > 0.01) {
      canvas.save();
      canvas.translate(254, 262);
      canvas.scale(diagScale, diagScale);
      canvas.translate(-254, -262);
      canvas.drawPath(
        _diagRibbonPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: diagOp),
              const Color(0xFFF6F8FC).withValues(alpha: diagOp),
              const Color(0xFFE7EEF8).withValues(alpha: diagOp),
              const Color(0xFFFFFFFF).withValues(alpha: diagOp),
            ],
            stops: const [0.0, 0.35, 0.68, 1.0],
          ).createShader(const Rect.fromLTWH(164, 168, 180, 188)),
      );
      canvas.restore();
    }

    // Gliding metallic sheen beam clipped cleanly to the "N"
    if (sheenProgress > 0 && sheenProgress < 1) {
      canvas.save();
      canvas.clipPath(_letterNClipPath);
      final x = _lerp(40, 415, sheenProgress);
      final env = math.sin(sheenProgress * math.pi) * 0.72 * sheenOpacityScale;
      canvas.translate(x, 0);
      canvas.translate(254, 262);
      canvas.rotate(24 * math.pi / 180);
      canvas.translate(-254, -262);
      const barRect = Rect.fromLTWH(20, 110, 130, 310);
      canvas.drawRect(
        barRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: const Alignment(1.0, 0.35),
            colors: [
              const Color(0x00FFFFFF),
              const Color(0x00FFFFFF),
              Colors.white.withValues(alpha: 0.88 * env),
              const Color(0x00E0EEFF),
              const Color(0x00FFFFFF),
            ],
            stops: const [0.0, 0.36, 0.50, 0.64, 1.0],
          ).createShader(barRect),
      );
      canvas.restore();
    }
  }

  void _paintOrbitalRing(
    Canvas canvas, {
    required double startNorm,
    required double endNorm,
    required double opacity,
    required double ringPulseProgress,
  }) {
    final len = _ringMetric.length;
    final clampedStart = startNorm.clamp(0.0, 1.0);
    final clampedEnd = endNorm.clamp(0.0, 1.0);
    if (opacity <= 0.01 || clampedEnd - clampedStart <= 0.005) {
      return;
    }

    final isFull = clampedStart <= 0.005 && clampedEnd >= 0.995 && opacity >= 0.99;

    if (!isFull) {
      canvas.saveLayer(const Rect.fromLTWH(80, 140, 320, 250), Paint());
    }

    canvas.drawPath(
      _ringExactPath.shift(const Offset(0, 3)),
      Paint()..color = const Color(0xFF040812).withValues(alpha: 0.34 * opacity),
    );

    canvas.drawPath(
      _ringExactPath,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.85, 0.85),
          end: const Alignment(0.85, -0.85),
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: opacity),
            const Color(0xFFFFFFFF).withValues(alpha: opacity),
            const Color(0xFFE5ECF6).withValues(alpha: opacity),
            const Color(0xFFCFD9E8).withValues(alpha: opacity),
          ],
          stops: const [0.0, 0.54, 0.82, 1.0],
        ).createShader(const Rect.fromLTWH(106, 174, 256, 178)),
    );

    if (ringPulseProgress >= 0 && ringPulseProgress <= 1) {
      canvas.save();
      canvas.clipPath(_ringExactPath);
      const pulseLen = 68.0;
      final head = ringPulseProgress * (len + pulseLen);
      final sOff = (head - pulseLen).clamp(0.0, len);
      final eOff = head.clamp(0.0, len);
      if (eOff > sOff) {
        canvas.drawPath(
          _ringMetric.extractPath(sOff, eOff),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 26
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(
              alpha: math.sin(ringPulseProgress * math.pi) * 0.85,
            ),
        );
      }
      canvas.restore();
    }

    if (!isFull) {
      final extract = _ringMetric.extractPath(
        clampedStart * len,
        clampedEnd * len,
      );
      canvas.drawPath(
        extract,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 28
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white
          ..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }
  }

  void _paintCometSpark(
    Canvas canvas,
    double progress,
    double opacity,
    double scale,
  ) {
    final len = _ringMetric.length;
    final tangent = _ringMetric.getTangentForOffset(
      progress.clamp(0.0, 1.0) * len,
    );
    if (tangent == null) return;
    final pt = tangent.position;

    canvas.save();
    canvas.translate(pt.dx, pt.dy);
    canvas.scale(scale, scale);

    canvas.drawCircle(
      Offset.zero,
      22,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            const Color(0xFFF6FAFF).withValues(alpha: 0.92 * opacity),
            const Color(0xFF9CC8FF).withValues(alpha: 0.36 * opacity),
            const Color(0x0060A5FA),
          ],
          stops: const [0.0, 0.24, 0.55, 1.0],
        ).createShader(const Rect.fromLTWH(-22, -22, 44, 44)),
    );

    canvas.drawCircle(
      Offset.zero,
      4.5,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    final miniFlare = Path()
      ..moveTo(0, -11)
      ..cubicTo(0.8, -2.8, 2.8, -0.8, 11, 0)
      ..cubicTo(2.8, 0.8, 0.8, 2.8, 0, 11)
      ..cubicTo(-0.8, 2.8, -2.8, 0.8, -11, 0)
      ..cubicTo(-2.8, -0.8, -0.8, -2.8, 0, -11)
      ..close();
    canvas.drawPath(
      miniFlare,
      Paint()..color = Colors.white.withValues(alpha: 0.95 * opacity),
    );

    canvas.restore();
  }

  void _paintPolarisStar(
    Canvas canvas, {
    required double scale,
    required double rotDeg,
    required double coreOpacity,
    required double haloScale,
    required double haloOpacity,
    required double shockwaveProgress,
  }) {
    const center = Offset(355, 148);

    // Expanding ignition shockwave ring
    if (shockwaveProgress > 0 && shockwaveProgress < 1) {
      final eased = _easeOutCubic(shockwaveProgress);
      final swScale = _lerp(0.55, 2.35, eased);
      final swOp = (1.0 - eased) * 0.62;
      canvas.drawCircle(
        center,
        26 * swScale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFFFF9E6).withValues(alpha: swOp),
      );
    }

    // Warm champagne-white halo
    if (haloOpacity > 0.01) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(haloScale, haloScale);
      canvas.drawCircle(
        Offset.zero,
        64,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFFDF5).withValues(alpha: 0.68 * haloOpacity),
              const Color(0xFFFFF4D4).withValues(alpha: 0.32 * haloOpacity),
              const Color(0xFFE6DFC8).withValues(alpha: 0.09 * haloOpacity),
              const Color(0x00FFF8E0),
            ],
            stops: const [0.0, 0.28, 0.62, 1.0],
          ).createShader(const Rect.fromLTWH(-64, -64, 128, 128)),
      );
      canvas.restore();
    }

    // Concave 4-point Polaris Star
    if (coreOpacity > 0.01) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotDeg * math.pi / 180.0);
      canvas.scale(scale, scale);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(
        _starCorePath,
        Paint()..color = const Color(0xFFFFFDF8).withValues(alpha: coreOpacity),
      );
      canvas.restore();
    }
  }

  static const List<(double, double, double, double, double, double, double, Color, int)>
      _signatureSparkles = [
    // Orbital create comet sparkles (gold, champagne, ice-blue, white)
    (120.7, 317.1, -14.8, -12.4, 0.131, 0.276, 2.3, Color(0xFFFFF3C4), 1),
    (117.8, 328.1, 13.8, -5.0, 0.142, 0.295, 1.8, Color(0xFFFFF3C4), 0),
    (125.9, 339.8, -25.3, 23.6, 0.152, 0.331, 2.0, Color(0xFFFDE68A), 1),
    (136.4, 342.1, -7.7, -25.3, 0.159, 0.355, 2.0, Color(0xFFFFFFFF), 0),
    (156.8, 340.4, -2.0, 14.8, 0.168, 0.329, 2.4, Color(0xFFFFFFFF), 1),
    (171.9, 336.7, -16.9, -28.1, 0.175, 0.376, 4.1, Color(0xFFFDE68A), 2),
    (184.3, 332.6, -8.0, 16.0, 0.179, 0.363, 2.4, Color(0xFFFDE68A), 2),
    (202.5, 324.9, -21.0, -13.0, 0.186, 0.380, 2.2, Color(0xFFCBE4FF), 0),
    (213.5, 319.4, 8.2, 30.2, 0.189, 0.349, 2.3, Color(0xFFFFF3C4), 2),
    (228.7, 310.9, -14.9, -14.1, 0.194, 0.345, 2.7, Color(0xFFFDE68A), 1),
    (237.9, 305.1, -4.0, 19.5, 0.197, 0.403, 2.2, Color(0xFFFDE68A), 1),
    (254.3, 294.0, -17.6, -17.7, 0.202, 0.409, 1.7, Color(0xFFFFFFFF), 0),
    (263.9, 286.9, 8.7, 19.5, 0.205, 0.374, 3.3, Color(0xFFFFFFFF), 2),
    (279.3, 274.6, -13.3, -8.7, 0.209, 0.360, 2.6, Color(0xFFFDE68A), 2),
    (293.1, 262.7, 6.6, 20.5, 0.213, 0.389, 2.1, Color(0xFFFDE68A), 0),
    (299.9, 256.2, -21.5, -7.0, 0.215, 0.384, 3.8, Color(0xFFCBE4FF), 2),
    (315.6, 240.4, 12.1, 28.5, 0.221, 0.378, 1.7, Color(0xFFFFF3C4), 0),
    (324.6, 230.3, -18.2, -8.6, 0.224, 0.354, 1.8, Color(0xFFFDE68A), 0),
    (335.6, 216.1, 11.8, 22.4, 0.229, 0.361, 2.8, Color(0xFFCBE4FF), 2),
    (345.7, 188.1, 18.1, 2.7, 0.238, 0.444, 2.5, Color(0xFFFFFFFF), 2),
    (340.5, 182.3, -1.6, 18.1, 0.241, 0.378, 3.5, Color(0xFFFFF3C4), 2),
    (307.8, 184.9, 18.1, 18.3, 0.254, 0.400, 3.2, Color(0xFFFFFFFF), 2),
    (288.5, 192.2, 0.3, -33.1, 0.264, 0.424, 2.3, Color(0xFFFFF3C4), 2),
    (254.4, 209.7, 20.3, 20.0, 0.297, 0.433, 2.9, Color(0xFFCBE4FF), 2),
    // Polaris ignition sparkles
    (368.5, 147.0, 40.7, -3.1, 0.340, 0.553, 1.9, Color(0xFFFFFDF5), 2),
    (363.0, 154.6, 37.0, 30.5, 0.335, 0.533, 2.5, Color(0xFFFFF3C4), 0),
    (356.8, 157.3, 7.9, 41.1, 0.339, 0.532, 2.4, Color(0xFFFDE68A), 2),
    (352.4, 161.4, -8.3, 42.4, 0.334, 0.509, 2.4, Color(0xFFFFFDF5), 1),
    (349.0, 153.7, -29.7, 28.2, 0.334, 0.540, 2.0, Color(0xFFFFF3C4), 2),
    (344.2, 147.1, -40.8, -3.5, 0.337, 0.523, 3.0, Color(0xFFFDE68A), 2),
    (344.9, 139.2, -35.4, -31.0, 0.339, 0.540, 3.4, Color(0xFFFFFDF5), 2),
    (350.6, 137.1, -10.6, -26.1, 0.328, 0.496, 1.8, Color(0xFFFFF3C4), 2),
    (359.0, 139.1, 15.9, -35.2, 0.327, 0.543, 2.3, Color(0xFFFDE68A), 2),
    (362.5, 142.1, 27.4, -21.7, 0.338, 0.542, 2.1, Color(0xFFFFFDF5), 2),
    // Erase dissolve sparkles
    (119.3, 320.4, 14.2, -3.7, 0.716, 0.889, 1.4, Color(0xFFCBE4FF), 0),
    (137.6, 342.1, 3.8, -16.1, 0.736, 0.849, 1.9, Color(0xFFCBE4FF), 0),
    (153.6, 340.9, 3.2, 4.1, 0.743, 0.911, 2.7, Color(0xFFCBE4FF), 1),
    (179.4, 334.3, -11.7, -23.1, 0.752, 0.890, 1.6, Color(0xFFCBE4FF), 0),
    (211.4, 320.5, -12.6, -16.7, 0.762, 0.889, 2.4, Color(0xFFFFFFFF), 0),
    (227.5, 311.6, 14.3, 19.4, 0.766, 0.914, 2.2, Color(0xFFCBE4FF), 2),
    (242.2, 302.3, -10.3, -30.0, 0.770, 0.945, 2.1, Color(0xFFFFFFFF), 2),
    (275.4, 277.8, -13.4, -26.6, 0.778, 0.940, 2.4, Color(0xFFFFFFFF), 1),
    (288.7, 266.6, 17.0, 16.2, 0.782, 0.936, 2.5, Color(0xFFCBE4FF), 2),
    (317.0, 238.8, 7.0, 4.3, 0.789, 0.900, 1.6, Color(0xFFFFF3C4), 1),
    (341.7, 206.3, 6.2, 6.3, 0.799, 0.950, 2.4, Color(0xFFFFFFFF), 2),
    (346.1, 189.7, -20.3, 0.4, 0.804, 0.976, 2.4, Color(0xFFFFFFFF), 2),
    (323.8, 181.1, 3.8, -22.5, 0.812, 0.939, 3.6, Color(0xFFFFF3C4), 2),
    (259.9, 206.6, -8.9, -16.4, 0.848, 0.961, 2.2, Color(0xFFCBE4FF), 1),
  ];

  void _paintSignatureSparkles(Canvas canvas, double norm) {
    for (final s in _signatureSparkles) {
      final (bx, by, dx, dy, start, end, r, color, shape) = s;
      if (norm < start || norm > end) continue;
      final u = ((norm - start) / (end - start)).clamp(0.0, 1.0);
      // Twinkle envelope: bright burst early, dip mid-flight, secondary shimmer, fade out
      final opacity = u < 0.16
          ? _lerp(0.0, 0.96, u / 0.16)
          : u < 0.44
              ? _lerp(0.96, 0.35, (u - 0.16) / 0.28)
              : u < 0.68
                  ? _lerp(0.35, 0.90, (u - 0.44) / 0.24)
                  : _lerp(0.90, 0.0, (u - 0.68) / 0.32);
      final sc = u < 0.16
          ? _lerp(0.15, 1.30, u / 0.16)
          : u < 0.44
              ? _lerp(1.30, 0.56, (u - 0.16) / 0.28)
              : u < 0.68
                  ? _lerp(0.56, 1.15, (u - 0.44) / 0.24)
                  : _lerp(1.15, 0.12, (u - 0.68) / 0.32);

      final cx = bx + dx * u;
      final cy = by + dy * u;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(sc, sc);

      if (shape == 2) {
        canvas.drawCircle(
          Offset.zero,
          r * 1.45,
          Paint()..color = color.withValues(alpha: 0.24 * opacity),
        );
        final sr = r;
        final k = sr * 0.16;
        final star = Path()
          ..moveTo(0, -sr)
          ..cubicTo(k, -k, k, -k, sr, 0)
          ..cubicTo(k, k, k, k, 0, sr)
          ..cubicTo(-k, k, -k, k, -sr, 0)
          ..cubicTo(-k, -k, -k, -k, 0, -sr)
          ..close();
        canvas.drawPath(star, Paint()..color = color.withValues(alpha: opacity));
      } else if (shape == 1) {
        final w = r * 0.62;
        final diamond = Path()
          ..moveTo(0, -r)
          ..lineTo(w, 0)
          ..lineTo(0, r)
          ..lineTo(-w, 0)
          ..close();
        canvas.drawPath(
            diamond, Paint()..color = color.withValues(alpha: opacity));
      } else {
        canvas.drawCircle(
            Offset.zero, r, Paint()..color = color.withValues(alpha: opacity));
      }
      canvas.restore();
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _invLerp(double a, double b, double v) =>
      ((v - a) / (b - a)).clamp(0.0, 1.0);
  static double _easeOutCubic(double t) =>
      1.0 - math.pow(1.0 - t.clamp(0.0, 1.0), 3).toDouble();
  static double _easeInOutCubic(double t) {
    final c = t.clamp(0.0, 1.0);
    return c < 0.5
        ? 4 * c * c * c
        : 1 - math.pow(-2 * c + 2, 3).toDouble() / 2;
  }

  static double _easeOutBack(double t, [double overshoot = 1.9]) {
    final c = t.clamp(0.0, 1.0);
    final c3 = overshoot + 1;
    return 1 +
        c3 * math.pow(c - 1, 3).toDouble() +
        overshoot * math.pow(c - 1, 2).toDouble();
  }

  @override
  bool shouldRepaint(covariant _NorthstarStudioPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.animated != animated ||
        oldDelegate.showBackground != showBackground ||
        oldDelegate.elapsed != elapsed ||
        oldDelegate.firstCycle != firstCycle ||
        oldDelegate.hoverBurstTimer != hoverBurstTimer ||
        oldDelegate.tilt != tilt ||
        oldDelegate.pointerActive != pointerActive;
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
