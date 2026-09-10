import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('synchro', () {
    test('two players, different slots, 80 ms apart: +25 each', () {
      final h = Harness();
      h.place(0, 'head_trex', 1000);
      final placed = one<CardPlaced>(h.place(1, 'tail_fox', 1080));
      expect(placed.synchro, isTrue);
      expect(h.silhouette.synchroThrows, 2);
      expect(h.incubator, 10 + 25 + 15);
    });

    test('81 ms apart: two plain throws', () {
      final h = Harness();
      h.place(0, 'head_trex', 1000);
      expect(one<CardPlaced>(h.place(1, 'tail_fox', 1081)).synchro, isFalse);
      expect(h.incubator, 20);
      expect(h.silhouette.synchroThrows, 0);
    });

    test('chain of three players counts three synchro throws', () {
      final h = Harness(players: 3);
      h.place(0, 'head_trex', 1000);
      h.place(1, 'tail_fox', 1050);
      h.place(2, 'front_trex', 1100);
      expect(h.silhouette.synchroThrows, 3);
      expect(h.incubator, 10 + 25 + 15 + 25);
    });

    test('bounced throws never count', () {
      final h = Harness();
      h.place(0, 'head_trex', 1000);
      h.place(1, 'head_shark', 1500);
      expect(has<CardBounced>(h.log), isTrue);
      expect(one<CardPlaced>(h.place(1, 'tail_fox', 1520)).synchro, isFalse);
    });
  });

  group('pass & catch', () {
    test('catch within 2 s moves the card and gives +5', () {
      final h = Harness();
      final card = h.give(0, 'head_trex');
      final started = one<PassStarted>(h.apply(PassCard(100, from: 0, to: 1, card: card)));
      expect(started.expiresAt, 2100);
      expect(h.player(0).hand, isNot(contains(card)));

      final events = h.apply(CatchCard(2100, player: 1, card: card));
      expect(has<PassCaught>(events), isTrue);
      expect(h.player(1).hand, contains(card));
      expect(h.incubator, 5);
    });

    test('uncaught card falls into the pot', () {
      final h = Harness();
      final card = h.give(0, 'head_trex');
      h.apply(PassCard(100, from: 0, to: 1, card: card));
      final events = h.apply(CatchCard(2101, player: 1, card: card));

      expect(one<PassDropped>(events).ts, 2100);
      expect(one<CommandRejected>(events).reason, RejectReason.noSuchPass);
      expect(h.state.pot, contains(card));
      expect(h.player(1).hand, isNot(contains(card)));
    });

    test('only the target can catch', () {
      final h = Harness(players: 3);
      final card = h.give(0, 'head_trex');
      h.apply(PassCard(100, from: 0, to: 1, card: card));
      final events = h.apply(CatchCard(200, player: 2, card: card));
      expect(one<CommandRejected>(events).reason, RejectReason.noSuchPass);
    });

    test('one pass per player per 4 s', () {
      final h = Harness();
      final a = h.give(0, 'head_trex');
      final b = h.give(0, 'tail_fox');
      h.apply(PassCard(0, from: 0, to: 1, card: a));
      expect(
        one<CommandRejected>(h.apply(PassCard(3999, from: 0, to: 1, card: b))).reason,
        RejectReason.onCooldown,
      );
      expect(has<PassStarted>(h.apply(PassCard(4000, from: 0, to: 1, card: b))), isTrue);
    });

    test('cannot pass to yourself', () {
      final h = Harness();
      final card = h.give(0, 'head_trex');
      expect(
        one<CommandRejected>(h.apply(PassCard(0, from: 0, to: 0, card: card))).reason,
        RejectReason.invalidTarget,
      );
    });

    test('passer refills their hand', () {
      final h = Harness(rules: const RulesConfig());
      final card = h.player(0).hand.first;
      final events = h.apply(PassCard(100, from: 0, to: 1, card: card));
      expect(has<CardDrawn>(events), isTrue);
      expect(h.player(0).hand, hasLength(5));
    });
  });

  group('štafeta (relay)', () {
    test('caught card thrown within 1 s counts as synchro', () {
      final h = Harness();
      final card = h.give(0, 'head_trex');
      h.apply(PassCard(0, from: 0, to: 1, card: card));
      h.apply(CatchCard(500, player: 1, card: card));
      final placed = one<CardPlaced>(h.throwCard(1, card, 1500));

      expect(placed.relay, isTrue);
      expect(placed.synchro, isTrue);
      expect(h.silhouette.relays, 1);
      expect(h.silhouette.synchroThrows, 1);
      expect(h.incubator, 5 + 25);
    });

    test('after 1 s it is a plain throw', () {
      final h = Harness();
      final card = h.give(0, 'head_trex');
      h.apply(PassCard(0, from: 0, to: 1, card: card));
      h.apply(CatchCard(500, player: 1, card: card));
      final placed = one<CardPlaced>(h.throwCard(1, card, 1501));
      expect(placed.relay, isFalse);
      expect(h.incubator, 5 + 10);
    });
  });

  group('hints (zavolej si)', () {
    test('lights up players holding a part for an empty slot', () {
      final h = Harness();
      h.give(0, 'head_trex');
      h.give(0, 'front_trex');
      h.give(1, 'tail_fox');
      expect(playersToCall(h.state, engine.catalog), {0, 1});
      expect(playerToFollow(h.state, engine.catalog), 0);

      h.place(0, 'tail_fish', 1000);
      expect(playersToCall(h.state, engine.catalog), {0});
    });
  });
}
