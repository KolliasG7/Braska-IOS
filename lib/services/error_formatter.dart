import 'api_service.dart';
import 'payload_sender_service.dart';

class ErrorFormatter {
  static String userMessage(dynamic error) {
    if (error is PayloadException) {
      return error.message;
    }

    if (error is ApiException) {
      if (error.statusCode == 401) return 'Authentication failed. Please login again.';
      if (error.statusCode == 403) return 'Permission denied for this action.';
      if (error.statusCode == 404) return 'Requested resource was not found.';
      if (error.statusCode == 408) return 'Request timed out. Please try again.';
      if (error.statusCode == 409) return 'Conflict detected. Please refresh and retry.';
      if (error.statusCode == 429) return 'Too many requests. Please wait a moment.';
      if (error.statusCode == 502) return 'Bad gateway. Server may be restarting.';
      if (error.statusCode == 503) return 'Service unavailable. Please try again shortly.';
      if (error.statusCode == 504) return 'Gateway timeout. Please check your connection.';
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
    if (msg.contains('FileSystemException')) {
      return 'File system error. Check file permissions and paths.';
    }
    if (msg.contains('FormatException')) {
      return 'Invalid data format received from server.';
    }
    return msg.replaceFirst('Exception: ', '');
  }
}
