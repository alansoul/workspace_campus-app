import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_mobile/features/auth/data/models/auth_models.dart';
import 'package:campus_mobile/features/auth/data/models/user_model.dart';
import 'package:campus_mobile/main.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getProfile() async => null;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserModel> loginWithGoogle() => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<DomainResolution> resolveDomain(String email) async =>
      const DomainResolution(
        allowed: true,
        isRegistered: true,
        isGmail: true,
        accountExists: true,
        hasPassword: true,
      );

  @override
  Future<String?> requestOtp({
    required String email,
    required OtpPurpose purpose,
    String? turnstileToken,
  }) async =>
      'Code sent';

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
    String? fullName,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserModel> setPassword({
    required String email,
    required String password,
    String? fullName,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserModel> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      throw UnimplementedError();

  @override
  Future<String?> requestUniversityOtp({
    required String email,
    required String domain,
  }) async =>
      'Domain OTP sent';

  @override
  Future<UserModel> claimUniversity(UniversityClaimRequest request) =>
      throw UnimplementedError();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App smoke test renders minimal LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const CampusWorkspaceApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Northstar Workspace'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
