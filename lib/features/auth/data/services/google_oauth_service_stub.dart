class GoogleOAuthCancelledException implements Exception {
  final String message;
  const GoogleOAuthCancelledException([
    this.message = 'Google sign-in was cancelled.',
  ]);
  @override
  String toString() => message;
}

/// Web-safe stub for `flutter run -d web-server` live UI previews where `dart:io`
/// loopback servers are unavailable.
class GoogleOAuthService {
  bool get isInProgress => false;

  void cancelPendingSignIn() {}

  Future<String> authenticateWithGoogle() async {
    throw Exception(
      'Google OAuth loopback is available in the native Android/Windows app or on the web portal (workspace-campus-web.vercel.app).',
    );
  }
}
