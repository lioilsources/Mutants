/// Tunable numbers from PLAN §2. Defaults = rules v1.
class RulesConfig {
  const RulesConfig({
    this.handSize = 5,
    this.incubatorMax = 100,
    this.incubatorStart = 60,
    this.drainPerSec = 4,
    this.drainPerHatch = 0.5,
    this.throwBonus = 10,
    this.synchroBonus = 25,
    this.catchBonus = 5,
    this.hazardMetBonus = 15,
    this.hazardFailPenalty = 25,
    this.synchroWindowMs = 80,
    this.relayWindowMs = 1000,
    this.catchWindowMs = 2000,
    this.passCooldownMs = 4000,
    this.hazardFuseMs = 5000,
  });

  final int handSize;
  final double incubatorMax;
  final double incubatorStart;

  /// Drain at game start; grows by [drainPerHatch] with every hatched creature.
  final double drainPerSec;
  final double drainPerHatch;

  /// Platný hod do slotu.
  final double throwBonus;

  /// Per throw that is part of a synchro (replaces [throwBonus]).
  final double synchroBonus;
  final double catchBonus;
  final double hazardMetBonus;
  final double hazardFailPenalty;

  /// Two throws by different players this close = synchro (or fusion).
  final int synchroWindowMs;

  /// Caught card thrown into a slot within this = štafeta (counts as synchro).
  final int relayWindowMs;
  final int catchWindowMs;
  final int passCooldownMs;
  final int hazardFuseMs;

  RulesConfig copyWith({
    int? handSize,
    double? incubatorStart,
    double? drainPerSec,
    double? drainPerHatch,
    int? synchroWindowMs,
    int? catchWindowMs,
    int? passCooldownMs,
    int? hazardFuseMs,
  }) => RulesConfig(
    handSize: handSize ?? this.handSize,
    incubatorMax: incubatorMax,
    incubatorStart: incubatorStart ?? this.incubatorStart,
    drainPerSec: drainPerSec ?? this.drainPerSec,
    drainPerHatch: drainPerHatch ?? this.drainPerHatch,
    throwBonus: throwBonus,
    synchroBonus: synchroBonus,
    catchBonus: catchBonus,
    hazardMetBonus: hazardMetBonus,
    hazardFailPenalty: hazardFailPenalty,
    synchroWindowMs: synchroWindowMs ?? this.synchroWindowMs,
    relayWindowMs: relayWindowMs,
    catchWindowMs: catchWindowMs ?? this.catchWindowMs,
    passCooldownMs: passCooldownMs ?? this.passCooldownMs,
    hazardFuseMs: hazardFuseMs ?? this.hazardFuseMs,
  );
}

class PlayerInfo {
  const PlayerInfo({required this.id, required this.name, this.avatar = ''});

  /// Seat index, 0-based.
  final int id;
  final String name;
  final String avatar;

  Map<String, dynamic> toJson() => {'playerId': id, 'name': name, 'avatar': avatar};

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => PlayerInfo(
    id: json['playerId'] as int,
    name: json['name'] as String,
    avatar: json['avatar'] as String? ?? '',
  );
}

class GameConfig {
  GameConfig({
    required this.seed,
    required this.players,
    this.rules = const RulesConfig(),
    this.epochMs = 0,
    this.expedition,
    Set<String> takenNames = const {},
  }) : takenNames = Set.unmodifiable(takenNames) {
    if (players.isEmpty || players.length > 5) {
      throw ArgumentError('Mutant needs 1–5 players, got ${players.length}');
    }
    for (var i = 0; i < players.length; i++) {
      if (players[i].id != i) {
        throw ArgumentError('Player ids must be seat indexes 0..n-1');
      }
    }
  }

  final int seed;
  final List<PlayerInfo> players;
  final RulesConfig rules;

  /// Wall clock at game start, supplied by the host. The engine never reads
  /// the real clock, so `createdAt = epochMs + game time` stays deterministic.
  final int epochMs;
  final String? expedition;

  /// Names already in the host's bestiary, so new names don't collide.
  final Set<String> takenNames;
}
