import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../host/local_host.dart';
import '../../services/bestiary_store.dart';
import '../../services/game_assets.dart';
import '../../theme.dart';
import '../figure/figure_view.dart';
import '../hand/card_face.dart';
import '../hatch/creature_card.dart';
import '../hatch/rename_dialog.dart';

enum RevealPhase { collect, assemble, turn, show, free }

/// Reveal of a collection mutant (PLAN-KOLEKCE §5.3). The game clock is
/// stopped while it runs; a tap skips to the next step.
class RevealOverlay extends StatefulWidget {
  const RevealOverlay({
    super.key,
    required this.record,
    required this.mutant,
    required this.host,
    required this.store,
  });

  final CreatureRecord record;
  final MutantDef mutant;
  final GameHost host;
  final BestiaryStore store;

  static const collectMs = 1500;
  static const assembleMs = 1500;
  static const turnMs = 2000;
  static const moveMs = 1350;

  @override
  State<RevealOverlay> createState() => _RevealOverlayState();
}

class _RevealOverlayState extends State<RevealOverlay>
    with SingleTickerProviderStateMixin {
  final _figure = FigureController();
  late final AnimationController _clock = AnimationController(vsync: this);
  RevealPhase _phase = RevealPhase.collect;
  Timer? _timer;
  int _shownSlot = -1;
  double _dragTurn = 0;

  CreatureRecord get record => widget.record;
  bool get halfBaked => record.premature;

  @override
  void initState() {
    super.initState();
    _enter(RevealPhase.collect);
  }

  void _enter(RevealPhase phase) {
    _timer?.cancel();
    setState(() {
      _phase = phase;
      _shownSlot = -1;
    });
    final ms = switch (phase) {
      RevealPhase.collect => RevealOverlay.collectMs,
      RevealPhase.assemble => RevealOverlay.assembleMs,
      RevealPhase.turn => RevealOverlay.turnMs,
      RevealPhase.show || RevealPhase.free => 0,
    };
    if (ms > 0) {
      _clock
        ..duration = Duration(milliseconds: ms)
        ..forward(from: 0);
      _timer = Timer(Duration(milliseconds: ms), _next);
    } else if (phase == RevealPhase.show) {
      _showSlot(0);
    } else {
      _figure.cheer();
    }
  }

  void _showSlot(int index) {
    if (!mounted) return;
    if (index >= Slot.values.length) return _enter(RevealPhase.free);
    final slot = Slot.values[index];
    setState(() => _shownSlot = index);
    _figure.play(slot, _moveOf(slot));
    _timer = Timer(
      const Duration(milliseconds: RevealOverlay.moveMs),
      () => _showSlot(index + 1),
    );
  }

  String _partOf(Slot slot) => widget.mutant.parts[slot]!;

  String _moveOf(Slot slot) => GameAssets.instance.moveOf(_partOf(slot), slot);

  void _next() {
    if (!mounted) return;
    final next = switch (_phase) {
      RevealPhase.collect => RevealPhase.assemble,
      RevealPhase.assemble => RevealPhase.turn,
      RevealPhase.turn => halfBaked ? RevealPhase.free : RevealPhase.show,
      RevealPhase.show || RevealPhase.free => RevealPhase.free,
    };
    if (next != _phase) _enter(next);
  }

  Future<void> _rename() async {
    final name = await showRenameDialog(context, record.name);
    if (name == null) return;
    widget.store.rename(record.id, name);
    widget.host.renamePendingHatch(name);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.dispose();
    _figure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _phase == RevealPhase.free ? null : _next,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MutantColors.night.withValues(alpha: 0.94),
          image: switch (GameAssets.instance.art.backdrop('reveal_stage')) {
            final path? => DecorationImage(
              image: AssetImage(path),
              fit: BoxFit.cover,
              opacity: 0.55,
            ),
            null => null,
          },
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final figureSize = math.min(
                box.maxWidth - 48,
                box.maxHeight * 0.46,
              );
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Text(switch (_phase) {
                    RevealPhase.collect => 'Líhne se…',
                    _ when halfBaked => 'Nedopečený!',
                    _ => 'Vylíhl se!',
                  }, style: text.displaySmall),
                  Expanded(
                    child: Center(
                      child: _phase == RevealPhase.collect
                          ? _CollectCards(
                              record: record,
                              host: widget.host,
                              clock: _clock,
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _stage(figureSize),
                            ),
                    ),
                  ),
                  _caption(text),
                  if (_phase == RevealPhase.free) _freeControls(),
                  if (_phase != RevealPhase.free)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Ťukni pro přeskočení',
                        style: text.bodySmall,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stage(double size) {
    final look = halfBaked ? FigureLook.grey : FigureLook.painted;
    Widget figure = FigureView(
      key: const ValueKey('reveal-figure'),
      mutant: widget.mutant,
      catalog: widget.host.catalog,
      look: look,
      controller: _figure,
      size: size,
    );
    figure = AnimatedBuilder(
      animation: _clock,
      child: figure,
      builder: (context, child) {
        var scale = 1.0;
        var turn = _dragTurn;
        var opacity = 1.0;
        if (_phase == RevealPhase.assemble) {
          final t = Curves.easeOutBack.transform(_clock.value);
          scale = 0.3 + 0.7 * t;
          opacity = _clock.value.clamp(0, 1);
        } else if (_phase == RevealPhase.turn) {
          turn = Curves.easeInOut.transform(_clock.value) * 2 * math.pi;
        }
        return Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(turn)
              ..scaleByDouble(scale, scale, 1, 1),
            child: child,
          ),
        );
      },
    );
    if (_phase == RevealPhase.free) {
      figure = GestureDetector(
        onHorizontalDragUpdate: (d) =>
            setState(() => _dragTurn += d.delta.dx / size * math.pi),
        onHorizontalDragEnd: (_) => setState(() => _dragTurn = 0),
        child: figure,
      );
    }
    final element = record.element;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (_phase == RevealPhase.show && !halfBaked)
              _Sparks(
                key: ValueKey('sparks-$_shownSlot'),
                color: MutantColors.element(element),
                size: size,
              ),
            figure,
          ],
        ),
        if (_phase != RevealPhase.assemble)
          Pedestal(rarity: halfBaked ? null : record.rarity, width: size * 0.8),
      ],
    );
  }

  Widget _caption(TextTheme text) {
    final names = widget.host.engine.names;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey('$_phase-$_shownSlot'),
        child: switch (_phase) {
          RevealPhase.collect ||
          RevealPhase.assemble => const SizedBox(height: 72),
          RevealPhase.show when _shownSlot >= 0 => SizedBox(
            height: 72,
            child: Text(
              GameAssets.instance.moveLabel(_partOf(Slot.values[_shownSlot])),
              style: text.headlineSmall?.copyWith(color: MutantColors.hint),
            ),
          ),
          _ => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(record.name, style: text.headlineSmall),
                const SizedBox(height: 4),
                if (halfBaked)
                  Text(
                    'Nestihli jsme ho dopéct – zkuste ho postavit celého',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RarityPips(
                        rarity: record.rarity,
                        color: MutantColors.chalk,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        names.rarityLabel(record.rarity),
                        style: text.titleSmall,
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  'Tvůrci: ${record.creators.map((c) => c.name).join(', ')}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        },
      ),
    );
  }

  Widget _freeControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          if (!halfBaked)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final slot in Slot.values)
                  ActionChip(
                    label: Text(GameAssets.instance.moveLabel(_partOf(slot))),
                    onPressed: () => _figure.play(slot, _moveOf(slot)),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _rename,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Přejmenovat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.host.acknowledgeHatch,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Další mutant'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Step 1: the cards from the silhouette fly into the incubator, then a flash.
class _CollectCards extends StatelessWidget {
  const _CollectCards({
    required this.record,
    required this.host,
    required this.clock,
  });

  final CreatureRecord record;
  final GameHost host;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    final ids = [for (final slot in Slot.values) ...?record.parts[slot]];
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final t = Curves.easeInCubic.transform(
            (clock.value / 0.8).clamp(0, 1),
          );
          final flash = ((clock.value - 0.75) / 0.25).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final (i, id) in ids.indexed)
                Transform.translate(
                  offset: Offset.fromDirection(
                    i / ids.length * 2 * math.pi - math.pi / 2,
                    (1 - t) * math.min(box.maxWidth, box.maxHeight) * 0.34,
                  ),
                  child: Transform.scale(
                    scale: 1 - 0.6 * t,
                    child: CardFace(
                      def: host.catalog[id],
                      catalog: host.catalog,
                      width: 72,
                    ),
                  ),
                ),
              Opacity(
                opacity: math.sin(flash * math.pi),
                child: Container(
                  width: box.maxWidth * 0.8,
                  height: box.maxWidth * 0.8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [MutantColors.chalk, Color(0x00F4EEFF)],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Element particles around the figure while a part shows its move.
class _Sparks extends StatefulWidget {
  const _Sparks({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_Sparks> createState() => _SparksState();
}

class _SparksState extends State<_Sparks> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 10; i++)
              Transform.translate(
                offset: Offset.fromDirection(
                  i / 10 * 2 * math.pi,
                  widget.size * (0.2 + 0.32 * _c.value),
                ),
                child: Opacity(
                  opacity: 1 - _c.value,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Podstavec: its colour is the rarity; null = unpainted grey.
class Pedestal extends StatelessWidget {
  const Pedestal({super.key, required this.rarity, required this.width});

  final Rarity? rarity;
  final double width;

  static Color colorOf(Rarity? rarity) => switch (rarity) {
    null => const Color(0xFF8E87A3),
    Rarity.common => const Color(0xFFB9ACD9),
    Rarity.uncommon => const Color(0xFF6EE7B7),
    Rarity.rare => const Color(0xFF42A5F5),
    Rarity.epic => const Color(0xFFB57BFF),
    Rarity.legendary => const Color(0xFFFFC94A),
    Rarity.mythic => const Color(0xFFFF7EB6),
  };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(rarity);
    return Container(
      width: width,
      height: width * 0.12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.elliptical(width / 2, width * 0.06),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, Color.lerp(color, MutantColors.ink, 0.5)!],
        ),
      ),
    );
  }
}
