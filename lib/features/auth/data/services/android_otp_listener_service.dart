import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Listens to Android's native `OtpNotificationListenerService` over platform channels
/// to auto-fill 6-digit Northstar OTP codes when email or SMS notifications arrive.
class AndroidOtpListenerService {
  AndroidOtpListenerService._();

  static const MethodChannel _methodChannel =
      MethodChannel('northstar/otp_autofill');
  static const EventChannel _eventChannel =
      EventChannel('northstar/otp_events');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Consumes a recent OTP already captured by the Android notification listener.
  static Future<String?> consumeLatestOtp() async {
    if (!_isAndroid) return null;
    try {
      final raw = await _methodChannel.invokeMethod<String>('getLatestOtp');
      if (raw != null && RegExp(r'^\d{6}$').hasMatch(raw)) {
        return raw;
      }
    } catch (_) {
      // MissingPluginException in tests or older builds — fail gracefully
    }
    return null;
  }

  /// Broadcasts incoming 6-digit OTPs from Android notification events.
  static Stream<String> otpStream() {
    if (!_isAndroid) return const Stream<String>.empty();
    return _eventChannel.receiveBroadcastStream().transform(
      StreamTransformer<dynamic, String>.fromHandlers(
        handleData: (data, sink) {
          if (data is String && RegExp(r'^\d{6}$').hasMatch(data)) {
            sink.add(data);
          }
        },
        handleError: (_, _, _) {
          // Ignore platform channel availability errors in tests / unsupported hosts
        },
      ),
    );
  }
}
