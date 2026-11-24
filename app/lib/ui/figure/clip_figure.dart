import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';
import 'package:video_player/video_player.dart';

import '../../services/game_assets.dart';
import 'figure_view.dart';

/// Video figure (PLAN-KOLEKCE §6.5): `idle` loops in a round "incubator
/// window"; a [FigureController] play swaps in `show_<slot>` (or `cheer`)
/// and returns to `idle` when it ends. Every clip starts and ends on the
/// hero frame, so swaps at clip boundaries do not jump.
///
/// Until a clip is ready the [fallback] (the standee) shows, so a missing
/// or slow clip never leaves a hole.
class ClipFigure extends StatefulWidget {
  const ClipFigure({
    super.key,
    required this.mutantId,
    required this.size,
    required this.fallback,
    this.controller,
    this.startWith,
  });

  final String mutantId;
  final double size;
  final Widget fallback;
  final FigureController? controller;

  /// A clip to play once before idling, e.g. `assemble` in the reveal.
  final String? startWith;

  @override
  State<ClipFigure> createState() => _ClipFigureState();
}

class _ClipFigureState extends State<ClipFigure> {
  final _players = <String, VideoPlayerController>{};
  VideoPlayerController? _showing;
  String? _current;
  bool _disposed = false;

  ArtIndex get _art => GameAssets.instance.art;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onPlay);
    // Preload every clip of this figure; each is a few hundred kB.
    for (final name in [
      'idle',
      'assemble',
      'cheer',
      for (final slot in Slot.values) 'show_${slot.name}',
    ]) {
      if (_art.clip(widget.mutantId, name) case final path?) {
        final player = VideoPlayerController.asset(
          path,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        _players[name] = player;
        player.initialize().then((_) {
          if (_disposed) return;
          player.setVolume(0);
          if (_current == null &&
              name == (widget.startWith ?? 'idle') &&
              player.value.isInitialized) {
            _switchTo(name);
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(ClipFigure old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onPlay);
      widget.controller?.addListener(_onPlay);
    }
  }

  void _onPlay() {
    final c = widget.controller!;
    final name = c.move == 'cheer' ? 'cheer' : 'show_${c.slot?.name}';
    if (_players[name]?.value.isInitialized ?? false) _switchTo(name);
  }

  void _switchTo(String name) {
    final next = _players[name]!;
    _showing?.removeListener(_onTick);
    if (_showing != next) _showing?.pause();
    next
      ..setLooping(name == 'idle')
      ..seekTo(Duration.zero)
      ..play()
      ..addListener(_onTick);
    setState(() {
      _showing = next;
      _current = name;
    });
  }

  /// A one-shot clip has ended: back to idle.
  void _onTick() {
    final v = _showing!.value;
    if (_current != 'idle' &&
        v.isInitialized &&
        !v.isPlaying &&
        v.position >= v.duration) {
      if (_players['idle']?.value.isInitialized ?? false) {
        _switchTo('idle');
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    widget.controller?.removeListener(_onPlay);
    _showing?.removeListener(_onTick);
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _showing;
    if (player == null || !player.value.isInitialized) return widget.fallback;
    // Round window with a soft rim instead of transparency (§6.5).
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const RadialGradient(
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0, 0.82, 1],
      ).createShader(rect),
      child: ClipOval(
        child: SizedBox.square(
          dimension: widget.size,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: player.value.size.width,
              height: player.value.size.height,
              child: VideoPlayer(player),
            ),
          ),
        ),
      ),
    );
  }
}
