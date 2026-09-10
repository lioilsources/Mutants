import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../host/local_host.dart';
import '../../host/seat.dart';
import '../../theme.dart';
import 'card_face.dart';

/// A card being dragged, with the seat that holds it – the view may switch
/// while the finger is down.
typedef HeldCard = ({int seat, int card});

/// The viewed seat's hand as a fan. Drag a card onto the creature to throw
/// it (a quick flick upwards works too) or onto an avatar to pass it.
class HandArea extends StatelessWidget {
  const HandArea({super.key, required this.host});

  static const height = 212.0;
  static const cardWidth = 100.0;

  final GameHost host;

  @override
  Widget build(BuildContext context) {
    final seat = host.viewedSeat;
    final hand = host.state.players[seat].hand;
    final fitting = fittingCards(host.state, host.catalog, seat).toSet();
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SeatMark(
                  initial: seatAvatars[seat].initial,
                  color: seatAvatars[seat].color,
                ),
                const SizedBox(width: 8),
                Text(seatAvatars[seat].name, style: text.titleSmall),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'táhni na tvora, nebo na kamaráda',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: hand.isEmpty
                ? Center(
                    child: Text(
                      'Kotlík ti brzy dá kartu.',
                      style: text.bodyMedium,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, box) =>
                        _fan(context, box.maxWidth, seat, hand, fitting),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _fan(
    BuildContext context,
    double width,
    int seat,
    List<int> hand,
    Set<int> fitting,
  ) {
    final n = hand.length;
    final step = n == 1
        ? 0.0
        : ((width - 32 - cardWidth) / (n - 1)).clamp(
            cardWidth * 0.5,
            cardWidth + 8,
          );
    final total = cardWidth + step * (n - 1);
    final start = ((width - total) / 2).clamp(8.0, double.infinity);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < n; i++)
          Positioned(
            left: start + step * i,
            top: 10 + (i - (n - 1) / 2).abs() * 5,
            child: Transform.rotate(
              angle: (i - (n - 1) / 2) * 0.05,
              child: _DraggableCard(
                key: ValueKey(hand[i]),
                host: host,
                seat: seat,
                card: hand[i],
                fits: fitting.contains(hand[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    super.key,
    required this.host,
    required this.seat,
    required this.card,
    required this.fits,
  });

  final GameHost host;
  final int seat;
  final int card;
  final bool fits;

  @override
  Widget build(BuildContext context) {
    final def = host.catalog[host.state.defIdOf(card)];
    Widget face({bool dimmed = false}) => CardFace(
      def: def,
      catalog: host.catalog,
      width: HandArea.cardWidth,
      dimmed: dimmed,
    );
    return Draggable<HeldCard>(
      data: (seat: seat, card: card),
      onDragStarted: () => host.viewLocked = true,
      onDragEnd: (details) {
        host.viewLocked = false;
        // A flick upwards that didn't reach the board still throws.
        if (!details.wasAccepted && details.velocity.pixelsPerSecond.dy < -900) {
          host.throwCard(seat, card);
        }
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.08, child: face()),
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: face()),
      child: face(dimmed: !fits),
    );
  }
}
