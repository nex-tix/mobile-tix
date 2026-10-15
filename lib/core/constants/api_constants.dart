import '../config/env_config.dart';

class ApiConstants {
  static String get baseUrl => EnvConfig.baseUrl;

  // Auth
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  // Checkpoint
  static const String checkpoints = '/checkpoints';

  // Ticket
  static const String ticketCheck = '/ticket/check';
  static const String ticketValidateAndCheckin = '/ticket/validate-and-checkin';
  static const String ticketHistory = '/ticket/history';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
}
