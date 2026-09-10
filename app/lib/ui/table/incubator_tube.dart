import 'package:flutter/material.dart';

import '../../theme.dart';

/// The game's heartbeat: a thick tube of liquid that drains and jumps back up
/// with every good throw. Mint when healthy, amber, then red.
class IncubatorTube extends StatelessWidget {
  const IncubatorTube({
    super.key,
    required this.level,
    required this.max,
    this.frozen = false,
  });

  final double level;
  final double max;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final fraction = (level / max).clamp(0.0, 1.0);
    return Semantics(
      label: 'Inkubátor ${level.round()} z ${max.round()}',
      child: Container(
        // Full width always, or the tube shrinks with the liquid and looks full.
        width: double.infinity,
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: MutantColors.board,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MutantColors.boardEdge, width: 2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: constraints.maxWidth * fraction,
                decoration: BoxDecoration(
                  color: MutantColors.incubator(level),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.egg_rounded,
                        size: 18,
                        color: MutantColors.ink,
                      ),
                      const Spacer(),
                      if (frozen)
                        Text(
                          'zmrazeno  ',
                          style: fredoka(13, 600, color: MutantColors.chalk),
                        ),
                      Text(
                        '${level.round()}',
                        style: fredoka(
                          15,
                          700,
                          color: fraction > 0.88
                              ? MutantColors.ink
                              : MutantColors.chalk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
