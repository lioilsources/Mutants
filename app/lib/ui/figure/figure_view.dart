import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../services/game_assets.dart';
import '../../theme.dart';

enum FigureLook {
  /// Normal colours.
  painted,

  /// Unpainted cast – a half-baked (premature) mutant or a "seen" shelf.
  grey,

  /// Black silhouette – unknown shelf, "Kdo to bude?" strip.
  shadow,
}

/// Drives the moves of one [FigureView]: `play` a part's move, `cheer`.
class FigureController extends ChangeNotifier {
  Slot? _slot;
  String? _move;
  int _serial = 0;

  Slot? get slot => _slot;
  String? get move => _move;

  /// Bumps on every play so the same move can be replayed.
  int get serial => _serial;

  void play(Slot slot, String move) {
    _slot = slot;
    _move = move;
    _serial++;
    notifyListeners();
  }

  void cheer() => play(Slot.torso, 'cheer');
}

/// The only place that knows how a figure is drawn (PLAN-KOLEKCE §5.3).
/// Today: [StandeeFigure] – the 2D hero image, or a placeholder toy built
/// from the recipe's element colours. Clips (M3b) and GLB (M4) plug in here.
class FigureView extends StatelessWidget {
  const FigureView({
    super.key,
    required this.mutant,
    required this.catalog,
    this.look = FigureLook.painted,
    this.controller,
    this.size = 240,
    this.sealElement,
  });

  final MutantDef mutant;
  final CardCatalog catalog;
  final FigureLook look;
  final FigureController? controller;
  final double size;
  final ElementType? sealElement;

  @override
  Widget build(BuildContext context) {
    final art = GameAssets.instance.art;
    final image = look == FigureLook.shadow
        ? (art.shadow(mutant.id) ?? art.hero(mutant.id))
        : art.hero(mutant.id);
    Widget figure = StandeeFigure(
      mutant: mutant,
      catalog: catalog,
      image: image,
      controller: controller,
      size: size,
    );
    figure = switch (look) {
      FigureLook.painted => figure,
      FigureLook.grey => ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyMatrix),
        child: figure,
      ),
      FigureLook.shadow => ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF0E0A1A), BlendMode.srcIn),
        child: figure,
      ),
    };
    return Semantics(
      label: look == FigureLook.shadow ? 'neznámý mutant' : mutant.name,
      child: SizedBox.square(dimension: size, child: figure),
    );
  }

  /// Desaturate and lift towards light grey plastic.
  static const _greyMatrix = <double>[
    0.24, 0.47, 0.09, 0, 40, //
    0.24, 0.47, 0.09, 0, 40,
    0.24, 0.47, 0.09, 0, 44,
    0, 0, 0, 1, 0,
  ];
}

/// 2D figure: the hero image bobbing as a whole, or a jointed placeholder
/// toy whose parts move one by one.
class StandeeFigure extends StatefulWidget {
  const StandeeFigure({
    super.key,
    required this.mutant,
    required this.catalog,
    required this.size,
    this.image,
    this.controller,
  });

  final MutantDef mutant;
  final CardCatalog catalog;
  final double size;
  final String? image;
  final FigureController? controller;

  /// Placeholder parts as fractions of the square, back to front.
  static const placeholderLayout = <(Slot, Rect)>[
    (Slot.extra, Rect.fromLTWH(0.14, 0.17, 0.72, 0.22)),
    (Slot.tail, Rect.fromLTWH(0.60, 0.56, 0.34, 0.14)),
    (Slot.back, Rect.fromLTWH(0.30, 0.64, 0.15, 0.32)),
    (Slot.back, Rect.fromLTWH(0.55, 0.64, 0.15, 0.32)),
    (Slot.torso, Rect.fromLTWH(0.27, 0.30, 0.46, 0.38)),
    (Slot.front, Rect.fromLTWH(0.11, 0.33, 0.17, 0.27)),
    (Slot.front, Rect.fromLTWH(0.72, 0.33, 0.17, 0.27)),
    (Slot.head, Rect.fromLTWH(0.31, 0.02, 0.38, 0.30)),
  ];

  @override
  State<StandeeFigure> createState() => _StandeeFigureState();
}

