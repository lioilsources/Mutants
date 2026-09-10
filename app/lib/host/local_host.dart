import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:mutant_core/mutant_core.dart';

import 'seat.dart';

/// Single-process host for puppet mode: owns the authoritative [GameState],
/// runs the game clock, drives bots and keeps the command log.
///
/// Phase 3 splits this into HostSession / ClientSession behind a Transport
/// (the shared `cardkit`), so UI code should only talk to this API.
class GameHost extends ChangeNotifier {
  GameHost({
    required this.engine,
    required List<SeatMode> seats,
    RulesConfig rules = const RulesConfig(),
    Set<String> takenNames = const {},
    this.onHatched,
    this.speed = 1,
  }) : _seats = List.of(seats) {
    _takenNames = Set.of(takenNames);
    restart(rules: rules);
  }

  final MutantEngine engine;
  final void Function(CreatureRecord record)? onHatched;

  late GameState _state;
  late RulesConfig _rules;
  late Set<String> _takenNames;
  List<SeatMode> _seats;
  int _seed = 0;
  final List<KidBot?> _bots = [];
  final List<int> _nextThink = [];
  final List<Command> _log = [];
  final Queue<GameEvent> _recent = Queue();
  final Queue<CreatureRecord> _hatches = Queue();
  final StreamController<GameEvent> _events = StreamController.broadcast();
  final Stopwatch _wall = Stopwatch();
  int _lastWallMs = 0;
  Timer? _timer;
  bool _paused = false;

  /// Game clock multiplier – slow the game down to play several seats.
  double speed;
  int viewedSeat = 0;

  /// Switch the view to the seat with the most cards for empty slots.
  bool autoFollow = false;

  /// Set while a card is being dragged so auto-follow doesn't swap hands.
  bool viewLocked = false;

  GameState get state => _state;
  RulesConfig get rules => _rules;
  CardCatalog get catalog => engine.catalog;
  List<SeatMode> get seats => List.unmodifiable(_seats);
  int get now => _state.now;
  bool get paused => _paused;
  List<Command> get log => List.unmodifiable(_log);

  /// Newest first.
  Iterable<GameEvent> get recentEvents => _recent;
  Stream<GameEvent> get events => _events.stream;

  /// Creature waiting to be shown; the clock stops until it is acknowledged.
  CreatureRecord? get pendingHatch => _hatches.isEmpty ? null : _hatches.first;

  void restart({RulesConfig? rules, List<SeatMode>? seats}) {
    _rules = rules ?? _rules;
    if (seats != null) _seats = List.of(seats);
    _seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    _state = engine.newGame(
      GameConfig(
        seed: _seed,
        players: [
          for (var i = 0; i < _seats.length; i++)
            PlayerInfo(
              id: i,
              name: seatAvatars[i].name,
              avatar: seatAvatars[i].emoji,
            ),
        ],
        rules: _rules,
        epochMs: DateTime.now().millisecondsSinceEpoch,
        takenNames: _takenNames,
      ),
    );
    _log.clear();
    _recent.clear();
    _hatches.clear();
    viewedSeat = viewedSeat.clamp(0, _seats.length - 1);
    _bots
      ..clear()
      ..addAll([for (var i = 0; i < _seats.length; i++) _botFor(i)]);
    _nextThink
      ..clear()
      ..addAll([for (final bot in _bots) bot?.thinkDelay() ?? 0]);
    notifyListeners();
  }

  KidBot? _botFor(int seat) {
    final profile = _seats[seat].botProfile;
    return profile == null
        ? null
        : KidBot(seat, profile, Rng.mix(_seed, 1000 + seat));
  }

  void setSeat(int seat, SeatMode mode) {
    _seats[seat] = mode;
    _bots[seat] = _botFor(seat);
    _nextThink[seat] = now + (_bots[seat]?.thinkDelay() ?? 0);
    notifyListeners();
  }

  void start() {
    _wall.start();
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _onWallTick(),
    );
  }

  void _onWallTick() {
    final wall = _wall.elapsedMilliseconds;
    final delta = wall - _lastWallMs;
    _lastWallMs = wall;
    advanceBy((delta * speed).round());
  }

  /// Advances game time. Public so tests can drive the host without timers.
  void advanceBy(int ms) {
    if (_paused || _hatches.isNotEmpty || ms <= 0) return;
    _apply(Tick(now + ms));
    _runBots();
    if (autoFollow && !viewLocked) viewedSeat = _seatToFollow();
    notifyListeners();
  }

  /// The seat with the most parts for empty slots. When nobody has one, stay
  /// put – unless the viewed hand is empty and someone else holds cards.
  int _seatToFollow() {
    final follow = playerToFollow(_state, catalog);
    if (follow != null) return follow;
    final players = _state.players;
    if (players[viewedSeat].hand.isNotEmpty) return viewedSeat;
    var best = viewedSeat;
    for (final p in players) {
      if (p.hand.length > players[best].hand.length) best = p.id;
    }
    return best;
  }

  void _runBots() {
    for (var seat = 0; seat < _bots.length; seat++) {
      final bot = _bots[seat];
      if (bot == null || _nextThink[seat] > now) continue;
      final decision = bot.think(_state, catalog);
      if (decision.command case final command?) _apply(command);
      _nextThink[seat] = now + decision.nextThinkInMs;
      if (_hatches.isNotEmpty) break;
    }
  }

  // --- player actions --------------------------------------------------------

  void throwCard(int seat, int card) =>
      _submit(ThrowCard(now, player: seat, card: card));

  void passCard(int from, int to, int card) =>
      _submit(PassCard(now, from: from, to: to, card: card));

  void catchCard(int seat, int card) =>
      _submit(CatchCard(now, player: seat, card: card));

  // --- debug -------------------------------------------------------------------

  /// DebugPanel entry point: builds a command at the current game time.
  List<GameEvent> debug(Command Function(int ts) build) => _submit(build(now));

  /// Gives [defId] to [seat]; returns the card instance, or null if rejected.
  int? giveCard(int seat, String defId) {
    final events = debug((ts) => DebugGiveCard(ts, player: seat, defId: defId));
    final drawn = events.whereType<CardDrawn>().where((e) => e.player == seat);
    return drawn.isEmpty ? null : drawn.last.card;
  }

  // --- flow ----------------------------------------------------------------------

  void acknowledgeHatch() {
    if (_hatches.isEmpty) return;
    _hatches.removeFirst();
    notifyListeners();
  }

  void renamePendingHatch(String name) {
    if (_hatches.isEmpty) return;
    _hatches.addFirst(_hatches.removeFirst().copyWith(name: name));
    _takenNames.add(name);
    notifyListeners();
  }

  void setPaused(bool value) {
    _paused = value;
    notifyListeners();
  }

  void setSpeed(double value) {
    speed = value;
    notifyListeners();
  }

  void setAutoFollow(bool value) {
    autoFollow = value;
    notifyListeners();
  }

  void view(int seat) {
    viewedSeat = seat;
    autoFollow = false;
    notifyListeners();
  }

  List<GameEvent> _submit(Command command) {
    final events = _apply(command);
    notifyListeners();
    return events;
  }

  List<GameEvent> _apply(Command command) {
    final (next, events) = engine.apply(_state, command);
    _state = next;
    _log.add(command);
    for (final event in events) {
      _recent.addFirst(event);
      if (event is CreatureHatched) {
        _hatches.add(event.record);
        _takenNames.add(event.record.name);
        onHatched?.call(event.record);
      }
      _events.add(event);
    }
    while (_recent.length > 60) {
      _recent.removeLast();
    }
    return events;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _events.close();
    super.dispose();
  }
}
