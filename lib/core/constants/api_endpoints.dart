class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://workspace-campus-api.onrender.com/api',
  );
  static String get socketUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  // IAM & Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String resolveDomain = '/auth/resolve-domain';
  static const String requestOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String setPassword = '/auth/password/set';
  static const String resetPassword = '/auth/password/reset';
  static const String verifyAndRegister = '/auth/verify-and-register';
  static const String googleOAuth = '/auth/google';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // University Organisation Onboarding
  static const String requestUniversityOtp = '/universities/request-otp';
  static const String claimUniversity = '/universities/claim';

  // Academics
  static const String timetable = '/university/timetable';
  static const String attendance = '/university/attendance';
  static const String logAttendance = '/university/attendance/log';
  static const String notices = '/university/notices';

  // Chat
  static const String channels = '/chat/channels';
  static const String directChats = '/chat/direct';
  static const String liveKitToken = '/chat/livekit/token';
  static const String upload = '/chat/upload';

  // Freelance
  static const String gigs = '/freelance/gigs';

  // AI Copilot
  static const String aiChat = '/ai/chat';
}
