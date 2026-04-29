// lib/models/telemetry.dart

class CpuData {
  final double percent;
  final List<double> perCore;
  final int coreCount;
  final double freqMhz, freqMaxMhz;
  final double load1, load5, load15;

  const CpuData({
    required this.percent, required this.perCore, required this.coreCount,
    required this.freqMhz, required this.freqMaxMhz,
    required this.load1, required this.load5, required this.load15,
  });

  factory CpuData.fromJson(Map<String, dynamic> j) => CpuData(
    percent:    _num(j['percent']),
    perCore:    _numList(j['per_core']),
    coreCount:  _int(j['core_count']),
    freqMhz:    _num(j['freq_mhz']),
    freqMaxMhz: _num(j['freq_max_mhz']),
    load1:      _num(j['load_1']),
    load5:      _num(j['load_5']),
    load15:     _num(j['load_15']),
  );
}

class RamData {
  final double totalMb, usedMb, availableMb, cachedMb, buffersMb, percent;

  const RamData({
    required this.totalMb, required this.usedMb, required this.availableMb,
    required this.cachedMb, required this.buffersMb, required this.percent,
  });

  factory RamData.fromJson(Map<String, dynamic> j) => RamData(
    totalMb:    _num(j['total_mb']),
    usedMb:     _num(j['used_mb']),
    availableMb:_num(j['available_mb']),
    cachedMb:   _num(j['cached_mb']),
    buffersMb:  _num(j['buffers_mb']),
    percent:    _num(j['percent']),
  );
}

class SwapData {
  final double totalMb, usedMb, percent;
  const SwapData({required this.totalMb, required this.usedMb, required this.percent});
  factory SwapData.fromJson(Map<String, dynamic> j) => SwapData(
    totalMb: _num(j['total_mb']),
    usedMb:  _num(j['used_mb']),
    percent: _num(j['percent']),
  );
}

class DiskData {
  final String mount, device, fstype;
  final double totalGb, usedGb, freeGb, percent, readBps, writeBps;

  const DiskData({
    required this.mount, required this.device, required this.fstype,
    required this.totalGb, required this.usedGb, required this.freeGb,
    required this.percent, required this.readBps, required this.writeBps,
  });

  factory DiskData.fromJson(Map<String, dynamic> j) => DiskData(
    mount:    j['mount']    as String? ?? '',
    device:   j['device']   as String? ?? '',
    fstype:   j['fstype']   as String? ?? '',
    totalGb:  _num(j['total_gb']),
    usedGb:   _num(j['used_gb']),
    freeGb:   _num(j['free_gb']),
    percent:  _num(j['percent']),
    readBps:  _num(j['read_bps']),
    writeBps: _num(j['write_bps']),
  );
}

class NetData {
  final String iface;
  final double bytesSentS, bytesRecvS;
  final int packetsSent, packetsRecv, errin, errout;

  const NetData({
    required this.iface, required this.bytesSentS, required this.bytesRecvS,
    required this.packetsSent, required this.packetsRecv,
    required this.errin, required this.errout,
  });

  factory NetData.fromJson(Map<String, dynamic> j) => NetData(
    iface:       j['iface']         as String? ?? '',
    bytesSentS:  _num(j['bytes_sent_s']),
    bytesRecvS:  _num(j['bytes_recv_s']),
    packetsSent: _int(j['packets_sent']),
    packetsRecv: _int(j['packets_recv']),
    errin:       _int(j['errin']),
    errout:      _int(j['errout']),
  );
}

class FanData {
  final int rpm, thresholdC;
  final double apuTempC;
  const FanData({required this.rpm, required this.thresholdC, required this.apuTempC});
  factory FanData.fromJson(Map<String, dynamic> j) => FanData(
    rpm:        _int(j['rpm']),
    thresholdC: _int(j['threshold_c']),
    apuTempC:   _num(j['apu_temp_c']),
  );
}

class TunnelStatus {
  final String state;
  final String? url;
  const TunnelStatus({required this.state, this.url});
  factory TunnelStatus.fromJson(Map<String, dynamic> j) => TunnelStatus(
    state: j['state'] as String? ?? 'stopped',
    url:   j['url']   as String?,
  );
  bool get isRunning => state == 'running';
}

class TelemetryFrame {
  final double ts;
  final FanData? fan;
  final CpuData? cpu;
  final RamData? ram;
  final SwapData? swap;
  final List<DiskData> disk;
  final List<NetData> net;
  final int uptimeS;
  final TunnelStatus? tunnel;
  final String? error;

  const TelemetryFrame({
    required this.ts, this.fan, this.cpu, this.ram, this.swap,
    this.disk = const [], this.net = const [],
    this.uptimeS = 0, this.tunnel, this.error,
  });

  bool get isError => error != null;

  factory TelemetryFrame.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('error')) {
      return TelemetryFrame(
        ts: _num(j['ts']),
        error: j['error'] as String? ?? 'Unknown telemetry error',
      );
    }
    return TelemetryFrame(
      ts:      _num(j['ts']),
      fan:     j['fan'] is Map ? FanData.fromJson(Map<String, dynamic>.from(j['fan'] as Map)) : null,
      cpu:     j['cpu'] is Map ? CpuData.fromJson(Map<String, dynamic>.from(j['cpu'] as Map)) : null,
      ram:     j['ram'] is Map ? RamData.fromJson(Map<String, dynamic>.from(j['ram'] as Map)) : null,
      swap:    j['swap'] is Map ? SwapData.fromJson(Map<String, dynamic>.from(j['swap'] as Map)) : null,
      disk:    _mapList(j['disk']).map(DiskData.fromJson).toList(),
      net:     _mapList(j['net']).map(NetData.fromJson).toList(),
      uptimeS: _int(j['uptime_s']),
      tunnel:  j['tunnel'] is Map ? TunnelStatus.fromJson(Map<String, dynamic>.from(j['tunnel'] as Map)) : null,
    );
  }

  String get uptimeFormatted {
    final d = uptimeS ~/ 86400;
    final h = (uptimeS % 86400) ~/ 3600;
    final m = (uptimeS % 3600)  ~/ 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  NetData? get primaryNet {
    if (net.isEmpty) return null;
    return net.firstWhere(
      (n) => n.iface != 'lo' && (n.bytesSentS > 0 || n.bytesRecvS > 0),
      orElse: () => net.firstWhere((n) => n.iface != 'lo', orElse: () => net.first),
    );
  }
}

double _num(dynamic value, [double fallback = 0.0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<double> _numList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => _num(e)).toList();
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}
