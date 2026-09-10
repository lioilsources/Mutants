import 'dart:math' as math;

import '../model/card.dart';
import '../model/catalog.dart';
import '../model/config.dart';
import '../model/enums.dart';
import '../model/game_state.dart';
import '../model/name_tables.dart';
import '../rules/hazard_check.dart';
import '../rules/pass_catch.dart';
import '../rules/placement.dart';
import '../util/rng.dart';
import 'commands.dart';
import 'creature_builder.dart';
import 'events.dart';

typedef StepResult = (GameState state, List<GameEvent> events);

/// `apply(Command) -> (State, [Event])`. Stateless apart from the static
/// card/name data: every call copies the given state and returns a new one.
class MutantEngine {
  MutantEngine(this.catalog, this.names);

  final CardCatalog catalog;
  final NameTables names;

  CardDef defOf(GameState state, int card) => catalog[state.defIdOf(card)];

  GameState newGame(GameConfig config) {
    final rng = Rng(config.seed);
    final cardDefs = [
      for (final def in catalog.cards)
        for (var i = 0; i < def.copies; i++) def.id,
    ];
    final pot = List.generate(cardDefs.length, (i) => i);
    rng.shuffle(pot);

    final state = GameState(
      config: config,
      cardDefs: cardDefs,
      now: 0,
      rngState: rng.state,
      pot: pot,
      players: [for (final p in config.players) PlayerState(id: p.id)],
      passes: [],
      silhouette: Silhouette(startedAt: 0),
      incubator: config.rules.incubatorStart,
      drainPerSec: config.rules.drainPerSec,
      takenNames: Set.of(config.takenNames),
    );

    // Deal round-robin. Hazards are never dealt – they stay where they are
    // in the pot and surface later.
    for (var round = 0; round < config.rules.handSize; round++) {
      for (final player in state.players) {
        final index = state.pot.lastIndexWhere(
          (c) => defOf(state, c).kind != CardKind.hazard,
        );
        if (index < 0) break;
        player.hand.add(state.pot.removeAt(index));
      }
    }
    return state;
  }

  StepResult apply(GameState state, Command command) {
    final step = _Step(state.copy());
    final s = step.s;
    _advance(step, command.ts);

    switch (command) {
      case Tick():
        break;
      case ThrowCard():
        _throw(step, command);
      case PassCard():
        _pass(step, command);
      case CatchCard():
        _catch(step, command);
      case DebugSetIncubator(:final level, :final frozen):
        if (level != null) {
          s.incubator = level.clamp(0, s.rules.incubatorMax).toDouble();
        }
        if (frozen != null) s.incubatorFrozen = frozen;
      case DebugSetDrain(:final drainPerSec):
        s.drainPerSec = drainPerSec;
      case DebugForceHazard():
        _debugForceHazard(step, command);
      case DebugGiveCard():
        _debugGiveCard(step, command);
      case DebugHatchNow():
        _hatch(step, premature: false);
    }

    s.rngState = step.rng.state;
    return (s, step.events);
  }

  // --- time ----------------------------------------------------------------

  /// Fires timers in chronological order up to [t]. Timers due exactly at
  /// [t] wait for the next advance, so a throw landing on the deadline still
  /// counts (lenient towards kids).
  void _advance(_Step step, int t) {
    final s = step.s;
    while (true) {
      int? next;
      PendingPass? pass;
      var hazardDue = false;
      var incubatorDue = false;

      for (final p in s.passes) {
        if (next == null || p.expiresAt < next) {
          next = p.expiresAt;
          pass = p;
        }
      }
      final hazard = s.hazard;
      if (hazard != null && (next == null || hazard.expiresAt < next)) {
        next = hazard.expiresAt;
        pass = null;
        hazardDue = true;
      }
      final zeroAt = _incubatorZeroAt(s);
      if (zeroAt != null && (next == null || zeroAt < next)) {
        next = zeroAt;
        pass = null;
        hazardDue = false;
        incubatorDue = true;
      }
      if (next == null || next >= t) break;

      _drainTo(s, next);
      if (pass != null) {
        s.passes.remove(pass);
        _returnToPot(step, pass.card);
        step.events.add(
          PassDropped(s.now, from: pass.from, to: pass.to, card: pass.card),
        );
      } else if (hazardDue) {
        _resolveHazard(step, met: false);
      } else if (incubatorDue) {
        s.incubator = 0;
        _hatch(step, premature: true);
      }
    }
    _drainTo(s, t);
  }

