// lib/models/process_info.dart

double _jsonDouble(Map<String, dynamic> j, List<String> keys, [double fallback = 0.0]) {
  for (final key in keys) {
    final value = j[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

int _jsonInt(Map<String, dynamic> j, List<String> keys, [int fallback = 0]) {
  for (final key in keys) {
    final value = j[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

String _jsonString(Map<String, dynamic> j, List<String> keys, [String fallback = '']) {
  for (final key in keys) {
    final value = j[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return fallback;
}

class ProcessInfo {
  final int pid, threads;
  final String name, user, status, cmdline;
  final double cpuPct, memRssMb, memPct;

  const ProcessInfo({
    required this.pid, required this.threads,
    required this.name, required this.user,
    required this.status, required this.cmdline,
    required this.cpuPct, required this.memRssMb, required this.memPct,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> j) => ProcessInfo(
    pid:      _jsonInt(j, ['pid']),
    threads:  _jsonInt(j, ['threads'], 1),
    name:     _jsonString(j, ['name', 'command']),
    user:     _jsonString(j, ['user', 'username']),
    status:   _jsonString(j, ['status', 'state']),
    cmdline:  _jsonString(j, ['cmdline', 'command']),
    cpuPct:   _jsonDouble(j, ['cpu_pct', 'cpuPercent', 'cpu_percent', 'cpu']),
    memRssMb: _jsonDouble(j, ['mem_rss_mb', 'memoryMb', 'memory_mb', 'memory']),
    memPct:   _jsonDouble(j, ['mem_pct', 'memory_percent']),
  );
}
