import '../model/card.dart';
import '../model/game_state.dart';

/// Whether a single card satisfies [req] on its own.
bool cardMeetsRequirement(CardDef def, HazardRequirement req) {
  if (def.slot == null || def.element == null) return false;
  if (req.slot != null && def.slot != req.slot) return false;
  if (req.tag != null && !def.tags.contains(req.tag)) return false;
  if (req.element != null && def.element != req.element) return false;
  return true;
}

/// Hazards test the creature as it is (PLAN §2 Události): e.g. Bouře is met
/// as soon as the extra slot holds wings – even if they were placed before
/// the storm surfaced. A seal counts for element-only requirements
/// ("celý mutant dostane element pečeti").
bool silhouetteMeetsRequirement(
  Silhouette silhouette,
  HazardRequirement req,
  CardDef Function(int card) defOf,
) {
  for (final entry in silhouette.slots.entries) {
    if (req.slot != null && entry.key != req.slot) continue;
    for (final card in entry.value.cards) {
      if (cardMeetsRequirement(defOf(card), req)) return true;
    }
  }
  final seal = silhouette.seal;
  if (seal != null &&
      req.element != null &&
      req.slot == null &&
      req.tag == null &&
      defOf(seal).element == req.element) {
    return true;
  }
  return false;
}