  int? _incubatorZeroAt(GameState s) {
    if (s.incubatorFrozen || s.drainPerSec <= 0) return null;
    if (s.incubator <= 0) return s.now;
    return s.now + (s.incubator / s.drainPerSec * 1000).ceil();
  }

  void _drainTo(GameState s, int t) {
    if (t <= s.now) return;
    if (!s.incubatorFrozen) {
      s.incubator = math.max(0, s.incubator - s.drainPerSec * (t - s.now) / 1000);
    }
    s.now = t;
  }

  void _changeIncubator(_Step step, double delta, IncubatorReason reason) {
    final s = step.s;
    s.incubator = (s.incubator + delta).clamp(0, s.rules.incubatorMax).toDouble();
    step.events.add(
      IncubatorChanged(s.now, delta: delta, level: s.incubator, reason: reason),
    );
    if (delta < 0 && s.incubator <= 0) _hatch(step, premature: true);
  }

  // --- commands ------------------------------------------------------------

  PlayerState? _player(_Step step, Command command, int id) {
    if (id < 0 || id >= step.s.players.length) {
      step.reject(command, RejectReason.unknownPlayer);
      return null;
    }
    return step.s.players[id];
  }

  void _throw(_Step step, ThrowCard command) {
    final s = step.s;
    final player = _player(step, command, command.player);
    if (player == null) return;
    final card = command.card;
    if (!player.hand.contains(card)) {
      return step.reject(command, RejectReason.cardNotInHand);
    }
    final def = defOf(s, card);
    final silhouette = s.silhouette;
    final result = resolvePlacement(
      silhouette,
      def,
      player: player.id,
      ts: s.now,
      synchroWindowMs: s.rules.synchroWindowMs,
    );

    switch (result) {
      case PlacementResult.notPlaceable:
        return step.reject(command, RejectReason.notPlaceable);
      case PlacementResult.bounceOccupied || PlacementResult.bounceSealTaken:
        step.events.add(
          CardBounced(
            s.now,
            player: player.id,
            card: card,
            reason: result == PlacementResult.bounceSealTaken
                ? BounceReason.sealTaken
                : BounceReason.slotOccupied,
          ),
        );
        return;
      default:
        break;
    }

    player.hand.remove(card);
    final slot = def.slot!;
    var replaced = const <int>[];
    switch (result) {
      case PlacementResult.place:
        final isMutation = def.kind == CardKind.mutation;
        silhouette.slots[slot] = SlotFill(
          cards: [card],
          placedBy: player.id,
          placedAt: s.now,
          mutated: isMutation,
        );
        if (isMutation) silhouette.mutations++;
      case PlacementResult.fusion:
        silhouette.slots[slot]!
          ..cards.add(card)
          ..fused = true;
        silhouette.fusions++;
      case PlacementResult.overwrite:
        replaced = silhouette.slots[slot]!.cards;
        silhouette.slots[slot] = SlotFill(
          cards: [card],
          placedBy: player.id,
          placedAt: s.now,
          mutated: true,
        );
        silhouette.mutations++;
      case PlacementResult.seal:
        silhouette.seal = card;
      default:
        throw StateError('unreachable: $result');
    }
    silhouette.contributors.add(player.id);

    // Synchro: another player's throw within the window, or a štafeta.
    final window = s.rules.synchroWindowMs;
    final relay = isRelay(player, card, s.now, s.rules.relayWindowMs);
    player.caughtAt.remove(card);
    silhouette.recentThrows.removeWhere((t) => s.now - t.ts > window);
    final partners = [
      for (final t in silhouette.recentThrows)
        if (t.player != player.id) t,
    ];
    final synchro = relay || partners.isNotEmpty;
    if (relay) silhouette.relays++;
    silhouette.recentThrows.add(
      ThrowRecord(player: player.id, card: card, ts: s.now, synchro: synchro),
    );

    step.events.add(
      CardPlaced(
        s.now,
        player: player.id,
        card: card,
        slot: slot,
        kind: switch (result) {
          PlacementResult.fusion => PlacementKind.fusion,
          PlacementResult.overwrite => PlacementKind.overwrite,
          PlacementResult.seal => PlacementKind.seal,
          _ => PlacementKind.place,
        },
        synchro: synchro,
        relay: relay,
        replaced: replaced,
      ),
    );
    for (final r in replaced) {
      _returnToPot(step, r);
    }

    if (synchro) {
      silhouette.synchroThrows++;
      _changeIncubator(step, s.rules.synchroBonus, IncubatorReason.synchro);
    } else {
      _changeIncubator(step, s.rules.throwBonus, IncubatorReason.throwBonus);
    }
    for (final partner in partners) {
      if (partner.synchro) continue;
      partner.synchro = true;
      silhouette.synchroThrows++;
      step.events.add(
        SynchroUpgraded(s.now, player: partner.player, card: partner.card),
      );
      _changeIncubator(
        step,
        s.rules.synchroBonus - s.rules.throwBonus,
        IncubatorReason.synchro,
      );
    }

    _checkHazard(step);
    if (silhouette.isComplete) _hatch(step, premature: false);
    _refill(step, player);
  }

