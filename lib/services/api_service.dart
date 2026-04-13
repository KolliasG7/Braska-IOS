// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/process_info.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  bool get isUnauth => statusCode == 401;
  @override String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService(this.baseUrl, {this.token = ''});

  final String baseUrl;
  String token;

  bool get isTunnel =>
    baseUrl.startsWith('https://') || baseUrl.startsWith('http://') ||
    baseUrl.contains('.trycloudflare.com');

  Uri _u(String path) {
    if (isTunnel) {
      final b = baseUrl.startsWith('http') ? baseUrl : 'https://$baseUrl';
      return Uri.parse('$b$path');
    }
    return Uri.parse('http://$baseUrl$path');
  }

  Map<String, String> get _h => {
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  // ── Auth ──────────────────────────────────────────────────────────────

  Future<String> login(String password) async {
    final r = await http.post(_u('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    ).timeout(const Duration(seconds: 8));
    _chk(r);
    final t = jsonDecode(r.body)['token'] as String;
    token = t;
    return t;
  }

  Future<bool> verifyToken() async {
    if (token.isEmpty) return false;
    try {
      final r = await http.get(_u('/auth/verify'), headers: _h)
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── Health ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getHealth() async {
    final r = await http.get(_u('/')).timeout(const Duration(seconds: 5));
    _chk(r); return jsonDecode(r.body);
  }

  // ── Fan ───────────────────────────────────────────────────────────────

  Future<int> getFanThreshold() async {
    final r = await http.get(_u('/api/fan/threshold'), headers: _h)
        .timeout(const Duration(seconds: 5));
    _chk(r); return (jsonDecode(r.body)['threshold'] as num).toInt();
  }

  Future<int> setFanThreshold(int c) async {
    final r = await http.post(_u('/api/fan/threshold'),
      headers: _h, body: jsonEncode({'threshold': c}),
    ).timeout(const Duration(seconds: 8));
    _chk(r); return (jsonDecode(r.body)['threshold_confirmed'] as num).toInt();
  }

  // ── LED ───────────────────────────────────────────────────────────────

  Future<List<String>> getLedProfiles() async {
    final r = await http.get(_u('/api/led/profiles'), headers: _h)
        .timeout(const Duration(seconds: 5));
    _chk(r); return List<String>.from(jsonDecode(r.body)['profiles']);
  }

  Future<String> setLed(String p) async {
    final r = await http.post(_u('/api/led'), headers: _h,
      body: jsonEncode({'profile': p}),
    ).timeout(const Duration(seconds: 5));
    _chk(r); return jsonDecode(r.body)['profile'];
  }

  Future<String?> getActiveLed() async {
    final r = await http.get(_u('/api/led/active'), headers: _h)
        .timeout(const Duration(seconds: 5));
    _chk(r); return jsonDecode(r.body)['active'] as String?;
  }

  // ── System ────────────────────────────────────────────────────────────

  Future<List<ProcessInfo>> getProcesses({int limit = 50, String sortBy = 'cpu'}) async {
    final r = await http.get(
      _u('/api/system/processes?limit=$limit&sort_by=$sortBy'), headers: _h,
    ).timeout(const Duration(seconds: 8));
    _chk(r);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final processes = body['processes'];
    if (processes is! List) return const [];
    return processes
        .whereType<Map>()
        .map((e) => ProcessInfo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> killProcess(int pid, {String signal = 'SIGTERM'}) async {
    final r = await http.post(_u('/api/system/process/kill'),
      headers: _h, body: jsonEncode({'pid': pid, 'signal': signal}),
    ).timeout(const Duration(seconds: 5));
    _chk(r);
  }

  // ── Tunnel ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startTunnel() async {
    final r = await http.post(_u('/api/tunnel/start'), headers: _h)
        .timeout(const Duration(seconds: 35));
    _chk(r); return jsonDecode(r.body);
  }

  Future<void> stopTunnel() async {
    final r = await http.post(_u('/api/tunnel/stop'), headers: _h)
        .timeout(const Duration(seconds: 10));
    _chk(r);
  }

  Future<Map<String, dynamic>> getTunnelStatus() async {
    final r = await http.get(_u('/api/tunnel/status'), headers: _h)
        .timeout(const Duration(seconds: 5));
    _chk(r); return jsonDecode(r.body);
  }

  // ── Power ─────────────────────────────────────────────────────────────

  Future<void> powerAction(String action) async {
    final r = await http.post(_u('/api/power/$action'), headers: _h)
        .timeout(const Duration(seconds: 10));
    _chk(r);
  }

  // ── Files ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listFiles(String path) async {
    final encoded = Uri.encodeQueryComponent(path);
    final r = await http.get(_u('/api/files/list?path=$encoded'), headers: _h)
        .timeout(const Duration(seconds: 10));
    _chk(r); return jsonDecode(r.body);
  }

  Future<Uint8List> downloadFile(String path) async {
    final encoded = Uri.encodeQueryComponent(path);
    final r = await http.get(_u('/api/files/download?path=$encoded'), headers: _h)
        .timeout(const Duration(seconds: 120));
    _chk(r); return r.bodyBytes;
  }

  Future<Map<String, dynamic>> uploadFile({
    required Uint8List bytes,
    required String filename,
    required String destDir,
  }) async {
    final encoded = Uri.encodeQueryComponent(destDir);
    final headers = {
      ...?(_h.isNotEmpty ? _h : null),
      'Content-Type':  'application/octet-stream',
      'X-File-Name':   filename,
      'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
    };
    final r = await http.post(
      _u('/api/files/upload?dest=$encoded'),
      headers: headers,
      body: bytes,
    ).timeout(const Duration(seconds: 120));
    _chk(r); return jsonDecode(r.body);
  }

  Future<void> deleteFile(String path) async {
    final encoded = Uri.encodeQueryComponent(path);
    final r = await http.delete(_u('/api/files/delete?path=$encoded'), headers: _h)
        .timeout(const Duration(seconds: 10));
    _chk(r);
  }

  void _chk(http.Response r) {
    if (r.statusCode >= 400) {
      String d = r.body;
      try { d = (jsonDecode(r.body)['detail'] ?? d).toString(); } catch (_) {}
      throw ApiException(r.statusCode, d);
    }
  }
}
