// lib/theme/typography.dart — Consistent typography for the whole app.
import 'package:flutter/material.dart';
import 'tokens.dart';

class T {
  T._();

  // Display / screen titles.
  static const display = TextStyle(
    color: Bk.textPri, fontSize: 26,
    fontWeight: FontWeight.w800, letterSpacing: -0.3,
  );

  // Section / card titles.
  static const title = TextStyle(
    color: Bk.textPri, fontSize: 17,
    fontWeight: FontWeight.w700, letterSpacing: -0.2,
  );

  // Small uppercase labels above values.
  static const label = TextStyle(
    color: Bk.textDim, fontSize: 10,
    fontWeight: FontWeight.w700, letterSpacing: 2.0,
  );

  // Body copy.
  static const body = TextStyle(
    color: Bk.textSec, fontSize: 13, height: 1.35,
  );

  // Numeric values inside cards.
  static const value = TextStyle(
    color: Bk.textPri, fontSize: 22,
    fontWeight: FontWeight.w900, letterSpacing: -0.5,
  );

  // Small secondary labels next to values.
  static const caption = TextStyle(
    color: Bk.textDim, fontSize: 11, letterSpacing: 0.2,
  );

  // Monospace (terminal, IPs, PIDs).
  static const mono = TextStyle(
    color: Bk.textPri, fontSize: 12,
    fontFamily: 'monospace', height: 1.4,
  );
}