class _StandeeFigureState extends State<StandeeFigure>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onPlay);
  }

  @override
  void didUpdateWidget(StandeeFigure old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onPlay);
      widget.controller?.addListener(_onPlay);
    }
  }

  void _onPlay() => _move.forward(from: 0);

  @override
  void dispose() {
    widget.controller?.removeListener(_onPlay);
    _idle.dispose();
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _move]),
      builder: (context, _) {
        final idle = math.sin(_idle.value * 2 * math.pi);
        final t = _move.value;
        final playing = _move.isAnimating;
        final controller = widget.controller;
        final slot = playing ? controller?.slot : null;
        final move = playing ? controller?.move : null;

        if (widget.image case final image?) {
          final m = _wholeMotion(slot, move, t);
          return Transform.translate(
            offset: Offset(m.dx * size, (m.dy + idle * 0.008) * size),
            child: Transform.rotate(
              angle: m.angle,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scaleX: m.scaleX,
                scaleY: m.scaleY * (1 + idle * 0.006),
                alignment: Alignment.bottomCenter,
                child: Image.asset(image, width: size, height: size),
              ),
            ),
          );
        }

        final colors = {
          for (final s in Slot.values)
            s: MutantColors.element(
              widget.catalog[widget.mutant.parts[s]!].element,
            ),
        };
        return Transform.translate(
          offset: Offset(0, idle * 0.008 * size),
          child: Stack(
            children: [
              for (final (i, (s, rect))
                  in StandeeFigure.placeholderLayout.indexed)
                _part(
                  s,
                  rect,
                  colors[s]!,
                  i,
                  slot == s || move == 'cheer'
                      ? _partMotion(s, move, t, mirrored: _isRight(i))
                      : _Motion.none,
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isRight(int index) {
    final rect = StandeeFigure.placeholderLayout[index].$2;
    return rect.center.dx > 0.5;
  }

  Widget _part(Slot slot, Rect rect, Color color, int index, _Motion m) {
    final size = widget.size;
    final radius = switch (slot) {
      Slot.head || Slot.torso => size * 0.12,
      Slot.extra => size * 0.1,
      _ => size * 0.06,
    };
    final dark = Color.lerp(color, MutantColors.ink, 0.35)!;
    return Positioned(
      left: (rect.left + m.dx) * size,
      top: (rect.top + m.dy) * size,
      width: rect.width * size,
      height: rect.height * size,
      child: Transform.rotate(
        angle: m.angle,
        child: Transform.scale(
          scaleX: m.scaleX,
          scaleY: m.scaleY,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: dark, width: size * 0.012),
            ),
            child: slot == Slot.head ? _Face(size: size) : null,
          ),
        ),
      ),
    );
  }

  /// Whole-image motion for the hero picture, chosen by slot.
  _Motion _wholeMotion(Slot? slot, String? move, double t) {
    if (slot == null) return _Motion.none;
    final wave = math.sin(t * math.pi);
    final shake = math.sin(t * math.pi * 6) * (1 - t);
    if (move == 'cheer') {
      return _Motion(dy: -0.08 * wave, scaleY: 1 + 0.05 * wave);
    }
    return switch (slot) {
      Slot.head => _Motion(angle: -0.12 * shake, scaleX: 1 + 0.04 * wave),
      Slot.torso => _Motion(scaleX: 1 + 0.1 * wave, scaleY: 1 - 0.06 * wave),
      Slot.front => _Motion(dx: 0.03 * shake),
      Slot.back => _Motion(dy: -0.12 * wave, scaleY: 1 - 0.04 * wave),
      Slot.tail => _Motion(angle: 0.1 * shake),
      Slot.extra => _Motion(dy: -0.05 * wave, scaleX: 1 + 0.06 * shake),
    };
  }

  /// Placeholder part motion: a rough stand-in for each move of §6.2.
  _Motion _partMotion(
    Slot slot,
    String? move,
    double t, {
    bool mirrored = false,
  }) {
    final wave = math.sin(t * math.pi);
    final shake = math.sin(t * math.pi * 6) * (1 - t);
    final dir = mirrored ? -1.0 : 1.0;
    return switch (move) {
      'cheer' => _Motion(dy: -0.06 * wave),
      'headspin' => _Motion(angle: t * 2 * math.pi),
      'roar' || 'howl' => _Motion(
        scaleX: 1 + 0.2 * wave,
        scaleY: 1 + 0.2 * wave,
        angle: 0.08 * shake,
      ),
      'chomp' ||
      'snap' => _Motion(scaleY: 1 - 0.25 * math.sin(t * math.pi * 4).abs()),
      'headbutt' || 'charge' => _Motion(dx: -0.08 * wave),
      'scan' || 'beam' => _Motion(angle: 0.15 * shake),
      'hide' => _Motion(scaleX: 1 - 0.3 * wave, scaleY: 1 - 0.3 * wave),
      'puff' ||
      'bristle' => _Motion(scaleX: 1 + 0.18 * wave, scaleY: 1 + 0.12 * wave),
      'wobble' => _Motion(angle: 0.18 * shake),
      'slash' ||
      'pound' ||
      'clap' ||
      'drill' => _Motion(angle: dir * 0.5 * wave),
      'hop' => _Motion(dy: -0.14 * wave),
      'stomp' => _Motion(dy: -0.06 * math.sin(t * math.pi * 4).abs()),
      'roll' || 'scuttle' => _Motion(dx: 0.05 * shake),
      'whip' ||
      'wag' ||
      'sting' ||
      'smash' ||
      'splash' ||
      'fan' => _Motion(angle: -0.6 * shake),
      'flap' || 'hover' || 'slice' => _Motion(
        scaleY: 1 - 0.5 * math.sin(t * math.pi * 6).abs(),
        dy: -0.03 * wave,
      ),
      _ => _Motion(scaleX: 1 + 0.12 * wave, scaleY: 1 + 0.12 * wave),
    };
  }
}

class _Motion {
  const _Motion({
    this.dx = 0,
    this.dy = 0,
    this.angle = 0,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  static const none = _Motion();

  final double dx;
  final double dy;
  final double angle;
  final double scaleX;
  final double scaleY;
}

class _Face extends StatelessWidget {
  const _Face({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget eye() => Container(
      width: size * 0.07,
      height: size * 0.07,
      decoration: BoxDecoration(
        color: MutantColors.chalk,
        shape: BoxShape.circle,
        border: Border.all(color: MutantColors.ink, width: size * 0.018),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: size * 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [eye(), eye()],
      ),
    );
  }
}
