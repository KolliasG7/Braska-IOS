import 'dart:async';
import 'dart:io';

class PayloadException implements Exception {
  PayloadException(this.message);
  final String message;
  @override String toString() => 'PayloadException: $message';
}

class PayloadSenderService {
  const PayloadSenderService();

  Future<void> send({
    required String ip,
    required int port,
    required File file,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Validate inputs
    if (ip.isEmpty) {
      throw PayloadException('IP address cannot be empty');
    }
    if (port <= 0 || port > 65535) {
      throw PayloadException('Port must be between 1 and 65535');
    }
    if (!await file.exists()) {
      throw PayloadException('File does not exist: ${file.path}');
    }
    if (await file.length() == 0) {
      throw PayloadException('File is empty: ${file.path}');
    }

    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: timeout);

      // Send file data
      final stream = file.openRead();
      await socket.addStream(stream);
      await socket.flush();

      // Give time for data to be sent
      await Future.delayed(const Duration(milliseconds: 100));
    } on SocketException catch (e) {
      throw PayloadException('Connection failed: ${e.message}');
    } on TimeoutException catch (e) {
      throw PayloadException('Connection timed out: ${e.message}');
    } on FileSystemException catch (e) {
      throw PayloadException('File system error: ${e.message}');
    } catch (e) {
      throw PayloadException('Failed to send payload: $e');
    } finally {
      socket?.destroy();
    }
  }
}
