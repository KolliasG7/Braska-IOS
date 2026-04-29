// lib/widgets/overview_widgets.dart — Strawberry Manager overview cards
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/telemetry.dart';
import '../theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

String _fmtBytes(double bps) {
  if (bps < 1024)    return '${bps.toStringAsFixed(0)} B/s';
  if (bps < 1048576) return '${(bps/1024).toStringAsFixed(1)} KB/s';
  return '${(bps/1048576).toStringAsFixed(1)} MB/s';
}

Color _pctColor(double p) =>
  p >= 90 ? Bk.red : p >= 70 ? Bk.amber : Bk.cyan;

Color _tempColor(double t) =>
  t >= 88 ? Bk.red : t >= 72 ? Bk.amber : t >= 55 ? const Color(0xFFFFD166) : Bk.green;

// ── Arc gauge ─────────────────────────────────────────────────────────────

class ArcGauge extends StatelessWidget {
  const ArcGauge({super.key, required this.value, required this.color,
    required this.label, required this.sub, this.size = 88});
  final double value, size; final Color color; final String label, sub;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
    child: CustomPaint(
      painter: _ArcP(value.clamp(0.0, 1.0), color),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
          color: color, fontSize: size * 0.22,
          fontWeight: FontWeight.w900, letterSpacing: -0.6,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        )),
        Text(sub, style: TextStyle(
          color: Bk.textDim, fontSize: size * 0.12, letterSpacing: 0.6)),
      ])),
    ),
  );
}

class _ArcP extends CustomPainter {
  const _ArcP(this.v, this.c);
  final double v; final Color c;
  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2; final cy = s.height / 2;
    final r  = s.shortestSide / 2 - 8;
    const start = math.pi * 0.75; const total = math.pi * 1.5;

    // Background arc with subtle glow
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
      start, total, false,
      Paint()..color = Bk.border..style = PaintingStyle.stroke
        ..strokeWidth = 6..strokeCap = StrokeCap.round);

    if (v <= 0) return;
    final sweep = total * v;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Enhanced foreground arc with gradient and glow
    canvas.drawArc(rect, start, sweep, false,
      Paint()
        ..shader = SweepGradient(
          colors: [
            c.withValues(alpha: 0.3),
            c.withValues(alpha: 0.6),
            c,
          ],
          startAngle: start, endAngle: start + sweep,
          tileMode: TileMode.clamp).createShader(rect)
        ..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3));
  }
  @override bool shouldRepaint(_ArcP o) => o.v != v || o.c != c;
}

// ── CPU Card ──────────────────────────────────────────────────────────────

class CpuCard extends StatelessWidget {
  const CpuCard({super.key, required this.cpu, required this.cpuHistory, required this.showGraph});
  final CpuData cpu;
  final List<double> cpuHistory;
  final bool showGraph;
  
  @override
  Widget build(BuildContext context) => GlassCard(
    tint: Bk.glassTintCyan,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const StatLabel('PROCESSOR'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Bk.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: Bk.accent.withValues(alpha: 0.3)),
          ),
          child: Text('${cpu.freqMhz.toStringAsFixed(0)} MHz',
            style: const TextStyle(color: Bk.accent, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        ArcGauge(
          value: cpu.percent / 100,
          color: _pctColor(cpu.percent),
          label: '${cpu.percent.toStringAsFixed(0)}%',
          sub:   '${cpu.coreCount}C',
        ),
        const SizedBox(width: 16),
        Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (int i = 0; i < cpu.perCore.length; i++)
            _CorePill(i, cpu.perCore[i]),
        ])),
      ]),
      const SizedBox(height: 12),

      if (showGraph) ...[
        SizedBox(
          height: 40,
          width: double.infinity,
          child: LineChart(
            duration: Duration.zero,
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              minX: 0, maxX: 49, minY: 0, maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(50, (i) {
                    final idx = cpuHistory.length - 50 + i;
                    return FlSpot(i.toDouble(), idx < 0 ? 0 : cpuHistory[idx]);
                  }),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: _pctColor(cpuHistory.isNotEmpty ? cpuHistory.last : cpu.percent),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _pctColor(cpuHistory.isNotEmpty ? cpuHistory.last : cpu.percent).withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ] else ...[
        ThinBar(value: cpu.percent / 100, gradient: Bk.cpuGrad),
      ],

      const SizedBox(height: 12),
      Row(children: [
        _LoadBadge('1m',  cpu.load1),
        const SizedBox(width: 6),
        _LoadBadge('5m',  cpu.load5),
        const SizedBox(width: 6),
        _LoadBadge('15m', cpu.load15),
      ]),
    ]),
  );
}

