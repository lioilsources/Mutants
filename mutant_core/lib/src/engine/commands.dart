/// Commands carry `ts` = host-assigned game time in ms. Time-based rules
/// (drain, hazard fuse, pass timeout) are advanced up to `ts` before the
/// command itself is applied, so a seed + command log replays exactly.
sealed class Command {
  const Command(this.ts);

  final int ts;
}

/// Advances time only. The host sends these periodically.
final class Tick extends Command {
  const Tick(super.ts);

  @override
  String toString() => 'Tick@$ts';
}

/// Swipe nahoru – the card finds its own slot.
final class ThrowCard extends Command {
  const ThrowCard(super.ts, {required this.player, required this.card});

  final int player;
  final int card;

  @override
  String toString() => 'Throw@$ts(p$player, #$card)';
}

/// Swipe do strany na avatar.
final class PassCard extends Command {
  const PassCard(
    super.ts, {
    required this.from,
    required this.to,
    required this.card,
  });

  final int from;
  final int to;
  final int card;

  @override
  String toString() => 'Pass@$ts(p$from→p$to, #$card)';
}

/// Tap to catch an incoming card.
final class CatchCard extends Command {
  const CatchCard(super.ts, {required this.player, required this.card});

  final int player;
  final int card;

  @override
  String toString() => 'Catch@$ts(p$player, #$card)';
}

// --- DebugPanel commands (PLAN §6.2) ---------------------------------------

final class DebugSetIncubator extends Command {
  const DebugSetIncubator(super.ts, {this.level, this.frozen});

  final double? level;
  final bool? frozen;
}

final class DebugSetDrain extends Command {
  const DebugSetDrain(super.ts, this.drainPerSec);

  final double drainPerSec;
}

/// Surfaces a hazard now (replacing any active one).
final class DebugForceHazard extends Command {
  const DebugForceHazard(super.ts, this.defId, {this.fuseMs});

  final String defId;
  final int? fuseMs;
}

/// Puts a card into a hand – taken from the pot if a copy is there,
/// otherwise a new card instance is minted.
final class DebugGiveCard extends Command {
  const DebugGiveCard(super.ts, {required this.player, required this.defId});

  final int player;
  final String defId;
}

/// `hatch now` – hatches whatever is on the silhouette (not premature).
final class DebugHatchNow extends Command {
  const DebugHatchNow(super.ts);
}
