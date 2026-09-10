import '../model/catalog.dart';
import '../model/enums.dart';
import '../model/game_state.dart';
import 'hazard_check.dart';
import 'placement.dart';

/// Cards in [player]'s hand that would land right now (ignoring fusion,
/// which depends on timing).
List<int> fittingCards(GameState state, CardCatalog catalog, int player) => [
  for (final card in state.players[player].hand)
    if (resolvePlacement(
      state.silhouette,
      catalog[state.defIdOf(card)],
      player: player,
      ts: state.now,
      synchroWindowMs: -1,
    ).succeeds)
      card,
];

/// Plain parts that fill an empty slot – mutations and seals excluded.
List<int> cardsForEmptySlots(GameState state, CardCatalog catalog, int player) {
  final empty = state.silhouette.emptySlots.toSet();
  return [
    for (final card in state.players[player].hand)
      if (catalog[state.defIdOf(card)] case final def
          when def.kind == CardKind.part && empty.contains(def.slot))
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
