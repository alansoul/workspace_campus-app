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
      'Multi-page flow verifies admin account, switches modes, recovery, and opens Create Org',
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

    // Page 1: minimal Login & Google OAuth visible
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // Enter university admin email and continue to Page 2 (Admin Sign In)
    await tester.enterText(find.byType(TextField).first, 'admin@iiitnr.edu.in');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Admin Account'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Page 2: shows dedicated Admin Sign In, Password/OTP toggle, Forgot password
    expect(find.text('Admin Sign In'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    // Navigate to Forgot Password page
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Send Verification Code'), findsOneWidget);

    // Go back to Page 2 -> Back to Page 1 -> switch to Register
    await tester.ensureVisible(find.text('Back to Sign In'));
    await tester.tap(find.text('Back to Sign In'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Back'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Full Name'), findsOneWidget);

    // Open bottom Create Org sheet
    await tester.ensureVisible(find.text('Create Org'));
    await tester.tap(find.text('Create Org'));
    await tester.pumpAndSettle();

    expect(find.byType(UniversityOnboardingSheet), findsOneWidget);
    expect(find.text('Create University Organisation'), findsOneWidget);
  });
}
