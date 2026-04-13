// lib/theme.dart  — Strawberry Manager stark monochrome
import 'package:flutter/material.dart';

class Bk {
  Bk._();

  static const oled        = Color(0xFF000000);
  static const border      = Color(0xFF333333); // subtle outline
  static const borderGlow  = Color(0xFFFFFFFF);
  static const white       = Color(0xFFFFFFFF);
  static const surface0    = Color(0xFF050505);
  static const surface1    = Color(0xFF0A0A0A);
  static const surface2    = Color(0xFF111111);

  // Map all previous accent colors to white/silver to adhere to strictly BW
  static const cyan        = Color(0xFFFFFFFF);
  static const cyanDim     = Color(0xFF888888);
  static const cyanGlow    = Color(0x22FFFFFF);
  static const amber       = Color(0xFFFFFFFF);
  static const red         = Color(0xFFFFFFFF);
  static const green       = Color(0xFFFFFFFF);
  static const violet      = Color(0xFFFFFFFF);
  static const orange      = Color(0xFFFFFFFF);
  static const pink        = Color(0xFFFFFFFF);

  // Text
  static const textPri  = Color(0xFFFFFFFF);
  static const textSec  = Color(0xFF999999);
  static const textDim  = Color(0xFF555555);

  // Glass tints become transparent
  static const glassTint       = Colors.transparent;
  static const glassTintCyan   = Colors.transparent;
  static const glassTintAmber  = Colors.transparent;
  static const glassTintViolet = Colors.transparent;
  static const glassTintRed    = Colors.transparent;

  // Gradients
  static const List<Color> cpuGrad  = [Color(0xFF444444), Color(0xFFFFFFFF)];
  static const List<Color> ramGrad  = [Color(0xFF444444), Color(0xFFFFFFFF)];
  static const List<Color> tempGrad = [Color(0xFF444444), Color(0xFFFFFFFF)];
  static const List<Color> diskGrad = [Color(0xFF444444), Color(0xFFFFFFFF)];
  static const List<Color> netGrad  = [Color(0xFF444444), Color(0xFFFFFFFF)];
}

// ── Outline card wrapper (Replacing GlassCard) ───────────────────────────

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding          = const EdgeInsets.all(18),
    this.radius           = 16.0,
    this.settings,
    this.tint,
    this.onTap,
    this.subtle           = false,
  });

  final Widget                 child;
  final EdgeInsetsGeometry     padding;
  final double                 radius;
  final dynamic                settings;
  final Color?                 tint;
  final VoidCallback?          onTap;
  final bool                   subtle;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: Bk.oled,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Bk.border, width: 1.5),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ── Fake / Glow fallback (Identical now) ───────────────

class FakeGlassCard extends GlassCard {
  const FakeGlassCard({super.key, required super.child, super.padding, super.radius, super.tint, super.onTap});
}

class GlowGlassCard extends GlassCard {
  const GlowGlassCard({super.key, required super.child, super.padding, super.radius, super.onTap, Color? glowColor, Color? tint});
}

// ── Monochrome nav bar ────────────────────────────────────────────────────

class StrawberryNavBar extends StatelessWidget {
  const StrawberryNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.hasCpuAlert   = false,
  });

  final int      selectedIndex;
  final void Function(int) onTap;
  final bool     hasCpuAlert;

  static const _items = [
    _NavItem(icon: 'monitor_heart', label: 'MONITOR'),
    _NavItem(icon: 'tune',          label: 'CONTROL'),
    _NavItem(icon: 'memory',        label: 'PROC'),
    _NavItem(icon: 'terminal',      label: 'SHELL'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Bk.oled,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Bk.border, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = i == selectedIndex;
              final item = _items[i];
              return _NavBtn(
                label:    item.label,
                iconName: item.icon,
                selected: selected,
                badge:    i == 2 && hasCpuAlert,
                onTap:    () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final String icon, label;
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.label, required this.iconName,
    required this.selected, required this.onTap, required this.badge,
  });
  final String label, iconName;
  final bool selected, badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Bk.oled : Bk.textDim;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: selected ? BoxDecoration(
          color: Bk.white,
          borderRadius: BorderRadius.circular(20),
        ) : null,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Badge(
            isLabelVisible: badge,
            backgroundColor: Bk.white,
            smallSize: 6,
            child: Icon(_iconFromName(iconName),
              color: color, size: selected ? 22 : 20),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color: color, fontSize: 8,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 1.5)),
        ]),
      ),
    );
  }

  IconData _iconFromName(String n) => switch (n) {
    'monitor_heart' => Icons.monitor_heart_outlined,
    'tune'          => Icons.tune_outlined,
    'memory'        => Icons.memory_outlined,
    'terminal'      => Icons.terminal_outlined,
    _               => Icons.circle_outlined,
  };
}

// ── Shared primitives ─────────────────────────────────────────────────────

class StatLabel extends StatelessWidget {
  const StatLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(
    color: Bk.textDim, fontSize: 9,
    letterSpacing: 2.5, fontWeight: FontWeight.w700,
  ));
}

class StatValue extends StatelessWidget {
  const StatValue(this.value, {super.key, this.color = Bk.textPri, this.size = 22});
  final String value; final Color color; final double size;
  @override
  Widget build(BuildContext context) => Text(value, style: TextStyle(
    color: color, fontSize: size,
    fontWeight: FontWeight.w900, letterSpacing: -0.5,
  ));
}

class ThinBar extends StatelessWidget {
  const ThinBar({super.key, required this.value, required this.gradient,
    this.height = 4, this.radius = 4});
  final double value; final List<Color> gradient;
  final double height, radius;
  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(children: [
        Container(height: height, color: Bk.border),
        FractionallySizedBox(
          widthFactor: pct,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [BoxShadow(
                color: Bk.white,
                blurRadius: 4, offset: Offset(0, 1),
              )],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────

ThemeData buildTheme() {
  final cs = const ColorScheme.dark().copyWith(
    primary:         Bk.white,
    secondary:       Bk.white,
    tertiary:        Bk.white,
    error:           Bk.white,
    surface:         Bk.oled,
    onSurface:       Bk.textPri,
    outline:         Bk.border,
    surfaceContainer: Bk.surface1,
  );

  return ThemeData(
    useMaterial3:          true,
    colorScheme:           cs,
    scaffoldBackgroundColor: Bk.oled,
    appBarTheme: const AppBarTheme(
      backgroundColor:     Colors.transparent,
      elevation:           0,
      centerTitle:         false,
      titleTextStyle:      TextStyle(
        color: Bk.textPri, fontSize: 16,
        fontWeight: FontWeight.w800, letterSpacing: 1.5,
      ),
      iconTheme:           IconThemeData(color: Bk.white),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor:    Bk.white,
      inactiveTrackColor:  Bk.border,
      thumbColor:          Bk.textPri,
      overlayColor:        Bk.cyanGlow,
      trackHeight:         2.0,
      thumbShape:          RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    textTheme: const TextTheme(
      bodyMedium:  TextStyle(color: Bk.textSec, fontSize: 13),
      labelSmall:  TextStyle(color: Bk.textDim, fontSize: 9, letterSpacing: 2),
    ),
  );
}
// Constants to satisfy legacy usages without throwing undefined
const kDefaultGlassSettings = null;
const kSubtleGlassSettings = null;
const kNavGlassSettings = null;
