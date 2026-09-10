import 'package:flutter/material.dart';

import '../../host/local_host.dart';
import '../../host/seat.dart';
import '../../theme.dart';
import '../widgets/pill.dart';
import 'card_face.dart';

/// Cards flying to the viewed seat. Tap before the ring runs out to catch.
class IncomingPasses extends StatelessWidget {
  const IncomingPasses({super.key, required this.host});

  final GameHost host;

  @override
  Widget build(BuildContext context) {
    final state = host.state;
    final seat = host.viewedSeat;
    final passes = [
      for (final pass in state.passes)
        if (pass.to == seat) pass,
    ];
    if (passes.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final pass in passes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              button: true,
              label: 'Chyť kartu',
              // The label sits under the card, inside the tap area.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => host.catchCard(seat, pass.card),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CardFace(
                          def: host.catalog[state.defIdOf(pass.card)],
                          catalog: host.catalog,
                          width: 76,
                        ),
                        Positioned(
                          top: -12,
                          right: -12,
                          child: _Countdown(
                            left: (pass.expiresAt - state.now).clamp(
                              0,
                              host.rules.catchWindowMs,
                            ),
                            total: host.rules.catchWindowMs,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Pill(
                          'Chyť!',
                          background: MutantColors.hint,
                          foreground: MutantColors.ink,
                          fontSize: 13,
                        ),
                        const SizedBox(width: 4),
                        SeatMark(
                          initial: seatAvatars[pass.from].initial,
                          color: seatAvatars[pass.from].color,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.left, required this.total});

  final int left;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: MutantColors.night,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : left / total,
              strokeWidth: 4,
              color: MutantColors.hint,
            ),
          ),
          Text(
            '${(left / 1000).ceil()}',
            style: fredoka(13, 700, color: MutantColors.chalk),
          ),
        ],
      ),
    );
  }
}
