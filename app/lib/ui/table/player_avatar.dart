import 'package:flutter/material.dart';

import '../../host/seat.dart';
import '../../theme.dart';
import '../widgets/pill.dart';

/// A seat at the table. Tap to see its hand; drop a card on it to pass.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.initial,
    required this.color,
    required this.name,
    required this.mode,
    required this.cards,
    required this.viewed,
    required this.calling,
    required this.incoming,
    required this.dropHover,
    required this.onTap,
  });

  final String initial;
  final Color color;
  final String name;
  final SeatMode mode;
  final int cards;
  final bool viewed;

  /// Holds a part for an empty slot – "zavolej si".
  final bool calling;

  /// A passed card is flying towards this seat.
  final bool incoming;
  final bool dropHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = dropHover
        ? MutantColors.hint
        : viewed
        ? MutantColors.chalk
        : MutantColors.boardEdge;
    return Semantics(
      button: true,
      label: '$name, $cards karet',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: ring,
                      width: viewed || dropHover ? 3 : 2,
                    ),
                    boxShadow: calling
                        ? [
                            BoxShadow(
                              color: MutantColors.hint.withValues(alpha: 0.6),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    initial,
                    style: fredoka(20, 700, color: MutantColors.ink, height: 1),
                  ),
                ),
                Positioned(
                  right: -6,
                  top: -4,
                  child: Pill(
                    '$cards',
                    background: MutantColors.chalk,
                    foreground: MutantColors.ink,
                    fontSize: 12,
                  ),
                ),
                if (incoming)
                  const Positioned(
                    left: -4,
                    bottom: -6,
                    child: Pill(
                      'chyť!',
                      background: MutantColors.hint,
                      foreground: MutantColors.ink,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(mode.label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
