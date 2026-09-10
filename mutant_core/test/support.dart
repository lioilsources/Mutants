import 'package:mutant_core/io.dart';
import 'package:mutant_core/mutant_core.dart';

final MutantEngine engine = loadEngine();

/// 2026-01-01T00:00:00Z
const epoch = 1767225600000;

/// All-fire creature: origins dino, dragon, dino, dragon, mammal, dragon.
const fireCreature = [
  'head_trex',
  'torso_dragon',
  'front_trex',
  'back_dragon',
  'tail_fox',
  'extra_dragon',
];

/// Scenario driver. Defaults: rules v1 with hand size 0 (no dealing, no
/// refills, so hands hold only what a test gives) and the incubator frozen at
/// 0 so bonuses can be read directly.
class Harness {
  Harness({
    int players = 2,
    RulesConfig? rules,
    int seed = 7,
    bool frozen = true,
    Set<String> takenNames = const {},
  }) {
    rules ??= RulesConfig.v1.copyWith(handSize: 0);
    state = engine.newGame(
      GameConfig(
        seed: seed,
        players: [
          for (var i = 0; i < players; i++)
            PlayerInfo(id: i, name: 'Hráč $i', avatar: 'a$i'),
        ],
        rules: rules,
        epochMs: epoch,
        takenNames: takenNames,
      ),
    );
    if (frozen) apply(const DebugSetIncubator(0, level: 0, frozen: true));
  }

  late GameState state;
  final List<GameEvent> log = [];

  double get incubator => state.incubator;

  Silhouette get silhouette => state.silhouette;

  PlayerState player(int id) => state.players[id];

  List<GameEvent> apply(Command command) {
    final (next, events) = engine.apply(state, command);
    state = next;
    log.addAll(events);
    return events;
  }

  void setIncubator(double level, {int ts = 0}) =>
      apply(DebugSetIncubator(ts, level: level, frozen: true));

  /// Puts a copy of [defId] into a hand and returns its instance id.
  int give(int player, String defId, {int ts = 0}) {
    final events = apply(DebugGiveCard(ts, player: player, defId: defId));
    // A timed deal may fire first in the same step; the command runs last.
    return events.whereType<CardDrawn>().last.card;
  }

  List<GameEvent> throwCard(int player, int card, int ts) =>
      apply(ThrowCard(ts, player: player, card: card));

  /// Give + throw at the same moment.
  List<GameEvent> place(int player, String defId, int ts) =>
      throwCard(player, give(player, defId, ts: ts), ts);

  /// Places [defIds] one per second by player 0, starting at [from].
  List<GameEvent> placeAll(List<String> defIds, {int from = 1000}) => [
    for (var i = 0; i < defIds.length; i++)
      ...place(0, defIds[i], from + i * 1000),
  ];
}

T one<T extends GameEvent>(List<GameEvent> events) =>
    events.whereType<T>().single;

bool has<T extends GameEvent>(List<GameEvent> events) =>
    events.whereType<T>().isNotEmpty;
