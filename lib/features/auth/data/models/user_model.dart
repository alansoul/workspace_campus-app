class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String role;
  final String? universityId;
  final String? universityName;
  final String? branch;
  final String? institutionalEmail;
  final bool isEmailVerified;
  final String accountType;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
    this.universityId,
    this.universityName,
    this.branch,
    this.institutionalEmail,
    this.isEmailVerified = false,
    required this.accountType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] as String?) ?? '';
    final fallbackUsername =
        email.contains('@') ? email.split('@').first : 'campus_user';
    return UserModel(
      id: (json['id'] as String?) ?? '',
      email: email,
      username: (json['username'] as String?) ?? fallbackUsername,
      fullName: (json['fullName'] as String?) ??
          (json['name'] as String?) ??
          fallbackUsername,
      role: (json['role'] as String?) ?? 'STUDENT',
      universityId: json['universityId'] as String?,
      universityName: json['universityName'] as String?,
      branch: json['branch'] as String?,
      institutionalEmail: json['institutionalEmail'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      accountType: json['accountType'] as String? ??
          (json['universityId'] != null ? 'INSTITUTIONAL' : 'INDIVIDUAL'),
    );
  }
}
