import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_api_service.dart';
import '../controllers/auth_controller.dart';
import 'auth_form_fields.dart';
import 'otp_code_boxes.dart';
import 'password_strength_checklist.dart';

/// Multi-step onboarding flow for claiming a new university workspace.
/// Presents as a centered modal dialog on Desktop/Tablet and a draggable bottom sheet on Mobile.
class UniversityOnboardingSheet extends ConsumerStatefulWidget {
  const UniversityOnboardingSheet({super.key});

  static Future<void> show(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    if (isWide) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: UniversityOnboardingSheet(),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UniversityOnboardingSheet(),
    );
  }

  @override
  ConsumerState<UniversityOnboardingSheet> createState() =>
      _UniversityOnboardingSheetState();
}

class _UniversityOnboardingSheetState
    extends ConsumerState<UniversityOnboardingSheet> {
  final _universityNameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _domainController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const List<String> _campusSizes = [
    'Just you',
    '2 - 9',
    '10 - 99',
    '100 - 299',
    '300+',
  ];

  int _step = 0; // 0: Org details, 1: Admin identity, 2: Verify domain OTP
  String _selectedSize = '100 - 299';
  String _otpCode = '';
  bool _obscurePassword = true;
  bool _customShortCodeEdited = false;
  bool _customAdminEmailEdited = false;
  bool _isBusy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _universityNameController.dispose();
    _shortCodeController.dispose();
    _domainController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _adminEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _syncDerivedShortCode(String name) {
    if (!_customShortCodeEdited) {
      _shortCodeController.text =
          name.trim().isEmpty ? '' : UniversityClaimRequest.deriveShortCode(name);
    }
    if (_error != null) setState(() => _error = null);
  }

  void _onDomainChanged(String raw) {
    final cleaned = UniversityClaimRequest.cleanDomain(raw);
    if (!_customAdminEmailEdited) {
      _adminEmailController.text = cleaned.isEmpty ? '' : 'admin@$cleaned';
    }
    if (_error != null || _info != null) {
      setState(() {
        _error = null;
        _info = null;
      });
    }
  }

  Future<void> _advanceFromOrgStep() async {
    final name = _universityNameController.text.trim();
    final domain = UniversityClaimRequest.cleanDomain(_domainController.text);
    final rawCode = _shortCodeController.text.trim();

    if (name.length < 3 || name.length > 150) {
      setState(
        () => _error = 'University name must be between 3 and 150 characters.',
      );
      return;
    }
    if (!domain.contains('.') || domain.length < 4 || domain.contains(' ')) {
      setState(
        () => _error =
            'Enter a valid official university domain (e.g. iitd.ac.in).',
      );
      return;
    }
    if (UniversityClaimRequest.isBlockedConsumerDomain(domain)) {
      setState(
        () => _error =
            'Consumer domains (@$domain) cannot be registered as a university.',
      );
      return;
    }
    if (rawCode.isNotEmpty && (rawCode.length < 2 || rawCode.length > 20)) {
      setState(
        () => _error = 'Short code must be between 2 and 20 characters.',
      );
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
      _info = null;
    });

    // Pre-check if domain already exists so the admin doesn't waste Steps 1 & 2.
    try {
      final resolution = await ref
          .read(authRepositoryProvider)
          .resolveDomain('admin@$domain');
      if (!mounted) return;
      if (resolution.isRegistered && resolution.isUniversity) {
        final existingName = resolution.universityName ?? domain;
        setState(() {
          _isBusy = false;
          _error =
              '@$domain is already registered as $existingName. Close this modal and sign in instead.';
        });
        return;
      }
    } catch (_) {
      // If offline or server waking up, proceed to Step 1 so user isn't blocked.
    }

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (!_customAdminEmailEdited ||
          _adminEmailController.text.trim().isEmpty) {
        _adminEmailController.text = 'admin@$domain';
      }
      _step = 1;
    });
  }

  Future<void> _requestDomainVerificationOtp() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final contactName = '$first $last'.trim();
    final email = _adminEmailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final domain = UniversityClaimRequest.cleanDomain(_domainController.text);

    if (first.length < 2 || contactName.length > 100) {
      setState(
        () => _error = 'Enter a valid administrator first name (2–100 chars).',
      );
      return;
    }

    final emailParts = email.split('@');
    if (emailParts.length != 2 ||
        emailParts[0].isEmpty ||
        !UniversityClaimRequest.isDomainRelated(domain, emailParts[1])) {
      setState(
        () => _error = 'Administrator email must belong to @$domain.',
      );
      return;
    }

    if (UniversityClaimRequest.isStudentEmail(email)) {
      setState(
        () => _error =
            'Student or roll-number emails cannot claim university admin access. Use an official staff/admin address.',
      );
      return;
    }

    if (password.length < 8) {
      setState(() => _error = 'Admin password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
      _info = null;
    });

    try {
      final msg = await ref
          .read(authFlowControllerProvider.notifier)
          .requestUniversityOtp(email: email, domain: domain);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _step = 2;
        _otpCode = '';
        _info = msg ?? 'Verification code sent to $email.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = AuthApiService.extractErrorMessage(
          e,
          fallback: 'Unable to send domain verification code.',
        );
      });
    }
  }

  Future<void> _claimAndCreateOrganisation() async {
    if (_otpCode.length < 6) {
      setState(() => _error = 'Enter the 6-digit domain verification code.');
      return;
    }

    final contactName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await ref.read(authFlowControllerProvider.notifier).claimUniversity(
            UniversityClaimRequest(
              universityName: _universityNameController.text,
              shortCode: _shortCodeController.text,
              contactName: contactName,
              contactEmail: _adminEmailController.text,
              domain: _domainController.text,
              otp: _otpCode,
              password: _passwordController.text,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = AuthApiService.extractErrorMessage(
          e,
          fallback: 'Failed to create university workspace.',
        );
      });
    }
  }

  void _goBackToStep(int targetStep) {
    if (_isBusy) return;
    setState(() {
      _step = targetStep;
      _error = null;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isWide = screen.width >= 700;

    return Padding(
      padding: EdgeInsets.only(bottom: isWide ? 0 : bottomInset),
      child: FocusTraversalGroup(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: isWide ? screen.height * 0.88 : screen.height * 0.92,
            maxWidth: isWide ? 560 : 500,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isWide
                ? BorderRadius.circular(28)
                : const BorderRadius.vertical(top: Radius.circular(28)),
            border: isWide
                ? Border.all(color: const Color(0xFFE2E8F0), width: 1.2)
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isWide) ...[
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 22,
                    isWide ? 24 : 18,
                    isWide ? 28 : 22,
                    isWide ? 26 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _StepProgressBar(currentStep: _step),
                      const SizedBox(height: 18),
                      if (_error != null) ...[
                        AuthFeedbackBanner(message: _error!, isError: true),
                        const SizedBox(height: 14),
                      ],
                      if (_info != null) ...[
                        AuthFeedbackBanner(message: _info!, isError: false),
                        const SizedBox(height: 14),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _step == 0
                            ? _buildOrgDetailsStep()
                            : (_step == 1
                                ? _buildAdminStep()
                                : _buildVerifyStep()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const titles = [
      'Create University Organisation',
      'Administrator Credentials',
      'Verify Institutional Domain',
    ];
    const subtitles = [
      'Provision an isolated campus workspace for students & faculty.',
      'Use an official administrative email matching your campus domain.',
      'Confirm domain ownership with the 6-digit verification code.',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accentIndigo],
            ),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titles[_step],
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitles[_step],
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildOrgDetailsStep() {
    return Column(
      key: const ValueKey('org_step_0'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FluidTextField(
          controller: _universityNameController,
          label: 'University / Institution Name',
          hint: 'e.g. Indian Institute of Technology Delhi',
          prefixIcon: Icons.school_outlined,
          enabled: !_isBusy,
          onChanged: _syncDerivedShortCode,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: FluidTextField(
                controller: _domainController,
                label: 'Official Domain',
                hint: 'iitd.ac.in',
                prefixIcon: Icons.language_rounded,
                keyboardType: TextInputType.url,
                enabled: !_isBusy,
                onChanged: _onDomainChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FluidTextField(
                controller: _shortCodeController,
                label: 'Short Code',
                hint: 'IITD',
                prefixIcon: Icons.tag_rounded,
                textInputAction: TextInputAction.done,
                enabled: !_isBusy,
                onChanged: (_) => _customShortCodeEdited = true,
                onSubmitted: (_) => _advanceFromOrgStep(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Expected campus size',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _campusSizes.map((size) {
            final selected = _selectedSize == size;
            return ChoiceChip(
              label: Text(size),
              selected: selected,
              onSelected:
                  _isBusy ? null : (_) => setState(() => _selectedSize = size),
              selectedColor: AppColors.primaryContainer,
              backgroundColor: AppColors.inputFill,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        FluidPrimaryButton(
          label: 'Continue to Admin Setup',
          trailingIcon: Icons.arrow_forward_rounded,
          isLoading: _isBusy,
          onPressed: _advanceFromOrgStep,
        ),
      ],
    );
  }

  Widget _buildAdminStep() {
    final password = _passwordController.text;
    final domain = UniversityClaimRequest.cleanDomain(_domainController.text);

    return Column(
      key: const ValueKey('org_step_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FluidTextField(
                controller: _firstNameController,
                label: 'First name',
                hint: 'Rohan',
                prefixIcon: Icons.person_outline_rounded,
                enabled: !_isBusy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FluidTextField(
                controller: _lastNameController,
                label: 'Last name',
                hint: 'Bhandari',
                prefixIcon: Icons.badge_outlined,
                enabled: !_isBusy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FluidTextField(
          controller: _adminEmailController,
          label: 'Official Admin Email',
          hint: 'registrar@$domain',
          prefixIcon: Icons.admin_panel_settings_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isBusy,
          onChanged: (_) {
            _customAdminEmailEdited = true;
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Must use @$domain (staff/registrar email — student roll-number emails are blocked).',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FluidTextField(
          controller: _passwordController,
          label: 'Admin Password',
          hint: 'At least 8 characters',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          enabled: !_isBusy,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _requestDomainVerificationOtp(),
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
        const SizedBox(height: 12),
        PasswordStrengthChecklist(password: password),
        const SizedBox(height: 18),
        FluidPrimaryButton(
          label: 'Send Verification Code',
          trailingIcon: Icons.mark_email_read_outlined,
          isLoading: _isBusy,
          onPressed: _requestDomainVerificationOtp,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isBusy ? null : () => _goBackToStep(0),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Back to Institution Details'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyStep() {
    final domain = UniversityClaimRequest.cleanDomain(_domainController.text);
    final email = _adminEmailController.text.trim().toLowerCase();
    final shortCode = _shortCodeController.text.trim().isEmpty
        ? UniversityClaimRequest.deriveShortCode(_universityNameController.text)
        : _shortCodeController.text.trim().toUpperCase();

    return Column(
      key: const ValueKey('org_step_2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _universityNameController.text.trim(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      shortCode,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Domain: @$domain  •  Admin: $email',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OtpCodeBoxes(
          value: _otpCode,
          enabled: !_isBusy,
          onChanged: (code) => setState(() => _otpCode = code),
          onCompleted: _claimAndCreateOrganisation,
        ),
        const SizedBox(height: 8),
        OtpResendBar(
          isLoading: _isBusy,
          onResend: _requestDomainVerificationOtp,
        ),
        const SizedBox(height: 18),
        FluidPrimaryButton(
          label: 'Verify & Create Organisation',
          useDarkPill: true,
          isLoading: _isBusy,
          onPressed:
              _otpCode.length == 6 ? _claimAndCreateOrganisation : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isBusy ? null : () => _goBackToStep(1),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: const Text('Edit Admin Email'),
        ),
      ],
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int currentStep;

  const _StepProgressBar({required this.currentStep});

  static const _labels = ['Campus', 'Admin', 'Verify'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(3, (idx) {
            final isDone = idx < currentStep;
            final isCurrent = idx == currentStep;
            return Expanded(
              child: Row(
                mainAxisAlignment: idx == 0
                    ? MainAxisAlignment.start
                    : (idx == 1
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.end),
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isCurrent
                          ? AppColors.primary
                          : AppColors.inputFill,
                      border: Border.all(
                        color: isDone || isCurrent
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            )
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _labels[idx],
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isCurrent || isDone
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isCurrent || isDone
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (idx) {
            final active = idx <= currentStep;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: idx < 2 ? 6 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
