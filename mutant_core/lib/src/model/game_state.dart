import 'config.dart';
import 'enums.dart';

/// One occupied slot on the silhouette.
class SlotFill {
  SlotFill({
    required this.cards,
    required this.placedBy,
    required this.placedAt,
    this.fused = false,
    this.mutated = false,
  });

  /// Card instance ids; two when fused.
  final List<int> cards;
  final int placedBy;
  final int placedAt;
  bool fused;
  final bool mutated;

  SlotFill copy() => SlotFill(
    cards: List.of(cards),
    placedBy: placedBy,
    placedAt: placedAt,
    fused: fused,
    mutated: mutated,
  );
}

/// A successful throw, remembered briefly for the synchro window.
class ThrowRecord {
  ThrowRecord({
    required this.player,
    required this.card,
    required this.ts,
    this.synchro = false,
  });

  final int player;
  final int card;
  final int ts;
  bool synchro;

  ThrowRecord copy() =>
      ThrowRecord(player: player, card: card, ts: ts, synchro: synchro);
}

/// Silueta – the creature being assembled.
class Silhouette {
  Silhouette({
    required this.startedAt,
    Map<Slot, SlotFill>? slots,
    this.seal,
    List<ThrowRecord>? recentThrows,
    Set<int>? contributors,
    this.synchroThrows = 0,
    this.relays = 0,
    this.fusions = 0,
    this.mutations = 0,
    this.hazardsMet = 0,
  }) : slots = slots ?? {},
       recentThrows = recentThrows ?? [],
       contributors = contributors ?? {};

  final int startedAt;
  final Map<Slot, SlotFill> slots;

  /// Seal card instance stamped on the torso (does not occupy the slot).
  int? seal;
  final List<ThrowRecord> recentThrows;
  final Set<int> contributors;
  int synchroThrows;
  int relays;
  int fusions;
  int mutations;
  int hazardsMet;

  bool get isComplete => slots.length == Slot.values.length;

  List<Slot> get emptySlots =>
      Slot.values.where((s) => !slots.containsKey(s)).toList();

  /// All card instances on the creature, seal included.
  Iterable<int> get allCards sync* {
    for (final fill in slots.values) {
      yield* fill.cards;
    }
    if (seal != null) yield seal!;
  }

  Silhouette copy() => Silhouette(
    startedAt: startedAt,
    slots: {for (final e in slots.entries) e.key: e.value.copy()},
    seal: seal,
    recentThrows: [for (final t in recentThrows) t.copy()],
    contributors: Set.of(contributors),
    synchroThrows: synchroThrows,
    relays: relays,
    fusions: fusions,
    mutations: mutations,
    hazardsMet: hazardsMet,
  );
}

class PlayerState {
  PlayerState({
    required this.id,
    List<int>? hand,
    this.lastPassAt,
    Map<int, int>? caughtAt,
  }) : hand = hand ?? [],
       caughtAt = caughtAt ?? {};

  final int id;

  /// In arrival order – the first card is the oldest.
  final List<int> hand;
  int? lastPassAt;

  /// Card instance → ts it was caught; used for štafeta.
  final Map<int, int> caughtAt;

  PlayerState copy() => PlayerState(
    id: id,
    hand: List.of(hand),
    lastPassAt: lastPassAt,
    caughtAt: Map.of(caughtAt),
  );
}

class PendingPass {
  const PendingPass({
    required this.card,
    required this.from,
    required this.to,
    required this.sentAt,
    required this.expiresAt,
  });

  final int card;
  final int from;
  final int to;
  final int sentAt;
  final int expiresAt;
}

class ActiveHazard {
  const ActiveHazard({
    required this.card,
    required this.surfacedAt,
    required this.expiresAt,
  });

  final int card;
  final int surfacedAt;
  final int expiresAt;
}

/// Complete game state. Host-authoritative; the engine never mutates a state
/// it was given – it works on [copy] and returns the new one.
class GameState {
  GameState({
    required this.config,
    required this.cardDefs,
    required this.now,
    required this.rngState,
    required this.pot,
    required this.players,
    required this.passes,
    required this.silhouette,
    required this.incubator,
    required this.drainPerSec,
    required this.takenNames,
    this.incubatorFrozen = false,
    this.hazard,
    this.hatchedCount = 0,
    this.nextDealAt,
  });

  final GameConfig config;

  /// Card instance id → card definition id. Append-only.
  final List<String> cardDefs;

  /// Host game time in ms.
  int now;
  int rngState;

  /// Kotlík. Top of the pot is the last element.
  final List<int> pot;
  final List<PlayerState> players;
  final List<PendingPass> passes;
  Silhouette silhouette;
  double incubator;
  bool incubatorFrozen;
  double drainPerSec;
  ActiveHazard? hazard;
  int hatchedCount;

  /// Next timed deal from the pot; null when dealing is off.
  int? nextDealAt;
  final Set<String> takenNames;

  RulesConfig get rules => config.rules;

  String defIdOf(int card) => cardDefs[card];

  GameState copy() => GameState(
    config: config,
    cardDefs: List.of(cardDefs),
    now: now,
    rngState: rngState,
    pot: List.of(pot),
    players: [for (final p in players) p.copy()],
    passes: List.of(passes),
    silhouette: silhouette.copy(),
    incubator: incubator,
    incubatorFrozen: incubatorFrozen,
    drainPerSec: drainPerSec,
    hazard: hazard,
    hatchedCount: hatchedCount,
    nextDealAt: nextDealAt,
    takenNames: Set.of(takenNames),
  );
}
