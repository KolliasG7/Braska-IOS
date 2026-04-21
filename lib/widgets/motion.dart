// lib/widgets/motion.dart — Shared motion primitives used across the app.
//
// Keep the motion vocabulary in one place so the whole app reads like it
// was designed together: everything presses the same, peer destinations
// fade-through together, and tab bodies swap with the same depth cue.
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Scale-on-press wrapper for tappable surfaces. Squeezes the child to
/// 0.96× while the pointer is down, then springs back on release/cancel.
/// Pair this with whatever haptic/onTap your parent already handles — this
/// widget intentionally doesn't consume the gesture, it only listens for
/// pointer state so it composes cleanly with `InkWell`, `GestureDetector`,
/// etc. above or below it.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown:   (_) => _set(true),
      onPointerUp:     (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: _down
            ? const Duration(milliseconds: 120)
            : const Duration(milliseconds: 220),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Material-ish "fade-through" route for peer destinations (e.g. opening
/// Settings from the dashboard). Incoming page fades in while scaling up
/// from 0.96 → 1.0; outgoing page fades out while scaling up slightly from
/// 1.0 → 1.03 so it reads as receding instead of sliding.
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required Widget child})
    : super(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => child,
        transitionDuration:        AppDurations.med,
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, anim, secondary, child) {
          final enter = CurvedAnimation(parent: anim,      curve: AppCurves.enter);
          final exit  = CurvedAnimation(parent: secondary, curve: AppCurves.exit);

          final fadeIn  = Tween<double>(begin: 0.0, end: 1.0).animate(enter);
          final scaleIn = Tween<double>(begin: 0.96, end: 1.0).animate(enter);

          final fadeOut  = Tween<double>(begin: 1.0, end: 0.0).animate(exit);
          final scaleOut = Tween<double>(begin: 1.0, end: 1.03).animate(exit);

          return FadeTransition(
            opacity: fadeOut,
            child: ScaleTransition(
              scale: scaleOut,
              child: FadeTransition(
                opacity: fadeIn,
                child: ScaleTransition(scale: scaleIn, child: child),
              ),
            ),
          );
        },
      );
}

/// `AnimatedSwitcher` transition builder for tab bodies: scale up from
/// 0.98 with a fade in, no horizontal slide. iOS tab bars never slide
/// their content sideways — the shared nav pill below carries the spatial
/// meaning, so the body just needs to reveal cleanly.
Widget tabBodyTransition(Widget child, Animation<double> anim) {
  final curved = CurvedAnimation(parent: anim, curve: AppCurves.enter);
  final scale  = Tween<double>(begin: 0.98, end: 1.0).animate(curved);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(scale: scale, child: child),
  );
}

/// Layout builder for [AnimatedSwitcher] that keeps the incoming child on
/// top of the outgoing one so the cross-fade doesn't briefly expose the
/// gradient between the two layers.
Widget stackedLayoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    alignment: Alignment.topCenter,
    children: <Widget>[
      ...previousChildren,
      if (currentChild != null) currentChild,
    ],
  );
}
