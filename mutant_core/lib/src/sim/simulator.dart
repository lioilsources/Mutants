import '../bots/kid_bot.dart';
import '../engine/commands.dart';
import '../engine/engine.dart';
import '../engine/events.dart';
import '../model/config.dart';
import '../model/creature.dart';
import '../model/enums.dart';
import '../util/rng.dart';

class SimOptions {
  const SimOptions({
    required this.players,
    required this.creatures,
    this.seed = 1,
    this.profiles = const [
      KidBotProfile.hasty,
      KidBotProfile.careful,
      KidBotProfile.passer,
    ],
    this.rules = const RulesConfig(),
    this.sessionLength = 5,
    this.maxSessionMs = 30 * 60 * 1000,
  });

  final int players;
  final int creatures;
  final int seed;

  /// Assigned to seats cyclically.
  final List<KidBotProfile> profiles;
  final RulesConfig rules;

  /// Creatures per play session. Drain grows with every hatch, so one
  /// 200-creature session would be meaningless; 0 = a single session.
  final int sessionLength;

  /// Safety stop for a session that never hatches anything.
  final int maxSessionMs;
}

class SimCreature {
  const SimCreature(this.record, this.indexInSession);

  final CreatureRecord record;

  /// 0-based position within its session (drain ramps up with it).
  final int indexInSession;
}

class SimReport {
  final List<SimCreature> creatures = [];
  int hazardsSurfaced = 0;
  int hazardsMet = 0;
  int hazardsFailed = 0;
  int hazardsCancelled = 0;
  int passesSent = 0;
  int passesCaught = 0;
  int passesDropped = 0;
  int placements = 0;
  int bounces = 0;
  int synchroPlacements = 0;
  int relays = 0;
  int fusions = 0;
  int mutations = 0;
  int sessions = 0;
  int simulatedMs = 0;
  bool truncated = false;

  int get count => creatures.length;

  double get prematureRate => _rate(creatures.where((c) => c.record.premature).length);

  double get rarePlusRate =>
      _rate(creatures.where((c) => c.record.rarity.index >= Rarity.rare.index).length);

  Map<Rarity, int> get rarityCounts => {
    for (final r in Rarity.values)
      r: creatures.where((c) => c.record.rarity == r).length,
  };

  double get hazardMetRate {
    final resolved = hazardsMet + hazardsFailed;
    return resolved == 0 ? 0 : hazardsMet / resolved;
  }

  double get passCatchRate {
    final resolved = passesCaught + passesDropped;
    return resolved == 0 ? 0 : passesCaught / resolved;
  }

  List<int> durationsMs({int? indexInSession}) {
    final list = [
      for (final c in creatures)
        if (indexInSession == null || c.indexInSession == indexInSession)
          c.record.durationMs,
    ]..sort();
    return list;
  }

  double _rate(int n) => count == 0 ? 0 : n / count;
}

/// Median / percentile of an already sorted list.
double percentile(List<int> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final pos = (sorted.length - 1) * p;
  final lo = pos.floor();
  final hi = pos.ceil();
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

/// Bots play against the engine in discrete time: whoever's think delay
/// elapses first looks at the table and acts (PLAN §6.1).
SimReport runSimulation(MutantEngine engine, SimOptions options) {
  final report = SimReport();
  final takenNames = <String>{};

  while (report.count < options.creatures) {
    final remaining = options.creatures - report.count;
    final target = options.sessionLength <= 0
        ? remaining
        : (options.sessionLength < remaining ? options.sessionLength : remaining);
    final sessionSeed = Rng.mix(options.seed, report.sessions);
    final profiles = [
      for (var i = 0; i < options.players; i++)
        options.profiles[i % options.profiles.length],
    ];
    var state = engine.newGame(
      GameConfig(
        seed: sessionSeed,
        players: [
          for (var i = 0; i < profiles.length; i++)
            PlayerInfo(id: i, name: profiles[i].name, avatar: profiles[i].id),
        ],
        rules: options.rules,
        takenNames: takenNames,
      ),
    );
    final bots = [
      for (var i = 0; i < profiles.length; i++)
        KidBot(i, profiles[i], Rng.mix(sessionSeed, 1000 + i)),
    ];
    final nextThink = [for (final bot in bots) bot.thinkDelay()];
    var hatched = 0;

    void collect(List<GameEvent> events) {
      for (final event in events) {
        switch (event) {
          case CreatureHatched(:final record):
            report.creatures.add(SimCreature(record, hatched++));
            takenNames.add(record.name);
          case HazardSurfaced():
            report.hazardsSurfaced++;
          case HazardResolved(:final met):
            met ? report.hazardsMet++ : report.hazardsFailed++;
          case HazardCancelled():
            report.hazardsCancelled++;
          case PassStarted():
            report.passesSent++;
          case PassCaught():
            report.passesCaught++;
          case PassDropped():
            report.passesDropped++;
          case CardPlaced(:final synchro, :final relay, :final kind):
            report.placements++;
            if (synchro) report.synchroPlacements++;
            if (relay) report.relays++;
            if (kind == PlacementKind.fusion) report.fusions++;
            if (kind == PlacementKind.overwrite) report.mutations++;
          case SynchroUpgraded():
            report.synchroPlacements++;
          case CardBounced():
            report.bounces++;
          default:
            break;
        }
      }
    }

    while (hatched < target) {
      var who = 0;
      for (var i = 1; i < bots.length; i++) {
        if (nextThink[i] < nextThink[who]) who = i;
      }
      final t = nextThink[who];
      if (t > options.maxSessionMs) break;

      final (ticked, tickEvents) = engine.apply(state, Tick(t));
      state = ticked;
      collect(tickEvents);
      if (hatched >= target) break;

      final decision = bots[who].think(state, engine.catalog);
      final command = decision.command;
      if (command != null) {
        final (next, events) = engine.apply(state, command);
        state = next;
        collect(events);
      }
      nextThink[who] = t + decision.nextThinkInMs;
    }

    report.sessions++;
    report.simulatedMs += state.now;
    if (hatched < target) {
      // Session timed out; continuing would likely loop forever.
      if (hatched == 0) {
        report.truncated = true;
        break;
      }
    }
  }
  return report;
}
