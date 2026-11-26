import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';
import 'auth_form_fields.dart';
import 'otp_code_boxes.dart';
import 'password_strength_checklist.dart';

/// Multi-step modal sheet for onboarding and claiming a new university workspace.
class UniversityOnboardingSheet extends ConsumerStatefulWidget {
  const UniversityOnboardingSheet({super.key});

  static Future<void> show(BuildContext context) {
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
  }

  void _advanceFromOrgStep() {
    final name = _universityNameController.text.trim();
    final domain =
        UniversityClaimRequest.cleanDomain(_domainController.text);

    if (name.length < 3) {
      setState(() => _error = 'University name must be at least 3 characters.');
      return;
    }
    if (!domain.contains('.') || domain.length < 4) {
      setState(
        () => _error = 'Enter a valid official university domain (e.g. iitd.ac.in).',
      );
      return;
    }
    if (domain == 'gmail.com' ||
        domain == 'yahoo.com' ||
        domain == 'outlook.com') {
      setState(
        () => _error = 'Generic consumer domains cannot be registered as a university.',
      );
      return;
    }

    setState(() {
      _error = null;
      _info = null;
      if (_adminEmailController.text.trim().isEmpty) {
        _adminEmailController.text = 'admin@$domain';
      }
      _step = 1;
    });
  }

  Future<void> _requestDomainVerificationOtp() async {
    final first = _firstNameController.text.trim();
    final email = _adminEmailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final domain =
        UniversityClaimRequest.cleanDomain(_domainController.text);

    if (first.length < 2) {
      setState(() => _error = 'Please enter the administrator first name.');
      return;
    }
    if (!email.contains('@') || !email.endsWith(domain)) {
      setState(
        () => _error = 'Administrator email must use your @$domain domain.',
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
        _error = e.toString().replaceFirst('Exception: ', '');
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
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
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
          onChanged: _syncDerivedShortCode,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FluidTextField(
                controller: _domainController,
                label: 'Official Domain',
                hint: 'iitd.ac.in',
                prefixIcon: Icons.language_rounded,
                keyboardType: TextInputType.url,
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
                onChanged: (_) => _customShortCodeEdited = true,
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
              onSelected: (_) => setState(() => _selectedSize = size),
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
          onPressed: _advanceFromOrgStep,
        ),
      ],
    );
  }

  Widget _buildAdminStep() {
    final password = _passwordController.text;
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
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FluidTextField(
                controller: _lastNameController,
                label: 'Last name',
                hint: 'Bhandari',
                prefixIcon: Icons.badge_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FluidTextField(
          controller: _adminEmailController,
          label: 'Official Admin Email',
          hint: 'registrar@iitd.ac.in',
          prefixIcon: Icons.admin_panel_settings_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        FluidTextField(
          controller: _passwordController,
          label: 'Admin Password',
          hint: 'At least 8 characters',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
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
          onPressed:
              _isBusy ? null : () => setState(() => _step = 0),
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
              Text(
                _universityNameController.text.trim(),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
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
          onPressed: _isBusy ? null : () => setState(() => _step = 1),
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

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
