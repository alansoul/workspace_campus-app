import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';

final googleOAuthServiceProvider = Provider<GoogleOAuthService>((ref) {
  return GoogleOAuthService();
});

/// Handles browser-based Google OAuth with a temporary localhost callback server
/// so Windows desktop and mobile apps receive the issued JWT seamlessly.
class GoogleOAuthService {
  Future<String> authenticateWithGoogle() async {
    if (kIsWeb) {
      throw Exception('Use web OAuth flow inside browser environments.');
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final callbackUrl = 'http://127.0.0.1:${server.port}/callback';
    final completer = Completer<String>();
    late final StreamSubscription<HttpRequest> subscription;

    subscription = server.listen((request) async {
      if (request.uri.path != '/callback') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final token = request.uri.queryParameters['token'];
      final error = request.uri.queryParameters['error'];

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.html;
      request.response.write(_buildCallbackHtml(success: token != null));
      await request.response.close();

      if (!completer.isCompleted) {
        if (token != null && token.isNotEmpty) {
          completer.complete(token);
        } else {
          completer.completeError(
            Exception(error ?? 'Google authentication was cancelled.'),
          );
        }
      }
    });

    try {
      final authUri = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.googleOAuth}',
      ).replace(queryParameters: {'redirect_uri': callbackUrl});

      final launched = await launchUrl(
        authUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not open browser for Google sign-in.');
      }

      return await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () =>
            throw Exception('Google sign-in timed out. Please try again.'),
      );
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  }

  static String _buildCallbackHtml({required bool success}) {
    final title = success ? 'Signed in to Northstar' : 'Sign-in cancelled';
    final body = success
        ? 'Authentication succeeded. You can close this tab and return to Northstar Workspace.'
        : 'Google sign-in was not completed. Please return to the app to retry.';
    return '''
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>$title</title></head>
  <body style="font-family:system-ui,-apple-system,sans-serif;display:grid;place-items:center;min-height:90vh;background:#f4f7ff;color:#0f172a;">
    <div style="background:#fff;padding:32px 36px;border-radius:20px;box-shadow:0 12px 32px rgba(15,23,42,0.08);text-align:center;max-width:380px;">
      <h2 style="margin:0 0 8px;">$title</h2>
      <p style="margin:0;color:#475569;font-size:14px;line-height:1.5;">$body</p>
    </div>
  </body>
</html>
''';
  }
}