class _CorePill extends StatelessWidget {
  const _CorePill(this.idx, this.pct);
  final int idx; final double pct;
  @override Widget build(BuildContext context) {
    final color = _pctColor(pct);
    return Container(
      width: 32, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(children: [
        Text('C$idx', style: const TextStyle(
          color: Bk.textDim, fontSize: 8, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ThinBar(value: pct / 100, gradient: Bk.cpuGrad, height: 4),
      ]),
    );
  }
}

class _LoadBadge extends StatelessWidget {
  const _LoadBadge(this.label, this.val);
  final String label; final double val;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Bk.surface1,
          Bk.surface2,
        ],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Bk.border, width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(
        color: Bk.textDim, fontSize: 9, letterSpacing: 1.8, fontWeight: FontWeight.w700)),
      const SizedBox(width: 6),
      Text(val.toStringAsFixed(2), style: const TextStyle(
        color: Bk.textPri, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
    ]),
  );
}

// ── RAM Card ──────────────────────────────────────────────────────────────

class RamCard extends StatelessWidget {
  const RamCard({super.key, required this.ram, required this.ramHistory, required this.showGraph, this.swap});
  final RamData ram; 
  final List<double> ramHistory;
  final bool showGraph;
  final SwapData? swap;
  @override
  Widget build(BuildContext context) {
    final usedGb  = ram.usedMb  / 1024;
    final totalGb = ram.totalMb / 1024;
    return GlassCard(
      tint: Bk.glassTintViolet,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const StatLabel('MEMORY'),
        const SizedBox(height: 14),
        Row(children: [
          ArcGauge(
            value: ram.percent / 100,
            color: _pctColor(ram.percent),
            label: '${ram.percent.toStringAsFixed(0)}%',
            sub:   '${totalGb.toStringAsFixed(1)}G',
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _MemRow('USED',    '${usedGb.toStringAsFixed(1)} GB',                  Bk.violet),
            _MemRow('FREE',    '${(ram.availableMb/1024).toStringAsFixed(1)} GB',  Bk.green),
            _MemRow('CACHED',  '${(ram.cachedMb/1024).toStringAsFixed(1)} GB',    Bk.textSec),
            _MemRow('BUFFERS', '${(ram.buffersMb/1024).toStringAsFixed(1)} GB',   Bk.textDim),
          ])),
        ]),
        const SizedBox(height: 12),
        if (showGraph) ...[
          SizedBox(
            height: 40, width: double.infinity,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0, maxX: 49, minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(50, (i) {
                      final idx = ramHistory.length - 50 + i;
                      return FlSpot(i.toDouble(), idx < 0 ? 0 : ramHistory[idx]);
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Bk.violet,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Bk.violet.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ThinBar(value: ram.percent / 100, gradient: Bk.ramGrad),
        ],
        if (swap != null && swap!.totalMb > 0) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const StatLabel('SWAP'),
            Text('${swap!.percent.toStringAsFixed(0)}%  '
                 '${(swap!.usedMb/1024).toStringAsFixed(1)}/'
                 '${(swap!.totalMb/1024).toStringAsFixed(1)} GB',
              style: const TextStyle(color: Bk.textSec, fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          ThinBar(value: swap!.percent / 100,
            gradient: const [Bk.amber, Bk.orange], height: 3),
        ],
      ]),
    );
  }
}

class _MemRow extends StatelessWidget {
  const _MemRow(this.label, this.val, this.color);
  final String label, val; final Color color;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(
        color: Bk.textDim, fontSize: 8, letterSpacing: 1.5)),
      Text(val, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    ]),
  );
}

// ── Thermal card ──────────────────────────────────────────────────────────

class ThermalCard extends StatelessWidget {
  const ThermalCard({super.key, required this.fan, required this.tempHistory, required this.fanHistory, required this.showGraph});
  final FanData fan;
  final List<double> tempHistory;
  final List<double> fanHistory;
  final bool showGraph;
  @override
  Widget build(BuildContext context) {
    final tc = _tempColor(fan.apuTempC);
    final tint = fan.apuTempC >= 88 ? Bk.glassTintRed
               : fan.apuTempC >= 72 ? Bk.glassTintAmber
               : Bk.glassTintCyan;
    return GlassCard(
      tint: tint,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const StatLabel('THERMAL · FAN'),
        const SizedBox(height: 14),
        Row(children: [
          ArcGauge(
            value: (fan.apuTempC / 100).clamp(0, 1),
            color: tc,
            label: '${fan.apuTempC.toStringAsFixed(0)}°',
            sub:   'APU',
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _TRow('SPEED',  fan.rpm == 0 ? 'IDLE' : '${fan.rpm} RPM', Bk.cyan),
            _TRow('TRIP',   '${fan.thresholdC}°C',                    Bk.amber),
            _TRow('STATUS', fan.apuTempC >= 88 ? 'CRITICAL'
              : fan.apuTempC >= 72 ? 'WARM' : 'NOMINAL',              tc),
          ])),
        ]),
        const SizedBox(height: 12),
        if (showGraph) ...[
          SizedBox(
            height: 40, width: double.infinity,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0, maxX: 49, minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(50, (i) {
                      final idx = tempHistory.length - 50 + i;
                      return FlSpot(i.toDouble(), idx < 0 ? 0 : tempHistory[idx]);
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _tempColor(tempHistory.isNotEmpty ? tempHistory.last : fan.apuTempC),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _tempColor(tempHistory.isNotEmpty ? tempHistory.last : fan.apuTempC).withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 25, width: double.infinity,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0, maxX: 49, minY: 0, maxY: 4500,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(50, (i) {
                      final idx = fanHistory.length - 50 + i;
                      return FlSpot(i.toDouble(), idx < 0 ? 0 : fanHistory[idx]);
                    }),
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: Bk.cyan,
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Bk.cyan.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ThinBar(value: fan.apuTempC / 100, gradient: Bk.tempGrad, height: 5),
        ],
      ]),
    );
  }
}

