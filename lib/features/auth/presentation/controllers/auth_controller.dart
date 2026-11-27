import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/google_oauth_service.dart';

/// Global authenticated session provider watched by the app shell.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Scoped UI action controller for multi-page login, signup, OTP, OAuth, and recovery.
final authFlowControllerProvider =
    StateNotifierProvider<AuthFlowController, AuthFlowState>((ref) {
  return AuthFlowController(
    ref.watch(authRepositoryProvider),
    ref.read(authControllerProvider.notifier),
  );
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AsyncValue.loading()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    try {
      final user = await _repo.getProfile();
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  void setAuthenticatedUser(UserModel user) {
    state = AsyncValue.data(user);
  }

  Future<void> login(String email, String password) async {
    final user = await _repo.login(email: email, password: password);
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}

enum AuthMode { signIn, signUp }

enum AuthMethod { password, otp }

enum AuthStep {
  credentials,
  authMethod,
  verifyOtp,
  setPassword,
  forgotPassword,
}

class AuthFlowState {
  final AuthMode mode;
  final AuthMethod method;
  final AuthStep step;
  final bool isLoading;
  final bool isGoogleLoading;
  final bool isResolvingDomain;
  final DomainResolution? domainResolution;
  final String? errorMessage;
  final String? infoMessage;

  const AuthFlowState({
    this.mode = AuthMode.signIn,
    this.method = AuthMethod.password,
    this.step = AuthStep.credentials,
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.isResolvingDomain = false,
    this.domainResolution,
    this.errorMessage,
    this.infoMessage,
  });

  AuthFlowState copyWith({
    AuthMode? mode,
    AuthMethod? method,
    AuthStep? step,
    bool? isLoading,
    bool? isGoogleLoading,
    bool? isResolvingDomain,
    DomainResolution? domainResolution,
    bool clearDomainResolution = false,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return AuthFlowState(
      mode: mode ?? this.mode,
      method: method ?? this.method,
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      isResolvingDomain: isResolvingDomain ?? this.isResolvingDomain,
      domainResolution: clearDomainResolution
          ? null
          : (domainResolution ?? this.domainResolution),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

class AuthFlowController extends StateNotifier<AuthFlowState> {
  final AuthRepository _repo;
  final AuthController _sessionController;
  String _lastResolvedEmail = '';

  AuthFlowController(this._repo, this._sessionController)
      : super(const AuthFlowState());

  void switchMode(AuthMode mode) {
    state = state.copyWith(
      mode: mode,
      method: mode == AuthMode.signUp ? AuthMethod.otp : AuthMethod.password,
      step: AuthStep.credentials,
      clearError: true,
      clearInfo: true,
    );
  }

  void switchMethod(AuthMethod method) {
    state = state.copyWith(
      method: method,
      clearError: true,
      clearInfo: true,
    );
  }

  void clearDomainResolution() {
    _lastResolvedEmail = '';
    if (state.domainResolution != null || state.isResolvingDomain) {
      state = state.copyWith(
        clearDomainResolution: true,
        isResolvingDomain: false,
      );
    }
  }

  void goToStep(AuthStep step, {String? infoMessage}) {
    state = state.copyWith(
      step: step,
      clearError: true,
      infoMessage: infoMessage,
      clearInfo: infoMessage == null,
    );
  }

  void clearBanners() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }

  void setValidationError(String message) {
    state = state.copyWith(errorMessage: message, clearInfo: true);
  }

  Future<DomainResolution?> resolveDomain(String email) async {
    final trimmed = email.trim().toLowerCase();
    final parts = trimmed.split('@');
    if (parts.length != 2 || !parts[1].contains('.')) {
      clearDomainResolution();
      return null;
    }

    _lastResolvedEmail = trimmed;
    state = state.copyWith(isResolvingDomain: true);
    try {
      final result = await _repo.resolveDomain(trimmed);
      if (_lastResolvedEmail != trimmed) return state.domainResolution;
      state = state.copyWith(
        domainResolution: result,
        isResolvingDomain: false,
      );
      return result;
    } catch (e) {
      if (_lastResolvedEmail != trimmed) return state.domainResolution;
      final err = DomainResolution(
        allowed: false,
        isRegistered: false,
        isNetworkError: true,
        errorMessage: AuthApiService.extractErrorMessage(
          e,
          fallback:
              'Unable to verify email domain right now. Tap Continue to retry.',
        ),
      );
      state = state.copyWith(
        domainResolution: err,
        isResolvingDomain: false,
      );
      return err;
    }
  }

  /// Resolves domain & user identity, then advances smoothly to Page 2 (or Register OTP).
  Future<void> continueFromEmail({
    required String email,
    String? fullName,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      setValidationError('Please enter a valid email address.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    DomainResolution? res;
    if (state.domainResolution == null || _lastResolvedEmail != normalized) {
      res = await resolveDomain(normalized);
    } else {
      res = state.domainResolution;
    }

    if (res == null || !res.allowed) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res?.errorMessage ??
            'Only @gmail.com or admin-registered campus domains are allowed.',
      );
      return;
    }

    if (state.mode == AuthMode.signUp) {
      final cleanName = fullName?.trim() ?? '';
      if (cleanName.length < 2) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Please enter your full name.',
        );
        return;
      }

      if (res.accountExists == true && res.hasPassword == true) {
        state = state.copyWith(
          isLoading: false,
          mode: AuthMode.signIn,
          method: AuthMethod.password,
          step: AuthStep.authMethod,
          infoMessage:
              'Account already exists! Enter your password or OTP to sign in.',
        );
        return;
      }

      await requestOtp(email: normalized, purpose: OtpPurpose.register);
      return;
    }

    // Login path: if account doesn't exist yet on Gmail, guide cleanly to Register
    if (res.accountExists == false && res.isGmail) {
      state = state.copyWith(
        isLoading: false,
        mode: AuthMode.signUp,
        method: AuthMethod.otp,
        step: AuthStep.credentials,
        infoMessage: 'No account found for $normalized. Create one below.',
      );
      return;
    }

    // Route directly to OTP if account has no password yet, otherwise AuthMethod page
    final preferredMethod =
        (res.accountExists == true && res.hasPassword == false)
            ? AuthMethod.otp
            : AuthMethod.password;

    state = state.copyWith(
      isLoading: false,
      method: preferredMethod,
      step: AuthStep.authMethod,
    );
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(isLoading: false);
      _sessionController.setAuthenticatedUser(user);
      return true;
    } catch (e) {
      final raw = AuthApiService.extractErrorMessage(
        e,
        fallback: 'Invalid email or password.',
      );
      final friendly = RegExp(r'no password', caseSensitive: false).hasMatch(raw)
          ? 'No password set yet. Switch to OTP Code to verify and create one.'
          : raw;
      state = state.copyWith(isLoading: false, errorMessage: friendly);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(
      isGoogleLoading: true,
      clearError: true,
      clearInfo: true,
    );
    try {
      final user = await _repo.loginWithGoogle();
      if (!mounted) return false;
      state = state.copyWith(isGoogleLoading: false);
      _sessionController.setAuthenticatedUser(user);
      return true;
    } on GoogleOAuthCancelledException {
      if (!mounted) return false;
      state = state.copyWith(isGoogleLoading: false);
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isGoogleLoading: false,
        errorMessage: AuthApiService.extractErrorMessage(
          e,
          fallback: 'Google sign-in failed. Please try again.',
        ),
      );
      return false;
    }
  }

  void cancelGoogleSignIn() {
    _repo.cancelGoogleSignIn();
    if (state.isGoogleLoading) {
      state = state.copyWith(isGoogleLoading: false);
    }
  }

  Future<bool> requestOtp({
    required String email,
    required OtpPurpose purpose,
    bool advanceToVerifyStep = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final msg = await _repo.requestOtp(email: email, purpose: purpose);
      state = state.copyWith(
        isLoading: false,
        step: advanceToVerifyStep ? AuthStep.verifyOtp : state.step,
        infoMessage: msg ?? '6-digit verification code sent to $email.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthApiService.extractErrorMessage(
          e,
          fallback: 'Failed to send verification code.',
        ),
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final result = await _repo.verifyOtp(
        email: email,
        otp: otp,
        fullName: fullName,
      );

      if (result.requiresPasswordSetup) {
        state = state.copyWith(
          isLoading: false,
          step: AuthStep.setPassword,
          infoMessage:
              result.message ?? 'Email verified! Create your password below.',
        );
        return true;
      }

      state = state.copyWith(isLoading: false);
      _sessionController.setAuthenticatedUser(result.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthApiService.extractErrorMessage(
          e,
          fallback: 'Invalid or expired verification code.',
        ),
      );
      return false;
    }
  }

  Future<bool> completePasswordSetup({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final user = await _repo.setPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = state.copyWith(isLoading: false);
      _sessionController.setAuthenticatedUser(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthApiService.extractErrorMessage(
          e,
          fallback: 'Failed to save password.',
        ),
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final user = await _repo.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      _sessionController.setAuthenticatedUser(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthApiService.extractErrorMessage(
          e,
          fallback: 'Failed to reset password.',
        ),
      );
      return false;
    }
  }

  Future<String?> requestUniversityOtp({
    required String email,
    required String domain,
  }) async {
    try {
      return await _repo.requestUniversityOtp(email: email, domain: domain);
    } catch (e) {
      throw Exception(
        AuthApiService.extractErrorMessage(
          e,
          fallback: 'Unable to send domain verification OTP.',
        ),
      );
    }
  }

  Future<UserModel> claimUniversity(UniversityClaimRequest request) async {
    try {
      final user = await _repo.claimUniversity(request);
      _sessionController.setAuthenticatedUser(user);
      return user;
    } catch (e) {
      throw Exception(
        AuthApiService.extractErrorMessage(
          e,
          fallback: 'Failed to register university workspace.',
        ),
      );
    }
  }
}
