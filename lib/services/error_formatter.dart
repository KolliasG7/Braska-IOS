import 'api_service.dart';

class ErrorFormatter {
  static String userMessage(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) return 'Authentication failed. Please login again.';
      if (error.statusCode == 403) return 'Permission denied for this action.';
      if (error.statusCode == 404) return 'Requested resource was not found.';
      if (error.statusCode == 408) return 'Request timed out. Please try again.';
      if (error.statusCode >= 500) return 'Server error. Please try again shortly.';
      return error.message.isNotEmpty ? error.message : 'Request failed.';
    }

    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'Unable to reach the server. Check host and network.';
    }
    if (msg.contains('TimeoutException') || msg.toLowerCase().contains('timed out')) {
      return 'Connection timed out. Please retry.';
    }
    return msg.replaceFirst('Exception: ', '');
  }
}
