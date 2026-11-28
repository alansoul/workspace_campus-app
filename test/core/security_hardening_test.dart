import 'dart:io';
import 'package:campus_mobile/core/constants/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cross-platform security hardening checks', () {
    test('default API endpoint enforces HTTPS', () {
      expect(ApiEndpoints.isSecureEndpoint(ApiEndpoints.baseUrl), isTrue);
      expect(ApiEndpoints.baseUrl.startsWith('https://'), isTrue);
    });

    test('rejects insecure remote cleartext HTTP while allowing loopback dev', () {
      expect(
        ApiEndpoints.isSecureEndpoint('http://workspace-campus-api.onrender.com/api'),
        isFalse,
      );
      expect(ApiEndpoints.isSecureEndpoint('http://127.0.0.1:4000/api'), isTrue);
      expect(ApiEndpoints.isSecureEndpoint('http://localhost:4000/api'), isTrue);
      expect(ApiEndpoints.isSecureEndpoint('http://10.0.2.2:4000/api'), isTrue);
    });

    test('AndroidManifest disables ADB backups and configures network security', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:networkSecurityConfig="@xml/network_security_config"'));

      final netConfig =
          File('android/app/src/main/res/xml/network_security_config.xml').readAsStringSync();
      expect(netConfig, contains('cleartextTrafficPermitted="false"'));
    });
  });
}
