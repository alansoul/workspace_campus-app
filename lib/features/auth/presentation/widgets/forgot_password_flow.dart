import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';
import 'auth_form_fields.dart';
import 'otp_code_boxes.dart';
import 'password_strength_checklist.dart';

/// Two-step password recovery flow: send reset OTP -> verify code & set password.
class ForgotPasswordFlow extends ConsumerStatefulWidget {
  final String initialEmail;
  final VoidCallback onCancel;

  const ForgotPasswordFlow({
    super.key,
    required this.initialEmail,
    required this.onCancel,
  });

  @override
  ConsumerState<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends ConsumerState<ForgotPasswordFlow> {
  late final TextEditingController _emailController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  String _otpCode = '';
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim().toLowerCase();
    final notifier = ref.read(authFlowControllerProvider.notifier);

    if (email.isEmpty || !email.contains('@')) {
      notifier.setValidationError('Please enter your registered email address.');
      return;
    }

    final ok = await notifier.requestOtp(
      email: email,
      purpose: OtpPurpose.resetPassword,
      advanceToVerifyStep: false,
    );
    if (ok && mounted) {
      setState(() {
        _codeSent = true;
        _otpCode = '';
      });
    }
  }

  Future<void> _submitReset() async {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final email = _emailController.text.trim().toLowerCase();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (_otpCode.length < 6) {
      notifier.setValidationError('Enter the 6-digit verification code.');
      return;
    }
    if (newPassword.length < 8) {
      notifier.setValidationError('Password must be at least 8 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      notifier.setValidationError('Passwords do not match.');
      return;
    }

    await notifier.resetPassword(
      email: email,
      otp: _otpCode,
      newPassword: newPassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(authFlowControllerProvider);
    final isLoading = flowState.isLoading;

    if (!_codeSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_reset_rounded,
                    size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter the email linked to your account and we will send a 6-digit code to reset your password.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FluidTextField(
            controller: _emailController,
            label: 'Account email',
            hint: 'student@univ.edu.in or you@gmail.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onSubmitted: (_) => _sendResetCode(),
          ),
          const SizedBox(height: 18),
          FluidPrimaryButton(
            label: 'Send Verification Code',
            trailingIcon: Icons.arrow_forward_rounded,
            isLoading: isLoading,
            onPressed: _sendResetCode,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: isLoading ? null : widget.onCancel,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to Sign In'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    final email = _emailController.text.trim().toLowerCase();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit code sent to $email and create a strong new password.',
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        OtpCodeBoxes(
          value: _otpCode,
          enabled: !isLoading,
          onChanged: (code) => setState(() => _otpCode = code),
        ),
        const SizedBox(height: 8),
        OtpResendBar(
          isLoading: isLoading,
          onResend: _sendResetCode,
        ),
        const SizedBox(height: 12),
        FluidTextField(
          controller: _newPasswordController,
          label: 'New password',
          hint: 'At least 8 characters',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureNew,
          enabled: !isLoading,
          onChanged: (_) => setState(() {}),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNew
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 12),
        FluidTextField(
          controller: _confirmPasswordController,
          label: 'Confirm new password',
          hint: 'Re-enter new password',
          prefixIcon: Icons.verified_outlined,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submitReset(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 12),
        PasswordStrengthChecklist(
          password: newPass,
          confirmPassword: confirmPass,
        ),
        const SizedBox(height: 18),
        FluidPrimaryButton(
          label: 'Reset Password & Sign In',
          isLoading: isLoading,
          onPressed: (_otpCode.length == 6 &&
                  newPass.length >= 8 &&
                  newPass == confirmPass)
              ? _submitReset
              : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isLoading ? null : widget.onCancel,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}
