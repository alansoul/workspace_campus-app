import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// Custom 6-digit fluid OTP verification boxes supporting paste and auto-advance.
class OtpCodeBoxes extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final bool enabled;

  const OtpCodeBoxes({
    super.key,
    required this.value,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  State<OtpCodeBoxes> createState() => _OtpCodeBoxesState();
}

class _OtpCodeBoxesState extends State<OtpCodeBoxes> {
  static const int _length = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());
    _syncFromExternalValue(widget.value);
  }

  @override
  void didUpdateWidget(covariant OtpCodeBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _combinedCode()) {
      _syncFromExternalValue(widget.value);
    }
  }

  void _syncFromExternalValue(String code) {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _length; i++) {
      final char = i < digits.length ? digits[i] : '';
      if (_controllers[i].text != char) {
        _controllers[i].text = char;
      }
    }
  }

  String _combinedCode() => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleDigitChange(int index, String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    // Handle multi-digit paste from clipboard / SMS autofill
    if (digits.length > 1) {
      for (var i = 0; i < _length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final combined = _combinedCode();
      widget.onChanged(combined);
      if (combined.length == _length) {
        _focusNodes.last.unfocus();
        widget.onCompleted?.call();
      } else {
        final nextIdx = digits.length.clamp(0, _length - 1);
        _focusNodes[nextIdx].requestFocus();
      }
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection =
        TextSelection.collapsed(offset: digits.length);

    if (digits.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final combined = _combinedCode();
    widget.onChanged(combined);
    if (combined.length == _length) {
      widget.onCompleted?.call();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, (index) {
        final hasDigit = _controllers[index].text.isNotEmpty;
        final isFocused = _focusNodes[index].hasFocus;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: index == 0 || index == 5 ? 2 : 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              decoration: BoxDecoration(
                color: hasDigit
                    ? AppColors.primaryContainer
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFocused
                      ? AppColors.primary
                      : (hasDigit
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : AppColors.border),
                  width: isFocused ? 1.8 : 1.2,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => setState(() {}),
                  onChanged: (val) => _handleDigitChange(index, val),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Resend OTP action link with an automatic countdown timer.
class OtpResendBar extends StatefulWidget {
  final Future<void> Function() onResend;
  final bool isLoading;

  const OtpResendBar({
    super.key,
    required this.onResend,
    this.isLoading = false,
  });

  @override
  State<OtpResendBar> createState() => _OtpResendBarState();
}

class _OtpResendBarState extends State<OtpResendBar> {
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft == 0 && !widget.isLoading;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          const Text(
            "Didn't receive the code?",
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: canResend
                ? () async {
                    await widget.onResend();
                    if (mounted) _startCooldown();
                  }
                : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _secondsLeft > 0
                  ? 'Request again in ${_secondsLeft}s'
                  : 'Request again',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: canResend ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
