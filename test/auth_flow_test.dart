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

  test('UniversityClaimRequest derives short codes and validates domains/emails', () {
    expect(UniversityClaimRequest.deriveShortCode('Stanford University'), 'STAN');
    expect(UniversityClaimRequest.deriveShortCode('A'), 'CAMP');
    expect(
      UniversityClaimRequest.cleanDomain('https://www.IITD.ac.in/'),
      'iitd.ac.in',
    );
    expect(UniversityClaimRequest.isBlockedConsumerDomain('gmail.com'), isTrue);
    expect(UniversityClaimRequest.isBlockedConsumerDomain('proton.me'), isTrue);
    expect(UniversityClaimRequest.isBlockedConsumerDomain('iitd.ac.in'), isFalse);
    expect(
      UniversityClaimRequest.isDomainRelated('iitd.ac.in', 'notiitd.ac.in'),
      isFalse,
    );
    expect(
      UniversityClaimRequest.isDomainRelated('cs.iitd.ac.in', 'iitd.ac.in'),
      isTrue,
    );
    expect(
      UniversityClaimRequest.isStudentEmail('21bcs042@iiitnr.edu.in'),
      isTrue,
    );
    expect(
      UniversityClaimRequest.isStudentEmail('rohan@student.iitd.ac.in'),
      isTrue,
    );
    expect(
      UniversityClaimRequest.isStudentEmail('registrar@iitd.ac.in'),
      isFalse,
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

  testWidgets(
      'Shows connection issue and keeps Continue enabled when domain lookup fails',
      (WidgetTester tester) async {
    final failingRepo = _NetworkFailingAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(failingRepo),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'admin@iiitnr.edu.in');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach server'), findsOneWidget);
    expect(find.text('Domain not registered yet'), findsNothing);

    final continueBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueBtn.onPressed, isNotNull);
  });

  testWidgets(
      'Renders desktop showcase + dialog onboarding and enforces student-email gate',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    expect(find.text('Your entire campus workspace, unified.'), findsOneWidget);

    await tester.tap(find.text('Onboard your university'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Create University Organisation'), findsOneWidget);

    // Fill org details -> Step 0 -> Step 1
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Indian Institute of Technology Delhi'),
      'IIIT Naya Raipur',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'iitd.ac.in'),
      'newcampus.edu.in',
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Continue to Admin Setup'));
    await tester.tap(find.text('Continue to Admin Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Administrator Credentials'), findsOneWidget);

    // Enter student roll-number email -> blocked upfront before API call
    await tester.enterText(
      find.widgetWithText(TextField, 'Rohan'),
      'Divya',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'admin@newcampus.edu.in'),
      '21bcs042@newcampus.edu.in',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'At least 8 characters'),
      'AdminPass1!',
    );
    await tester.ensureVisible(find.text('Send Verification Code'));
    await tester.tap(find.text('Send Verification Code'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Student or roll-number emails cannot claim'),
      findsOneWidget,
    );

    // Fix to staff email -> advances to Step 2
    await tester.enterText(
      find.widgetWithText(TextField, '21bcs042@newcampus.edu.in'),
      'registrar@newcampus.edu.in',
    );
    await tester.ensureVisible(find.text('Send Verification Code'));
    await tester.tap(find.text('Send Verification Code'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Institutional Domain'), findsOneWidget);
    expect(find.text('Verify & Create Organisation'), findsOneWidget);
  });
}

class _NetworkFailingAuthRepository extends FakeAuthRepository {
  @override
  Future<DomainResolution> resolveDomain(String email) {
    throw Exception('Unable to reach server. Check your internet connection.');
  }
}
