import '../model/card.dart';
import '../model/creature.dart';
import '../model/enums.dart';

class RarityInput {
  const RarityInput({
    required this.parts,
    required this.stumps,
    this.fusions = 0,
    this.mutations = 0,
    this.hazardsMet = 0,
    this.synchroThrows = 0,
    this.premature = false,
  });

  /// Every card sitting in a slot (both halves of a fusion). Seal excluded.
  final List<CardDef> parts;
  final int stumps;
  final int fusions;
  final int mutations;
  final int hazardsMet;
  final int synchroThrows;
  final bool premature;
}

class RarityResult {
  const RarityResult(this.rarity, this.raw, this.reasons);

  final Rarity rarity;

  /// Unclamped sum of [reasons].
  final int raw;
  final List<RarityReason> reasons;
}

/// PLAN §4 Rarita (0–5):
/// - +1 per 3 distinct origins (chaos) *or* +2 when all parts share one
///   element (soulad) – whichever is higher; soulad needs no stumps
/// - +1 any fusion, +1 any mutation, +1 per met hazard, +1 for ≥ 3 synchro throws
/// - −1 premature hatch, −1 per 2 stumps
RarityResult evaluateRarity(RarityInput input) {
  final reasons = <RarityReason>[];

  final origins = {for (final p in input.parts) p.origin}..remove(null);
  final chaos = origins.length ~/ 3;
  final elements = {for (final p in input.parts) p.element};
  final harmony =
      input.parts.isNotEmpty && input.stumps == 0 && elements.length == 1
      ? 2
      : 0;
  if (harmony > 0 && harmony >= chaos) {
    reasons.add(RarityReason('harmony', harmony));
  } else if (chaos > 0) {
    reasons.add(RarityReason('chaos', chaos));
  }

  if (input.fusions > 0) reasons.add(const RarityReason('fusion', 1));
  if (input.mutations > 0) reasons.add(const RarityReason('mutation', 1));
  if (input.hazardsMet > 0) {
    reasons.add(RarityReason('hazard', input.hazardsMet));
  }
  if (input.synchroThrows >= 3) reasons.add(const RarityReason('synchro', 1));
  if (input.premature) reasons.add(const RarityReason('premature', -1));
  final stumpPenalty = input.stumps ~/ 2;
  if (stumpPenalty > 0) reasons.add(RarityReason('stumps', -stumpPenalty));

  final raw = reasons.fold(0, (sum, r) => sum + r.delta);
  final clamped = raw.clamp(0, Rarity.values.length - 1);
  return RarityResult(Rarity.values[clamped], raw, reasons);
}
