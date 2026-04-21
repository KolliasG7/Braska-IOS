import 'dart:io';

class PayloadSenderService {
  const PayloadSenderService();

  Future<void> send({
    required String ip,
    required int port,
    required File file,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final socket = await Socket.connect(ip, port, timeout: timeout);
    try {
      await socket.addStream(file.openRead());
      await socket.flush();
    } finally {
      socket.destroy();
    }
  }
}
