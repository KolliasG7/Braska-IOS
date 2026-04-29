// lib/widgets/led_panel.dart — Strawberry Manager LED control with LiquidGlassBlendGroup
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

const _kMeta = <String, _M>{
  'off':               _M('Off',           Color(0xFF2E4459), Icons.power_off_outlined),
  'blue':              _M('Blue',          Color(0xFF0096C7), Icons.circle),
  'white':             _M('White',         Color(0xFFCFDFEE), Icons.circle),
  'white_blue':        _M('White+Blue',    Color(0xFF6AC4E0), Icons.circle),
  'orange':            _M('Orange',        Color(0xFFFF8C00), Icons.circle),
  'orange_blue':       _M('Orange+Blue',   Color(0xFF48CAE4), Icons.circle),
  'orange_white':      _M('Orange+White',  Color(0xFFFFCC44), Icons.circle),
  'orange_white_blue': _M('Full Mix',      Color(0xFFADE8F4), Icons.circle),
  'violet_blue':       _M('Violet',        Color(0xFF9B6DFF), Icons.circle),
  'pink':              _M('Pink 🍓',       Color(0xFFFF6BA8), Icons.circle),
  'pink_blue':         _M('Pink+Blue',     Color(0xFFDA77FF), Icons.circle),
  'pulsate_orange':    _M('Pulsate',       Color(0xFFFF8C00), Icons.auto_awesome_outlined),
};

class _M {
  const _M(this.label, this.color, this.icon);
  final String label; final Color color; final IconData icon;
}

class LedPanelCard extends StatefulWidget {
  const LedPanelCard({super.key, required this.api});
  final ApiService api;
  @override State<LedPanelCard> createState() => _LedPanelCardState();
}

class _LedPanelCardState extends State<LedPanelCard>
    with SingleTickerProviderStateMixin {
  List<String> _profiles = [];
  String? _active, _pending, _err;
  bool _loading = true;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _load();
  }

  @override void dispose() { _glowCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final p = await widget.api.getLedProfiles();
      final a = await widget.api.getActiveLed();
      if (!mounted) return;
      setState(() { _profiles = p; _active = a; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _set(String p) async {
    if (_pending != null) return;
    setState(() { _pending = p; _err = null; });
    try {
      await widget.api.setLed(p);
      if (!mounted) return;
      setState(() { _active = p; _pending = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = e.toString(); _pending = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMeta = _active != null ? _kMeta[_active] : null;

    return GlassCard(
      tint: activeMeta != null && _active != 'off'
        ? activeMeta.color.withValues(alpha:0.08) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const StatLabel('FRONT PANEL'),
          if (activeMeta != null && _active != 'off')
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeMeta.color.withValues(alpha:0.05 + _glowCtrl.value * 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activeMeta.color.withValues(alpha:0.3 + _glowCtrl.value * 0.3)),
                  boxShadow: [BoxShadow(
                    color: activeMeta.color.withValues(alpha:0.15 + _glowCtrl.value * 0.15),
                    blurRadius: 8)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeMeta.color,
                    boxShadow: [BoxShadow(
                      color: activeMeta.color.withValues(alpha:0.8), blurRadius: 6)],
                  )),
                  const SizedBox(width: 6),
                  Text(activeMeta.label, style: TextStyle(
                    color: activeMeta.color, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 14),

        if (_loading)
          const Center(child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(color: Bk.cyan, strokeWidth: 2)))
        else
          // Button grid — 3 columns
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 2.0,
              crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _profiles.length,
            itemBuilder: (_, i) {
              final p   = _profiles[i];
              final m   = _kMeta[p] ?? _M(p, Bk.textDim, Icons.circle);
              final act = p == _active;
              final pnd = p == _pending;
              return _LedBtn(
                profile: p, meta: m,
                active: act, pending: pnd,
                onTap: () => _set(p),
                glowAnim: act ? _glowCtrl : null,
              );
            },
          ),

        if (_err != null) ...[
          const SizedBox(height: 10),
          Text('✗ $_err',
            style: const TextStyle(color: Bk.red, fontSize: 11)),
        ],
      ]),
    );
  }
}

class _LedBtn extends StatelessWidget {
  const _LedBtn({
    required this.profile, required this.meta,
    required this.active, required this.pending,
    required this.onTap, this.glowAnim,
  });
  final String profile; final _M meta;
  final bool active, pending;
  final VoidCallback onTap;
  final Animation<double>? glowAnim;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: active && glowAnim != null
        // Active state
        ? AnimatedBuilder(
            animation: glowAnim!,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                color: Bk.white.withValues(alpha:0.12 + glowAnim!.value * 0.06),
                border: Border.all(color: Bk.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _BtnContent(meta: meta, active: true, pending: pending),
            ),
          )
        // Inactive
        : Container(
            decoration: BoxDecoration(
              color: Bk.surface1,
              border: Border.all(color: Bk.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _BtnContent(meta: meta, active: false, pending: pending),
          ),
    );
  }
}

class _BtnContent extends StatelessWidget {
  const _BtnContent({required this.meta, required this.active, required this.pending});
  final _M meta; final bool active, pending;
  @override Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(meta.icon,
          color: active ? Bk.white : Bk.textDim,
          size: 15),
        const SizedBox(height: 3),
        Text(meta.label, style: TextStyle(
          color: active ? Bk.white : Bk.textDim,
          fontSize: 8.5,
          fontWeight: active ? FontWeight.w900 : FontWeight.w400,
          letterSpacing: 0.3),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
      if (pending)
        const Positioned(top: 4, right: 4,
          child: SizedBox(width: 9, height: 9,
            child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Bk.white))),
    ],
  );
}
