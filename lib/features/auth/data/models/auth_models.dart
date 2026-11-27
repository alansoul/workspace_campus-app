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
  final bool isNetworkError;
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
    this.isNetworkError = false,
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

  static const Set<String> blockedConsumerDomains = {
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'icloud.com',
    'proton.me',
    'protonmail.com',
    'aol.com',
  };

  static String deriveShortCode(String name) {
    final letters = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (letters.length < 2) return 'CAMP';
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

  static bool isBlockedConsumerDomain(String domain) {
    return blockedConsumerDomains.contains(cleanDomain(domain));
  }

  static bool isDomainRelated(String domain, String emailDomain) {
    final d = cleanDomain(domain);
    final ed = cleanDomain(emailDomain);
    if (d.isEmpty || ed.isEmpty) return false;
    return d == ed || d.endsWith('.$ed');
  }

  /// Mirrors `isStudentEmail` in campus-api (`university.service.ts`).
  static bool isStudentEmail(String email) {
    final parts = email.trim().toLowerCase().split('@');
    if (parts.length != 2) return false;
    final localPart = parts[0];
    final domainPart = parts[1];
    if (localPart.isEmpty || domainPart.isEmpty) return false;

    if (domainPart.startsWith('student.') ||
        domainPart.contains('.std.') ||
        domainPart.contains('.student.')) {
      return true;
    }

    return RegExp(r'^[a-z]{0,4}\d{4,8}[a-z0-9]*$', caseSensitive: false)
            .hasMatch(localPart) ||
        RegExp(r'^\d{2,4}[a-z]{2,5}\d{2,5}$', caseSensitive: false)
            .hasMatch(localPart) ||
        RegExp(r'\d{5,}').hasMatch(localPart);
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
