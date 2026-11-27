import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_mobile/features/auth/data/models/auth_models.dart';
import 'package:campus_mobile/features/auth/data/models/user_model.dart';
import 'package:campus_mobile/features/auth/data/services/google_oauth_service.dart';
import 'package:campus_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_mobile/features/auth/presentation/widgets/fluid_auth_backdrop.dart';
import 'package:campus_mobile/features/auth/presentation/widgets/university_onboarding_sheet.dart';
import 'widget_test.dart';

class _InteractiveFakeAuthRepository extends FakeAuthRepository {
  Completer<UserModel>? _pendingGoogle;

  @override
  Future<DomainResolution> resolveDomain(String email) async {
    if (email == 'admin@iiitnr.edu.in') {
      return const DomainResolution(
        allowed: true,
        isRegistered: true,
        isUniversity: true,
        domain: 'iiitnr.edu.in',
        universityName: 'IIIT Naya Raipur',
        accountExists: true,
        hasPassword: true,
        isUniversityAdmin: true,
        accountRole: 'ADMIN',
      );
    }
    return super.resolveDomain(email);
  }

  @override
  Future<UserModel> loginWithGoogle() {
    _pendingGoogle = Completer<UserModel>();
    return _pendingGoogle!.future;
  }

  @override
  void cancelGoogleSignIn() {
    final pending = _pendingGoogle;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const GoogleOAuthCancelledException());
    }
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
    String? fullName,
  }) async {
    return OtpVerificationResult(
      requiresPasswordSetup: true,
      message: 'Verified',
      user: UserModel(
        id: 'u1',
        email: email,
        username: 'rohan',
        fullName: fullName ?? 'Rohan Singh',
        role: 'STUDENT',
        accountType: 'INDIVIDUAL',
      ),
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('PasswordRequirements evaluates strength rules accurately', () {
    final weak = PasswordRequirements.evaluate('abc');
    expect(weak.hasMinLength, isFalse);
    expect(weak.hasUppercase, isFalse);
    expect(weak.hasNumberOrSymbol, isFalse);
    expect(weak.isStrong, isFalse);

    final strong = PasswordRequirements.evaluate('CampusPass1!');
    expect(strong.hasMinLength, isTrue);
    expect(strong.hasUppercase, isTrue);
    expect(strong.hasNumberOrSymbol, isTrue);
    expect(strong.isStrong, isTrue);
  });

  test('UniversityClaimRequest derives short codes and strips domain URLs', () {
    expect(UniversityClaimRequest.deriveShortCode('Stanford University'), 'STAN');
    expect(
      UniversityClaimRequest.cleanDomain('https://www.IITD.ac.in/'),
      'iitd.ac.in',
    );
  });

  testWidgets(
      'Keeps consistent card height across pages and supports cancelling Google OAuth',
      (WidgetTester tester) async {
    final fakeRepo = _InteractiveFakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final initialCardSize = tester.getSize(find.byType(FrostedGlassCard).first);

    // Clicking Google OAuth shows inline cancel option and recovers immediately on cancel
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(find.text('Waiting for browser • Cancel'), findsOneWidget);

    await tester.tap(find.text('Waiting for browser • Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);

    // Enter university admin email and continue to Page 2 (Admin Sign In)
    await tester.enterText(find.byType(TextField).first, 'admin@iiitnr.edu.in');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Admin Account'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FrostedGlassCard).first).height,
      equals(initialCardSize.height),
    );

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Page 2 keeps identical card height
    expect(find.text('Admin Sign In'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FrostedGlassCard).first).height,
      equals(initialCardSize.height),
    );

    // Navigate to Forgot Password -> also keeps identical card height
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Password'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FrostedGlassCard).first).height,
      equals(initialCardSize.height),
    );

    // Go back -> open Create Org sheet
    await tester.ensureVisible(find.text('Back'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Org'));
    await tester.tap(find.text('Create Org'));
    await tester.pumpAndSettle();

    expect(find.byType(UniversityOnboardingSheet), findsOneWidget);
  });
}
