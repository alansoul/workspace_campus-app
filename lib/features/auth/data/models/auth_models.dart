import 'user_model.dart';

/// Supported OTP request purposes matching `RequestOtpDto` in campus-api.
enum OtpPurpose {
  login('LOGIN'),
  register('REGISTER'),
  resetPassword('RESET_PASSWORD');

  final String apiValue;
  const OtpPurpose(this.apiValue);
}

/// University domain & safe account lookup result from `/auth/resolve-domain`.
class DomainResolution {
  final bool allowed;
  final bool isRegistered;
  final bool isGmail;
  final bool isUniversity;
  final String? domain;
  final String? universityId;
  final String? universityName;
  final String? universityShortCode;
  final bool? accountExists;
  final bool? hasPassword;
  final bool isUniversityAdmin;
  final String? accountRole;
  final String? errorMessage;

  const DomainResolution({
    required this.allowed,
    required this.isRegistered,
    this.isGmail = false,
    this.isUniversity = false,
    this.domain,
    this.universityId,
    this.universityName,
    this.universityShortCode,
    this.accountExists,
    this.hasPassword,
    this.isUniversityAdmin = false,
    this.accountRole,
    this.errorMessage,
  });

  factory DomainResolution.fromJson(Map<String, dynamic> json) {
    final uni = json['university'] as Map<String, dynamic>?;
    return DomainResolution(
      allowed: json['allowed'] as bool? ?? false,
      isRegistered: json['isRegistered'] as bool? ?? false,
      isGmail: json['isGmail'] as bool? ?? false,
      isUniversity: json['isUniversity'] as bool? ?? false,
      domain: json['domain'] as String?,
      universityId: uni?['id'] as String?,
      universityName:
          (json['universityName'] as String?) ?? (uni?['name'] as String?),
      universityShortCode: uni?['shortCode'] as String?,
      accountExists: json['accountExists'] as bool?,
      hasPassword: json['hasPassword'] as bool?,
      isUniversityAdmin: json['isUniversityAdmin'] as bool? ?? false,
      accountRole: json['accountRole'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Result returned when verifying an OTP code.
class OtpVerificationResult {
  final UserModel user;
  final bool requiresPasswordSetup;
  final String? message;

  const OtpVerificationResult({
    required this.user,
    required this.requiresPasswordSetup,
    this.message,
  });
}

/// Payload used when claiming and creating a new university organisation.
class UniversityClaimRequest {
  final String universityName;
  final String shortCode;
  final String contactName;
  final String contactEmail;
  final String domain;
  final String otp;
  final String password;

  const UniversityClaimRequest({
    required this.universityName,
    required this.shortCode,
    required this.contactName,
    required this.contactEmail,
    required this.domain,
    required this.otp,
    required this.password,
  });

  static String deriveShortCode(String name) {
    final letters = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (letters.isEmpty) return 'CAMP';
    return letters.length >= 4 ? letters.substring(0, 4) : letters;
  }

  static String cleanDomain(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^www\.', caseSensitive: false), '')
        .replaceAll(RegExp(r'/+$'), '');
  }

  Map<String, dynamic> toJson() => {
        'name': universityName.trim(),
        'shortCode': shortCode.trim().isEmpty
            ? deriveShortCode(universityName)
            : shortCode.trim().toUpperCase(),
        'contactName': contactName.trim(),
        'contactEmail': contactEmail.trim().toLowerCase(),
        'domains': [cleanDomain(domain)],
        'otp': otp.trim(),
        'password': password,
      };
}

/// Password rule checklist helper shared by signup, reset, and org setup.
class PasswordRequirements {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumberOrSymbol;

  const PasswordRequirements({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumberOrSymbol,
  });

  factory PasswordRequirements.evaluate(String password) {
    return PasswordRequirements(
      hasMinLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasNumberOrSymbol: RegExp(r'[0-9!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]')
          .hasMatch(password),
    );
  }

  bool get isStrong => hasMinLength && hasUppercase && hasNumberOrSymbol;
}
