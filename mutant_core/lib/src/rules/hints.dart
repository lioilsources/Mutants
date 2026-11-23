import '../model/card.dart';
import '../model/catalog.dart';
import '../model/collection.dart';
import '../model/enums.dart';
import '../model/game_state.dart';
import 'candidates.dart';
import 'hazard_check.dart';
import 'placement.dart';

/// Collection mode: mutants still possible for the current silhouette.
/// Free mode: empty.
List<MutantDef> currentCandidates(GameState state) {
  final collection = state.collection;
  if (!state.rules.closedCollection || collection == null) return const [];
  return candidatesOf(state.silhouette, state.defIdOf, collection);
}

/// What a throw of [def] by [player] would do right now (ignoring fusion,
/// which depends on timing). Pass [candidates] to avoid recomputing them.
PlacementResult placementNow(
  GameState state,
  CardDef def,
  int player, {
  List<MutantDef>? candidates,
}) {
  if (state.rules.closedCollection && state.collection != null) {
    return resolveCollectionPlacement(
      state.silhouette,
      def,
      candidates: candidates ?? currentCandidates(state),
      maxWild: state.rules.maxWildPerCreature,
    );
  }
  return resolvePlacement(
    state.silhouette,
    def,
    player: player,
    ts: state.now,
    synchroWindowMs: -1,
  );
}

/// Cards in [player]'s hand that would land right now.
List<int> fittingCards(GameState state, CardCatalog catalog, int player) {
  final candidates = currentCandidates(state);
  return [
    for (final card in state.players[player].hand)
      if (placementNow(
        state,
        catalog[state.defIdOf(card)],
        player,
        candidates: candidates,
      ).succeeds)
        card,
  ];
}

/// Plain parts that fill an empty slot – mutations and seals excluded.
/// Collection mode: only parts some candidate still uses.
List<int> cardsForEmptySlots(GameState state, CardCatalog catalog, int player) {
  final empty = state.silhouette.emptySlots.toSet();
  final collection = state.rules.closedCollection && state.collection != null;
  final candidates = collection
      ? currentCandidates(state)
      : const <MutantDef>[];
  return [
    for (final card in state.players[player].hand)
      if (catalog[state.defIdOf(card)] case final def
          when def.kind == CardKind.part &&
              empty.contains(def.slot) &&
              (!collection || partFits(candidates, def)))
        card,
  ];
}

/// "Zavolej si" – players holding a part for an empty slot; the UI lights
/// up their avatars.
Set<int> playersToCall(GameState state, CardCatalog catalog) => {
  for (final p in state.players)
    if (cardsForEmptySlots(state, catalog, p.id).isNotEmpty) p.id,
};

/// Puppet-mode auto-follow: the player with the most fitting cards.
int? playerToFollow(GameState state, CardCatalog catalog) {
  int? best;
  var bestCount = 0;
  for (final p in state.players) {
    final count = cardsForEmptySlots(state, catalog, p.id).length;
    if (count > bestCount) {
      best = p.id;
      bestCount = count;
    }
  }
  return best;
}

/// Cards in hand that would satisfy the active hazard if thrown now.
List<int> hazardFixers(GameState state, CardCatalog catalog, int player) {
  final hazard = state.hazard;
  if (hazard == null) return const [];
  final req = catalog[state.defIdOf(hazard.card)].requires!;
  return [
    for (final card in fittingCards(state, catalog, player))
      if (cardMeetsRequirement(catalog[state.defIdOf(card)], req)) card,
  ];
}
