import '../model/card.dart';
import '../model/enums.dart';
import '../model/game_state.dart';

enum PlacementResult {
  place,
  fusion,
  overwrite,
  seal,
  bounceOccupied,
  bounceSealTaken,
  notPlaceable,
}

extension PlacementResultX on PlacementResult {
  bool get succeeds => switch (this) {
    PlacementResult.place ||
    PlacementResult.fusion ||
    PlacementResult.overwrite ||
    PlacementResult.seal => true,
    _ => false,
  };
}

/// Decides what happens when [player] throws [def] at [ts] (PLAN §2 Hod části,
/// Konflikt o slot). The slot is given by the card.
///
/// - part → empty slot: place; occupied: fusion if the occupant is a plain
///   part thrown by another player within the synchro window, else bounce
/// - mutation → always lands; overwrites whatever is there
/// - seal → stamped on the torso unless a seal is already there
PlacementResult resolvePlacement(
  Silhouette silhouette,
  CardDef def, {
  required int player,
  required int ts,
  required int synchroWindowMs,
}) {
  switch (def.kind) {
    case CardKind.hazard:
      return PlacementResult.notPlaceable;
    case CardKind.seal:
      return silhouette.seal == null
          ? PlacementResult.seal
          : PlacementResult.bounceSealTaken;
    case CardKind.mutation:
      return silhouette.slots.containsKey(def.slot)
          ? PlacementResult.overwrite
          : PlacementResult.place;
    case CardKind.part:
      final fill = silhouette.slots[def.slot!];
      if (fill == null) return PlacementResult.place;
      final canFuse =
          !fill.fused &&
          !fill.mutated &&
          fill.placedBy != player &&
          (ts - fill.placedAt).abs() <= synchroWindowMs;
      return canFuse ? PlacementResult.fusion : PlacementResult.bounceOccupied;
  }
}
