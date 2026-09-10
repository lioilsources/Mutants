import '../engine/commands.dart';
import '../model/catalog.dart';
import '../model/game_state.dart';
import '../rules/hints.dart';
import '../rules/pass_catch.dart';
import '../util/rng.dart';

/// `KidBot(reactionMs, catchRate, passRate, mistakeRate)` from PLAN §5/§6.2.
class KidBotProfile {
  const KidBotProfile({
    required this.id,
    required this.name,
    required this.reactionMs,
    required this.catchRate,
    required this.passRate,
    required this.mistakeRate,
  });

  final String id;
  final String name;

  /// Mean time between looks at the table (±30 % jitter).
  final int reactionMs;
  final double catchRate;

  /// Chance to hand a card to a friend instead of throwing it.
  final double passRate;

  /// Chance to throw a random card without checking whether it fits.
  final double mistakeRate;

  /// Zbrklý – fast, 30 % mistakes, never catches.
  static const hasty = KidBotProfile(
    id: 'hasty',
    name: 'Zbrklý',
    reactionMs: 450,
    catchRate: 0,
    passRate: 0.05,
    mistakeRate: 0.30,
  );

  /// Opatrný – slow, always catches.
  static const careful = KidBotProfile(
    id: 'careful',
    name: 'Opatrný',
    reactionMs: 1300,
    catchRate: 1,
    passRate: 0.10,
    mistakeRate: 0.05,
  );

  /// Předávač – prefers sending cards to others.
  static const passer = KidBotProfile(
    id: 'passer',
    name: 'Předávač',
    reactionMs: 800,
    catchRate: 0.8,
    passRate: 0.6,
    mistakeRate: 0.10,
  );

  static const all = {'hasty': hasty, 'careful': careful, 'passer': passer};

  KidBotProfile copyWith({int? reactionMs, double? catchRate, double? passRate, double? mistakeRate}) =>
      KidBotProfile(
        id: id,
        name: name,
        reactionMs: reactionMs ?? this.reactionMs,
        catchRate: catchRate ?? this.catchRate,
        passRate: passRate ?? this.passRate,
        mistakeRate: mistakeRate ?? this.mistakeRate,
      );
}

class BotDecision {
  const BotDecision(this.command, this.nextThinkInMs);

  final Command? command;
  final int nextThinkInMs;
}

/// A simulated kid. The driver calls [think] whenever the bot's delay has
/// elapsed; the bot looks at the table and does at most one thing.
class KidBot {
  KidBot(this.player, this.profile, int seed) : _rng = Rng(seed);

  final int player;
  final KidBotProfile profile;
  final Rng _rng;

  /// Incoming passes already rolled against [KidBotProfile.catchRate].
  final Set<int> _rolledPasses = {};

  int thinkDelay() =>
      (profile.reactionMs * (0.7 + 0.6 * _rng.nextDouble())).round();

  /// A kid who just caught a card they need throws it right away.
  int _quickDelay() => (profile.reactionMs * 0.4).round();

  BotDecision think(GameState state, CardCatalog catalog) {
    final now = state.now;
    final me = state.players[player];

    final incoming = [
      for (final p in state.passes)
        if (p.to == player) p.card,
    ];
    _rolledPasses.retainAll(incoming);
    for (final card in incoming) {
      if (!_rolledPasses.add(card)) continue;
      if (_rng.chance(profile.catchRate)) {
        return BotDecision(CatchCard(now, player: player, card: card), _quickDelay());
      }
    }

    if (me.hand.isEmpty) return BotDecision(null, thinkDelay());

    if (_rng.chance(profile.mistakeRate)) {
      final card = _rng.pick(me.hand);
      return BotDecision(ThrowCard(now, player: player, card: card), thinkDelay());
    }

    final teammates = [
      for (final p in state.players)
        if (p.id != player) p.id,
    ];
    final canPass =
        teammates.isNotEmpty &&
        !passOnCooldown(me, now, state.rules.passCooldownMs);

    final fitting = fittingCards(state, catalog, player);
    if (fitting.isNotEmpty) {
      final fixers = hazardFixers(state, catalog, player);
      final card = fixers.isNotEmpty ? fixers.first : _rng.pick(fitting);
      final justCaught = me.caughtAt.containsKey(card);
      if (canPass && !justCaught && _rng.chance(profile.passRate)) {
        return BotDecision(
          PassCard(now, from: player, to: _rng.pick(teammates), card: card),
          thinkDelay(),
        );
      }
      return BotDecision(ThrowCard(now, player: player, card: card), thinkDelay());
    }

    // Nothing fits – hand a useless card to a friend (it cycles the hand
    // even if nobody catches it).
    if (canPass && _rng.chance(profile.passRate)) {
      return BotDecision(
        PassCard(now, from: player, to: _rng.pick(teammates), card: _rng.pick(me.hand)),
        thinkDelay(),
      );
    }
    return BotDecision(null, thinkDelay());
  }
}