  void _pass(_Step step, PassCard command) {
    final s = step.s;
    final from = _player(step, command, command.from);
    if (from == null) return;
    if (command.to < 0 ||
        command.to >= s.players.length ||
        command.to == command.from) {
      return step.reject(command, RejectReason.invalidTarget);
    }
    if (!from.hand.contains(command.card)) {
      return step.reject(command, RejectReason.cardNotInHand);
    }
    if (passOnCooldown(from, s.now, s.rules.passCooldownMs)) {
      return step.reject(command, RejectReason.onCooldown);
    }

    from.hand.remove(command.card);
    from.caughtAt.remove(command.card);
    from.lastPassAt = s.now;
    final expiresAt = s.now + s.rules.catchWindowMs;
    s.passes.add(
      PendingPass(
        card: command.card,
        from: from.id,
        to: command.to,
        sentAt: s.now,
        expiresAt: expiresAt,
      ),
    );
    step.events.add(
      PassStarted(
        s.now,
        from: from.id,
        to: command.to,
        card: command.card,
        expiresAt: expiresAt,
      ),
    );
    _refill(step, from);
  }

  void _catch(_Step step, CatchCard command) {
    final s = step.s;
    final player = _player(step, command, command.player);
    if (player == null) return;
    final index = s.passes.indexWhere(
      (p) => p.card == command.card && p.to == player.id,
    );
    if (index < 0) return step.reject(command, RejectReason.noSuchPass);

    final pass = s.passes.removeAt(index);
    player.hand.add(pass.card);
    player.caughtAt[pass.card] = s.now;
    step.events.add(
      PassCaught(s.now, from: pass.from, to: pass.to, card: pass.card),
    );
    _changeIncubator(step, s.rules.catchBonus, IncubatorReason.catchBonus);
  }

  // --- hazards -------------------------------------------------------------

  void _surfaceHazard(_Step step, int card, int fuseMs) {
    final s = step.s;
    s.hazard = ActiveHazard(
      card: card,
      surfacedAt: s.now,
      expiresAt: s.now + fuseMs,
    );
    step.events.add(
      HazardSurfaced(
        s.now,
        card: card,
        defId: s.defIdOf(card),
        expiresAt: s.now + fuseMs,
      ),
    );
    _checkHazard(step);
  }

  void _checkHazard(_Step step) {
    final s = step.s;
    final hazard = s.hazard;
    if (hazard == null) return;
    final req = defOf(s, hazard.card).requires!;
    if (silhouetteMeetsRequirement(s.silhouette, req, (c) => defOf(s, c))) {
      _resolveHazard(step, met: true);
    }
  }

