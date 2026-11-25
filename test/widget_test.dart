import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_mobile/features/auth/data/models/user_model.dart';
import 'package:campus_mobile/main.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getProfile() async => null;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<Map<String, dynamic>> resolveDomain(String email) async => {};
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App smoke test renders LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const CampusWorkspaceApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Northstar Workspace'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
