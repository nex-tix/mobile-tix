/// API endpoints for Mobile Tix application
/// 
/// Sesuai dengan PRDMOBILE.md — 8 endpoints tetap.
import '../config/env_config.dart';

class ApiEndpoints {
  const ApiEndpoints._();

  // Authentication
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  // Checkpoint Management
  static const String checkpoints = '/checkpoints';

  // Ticket Validation & Check-in
  static const String ticketCheck = '/ticket/check';
  static const String ticketValidateAndCheckin = '/ticket/validate-and-checkin';

  // Dashboard & History
  static const String dashboardSummary = '/dashboard/summary';
  static const String ticketHistory = '/ticket/history';

  /// Full URL untuk endpoint tertentu
  static String full(String endpoint) {
    return '${EnvConfig.baseUrl}$endpoint';
  }

  /// List semua endpoint yang tersedia
  static const List<String> all = [
    login,
    logout,
    me,
    checkpoints,
    ticketCheck,
    ticketValidateAndCheckin,
    dashboardSummary,
    ticketHistory,
  ];
}