  void _resolveHazard(_Step step, {required bool met}) {
    final s = step.s;
    final hazard = s.hazard!;
    s.hazard = null;
    step.events.add(
      HazardResolved(
        s.now,
        card: hazard.card,
        defId: s.defIdOf(hazard.card),
        met: met,
      ),
    );
    _returnToPot(step, hazard.card);
    if (met) {
      s.silhouette.hazardsMet++;
      _changeIncubator(step, s.rules.hazardMetBonus, IncubatorReason.hazardMet);
    } else {
      _changeIncubator(
        step,
        -s.rules.hazardFailPenalty,
        IncubatorReason.hazardFailed,
      );
    }
  }

  void _cancelHazard(_Step step) {
    final s = step.s;
    final hazard = s.hazard;
    if (hazard == null) return;
    s.hazard = null;
    step.events.add(
      HazardCancelled(s.now, card: hazard.card, defId: s.defIdOf(hazard.card)),
    );
    _returnToPot(step, hazard.card);
  }

  // --- pot & hatching ------------------------------------------------------

  /// Draws up to hand size. A hazard on top surfaces (or, if one is already
  /// ticking, goes to the bottom of the pot).
  void _refill(_Step step, PlayerState player) {
    final s = step.s;
    var hazardSkips = 0;
    while (player.hand.length < s.rules.handSize && s.pot.isNotEmpty) {
      final card = s.pot.removeLast();
      if (defOf(s, card).kind == CardKind.hazard) {
        if (s.hazard == null) {
          _surfaceHazard(step, card, s.rules.hazardFuseMs);
        } else {
          s.pot.insert(0, card);
          if (++hazardSkips > s.pot.length) break;
        }
        continue;
      }
      player.hand.add(card);
      step.events.add(CardDrawn(s.now, player: player.id, card: card));
    }
  }

  /// Parts go back to a random spot; hazards to the bottom so an instantly
  /// met hazard cannot be redrawn in a loop.
  void _returnToPot(_Step step, int card) {
    final s = step.s;
    if (defOf(s, card).kind == CardKind.hazard) {
      s.pot.insert(0, card);
    } else {
      s.pot.insert(step.rng.nextInt(s.pot.length + 1), card);
    }
  }

  void _hatch(_Step step, {required bool premature}) {
    final s = step.s;
    final record = buildCreatureRecord(s, catalog, names, premature: premature);
    s.takenNames.add(record.name);
    step.events.add(CreatureHatched(s.now, record));

    _cancelHazard(step);
    final cards = s.silhouette.allCards.toList();
    s.silhouette = Silhouette(startedAt: s.now);
    for (final card in cards) {
      _returnToPot(step, card);
    }
    s.incubator = s.rules.incubatorStart;
    s.drainPerSec += s.rules.drainPerHatch;
    s.hatchedCount++;
  }

  // --- debug ---------------------------------------------------------------

  int _takeOrMint(GameState s, String defId) {
    final index = s.pot.lastIndexWhere((c) => s.defIdOf(c) == defId);
    if (index >= 0) return s.pot.removeAt(index);
    s.cardDefs.add(defId);
    return s.cardDefs.length - 1;
  }

  void _debugForceHazard(_Step step, DebugForceHazard command) {
    final s = step.s;
    if (!catalog.contains(command.defId)) {
      return step.reject(command, RejectReason.unknownCard);
    }
    if (catalog[command.defId].kind != CardKind.hazard) {
      return step.reject(command, RejectReason.notPlaceable);
    }
    _cancelHazard(step);
    final card = _takeOrMint(s, command.defId);
    _surfaceHazard(step, card, command.fuseMs ?? s.rules.hazardFuseMs);
  }

  void _debugGiveCard(_Step step, DebugGiveCard command) {
    final s = step.s;
    final player = _player(step, command, command.player);
    if (player == null) return;
    if (!catalog.contains(command.defId)) {
      return step.reject(command, RejectReason.unknownCard);
    }
    if (!catalog[command.defId].isPlaceable) {
      return step.reject(command, RejectReason.notPlaceable);
    }
    final card = _takeOrMint(s, command.defId);
    player.hand.add(card);
    step.events.add(CardDrawn(s.now, player: player.id, card: card));
  }
}

class _Step {
  _Step(this.s) : rng = Rng.fromState(s.rngState);

  final GameState s;
  final Rng rng;
  final List<GameEvent> events = [];

  void reject(Command command, RejectReason reason) =>
      events.add(CommandRejected(s.now, command, reason));
}
