import '../model/game_state.dart';

/// Max 1 předání per player per `passCooldownMs`.
bool passOnCooldown(PlayerState player, int ts, int passCooldownMs) {
  final last = player.lastPassAt;
  return last != null && ts - last < passCooldownMs;
}

/// Štafeta: a caught card thrown into a slot within `relayWindowMs` of the
/// catch counts as synchro.
bool isRelay(PlayerState player, int card, int ts, int relayWindowMs) {
  final caughtAt = player.caughtAt[card];
  return caughtAt != null && ts - caughtAt <= relayWindowMs;
}
