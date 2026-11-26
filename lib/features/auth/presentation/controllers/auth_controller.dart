import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_api_service.dart';

/// Global authenticated session provider watched by the app shell.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Scoped UI action controller for multi-step login, signup, OTP, and recovery.
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

enum AuthStep { credentials, verifyOtp, setPassword, forgotPassword }

class AuthFlowState {
  final AuthMode mode;
  final AuthMethod method;
  final AuthStep step;
  final bool isLoading;
  final bool isResolvingDomain;
  final DomainResolution? domainResolution;
  final String? errorMessage;
  final String? infoMessage;
  final bool requiresTurnstileFallback;

  const AuthFlowState({
    this.mode = AuthMode.signIn,
    this.method = AuthMethod.password,
    this.step = AuthStep.credentials,
    this.isLoading = false,
    this.isResolvingDomain = false,
    this.domainResolution,
    this.errorMessage,
    this.infoMessage,
    this.requiresTurnstileFallback = false,
  });

  AuthFlowState copyWith({
    AuthMode? mode,
    AuthMethod? method,
    AuthStep? step,
    bool? isLoading,
    bool? isResolvingDomain,
    DomainResolution? domainResolution,
    bool clearDomainResolution = false,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
    bool? requiresTurnstileFallback,
  }) {
    return AuthFlowState(
      mode: mode ?? this.mode,
      method: method ?? this.method,
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      isResolvingDomain: isResolvingDomain ?? this.isResolvingDomain,
      domainResolution: clearDomainResolution
          ? null
          : (domainResolution ?? this.domainResolution),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      requiresTurnstileFallback:
          requiresTurnstileFallback ?? this.requiresTurnstileFallback,
    );
  }
}

class AuthFlowController extends StateNotifier<AuthFlowState> {
  final AuthRepository _repo;
  final AuthController _sessionController;

  AuthFlowController(this._repo, this._sessionController)
      : super(const AuthFlowState());

  void switchMode(AuthMode mode) {
    state = state.copyWith(
      mode: mode,
      method: mode == AuthMode.signUp ? AuthMethod.otp : AuthMethod.password,
      step: AuthStep.credentials,
      clearError: true,
      clearInfo: true,
      requiresTurnstileFallback: false,
    );
  }

  void switchMethod(AuthMethod method) {
    state = state.copyWith(
      method: method,
      clearError: true,
      clearInfo: true,
      requiresTurnstileFallback: false,
    );
  }

  void goToStep(AuthStep step, {String? infoMessage}) {
    state = state.copyWith(
      step: step,
      clearError: true,
      infoMessage: infoMessage,
      clearInfo: infoMessage == null,
      requiresTurnstileFallback: false,
    );
  }

  void clearBanners() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }

  void setValidationError(String message) {
    state = state.copyWith(errorMessage: message, clearInfo: true);
  }

  Future<void> resolveDomain(String email) async {
    final trimmed = email.trim().toLowerCase();
    final parts = trimmed.split('@');
    if (parts.length != 2 || !parts[1].contains('.')) {
      state = state.copyWith(
        clearDomainResolution: true,
        isResolvingDomain: false,
      );
      return;
    }

    state = state.copyWith(isResolvingDomain: true);
    try {
      final result = await _repo.resolveDomain(trimmed);
      state = state.copyWith(
        domainResolution: result,
        isResolvingDomain: false,
      );
    } catch (_) {
      state = state.copyWith(
        domainResolution: const DomainResolution(
          allowed: false,
          isRegistered: false,
          errorMessage: 'Unable to verify email domain right now.',
        ),
        isResolvingDomain: false,
      );
    }
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
          ? 'No password set yet. Sign in with OTP once to create your password.'
          : raw;
      state = state.copyWith(isLoading: false, errorMessage: friendly);
      return false;
    }
  }

  Future<bool> requestOtp({
    required String email,
    required OtpPurpose purpose,
    bool advanceToVerifyStep = true,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      requiresTurnstileFallback: false,
    );
    try {
      final msg = await _repo.requestOtp(email: email, purpose: purpose);
      state = state.copyWith(
        isLoading: false,
        step: advanceToVerifyStep ? AuthStep.verifyOtp : state.step,
        infoMessage: msg ?? '6-digit verification code sent to $email.',
      );
      return true;
    } catch (e) {
      final raw = AuthApiService.extractErrorMessage(
        e,
        fallback: 'Failed to send verification code.',
      );
      final needsTurnstile =
          RegExp(r'human verification', caseSensitive: false).hasMatch(raw);
      state = state.copyWith(
        isLoading: false,
        requiresTurnstileFallback: needsTurnstile,
        errorMessage: needsTurnstile
            ? 'Human verification (Turnstile) is required for OTP from this client. Sign in with Password or complete verification on the web portal first.'
            : raw,
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
