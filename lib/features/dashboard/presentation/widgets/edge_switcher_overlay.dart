import 'dart:ui';
import 'package:flutter/material.dart';

class EdgeSwitcherOverlay extends StatefulWidget {
  final Widget child;
  final Function(int) onSelectApp;
  final VoidCallback onOpenAi;

  const EdgeSwitcherOverlay({
    super.key,
    required this.child,
    required this.onSelectApp,
    required this.onOpenAi,
  });

  @override
  State<EdgeSwitcherOverlay> createState() => _EdgeSwitcherOverlayState();
}

class _EdgeSwitcherOverlayState extends State<EdgeSwitcherOverlay> {
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Tap-outside barrier when edge panel is expanded
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),
          ),

        // Slide-out Dock + Handle
        AnimatedPositioned(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          right: _isOpen ? 0 : -80,
          top: MediaQuery.of(context).size.height * 0.32,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edge Trigger Pill (Always accessible on the right bezel)
              GestureDetector(
                onTap: _toggle,
                onHorizontalDragUpdate: (details) {
                  if (details.primaryDelta! < -4 && !_isOpen) _toggle();
                  if (details.primaryDelta! > 4 && _isOpen) _toggle();
                },
                child: Container(
                  width: 14,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),

              // Frosted-Glass Floating Quick-Switcher Dock
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dockIconButton(
                          icon: Icons.school_rounded,
                          color: const Color(0xFF2563EB),
                          tooltip: 'Academics',
                          onTap: () {
                            _toggle();
                            widget.onSelectApp(0);
                          },
                        ),
                        const SizedBox(height: 14),
                        _dockIconButton(
                          icon: Icons.forum_rounded,
                          color: const Color(0xFF7C3AED),
                          tooltip: 'Channels',
                          onTap: () {
                            _toggle();
                            widget.onSelectApp(1);
                          },
                        ),
                        const SizedBox(height: 14),
                        _dockIconButton(
                          icon: Icons.work_rounded,
                          color: const Color(0xFFD97706),
                          tooltip: 'Freelance',
                          onTap: () {
                            _toggle();
                            widget.onSelectApp(2);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Divider(height: 1),
                        ),
                        _dockIconButton(
                          icon: Icons.auto_awesome,
                          color: const Color(0xFF0B57D0),
                          tooltip: 'Campus AI',
                          onTap: () {
                            _toggle();
                            widget.onOpenAi();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dockIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 24),
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}