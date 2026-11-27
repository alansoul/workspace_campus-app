import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/domain_status_banner.dart';
import '../widgets/fluid_auth_backdrop.dart';
import '../widgets/forgot_password_flow.dart';
import '../widgets/google_oauth_button.dart';
import '../widgets/otp_code_boxes.dart';
import '../widgets/password_strength_checklist.dart';
import '../widgets/segmented_pill_switch.dart';
import '../widgets/university_onboarding_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _domainDebounce;
  Timer? _googleResumeTimer;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _domainDebounce?.cancel();
    _googleResumeTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final flow = ref.read(authFlowControllerProvider);
      if (flow.isGoogleLoading) {
        _googleResumeTimer?.cancel();
        // Allow brief window for an in-flight localhost callback before cancelling
        _googleResumeTimer = Timer(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          if (ref.read(authFlowControllerProvider).isGoogleLoading) {
            ref.read(authFlowControllerProvider.notifier).cancelGoogleSignIn();
          }
        });
      }
    }
  }

  void _onEmailChanged(String value) {
    _domainDebounce?.cancel();
    final notifier = ref.read(authFlowControllerProvider.notifier);
    notifier.clearBanners();

    final trimmed = value.trim();
    if (!trimmed.contains('@') || !trimmed.split('@').last.contains('.')) {
      notifier.clearDomainResolution();
      return;
    }
    _domainDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(authFlowControllerProvider.notifier).resolveDomain(trimmed);
      }
    });
  }

  Future<void> _submitEmailEntry() async {
    _domainDebounce?.cancel();
    await ref.read(authFlowControllerProvider.notifier).continueFromEmail(
          email: _emailController.text.trim().toLowerCase(),
          fullName: _nameController.text.trim(),
        );
    if (mounted) {
      setState(() => _otpCode = '');
    }
  }

  Future<void> _submitAuthMethod() async {
    final flow = ref.read(authFlowControllerProvider);
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final email = _emailController.text.trim().toLowerCase();

    if (flow.method == AuthMethod.otp) {
      await notifier.requestOtp(email: email, purpose: OtpPurpose.login);
      if (mounted) setState(() => _otpCode = '');
      return;
    }

    final password = _passwordController.text;
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final cardHeight = math.min(510.0, math.max(360.0, screenHeight - 170.0));

    return Scaffold(
      backgroundColor: AppColors.auroraLavender,
      body: FluidAuthBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: cardHeight,
              child: FrostedGlassCard(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(flow),
                    const SizedBox(height: 14),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: SingleChildScrollView(
                          key: ValueKey('scroll_${flow.step.name}'),
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                              _buildPageContent(flow),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _UniversityOnboardingCard(
              onTap: () => UniversityOnboardingSheet.show(context),
            ),
            const SizedBox(height: 10),
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

  Widget _buildHeader(AuthFlowState flow) {
    final showBack = flow.step != AuthStep.credentials;
    String title = 'Northstar Workspace';
    String subtitle;

    switch (flow.step) {
      case AuthStep.credentials:
        subtitle = flow.mode == AuthMode.signIn
            ? 'Sign in with your university or Google account'
            : 'Create your campus workspace account';
        break;
      case AuthStep.authMethod:
        title = flow.domainResolution?.isUniversityAdmin == true
            ? 'Admin Sign In'
            : 'Verify Identity';
        subtitle = 'Choose how you want to authenticate';
        break;
      case AuthStep.verifyOtp:
        title = 'Enter Verification Code';
        subtitle =
            'Sent a 6-digit code to ${_emailController.text.trim()}';
        break;
      case AuthStep.setPassword:
        title = 'Create Password';
        subtitle = 'Email verified! Secure your account to continue.';
        break;
      case AuthStep.forgotPassword:
        title = 'Reset Password';
        subtitle = 'Verify your email with a 6-digit code';
        break;
    }

    return Column(
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: flow.isLoading
                  ? null
                  : () {
                      final backStep = flow.step == AuthStep.setPassword
                          ? AuthStep.verifyOtp
                          : AuthStep.credentials;
                      ref
                          .read(authFlowControllerProvider.notifier)
                          .goToStep(backStep);
                    },
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF38BDF8),
                  AppColors.primary,
                  AppColors.accentIndigo,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
        SizedBox(height: showBack ? 6 : 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPageContent(AuthFlowState flow) {
    switch (flow.step) {
      case AuthStep.authMethod:
        return _buildAuthMethodPage(flow);
      case AuthStep.verifyOtp:
        return _buildVerifyOtpPage(flow);
      case AuthStep.setPassword:
        return _buildSetPasswordPage(flow);
      case AuthStep.forgotPassword:
        return ForgotPasswordFlow(
          initialEmail: _emailController.text.trim(),
          onCancel: () => ref
              .read(authFlowControllerProvider.notifier)
              .goToStep(AuthStep.authMethod),
        );
      case AuthStep.credentials:
        return _buildEntryPage(flow);
    }
  }

  /// PAGE 1: Clean minimal email entry + Login/Register toggle + Google OAuth.
  Widget _buildEntryPage(AuthFlowState flow) {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final isSignUp = flow.mode == AuthMode.signUp;
    final hasInvalidDomain =
        flow.domainResolution != null && !flow.domainResolution!.allowed;
    final hasBlockedDomain =
        hasInvalidDomain && !flow.domainResolution!.isNetworkError;
    final showBanner = _emailController.text.trim().contains('@') &&
        (flow.isResolvingDomain || flow.domainResolution != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedPillSwitch<AuthMode>(
          value: flow.mode,
          leftValue: AuthMode.signIn,
          rightValue: AuthMode.signUp,
          leftLabel: 'Login',
          rightLabel: 'Register',
          onChanged: (mode) {
            notifier.switchMode(mode);
            _onEmailChanged(_emailController.text);
          },
        ),
        const SizedBox(height: 14),
        if (isSignUp) ...[
          FluidTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g. Rohan Singh',
            prefixIcon: Icons.person_outline_rounded,
            enabled: !flow.isLoading && !flow.isGoogleLoading,
            onChanged: (_) => notifier.clearBanners(),
          ),
          const SizedBox(height: 10),
        ],
        FluidTextField(
          controller: _emailController,
          label: 'Email address',
          hint: 'student@univ.edu.in or you@gmail.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !flow.isLoading && !flow.isGoogleLoading,
          hasWarningBorder: hasInvalidDomain,
          onChanged: _onEmailChanged,
          onSubmitted: (_) => _submitEmailEntry(),
        ),
        if (showBanner) ...[
          const SizedBox(height: 10),
          DomainStatusBanner(
            resolution: flow.domainResolution,
            isResolving: flow.isResolvingDomain,
          ),
        ],
        const SizedBox(height: 16),
        FluidPrimaryButton(
          label: 'Continue',
          trailingIcon: Icons.arrow_forward_rounded,
          isLoading: flow.isLoading,
          useDarkPill: isSignUp,
          onPressed: (hasBlockedDomain || flow.isGoogleLoading)
              ? null
              : _submitEmailEntry,
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 12),
        GoogleOAuthButton(
          isLoading: flow.isGoogleLoading,
          onPressed: flow.isLoading ? null : notifier.signInWithGoogle,
          onCancel: notifier.cancelGoogleSignIn,
        ),
      ],
    );
  }

  /// PAGE 2: Dedicated Password / OTP authentication step with verified identity badge.
  Widget _buildAuthMethodPage(AuthFlowState flow) {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final email = _emailController.text.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E7FF)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.alternate_email_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: flow.isLoading
                    ? null
                    : () => notifier.goToStep(AuthStep.credentials),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (flow.domainResolution != null) ...[
          const SizedBox(height: 10),
          DomainStatusBanner(
            resolution: flow.domainResolution,
            isResolving: false,
          ),
        ],
        const SizedBox(height: 12),
        SegmentedPillSwitch<AuthMethod>(
          value: flow.method,
          leftValue: AuthMethod.password,
          rightValue: AuthMethod.otp,
          leftLabel: 'Password',
          rightLabel: 'OTP Code',
          leftIcon: Icons.lock_outline_rounded,
          rightIcon: Icons.mark_email_read_outlined,
          height: 42,
          activeColor: AppColors.accentIndigo,
          onChanged: notifier.switchMethod,
        ),
        const SizedBox(height: 12),
        if (flow.method == AuthMethod.password) ...[
          FluidTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !flow.isLoading,
            onChanged: (_) => notifier.clearBanners(),
            onSubmitted: (_) => _submitAuthMethod(),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              'We will send a 6-digit login verification code to $email.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        FluidPrimaryButton(
          label: flow.method == AuthMethod.otp ? 'Send OTP Code' : 'Sign In',
          trailingIcon: flow.method == AuthMethod.otp
              ? Icons.arrow_forward_rounded
              : Icons.login_rounded,
          isLoading: flow.isLoading,
          onPressed: _submitAuthMethod,
        ),
      ],
    );
  }

  /// PAGE 3: Spacious 6-digit OTP verification screen.
  Widget _buildVerifyOtpPage(AuthFlowState flow) {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final email = _emailController.text.trim().toLowerCase();
    final purpose =
        flow.mode == AuthMode.signUp ? OtpPurpose.register : OtpPurpose.login;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        OtpCodeBoxes(
          value: _otpCode,
          enabled: !flow.isLoading,
          onChanged: (code) {
            notifier.clearBanners();
            setState(() => _otpCode = code);
          },
          onCompleted: _submitOtpVerification,
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 20),
        FluidPrimaryButton(
          label: 'Confirm Code',
          trailingIcon: Icons.verified_rounded,
          isLoading: flow.isLoading,
          onPressed: _otpCode.length == 6 ? _submitOtpVerification : null,
        ),
      ],
    );
  }

  /// PAGE 4: Password creation after first-time OTP signup verification.
  Widget _buildSetPasswordPage(AuthFlowState flow) {
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
          onChanged: (_) {
            notifier.clearBanners();
            setState(() {});
          },
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
        const SizedBox(height: 10),
        FluidTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          prefixIcon: Icons.verified_outlined,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          enabled: !flow.isLoading,
          onChanged: (_) {
            notifier.clearBanners();
            setState(() {});
          },
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
        const SizedBox(height: 10),
        PasswordStrengthChecklist(
          password: pass,
          confirmPassword: confirm,
        ),
        const SizedBox(height: 14),
        FluidPrimaryButton(
          label: 'Create Password & Enter Workspace',
          useDarkPill: true,
          isLoading: flow.isLoading,
          onPressed:
              (pass.length >= 8 && pass == confirm) ? _submitSetPassword : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      borderRadius: 22,
      tintColor: Colors.white.withValues(alpha: 0.72),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 19,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Create an organisation for your campus',
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
                  Flexible(
                    child: Text(
                      'Create Org',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
