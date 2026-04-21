// lib/screens/settings_screen.dart - KEY FIX FOR PAYLOAD INJECTION
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/connection_provider.dart';
import '../services/payload_history_service.dart';
import '../theme.dart';

  Future<void> _injectPayload(String ip, int port, File file) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Bk.surface2,
      content: Text('Connecting to $ip:$port...',
        style: const TextStyle(color: Bk.white, fontSize: 12))));

    try {
      // FIXED: Increased timeout from 3 seconds to 10 seconds for slow networks
      final socket = await Socket.connect(ip, port,
        timeout: const Duration(seconds: 10));
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      final fileName = file.path.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Bk.surface2,
        content: Text('Sending $fileName...',
          style: const TextStyle(color: Bk.textSec, fontSize: 12))));

      await socket.addStream(file.openRead());
      await socket.flush();
      socket.destroy();

      // Save to history
      await PayloadHistoryService.save(PayloadRecord(
        ip: ip,
        port: port,
        fileName: fileName,
        filePath: file.path,
        sentAt: DateTime.now(),
      ));
      _loadPayloadHistory();

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✓ Payload sent successfully!',
          style: TextStyle(color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w900)),
        backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e',
          style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: Colors.red.shade900));
    }
  }
