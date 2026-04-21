// lib/theme/glass.dart — Real glassmorphism primitives using BackdropFilter.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'tokens.dart';

enum GlassStyle { subtle, normal, raised }

/// Translucent frosted-glass card. Uses a BackdropFilter so the dark gradient
/// background shows through a blurred layer. Stack under an `AppShell` or any
/// scaffold with a non-opaque background for the effect to be visible.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius  = AppRadii.lg,
    this.style   = GlassStyle.normal,
    this.tint,
    this.onTap,
    this.margin,
    // Legacy params — ignored but preserved so existing call sites compile.
    @Deprecated('use style') this.settings,
    @Deprecated('use style: GlassStyle.subtle') this.subtle = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final GlassStyle style;
  final Color? tint;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Object? settings;
  final bool subtle;

  Color get _fill => switch (subtle ? GlassStyle.subtle : style) {
    GlassStyle.subtle => Bk.glassSubtle,
    GlassStyle.normal => Bk.glassDefault,
    GlassStyle.raised => Bk.glassRaised,
  };

  Color get _border => switch (subtle ? GlassStyle.subtle : style) {
    GlassStyle.subtle => Bk.glassBorder,
    GlassStyle.normal => Bk.glassBorder,
    GlassStyle.raised => Bk.glassBorderHi,
  };

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    // Glass fill and the optional tint gradient live on separate layers so
    // the tint (which fades to transparent) never erases the frosted fill,
    // and the caller's intended alpha is preserved instead of being clobbered
    // by a hardcoded opacity.
    Widget body = Container(
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: borderRadius,
        border: Border.all(color: _border, width: 1),
      ),
      child: tint == null
          ? Padding(padding: padding, child: child)
          : Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tint!, tint!.withOpacity(0)],
                ),
              ),
              padding: padding,
              child: child,
            ),
    );
    Widget content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: body,
      ),
    );

    if (style == GlassStyle.raised) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: content,
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    return content;
  }
}

/// A small glass capsule — used for chips, status pills, nav items.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.tint,
    this.onTap,
    this.selected = false,
    this.radius = AppRadii.pill,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final VoidCallback? onTap;
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final baseTint = tint ?? Bk.accent;
    final fill = selected ? baseTint.withOpacity(0.18) : Bk.glassDefault;
    final borderColor = selected ? baseTint.withOpacity(0.55) : Bk.glassBorder;

    Widget inner = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: inner,
      ),
    );
  }
}

/// Bottom sheet / modal body wrapped in glass.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Bk.glassDefault,
            border: Border(top: BorderSide(color: Bk.glassBorderHi, width: 1)),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

// ── Legacy aliases ──────────────────────────────────────────────────────────
// Some screens still import these names. Keep them as thin wrappers.

class FakeGlassCard extends GlassCard {
  const FakeGlassCard({
    super.key,
    required super.child,
    super.padding,
    super.radius,
    super.tint,
    super.onTap,
  });
}

class GlowGlassCard extends GlassCard {
  const GlowGlassCard({
    super.key,
    required super.child,
    super.padding,
    super.radius,
    super.onTap,
    Color? glowColor,
    Color? tint,
  }) : super(tint: tint);
}
