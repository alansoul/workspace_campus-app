import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_mobile/features/auth/data/models/auth_models.dart';
import 'package:campus_mobile/features/auth/data/models/user_model.dart';
import 'package:campus_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_mobile/features/auth/presentation/widgets/university_onboarding_sheet.dart';
import 'widget_test.dart';

class _InteractiveFakeAuthRepository extends FakeAuthRepository {
  OtpPurpose? lastPurpose;
  String? lastEmail;
  bool requirePasswordSetupOnVerify = true;

  @override
  Future<String?> requestOtp({
    required String email,
    required OtpPurpose purpose,
    String? turnstileToken,
  }) async {
    lastEmail = email;
    lastPurpose = purpose;
    return 'Verification code sent to $email';
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
    String? fullName,
  }) async {
    return OtpVerificationResult(
      requiresPasswordSetup: requirePasswordSetupOnVerify,
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

  testWidgets('Switches across Login, Register, OTP, Forgot Password, and Org Sheet',
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

    // Default Login -> Password mode shows Password field and Forgot password link
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    // Switch to OTP Code mode
    await tester.tap(find.text('OTP Code'));
    await tester.pumpAndSettle();
    expect(find.text('Send OTP Code'), findsOneWidget);

    // Switch to Register mode -> shows Full Name field + CTA
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Verify Email & Continue'), findsOneWidget);

    // Switch back to Login -> Forgot password flow
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Send Verification Code'), findsOneWidget);

    // Return to Login and open bottom Create Org sheet
    await tester.ensureVisible(find.text('Back to Sign In'));
    await tester.tap(find.text('Back to Sign In'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Org'));
    await tester.tap(find.text('Create Org'));
    await tester.pumpAndSettle();

    expect(find.byType(UniversityOnboardingSheet), findsOneWidget);
    expect(find.text('Create University Organisation'), findsOneWidget);
    expect(find.text('Continue to Admin Setup'), findsOneWidget);
  });
}