class _TRow extends StatelessWidget {
  const _TRow(this.l, this.v, this.c);
  final String l, v; final Color c;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(
        color: Bk.textDim, fontSize: 8, letterSpacing: 1.5)),
      Text(v, style: TextStyle(
        color: c, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    ]),
  );
}

// ── Network card ──────────────────────────────────────────────────────────

class NetworkCard extends StatelessWidget {
  const NetworkCard({super.key, required this.netList});
  final List<NetData> netList;
  @override
  Widget build(BuildContext context) {
    final ifaces = netList.where((n) => n.iface != 'lo').toList();
    if (ifaces.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const StatLabel('NETWORK'),
        const SizedBox(height: 12),
        for (final n in ifaces) _IfRow(n),
      ]),
    );
  }
}

class _IfRow extends StatelessWidget {
  const _IfRow(this.n);
  final NetData n;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(n.iface, style: const TextStyle(
          color: Bk.textPri, fontSize: 12,
          fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        Row(children: [
          _NetBadge('↑', _fmtBytes(n.bytesSentS), Bk.cyan),
          const SizedBox(width: 8),
          _NetBadge('↓', _fmtBytes(n.bytesRecvS), Bk.green),
        ]),
      ]),
      if (n.bytesSentS > 0 || n.bytesRecvS > 0) ...[
        const SizedBox(height: 5),
        ThinBar(
          value: math.min(1.0, (n.bytesRecvS + n.bytesSentS) / 1048576),
          gradient: Bk.netGrad, height: 3),
      ],
      if (n.errin > 0 || n.errout > 0)
        Padding(padding: const EdgeInsets.only(top: 3),
          child: Text('ERR in:${n.errin} out:${n.errout}',
            style: const TextStyle(color: Bk.red, fontSize: 9))),
    ]),
  );
}

class _NetBadge extends StatelessWidget {
  const _NetBadge(this.dir, this.val, this.color);
  final String dir, val; final Color color;
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(dir, style: TextStyle(
      color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900)),
    const SizedBox(width: 3),
    Text(val, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  ]);
}

// ── Disk card ─────────────────────────────────────────────────────────────

class DiskCard extends StatelessWidget {
  const DiskCard({super.key, required this.disks});
  final List<DiskData> disks;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const StatLabel('STORAGE'),
      const SizedBox(height: 12),
      for (final d in disks) _DRow(d),
    ]),
  );
}

class _DRow extends StatelessWidget {
  const _DRow(this.d);
  final DiskData d;
  Color get _c => d.percent >= 90 ? Bk.red
    : d.percent >= 75 ? Bk.amber : Bk.cyan;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(d.mount, style: const TextStyle(
          color: Bk.textPri, fontSize: 12, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis)),
        Text('${d.usedGb.toStringAsFixed(1)} / ${d.totalGb.toStringAsFixed(1)} GB',
          style: const TextStyle(color: Bk.textSec, fontSize: 10)),
      ]),
      const SizedBox(height: 5),
      ThinBar(value: d.percent / 100,
        gradient: [_c.withValues(alpha: 0.5), _c], height: 5),
      const SizedBox(height: 4),
      Row(children: [
        Text('${d.percent.toStringAsFixed(1)}%  ${d.fstype}',
          style: const TextStyle(color: Bk.textDim, fontSize: 9, letterSpacing: 0.5)),
        const Spacer(),
        if (d.readBps > 0 || d.writeBps > 0) ...[
          Text('R ${_fmtBytes(d.readBps)}',
            style: const TextStyle(color: Bk.textDim, fontSize: 9)),
          const SizedBox(width: 8),
          Text('W ${_fmtBytes(d.writeBps)}',
            style: const TextStyle(color: Bk.textDim, fontSize: 9)),
        ],
      ]),
    ]),
  );
}

// ── Uptime chip ───────────────────────────────────────────────────────────

class UptimeChip extends StatelessWidget {
  const UptimeChip({super.key, required this.uptime});
  final String uptime;
  @override Widget build(BuildContext context) => GlassCard(
    style: GlassStyle.subtle,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.timer_outlined, color: Bk.textDim, size: 14),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const StatLabel('UPTIME'),
        const SizedBox(height: 2),
        Text(uptime, style: const TextStyle(
          color: Bk.textPri, fontSize: 14, fontWeight: FontWeight.w900)),
      ]),
    ]),
  );
}
