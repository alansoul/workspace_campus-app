class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://workspace-campus-api.onrender.com/api';
  static const String socketUrl = 'https://workspace-campus-api.onrender.com';

  // IAM & Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String resolveDomain = '/auth/resolve-domain';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

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