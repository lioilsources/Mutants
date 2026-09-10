import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

RulesConfig dealing({int interval = 1000, int maxHand = 3, int hand = 0}) =>
    RulesConfig.v1.copyWith(
      handSize: hand,
      refillOnPlay: false,
      dealIntervalMs: interval,
      maxHandSize: maxHand,
    );

void main() {
  test('the pot deals one card per interval to the player with the fewest cards', () {
    final h = Harness(rules: dealing());
    h.apply(const Tick(1000));
    expect(h.log.whereType<CardDrawn>(), isEmpty, reason: 'due exactly now waits');

    h.apply(const Tick(1001));
    expect(h.log.whereType<CardDrawn>(), hasLength(1));

    h.apply(const Tick(2001));
    final drawn = h.log.whereType<CardDrawn>().toList();
    expect(drawn, hasLength(2));
    expect(drawn.map((d) => d.player).toSet(), {0, 1});
  });

  test('no refill after a throw when dealing is on', () {
    final h = Harness(rules: dealing(interval: 60000, hand: 3));
    expect(h.player(0).hand, hasLength(3));
    h.throwCard(0, h.player(0).hand.first, 100);
    expect(h.player(0).hand, hasLength(2));
  });

  test('full hand: the pot swaps back the oldest card that does not fit', () {
    final h = Harness(players: 1, rules: dealing(maxHand: 2));
    h.place(0, 'head_trex', 10);
    final shark = h.give(0, 'head_shark', ts: 20);
    final wolf = h.give(0, 'head_wolf', ts: 30);

    final events = h.apply(const Tick(1001));
    expect(one<CardReturned>(events).card, shark);
    expect(h.player(0).hand, contains(wolf));
    expect(h.player(0).hand, hasLength(2));
  });

  test('a full hand of fitting cards is left alone', () {
    final h = Harness(players: 1, rules: dealing(maxHand: 1));
    h.give(0, 'tail_fox');
    final events = h.apply(const Tick(1001));
    expect(has<CardDrawn>(events), isFalse);
    expect(has<CardReturned>(events), isFalse);
  });

  test('hazards surface while the pot deals', () {
    final h = Harness(players: 1, rules: dealing());
    final pot = h.state.pot;
    final storm = pot.removeAt(pot.indexWhere((c) => h.state.defIdOf(c) == 'hazard_storm'));
    pot.add(storm);

    final events = h.apply(const Tick(1001));
    expect(one<HazardSurfaced>(events).card, storm);
    expect(has<CardDrawn>(events), isTrue);
  });

  test('dealing keeps its rhythm across a hatch', () {
    final h = Harness(players: 1, rules: dealing(interval: 5000, maxHand: 10));
    h.placeAll(fireCreature, from: 100);
    expect(h.state.hatchedCount, 1);
    expect(h.state.nextDealAt, 10000);
  });
}
