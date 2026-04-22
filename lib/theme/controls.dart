// lib/theme/controls.dart — Buttons, section headers, and small stat primitives.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/motion.dart';
import 'glass.dart';
import 'tokens.dart';
import 'typography.dart';

enum ButtonVariant { primary, glass, destructive }

/// Uniform button used across the app. Primary = filled accent, glass = subtle
/// translucent, destructive = red accent. All share the same height + radius
/// for a consistent visual rhythm.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final (bg, fg, border) = switch (variant) {
      ButtonVariant.primary     => (Bk.accent,        const Color(0xFF06141E), null),
      ButtonVariant.glass       => (Bk.glassDefault,  Bk.textPri,              Bk.glassBorderHi),
      ButtonVariant.destructive => (Bk.danger.withOpacity(0.18), Bk.danger,    Bk.danger.withOpacity(0.45)),
    };

    final radius = BorderRadius.circular(AppRadii.md);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else if (icon != null)
            Icon(icon, size: 18, color: fg),
          if ((loading || icon != null)) const SizedBox(width: 10),
          Text(label, style: TextStyle(
            color: fg, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        ],
      ),
    );

    Widget body = variant == ButtonVariant.primary
      ? Container(
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: content,
        )
      : ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: radius,
                    border: border == null ? null : Border.all(color: border, width: 1),
                  ),
                  child: content,
                ),
                Positioned.fill(
                  child: LiquidGlassSheen(borderRadius: radius),
                ),
              ],
            ),
          ),
        );

    body = Opacity(opacity: disabled ? 0.55 : 1.0, child: body);
    body = Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: disabled ? null : () {
          HapticFeedback.selectionClick();
          onPressed?.call();
        },
        borderRadius: radius,
        child: body,
      ),
    );
    // Squeeze on press so every primary action in the app shares the same
    // tactile "something happened" cue.
    body = PressScale(enabled: !disabled, child: body);
    return expand ? SizedBox(width: double.infinity, child: body) : body;
  }
}

/// Circular icon-only glass button (used for nav/utility actions).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget btn = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: SizedBox(
          width: size, height: size,
          child: Stack(
            children: [
              Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  color: Bk.glassDefault,
                  shape: BoxShape.circle,
                  border: Border.all(color: Bk.glassBorder, width: 1),
                ),
                child: Icon(icon, size: size * 0.48, color: Bk.textPri),
              ),
              Positioned.fill(
                child: LiquidGlassSheen(
                  borderRadius: BorderRadius.circular(size / 2),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    btn = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed == null ? null : () {
          HapticFeedback.selectionClick();
          onPressed!.call();
        },
        child: btn,
      ),
    );
    btn = PressScale(enabled: onPressed != null, child: btn);
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Uppercase section label (used above card groups).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: Text(label, style: T.label)),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ── Legacy primitives kept for the widgets that still use them ─────────────

class StatLabel extends StatelessWidget {
  const StatLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) =>
      Text(label, style: const TextStyle(
        color: Bk.textDim, fontSize: 10,
        letterSpacing: 2.0, fontWeight: FontWeight.w700,
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
  const ThinBar({
    super.key,
    required this.value,
    required this.gradient,
    this.height = 4,
    this.radius = 4,
  });
  final double value;
  final List<Color> gradient;
  final double height, radius;
  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(children: [
        Container(height: height, color: Bk.glassBorder),
        FractionallySizedBox(
          widthFactor: pct,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      ]),
    );
  }
}
