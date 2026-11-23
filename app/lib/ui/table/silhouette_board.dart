import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../host/local_host.dart';
import '../../services/game_assets.dart';
import '../../theme.dart';
import '../figure/figure_view.dart';
import '../widgets/pill.dart';

/// Silueta: six slot tiles laid out as an upright figure (PLAN-KOLEKCE §5.1).
/// In collection mode the single remaining mutant shows as a big shadow
/// behind the tiles and its missing parts are named. Shakes when a throw of
/// the viewed seat is rejected.
class SilhouetteBoard extends StatefulWidget {
  const SilhouetteBoard({
    super.key,
    required this.host,
    this.highlight = false,
  });

  final GameHost host;

  /// A card is being dragged over the board.
  final bool highlight;

  /// Slot tiles as fractions of the board: head on top, torso in the middle,
  /// front limbs at the side, hind limbs below, tail low behind, extra over
  /// the shoulder.
  static const layout = <Slot, Rect>{
    Slot.head: Rect.fromLTWH(0.33, 0.00, 0.34, 0.25),
    Slot.extra: Rect.fromLTWH(0.70, 0.04, 0.29, 0.24),
    Slot.front: Rect.fromLTWH(0.01, 0.30, 0.29, 0.26),
    Slot.torso: Rect.fromLTWH(0.33, 0.28, 0.34, 0.36),
    Slot.tail: Rect.fromLTWH(0.70, 0.46, 0.29, 0.24),
    Slot.back: Rect.fromLTWH(0.33, 0.68, 0.34, 0.31),
  };

  @override
  State<SilhouetteBoard> createState() => _SilhouetteBoardState();
}

class _SilhouetteBoardState extends State<SilhouetteBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late StreamSubscription<GameEvent> _events;

  GameHost get host => widget.host;

  @override
  void initState() {
    super.initState();
    _events = host.events.listen(_onEvent);
  }

  @override
  void didUpdateWidget(SilhouetteBoard old) {
    super.didUpdateWidget(old);
    if (old.host != widget.host) {
      _events.cancel();
      _events = host.events.listen(_onEvent);
    }
  }

  void _onEvent(GameEvent event) {
    if (event is CardBounced && event.player == host.viewedSeat) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _events.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = host.state;
    final silhouette = state.silhouette;
    final hazard = state.hazard;
    final wantedSlot = hazard == null
        ? null
        : host.catalog[state.defIdOf(hazard.card)].requires?.slot;
    final candidates = currentCandidates(state);
    final single = candidates.length == 1 ? candidates.single : null;
    final missing = neededParts(silhouette, candidates);

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
          0,
        ),
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MutantColors.board,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.highlight ? MutantColors.hint : MutantColors.board,
            width: 3,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final side = math.min(box.maxWidth, box.maxHeight);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (single != null)
                  Center(
                    child: Opacity(
                      opacity: 0.55,
                      child: FigureView(
                        key: ValueKey('shadow-${single.id}'),
                        mutant: single,
                        catalog: host.catalog,
                        look: FigureLook.shadow,
                        size: side,
                      ),
                    ),
                  ),
                for (final MapEntry(key: slot, value: rect)
                    in SilhouetteBoard.layout.entries)
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
                      missingCard: missing[slot],
                    ),
                  ),
                if (silhouette.seal case final seal?)
                  Positioned(
                    left: 0.67 * box.maxWidth - 30,
                    top: 0.28 * box.maxHeight - 14,
                    child: _SealStamp(def: host.catalog[state.defIdOf(seal)]),
                  ),
              ],
            );
          },
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
    this.missingCard,
  });

  final Slot slot;
  final SlotFill? fill;
  final GameHost host;

  /// The active hazard asks for this slot.
  final bool wanted;

  /// Collection mode with one candidate left: the part still needed here.
  final String? missingCard;

  @override
  Widget build(BuildContext context) {
    final label = host.catalog.label('slot', slot);
    final fill = this.fill;
    final Widget child;
    if (fill == null) {
      final missing = missingCard;
      final accent = wanted || missing != null;
      child = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: MutantColors.night.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent ? MutantColors.hint : MutantColors.boardEdge,
            width: accent ? 3 : 2,
          ),
        ),
        alignment: Alignment.center,
        child: missing == null
            ? Text(
                label,
                style: fredoka(
                  14,
                  600,
                  color: wanted ? MutantColors.hint : MutantColors.mist,
                ),
              )
            : Text(
                'Chybí:\n${host.catalog[missing].name}',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: fredoka(12, 600, color: MutantColors.hint, height: 1.1),
              ),
      );
    } else {
      final defs = [
        for (final card in fill.cards) host.catalog[host.state.defIdOf(card)],
      ];
      final colors = [for (final d in defs) MutantColors.element(d.element)];
      final on = MutantColors.onElement(defs.first.element);
      final image = GameAssets.instance.art.card(defs.first.id);
      child = Container(
        padding: const EdgeInsets.all(5),
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
                if (fill.wild)
                  const Pill('žolík')
                else if (fill.mutated)
                  const Pill('mutace'),
              ],
            ),
            Expanded(
              child: image != null
                  ? Image.asset(image, fit: BoxFit.contain)
                  : Align(
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
        key: ValueKey(fill?.cards.join(',') ?? 'empty-$missingCard'),
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
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MutantColors.element(def.element),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MutantColors.chalk, width: 2),
      ),
      child: Text(
        'pečeť',
        style: fredoka(12, 700, color: MutantColors.onElement(def.element)),
      ),
    );
  }
}

/// „Kdo to bude?" – which mutants the silhouette can still become.
/// Many → a question mark; 2–4 → their shadows; 1 → it is decided.
class CandidateStrip extends StatelessWidget {
  const CandidateStrip({super.key, required this.host});

  static const height = 60.0;

  final GameHost host;

  @override
  Widget build(BuildContext context) {
    final collection = host.engine.collection;
    if (!host.rules.closedCollection || collection == null) {
      return const SizedBox.shrink();
    }
    final candidates = currentCandidates(host.state);
    final text = Theme.of(context).textTheme;
    final Widget content;
    if (candidates.length == 1) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: MutantColors.hint),
          const SizedBox(width: 8),
          Text('Už víme, kdo to bude!', style: text.titleSmall),
        ],
      );
    } else if (candidates.length <= 4) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Kdo to bude?', style: text.titleSmall),
          const SizedBox(width: 10),
          for (final m in candidates)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FigureView(
                key: ValueKey('cand-${m.id}'),
                mutant: m,
                catalog: host.catalog,
                look: FigureLook.shadow,
                size: 46,
              ),
            ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Kdo to bude?', style: text.titleSmall),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: MutantColors.ink,
              shape: BoxShape.circle,
            ),
            child: Text('?', style: fredoka(24, 700, color: MutantColors.hint)),
          ),
          if (candidates.length < collection.length) ...[
            const SizedBox(width: 10),
            Text('ještě ${candidates.length} možností', style: text.bodySmall),
          ],
        ],
      );
    }
    return SizedBox(
      height: height,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(candidates.map((m) => m.id).join(',')),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(fit: BoxFit.scaleDown, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
