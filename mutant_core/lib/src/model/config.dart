/// Tunable numbers from PLAN §2. Defaults = current recommended rules
/// (calibrated with the CLI sim); [RulesConfig.v1] = the plan's originals.
class RulesConfig {
  const RulesConfig({
    this.handSize = 3,
    this.refillOnPlay = false,
    this.dealIntervalMs = 6000,
    this.maxHandSize = 5,
    this.incubatorMax = 100,
    this.incubatorStart = 60,
    this.drainPerSec = 0.85,
    this.drainPerHatch = 0.2,
    this.chaosOriginsPerPoint = 5,
    this.mutationBonusNeedsOverwrite = true,
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

  /// Rules v1 exactly as in the plan: 5 cards, the hand refills after every
  /// throw or pass, no timed dealing.
  static const v1 = RulesConfig(
    handSize: 5,
    refillOnPlay: true,
    dealIntervalMs: 0,
    maxHandSize: 5,
    drainPerSec: 4,
    drainPerHatch: 0.5,
    chaosOriginsPerPoint: 3,
    mutationBonusNeedsOverwrite: false,
  );

  /// Cards dealt at the start (and the refill target when [refillOnPlay]).
  final int handSize;

  /// v1: draw back up to [handSize] after every throw or pass.
  final bool refillOnPlay;

  /// Kotlík rozdává: every this many ms the player with the fewest cards gets
  /// one from the pot. 0 = off.
  final int dealIntervalMs;

  /// A timed deal to a full hand first returns its oldest card that does not
  /// fit into the pot.
  final int maxHandSize;
  final double incubatorMax;
  final double incubatorStart;

  /// Drain at game start; grows by [drainPerHatch] with every hatched creature.
  final double drainPerSec;
  final double drainPerHatch;

  /// Rarity chaos bonus: +1 per this many distinct origins.
  final int chaosOriginsPerPoint;

  /// Rarity mutation bonus only when a mutation replaced an occupied slot
  /// ("přepíše ho"). v1: any mutation on the creature counts.
  final bool mutationBonusNeedsOverwrite;

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
    bool? refillOnPlay,
    int? dealIntervalMs,
    int? maxHandSize,
    double? incubatorMax,
    double? incubatorStart,
    double? drainPerSec,
    double? drainPerHatch,
    int? chaosOriginsPerPoint,
    bool? mutationBonusNeedsOverwrite,
    double? throwBonus,
    double? synchroBonus,
    double? catchBonus,
    double? hazardMetBonus,
    double? hazardFailPenalty,
    int? synchroWindowMs,
    int? relayWindowMs,
    int? catchWindowMs,
    int? passCooldownMs,
    int? hazardFuseMs,
  }) => RulesConfig(
    handSize: handSize ?? this.handSize,
    refillOnPlay: refillOnPlay ?? this.refillOnPlay,
    dealIntervalMs: dealIntervalMs ?? this.dealIntervalMs,
    maxHandSize: maxHandSize ?? this.maxHandSize,
    incubatorMax: incubatorMax ?? this.incubatorMax,
    incubatorStart: incubatorStart ?? this.incubatorStart,
    drainPerSec: drainPerSec ?? this.drainPerSec,
    drainPerHatch: drainPerHatch ?? this.drainPerHatch,
    chaosOriginsPerPoint: chaosOriginsPerPoint ?? this.chaosOriginsPerPoint,
    mutationBonusNeedsOverwrite:
        mutationBonusNeedsOverwrite ?? this.mutationBonusNeedsOverwrite,
    throwBonus: throwBonus ?? this.throwBonus,
    synchroBonus: synchroBonus ?? this.synchroBonus,
    catchBonus: catchBonus ?? this.catchBonus,
    hazardMetBonus: hazardMetBonus ?? this.hazardMetBonus,
    hazardFailPenalty: hazardFailPenalty ?? this.hazardFailPenalty,
    synchroWindowMs: synchroWindowMs ?? this.synchroWindowMs,
    relayWindowMs: relayWindowMs ?? this.relayWindowMs,
    catchWindowMs: catchWindowMs ?? this.catchWindowMs,
    passCooldownMs: passCooldownMs ?? this.passCooldownMs,
    hazardFuseMs: hazardFuseMs ?? this.hazardFuseMs,
  );

  @override
  String toString() =>
      'hand $handSize${refillOnPlay ? ' (refill)' : ''}'
      ' · deal ${dealIntervalMs == 0 ? 'off' : '$dealIntervalMs ms'}'
      ' · max hand $maxHandSize'
      ' · drain $drainPerSec/s (+$drainPerHatch/hatch)'
      ' · chaos per $chaosOriginsPerPoint origins'
      ' · mutation bonus ${mutationBonusNeedsOverwrite ? 'on overwrite' : 'any'}';
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
