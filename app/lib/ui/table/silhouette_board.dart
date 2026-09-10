import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../host/local_host.dart';
import '../../theme.dart';
import '../widgets/pill.dart';

/// Silueta: six slot rectangles arranged as a four-legged creature facing
/// left. Placeholder for the phase-2 paper doll.
class SilhouetteBoard extends StatelessWidget {
  const SilhouetteBoard({super.key, required this.host, this.highlight = false});

  final GameHost host;

  /// A card is being dragged over the board.
  final bool highlight;

  /// Slot rectangles as fractions of the board.
  static const layout = <Slot, Rect>{
    Slot.extra: Rect.fromLTWH(0.38, 0.00, 0.34, 0.22),
    Slot.head: Rect.fromLTWH(0.00, 0.18, 0.30, 0.30),
    Slot.torso: Rect.fromLTWH(0.33, 0.27, 0.40, 0.34),
    Slot.tail: Rect.fromLTWH(0.76, 0.33, 0.24, 0.28),
    Slot.front: Rect.fromLTWH(0.22, 0.66, 0.30, 0.30),
    Slot.back: Rect.fromLTWH(0.56, 0.66, 0.30, 0.30),
  };

  @override
  Widget build(BuildContext context) {
    final state = host.state;
    final silhouette = state.silhouette;
    final hazard = state.hazard;
    final wantedSlot = hazard == null
        ? null
        : host.catalog[state.defIdOf(hazard.card)].requires?.slot;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MutantColors.board,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight ? MutantColors.hint : MutantColors.board,
          width: 3,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (final MapEntry(key: slot, value: rect) in layout.entries)
              Positioned(
                left: rect.left * box.maxWidth,
                top: rect.top * box.maxHeight,
                width: rect.width * box.maxWidth,
                height: rect.height * box.maxHeight,
                child: _SlotTile(
                  slot: slot,
                  fill: silhouette.slots[slot],
                  host: host,
                  wanted: wantedSlot == slot,
                ),
              ),
            if (silhouette.seal case final seal?)
              Positioned(
                left: 0.73 * box.maxWidth - 30,
                top: 0.27 * box.maxHeight - 16,
                child: _SealStamp(def: host.catalog[state.defIdOf(seal)]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.fill,
    required this.host,
    required this.wanted,
  });

  final Slot slot;
  final SlotFill? fill;
  final GameHost host;

  /// The active hazard asks for this slot.
  final bool wanted;

  @override
  Widget build(BuildContext context) {
    final label = host.catalog.label('slot', slot);
    final fill = this.fill;
    final Widget child;
    if (fill == null) {
      child = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: wanted ? MutantColors.hint : MutantColors.boardEdge,
            width: wanted ? 3 : 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: fredoka(
            14,
            600,
            color: wanted ? MutantColors.hint : MutantColors.mist,
          ),
        ),
      );
    } else {
      final defs = [
        for (final card in fill.cards) host.catalog[host.state.defIdOf(card)],
      ];
      final colors = [for (final d in defs) MutantColors.element(d.element)];
      final on = MutantColors.onElement(defs.first.element);
      child = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colors.length == 1 ? colors.first : null,
          gradient: colors.length > 1
              ? LinearGradient(
                  colors: [colors[0], colors[0], colors[1], colors[1]],
                  stops: const [0, 0.5, 0.5, 1],
                )
              : null,
          border: wanted
              ? Border.all(color: MutantColors.hint, width: 3)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  label,
                  style: fredoka(11, 600, color: on.withValues(alpha: 0.75)),
                ),
                if (fill.fused) const Pill('×2'),
                if (fill.mutated) const Pill('mutace'),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  defs.map((d) => d.name).join(' + '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: fredoka(12.5, 600, color: on, height: 1.1),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey(fill?.cards.join(',') ?? 'empty'),
        child: child,
      ),
    );
  }
}

class _SealStamp extends StatelessWidget {
  const _SealStamp({required this.def});

  final CardDef def;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MutantColors.element(def.element),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MutantColors.chalk, width: 2),
      ),
      child: Text(
        'pečeť',
        style: fredoka(12, 700, color: MutantColors.onElement(def.element)),
      ),
    );
  }
}
