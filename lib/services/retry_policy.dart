// lib/services/retry_policy.dart - Network retry logic with proper imports
import 'dart:async';

/// Retry policy for failed network operations
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
  });

  /// Execute function with exponential backoff retry
  Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(dynamic error)? retryIf,
  }) async {
    Duration delay = initialDelay;
    dynamic lastError;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        
        // Check if we should retry this error
        if (retryIf != null && !retryIf(e)) {
          rethrow;
        }
        
        // Don't delay after last attempt
        if (attempt == maxAttempts) {
          rethrow;
        }
        
        // Wait before retrying
        await Future.delayed(delay);
        
        // Exponential backoff: 1s → 2s → 4s
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );
      }
    }
    
    throw lastError ?? Exception('Retry exhausted');
  }
}

/// Common retry conditions
class RetryConditions {
  /// Only retry on timeout errors
  static bool isTimeout(dynamic error) {
    return error.toString().contains('TimeoutException') ||
           error.toString().contains('timed out');
  }
  
  /// Only retry on connection errors (not auth errors)
  static bool isConnectionError(dynamic error) {
    final msg = error.toString();
    return (msg.contains('Connection') || 
            msg.contains('timeout') ||
            msg.contains('SocketException')) &&
           !msg.contains('401') &&
           !msg.contains('Unauthorized');
  }
  
  /// Retry on most errors except auth/validation
  static bool isFatal(dynamic error) {
    final msg = error.toString();
    // Don't retry auth/validation errors
    if (msg.contains('401') || 
        msg.contains('403') || 
        msg.contains('422') ||
        msg.contains('Unauthorized') ||
        msg.contains('Forbidden')) {
      return false;
    }
    return true;
  }
}
