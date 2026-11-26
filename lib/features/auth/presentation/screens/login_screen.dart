import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/domain_status_banner.dart';
import '../widgets/fluid_auth_backdrop.dart';
import '../widgets/forgot_password_flow.dart';
import '../widgets/otp_code_boxes.dart';
import '../widgets/password_strength_checklist.dart';
import '../widgets/segmented_pill_switch.dart';
import '../widgets/university_onboarding_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _domainDebounce;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _otpCode = '';

  @override
  void dispose() {
    _domainDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    _domainDebounce?.cancel();
    _domainDebounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) {
        ref.read(authFlowControllerProvider.notifier).resolveDomain(value);
      }
    });
  }

  Future<void> _submitCredentials() async {
    final flow = ref.read(authFlowControllerProvider);
    final notifier = ref.read(authFlowControllerProvider.notifier);

    final email = _emailController.text.trim().toLowerCase();
    final fullName = _nameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      notifier.setValidationError('Please enter a valid email address.');
      return;
    }

    final domainRes = flow.domainResolution;
    if (domainRes != null && !domainRes.allowed) {
      notifier.setValidationError(
        domainRes.errorMessage ??
            'Only @gmail.com or registered university domains are allowed.',
      );
      return;
    }

    if (flow.mode == AuthMode.signUp) {
      if (fullName.length < 2) {
        notifier.setValidationError('Please enter your full name.');
        return;
      }
      await notifier.requestOtp(email: email, purpose: OtpPurpose.register);
      setState(() => _otpCode = '');
      return;
    }

    if (flow.method == AuthMethod.otp) {
      await notifier.requestOtp(email: email, purpose: OtpPurpose.login);
      setState(() => _otpCode = '');
      return;
    }

    if (password.isEmpty) {
      notifier.setValidationError('Please enter your password.');
      return;
    }
    await notifier.signInWithPassword(email: email, password: password);
  }

  Future<void> _submitOtpVerification() async {
    final flow = ref.read(authFlowControllerProvider);
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final email = _emailController.text.trim().toLowerCase();

    if (_otpCode.length < 6) {
      notifier.setValidationError('Enter the 6-digit verification code.');
      return;
    }

    await notifier.verifyOtp(
      email: email,
      otp: _otpCode,
      fullName:
          flow.mode == AuthMode.signUp ? _nameController.text.trim() : null,
    );
  }

  Future<void> _submitSetPassword() async {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final email = _emailController.text.trim().toLowerCase();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8) {
      notifier.setValidationError('Password must be at least 8 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      notifier.setValidationError('Passwords do not match.');
      return;
    }

    await notifier.completePasswordSetup(
      email: email,
      password: newPassword,
      fullName: _nameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(authFlowControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.auroraLavender,
      body: FluidAuthBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FrostedGlassCard(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBrandHeader(flow),
                    const SizedBox(height: 18),
                    if (flow.errorMessage != null) ...[
                      AuthFeedbackBanner(
                        message: flow.errorMessage!,
                        isError: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (flow.infoMessage != null) ...[
                      AuthFeedbackBanner(
                        message: flow.infoMessage!,
                        isError: false,
                      ),
                      const SizedBox(height: 12),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildCurrentStep(flow),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _UniversityOnboardingCard(
              onTap: () => UniversityOnboardingSheet.show(context),
            ),
            const SizedBox(height: 12),
            const Text(
              'By continuing, you agree to Northstar Terms & Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader(AuthFlowState flow) {
    String subtitle;
    switch (flow.step) {
      case AuthStep.verifyOtp:
        subtitle =
            'Enter the 6-digit code sent to ${_emailController.text.trim()}';
        break;
      case AuthStep.setPassword:
        subtitle = 'Email verified! Create a password to secure your workspace.';
        break;
      case AuthStep.forgotPassword:
        subtitle = 'Reset your password safely with 6-digit OTP verification.';
        break;
      case AuthStep.credentials:
        subtitle = flow.mode == AuthMode.signIn
            ? 'Welcome back! Sign in with password or one-time code.'
            : 'Verify your university or @gmail.com email to get started.';
    }

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF38BDF8), AppColors.primary, AppColors.accentIndigo],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Northstar Workspace',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(AuthFlowState flow) {
    switch (flow.step) {
      case AuthStep.verifyOtp:
        return KeyedSubtree(
          key: const ValueKey('step_verify_otp'),
          child: _buildVerifyOtpStep(flow),
        );
      case AuthStep.setPassword:
        return KeyedSubtree(
          key: const ValueKey('step_set_password'),
          child: _buildSetPasswordStep(flow),
        );
      case AuthStep.forgotPassword:
        return KeyedSubtree(
          key: const ValueKey('step_forgot_password'),
          child: ForgotPasswordFlow(
            initialEmail: _emailController.text.trim(),
            onCancel: () => ref
                .read(authFlowControllerProvider.notifier)
                .goToStep(AuthStep.credentials),
          ),
        );
      case AuthStep.credentials:
        return KeyedSubtree(
          key: const ValueKey('step_credentials'),
          child: _buildCredentialsStep(flow),
        );
    }
  }

  Widget _buildCredentialsStep(AuthFlowState flow) {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final isSignUp = flow.mode == AuthMode.signUp;
    final isOtpMethod = isSignUp || flow.method == AuthMethod.otp;
    final hasInvalidDomain =
        flow.domainResolution != null && !flow.domainResolution!.allowed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedPillSwitch<AuthMode>(
          value: flow.mode,
          leftValue: AuthMode.signIn,
          rightValue: AuthMode.signUp,
          leftLabel: 'Login',
          rightLabel: 'Register',
          onChanged: notifier.switchMode,
        ),
        const SizedBox(height: 14),
        if (!isSignUp) ...[
          SegmentedPillSwitch<AuthMethod>(
            value: flow.method,
            leftValue: AuthMethod.password,
            rightValue: AuthMethod.otp,
            leftLabel: 'Password',
            rightLabel: 'OTP Code',
            leftIcon: Icons.lock_outline_rounded,
            rightIcon: Icons.mark_email_read_outlined,
            height: 40,
            activeColor: AppColors.accentIndigo,
            onChanged: notifier.switchMethod,
          ),
          const SizedBox(height: 14),
        ],
        if (isSignUp) ...[
          FluidTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g. Rohan Singh',
            prefixIcon: Icons.person_outline_rounded,
            enabled: !flow.isLoading,
          ),
          const SizedBox(height: 12),
        ],
        FluidTextField(
          controller: _emailController,
          label: 'University or @gmail.com Email',
          hint: 'student@univ.edu.in or you@gmail.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction:
              isOtpMethod ? TextInputAction.done : TextInputAction.next,
          enabled: !flow.isLoading,
          hasWarningBorder: hasInvalidDomain,
          onChanged: _onEmailChanged,
          onSubmitted: isOtpMethod ? (_) => _submitCredentials() : null,
        ),
        if (flow.isResolvingDomain || flow.domainResolution != null) ...[
          const SizedBox(height: 10),
          DomainStatusBanner(
            resolution: flow.domainResolution,
            isResolving: flow.isResolvingDomain,
          ),
        ],
        if (!isOtpMethod) ...[
          const SizedBox(height: 12),
          FluidTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !flow.isLoading,
            onSubmitted: (_) => _submitCredentials(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: flow.isLoading
                  ? null
                  : () => notifier.goToStep(AuthStep.forgotPassword),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ] else
          const SizedBox(height: 18),
        FluidPrimaryButton(
          label: isSignUp
              ? 'Verify Email & Continue'
              : (isOtpMethod ? 'Send OTP Code' : 'Sign In'),
          trailingIcon:
              isOtpMethod ? Icons.arrow_forward_rounded : Icons.login_rounded,
          isLoading: flow.isLoading,
          useDarkPill: isSignUp,
          onPressed: hasInvalidDomain ? null : _submitCredentials,
        ),
        if (flow.requiresTurnstileFallback && !isSignUp) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => notifier.switchMethod(AuthMethod.password),
            icon: const Icon(Icons.password_rounded, size: 17),
            label: const Text('Use Password Login instead'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerifyOtpStep(AuthFlowState flow) {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final email = _emailController.text.trim().toLowerCase();
    final purpose =
        flow.mode == AuthMode.signUp ? OtpPurpose.register : OtpPurpose.login;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtpCodeBoxes(
          value: _otpCode,
          enabled: !flow.isLoading,
          onChanged: (code) => setState(() => _otpCode = code),
          onCompleted: _submitOtpVerification,
        ),
        const SizedBox(height: 10),
        OtpResendBar(
          isLoading: flow.isLoading,
          onResend: () async {
            await notifier.requestOtp(
              email: email,
              purpose: purpose,
              advanceToVerifyStep: false,
            );
          },
        ),
        const SizedBox(height: 16),
        FluidPrimaryButton(
          label: 'Confirm Verification Code',
          trailingIcon: Icons.verified_rounded,
          isLoading: flow.isLoading,
          onPressed: _otpCode.length == 6 ? _submitOtpVerification : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: flow.isLoading
              ? null
              : () => notifier.goToStep(AuthStep.credentials),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Change email address'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSetPasswordStep(AuthFlowState flow) {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final pass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FluidTextField(
          controller: _newPasswordController,
          label: 'Create Password',
          hint: 'At least 8 characters',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureNewPassword,
          enabled: !flow.isLoading,
          onChanged: (_) => setState(() {}),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
        ),
        const SizedBox(height: 12),
        FluidTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          prefixIcon: Icons.verified_outlined,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          enabled: !flow.isLoading,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submitSetPassword(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: 12),
        PasswordStrengthChecklist(
          password: pass,
          confirmPassword: confirm,
        ),
        const SizedBox(height: 18),
        FluidPrimaryButton(
          label: 'Create Password & Enter Workspace',
          useDarkPill: true,
          isLoading: flow.isLoading,
          onPressed:
              (pass.length >= 8 && pass == confirm) ? _submitSetPassword : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: flow.isLoading
              ? null
              : () => notifier.goToStep(AuthStep.verifyOtp),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Back to OTP'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Bottom-anchored card inviting university administrators to onboard their campus.
class _UniversityOnboardingCard extends StatelessWidget {
  final VoidCallback onTap;

  const _UniversityOnboardingCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      borderRadius: 22,
      tintColor: Colors.white.withValues(alpha: 0.72),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Onboarding a university?',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Create an organisation workspace for your campus',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create Org',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
