import '../model/creature.dart';
import '../model/enums.dart';
import 'commands.dart';

sealed class GameEvent {
  const GameEvent(this.ts);

  final int ts;
}

enum RejectReason {
  unknownPlayer,
  unknownCard,
  cardNotInHand,
  notPlaceable,
  invalidTarget,
  onCooldown,
  noSuchPass,
}

final class CommandRejected extends GameEvent {
  const CommandRejected(super.ts, this.command, this.reason);

  final Command command;
  final RejectReason reason;

  @override
  String toString() => 'Rejected($command: ${reason.name})';
}

enum PlacementKind {
  /// Into an empty slot.
  place,

  /// Second part into the same slot within the synchro window.
  fusion,

  /// Mutation over an occupied slot.
  overwrite,

  /// Seal stamped on the torso.
  seal,
}

final class CardPlaced extends GameEvent {
  const CardPlaced(
    super.ts, {
    required this.player,
    required this.card,
    required this.slot,
    required this.kind,
    required this.synchro,
    required this.relay,
    this.replaced = const [],
  });

  final int player;
  final int card;
  final Slot slot;
  final PlacementKind kind;
  final bool synchro;
  final bool relay;

  /// Cards knocked back into the pot by a mutation.
  final List<int> replaced;

  @override
  String toString() =>
      'Placed(p$player #$card → ${slot.name} ${kind.name}'
      '${synchro ? ' synchro' : ''}${relay ? ' relay' : ''})';
}

enum BounceReason { slotOccupied, sealTaken }

/// Karta se odrazí zpět – stays in hand, no penalty.
final class CardBounced extends GameEvent {
  const CardBounced(super.ts, {required this.player, required this.card, required this.reason});

  final int player;
  final int card;
  final BounceReason reason;

  @override
  String toString() => 'Bounced(p$player #$card ${reason.name})';
}

/// An earlier throw became part of a synchro thanks to a later one.
final class SynchroUpgraded extends GameEvent {
  const SynchroUpgraded(super.ts, {required this.player, required this.card});

  final int player;
  final int card;
}

enum IncubatorReason { throwBonus, synchro, catchBonus, hazardMet, hazardFailed }

/// Bonus/penalty jumps only; continuous drain is read from state.
final class IncubatorChanged extends GameEvent {
  const IncubatorChanged(super.ts, {required this.delta, required this.level, required this.reason});

  final double delta;
  final double level;
  final IncubatorReason reason;

  @override
  String toString() => 'Incubator(${delta >= 0 ? '+' : ''}$delta → ${level.toStringAsFixed(1)} ${reason.name})';
}

final class CardDrawn extends GameEvent {
  const CardDrawn(super.ts, {required this.player, required this.card});

  final int player;
  final int card;
}

final class HazardSurfaced extends GameEvent {
  const HazardSurfaced(super.ts, {required this.card, required this.defId, required this.expiresAt});

  final int card;
  final String defId;
  final int expiresAt;

  @override
  String toString() => 'HazardSurfaced($defId until $expiresAt)';
}

final class HazardResolved extends GameEvent {
  const HazardResolved(super.ts, {required this.card, required this.defId, required this.met});

  final int card;
  final String defId;
  final bool met;

  @override
  String toString() => 'HazardResolved($defId ${met ? 'met' : 'failed'})';
}

/// The creature hatched while a hazard was still ticking.
final class HazardCancelled extends GameEvent {
  const HazardCancelled(super.ts, {required this.card, required this.defId});

  final int card;
  final String defId;
}

final class PassStarted extends GameEvent {
  const PassStarted(super.ts, {required this.from, required this.to, required this.card, required this.expiresAt});

  final int from;
  final int to;
  final int card;
  final int expiresAt;
}

final class PassCaught extends GameEvent {
  const PassCaught(super.ts, {required this.from, required this.to, required this.card});

  final int from;
  final int to;
  final int card;
}

/// Nobody caught it in time – the card fell into the pot.
final class PassDropped extends GameEvent {
  const PassDropped(super.ts, {required this.from, required this.to, required this.card});

  final int from;
  final int to;
  final int card;
}

final class CreatureHatched extends GameEvent {
  const CreatureHatched(super.ts, this.record);

  final CreatureRecord record;

  @override
  String toString() => 'Hatched(${record.name}, ${record.rarity.name}${record.premature ? ', premature' : ''})';
}
