import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

String fingerprint(GameState s) => [
  s.now,
  s.rngState,
  s.pot,
  [for (final p in s.players) p.hand],
  s.incubator,
  s.drainPerSec,
  s.hatchedCount,
  [for (final e in s.silhouette.slots.entries) '${e.key.name}:${e.value.cards}'],
  s.silhouette.seal,
  s.hazard?.card,
  [for (final p in s.passes) '${p.card}>${p.to}'],
  s.takenNames.toList()..sort(),
].join('|');

GameConfig config(int seed) => GameConfig(
  seed: seed,
  players: [for (var i = 0; i < 3; i++) PlayerInfo(id: i, name: 'P$i')],
);

void main() {
  test('Rng is reproducible and in range', () {
    final a = Rng(42);
    final b = Rng(42);
    final seqA = [for (var i = 0; i < 100; i++) a.nextInt(10)];
    expect([for (var i = 0; i < 100; i++) b.nextInt(10)], seqA);
    expect(seqA.every((v) => v >= 0 && v < 10), isTrue);
    expect(seqA.toSet(), hasLength(10));
    expect(Rng(1).nextInt(1 << 30), isNot(Rng(2).nextInt(1 << 30)));
  });

  test('same seed deals the same game; different seeds do not', () {
    expect(fingerprint(engine.newGame(config(5))), fingerprint(engine.newGame(config(5))));
    expect(fingerprint(engine.newGame(config(5))), isNot(fingerprint(engine.newGame(config(6)))));
  });

  test('apply never mutates the state it was given', () {
    final state = engine.newGame(config(1));
    final before = fingerprint(state);
    final card = state.players[0].hand.first;
    engine.apply(state, ThrowCard(1000, player: 0, card: card));
    engine.apply(state, const Tick(60000));
    expect(fingerprint(state), before);
  });

  test('seed + command log replays identically', () {
    final cfg = config(11);
    var state = engine.newGame(cfg);
    final bots = [
      for (var i = 0; i < 3; i++)
        KidBot(i, KidBotProfile.all.values.elementAt(i), 100 + i),
    ];
    final nextThink = [0, 0, 0];
    final commands = <Command>[];
    final events = <String>[];

    for (var step = 0; step < 3000; step++) {
      var who = 0;
      for (var i = 1; i < 3; i++) {
        if (nextThink[i] < nextThink[who]) who = i;
      }
      final tick = Tick(nextThink[who]);
      commands.add(tick);
      var (next, ev) = engine.apply(state, tick);
      state = next;
      events.addAll(ev.map((e) => e.toString()));
      final decision = bots[who].think(state, engine.catalog);
      if (decision.command case final command?) {
        commands.add(command);
        (next, ev) = engine.apply(state, command);
        state = next;
        events.addAll(ev.map((e) => e.toString()));
      }
      nextThink[who] += decision.nextThinkInMs;
    }
    expect(state.hatchedCount, greaterThan(0));

    var replay = engine.newGame(cfg);
    final replayEvents = <String>[];
    for (final command in commands) {
      final (next, ev) = engine.apply(replay, command);
      replay = next;
      replayEvents.addAll(ev.map((e) => e.toString()));
    }
    expect(fingerprint(replay), fingerprint(state));
    expect(replayEvents, events);
  });
}
