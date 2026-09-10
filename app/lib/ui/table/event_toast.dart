import 'package:flutter/material.dart';

import '../../theme.dart';

class EventToast extends StatelessWidget {
  const EventToast({super.key, required this.message, required this.id});

  final String? message;

  /// Changes with every new message so repeated texts still animate.
  final int id;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          // Drop the old line at once so two messages never overlap.
          reverseDuration: Duration.zero,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: message == null
              ? const SizedBox.shrink(key: ValueKey('none'))
              : Padding(
                  key: ValueKey(id),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    message!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fredoka(16, 600, color: MutantColors.hint),
                  ),
                ),
        ),
      ),
    );
  }
}
