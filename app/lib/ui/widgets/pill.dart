import 'package:flutter/material.dart';

import '../../theme.dart';

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.background,
    this.foreground,
    this.fontSize = 11,
  });

  final String text;
  final Color? background;
  final Color? foreground;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.65,
        vertical: fontSize * 0.18,
      ),
      decoration: BoxDecoration(
        color: background ?? MutantColors.ink.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: fredoka(fontSize, 600, color: foreground ?? MutantColors.chalk),
      ),
    );
  }
}
