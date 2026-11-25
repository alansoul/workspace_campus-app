class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String role;
  final String? universityId;
  final String? universityName;
  final String? branch;
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
    required this.accountType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      universityId: json['universityId'] as String?,
      universityName: json['universityName'] as String?,
      branch: json['branch'] as String?,
      accountType: json['accountType'] as String? ?? 'INDIVIDUAL',
    );
  }
}