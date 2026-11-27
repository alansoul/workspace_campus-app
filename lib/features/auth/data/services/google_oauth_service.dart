import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'google_oauth_service_stub.dart'
    if (dart.library.io) 'google_oauth_service_io.dart';

export 'google_oauth_service_stub.dart'
    if (dart.library.io) 'google_oauth_service_io.dart';

final googleOAuthServiceProvider = Provider<GoogleOAuthService>((ref) {
  return GoogleOAuthService();
});
