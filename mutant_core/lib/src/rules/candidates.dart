import '../model/card.dart';
import '../model/collection.dart';
import '../model/enums.dart';
import '../model/game_state.dart';
import 'hazard_check.dart';

/// Mutants whose recipe matches every placed part (PLAN-KOLEKCE §3.1).
/// Wildcard slots are not compared; an empty silhouette keeps all of them.
List<MutantDef> candidatesOf(
  Silhouette silhouette,
  String Function(int card) defIdOf,
  MutantCollection collection,
) {
  final placed = <Slot, String>{
    for (final e in silhouette.slots.entries)
      if (!e.value.wild) e.key: defIdOf(e.value.cards.first),
  };
  return [
    for (final m in collection.mutants)
      if (placed.entries.every((e) => m.parts[e.key] == e.value)) m,
  ];
}

/// Whether [def] (a part) would keep at least one candidate if placed into
/// its (empty) slot.
bool partFits(List<MutantDef> candidates, CardDef def) =>
    def.kind == CardKind.part &&
    candidates.any((m) => m.parts[def.slot] == def.id);

/// Slot → card still missing, once only one candidate is left.
Map<Slot, String> neededParts(
  Silhouette silhouette,
  List<MutantDef> candidates,
) {
  if (candidates.length != 1) return const {};
  final mutant = candidates.single;
  return {for (final slot in silhouette.emptySlots) slot: mutant.parts[slot]!};
}

/// Hazards surface only when some candidate can meet them, or the creature
/// already does (PLAN-KOLEKCE §3.5). A wildcard can only meet a bare "slot
/// is filled" requirement; a seal can meet an element-only one.
bool hazardSatisfiable(
  HazardRequirement req,
  Silhouette silhouette,
  List<MutantDef> candidates,
  CardDef Function(String defId) defById,
  CardDef Function(int card) defOf, {
  required Iterable<CardDef> seals,
  required bool wildAvailable,
}) {
  if (silhouetteMeetsRequirement(silhouette, req, defOf)) return true;
  final empty = silhouette.emptySlots;
  for (final m in candidates) {
    for (final slot in empty) {
      if (cardMeetsRequirement(defById(m.parts[slot]!), req)) return true;
    }
  }
  if (req.slot != null &&
      req.tag == null &&
      req.element == null &&
      wildAvailable &&
      empty.contains(req.slot)) {
    return true;
  }
  if (req.element != null &&
      req.slot == null &&
      req.tag == null &&
      silhouette.seal == null &&
      seals.any((s) => s.element == req.element)) {
    return true;
  }
  return false;
}
