import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  // hazard, a part that meets it, a part that does not
  const table = [
    ('hazard_storm', 'extra_dragonfly', 'extra_rhino'),
    ('hazard_earthquake', 'back_crab', 'tail_fish'),
    ('hazard_hunger', 'head_trex', 'head_deer'),
    ('hazard_flood', 'tail_fish', 'tail_fox'),
    ('hazard_darkness', 'back_spider', 'back_crab'),
  ];

  for (final (hazard, good, bad) in table) {
    group(hazard, () {
      test('met by $good: +15 and counted for rarity', () {
        final h = Harness();
        h.setIncubator(50);
        final surfaced = one<HazardSurfaced>(h.apply(DebugForceHazard(0, hazard)));
        expect(surfaced.expiresAt, 5000);

        final events = h.place(0, good, 1000);
        expect(one<HazardResolved>(events).met, isTrue);
        expect(h.state.hazard, isNull);
        expect(h.silhouette.hazardsMet, 1);
        expect(h.incubator, 50 + 10 + 15);
      });

      test('not met by $bad: −25 when the fuse runs out', () {
        final h = Harness();
        h.setIncubator(50);
        h.apply(DebugForceHazard(0, hazard));
        h.place(0, bad, 1000);
        expect(h.state.hazard, isNotNull);

        final events = h.apply(const Tick(5001));
        expect(one<HazardResolved>(events).met, isFalse);
        expect(h.incubator, 50 + 10 - 25);
        expect(h.silhouette.hazardsMet, 0);
      });
    });
  }

  test('a creature that already qualifies meets the hazard on surfacing', () {
    final h = Harness();
    h.place(0, 'extra_bat', 100);
    final events = h.apply(const DebugForceHazard(200, 'hazard_storm'));
    expect(one<HazardResolved>(events).met, isTrue);
  });

  test('water seal satisfies Záplava', () {
    final h = Harness();
    h.apply(const DebugForceHazard(0, 'hazard_flood'));
    expect(one<HazardResolved>(h.place(0, 'seal_water', 100)).met, isTrue);
  });

  test('a throw exactly at the deadline still counts', () {
    final h = Harness();
    h.apply(const DebugForceHazard(0, 'hazard_storm'));
    expect(one<HazardResolved>(h.place(0, 'extra_butterfly', 5000)).met, isTrue);
  });

  test('failed hazard that empties the incubator hatches early', () {
    final h = Harness();
    h.setIncubator(10);
    h.apply(const DebugForceHazard(0, 'hazard_storm'));
    final events = h.apply(const Tick(5001));
    expect(one<CreatureHatched>(events).record.premature, isTrue);
    expect(h.incubator, 60);
  });

  test('met hazard shows up in the rarity breakdown', () {
    final h = Harness();
    h.apply(const DebugForceHazard(0, 'hazard_storm'));
    h.place(0, 'extra_dragonfly', 100);
    final record = one<CreatureHatched>(h.apply(const DebugHatchNow(200))).record;
    expect(record.rarityReasons, contains(const RarityReason('hazard', 1)));
  });

  test('hazards surface when drawn; a second one waits at the bottom', () {
    final h = Harness(players: 1, rules: RulesConfig.v1.copyWith(handSize: 1));
    final pot = h.state.pot;
    int take(String id) => pot.removeAt(pot.indexWhere((c) => h.state.defIdOf(c) == id));
    final flood = take('hazard_flood');
    final darkness = take('hazard_darkness');
    pot
      ..add(darkness)
      ..add(flood); // flood on top
    h.player(0).hand.clear();

    final events = h.place(0, 'head_trex', 100);
    expect(one<HazardSurfaced>(events).card, flood);
    expect(h.state.hazard!.card, flood);
    // Only other skipped hazards can sit below it.
    expect(h.state.pot.indexOf(darkness), lessThan(6));
    final drawn = one<CardDrawn>(events.skipWhile((e) => e is! CardPlaced).toList());
    expect(engine.defOf(h.state, drawn.card).kind, isNot(CardKind.hazard));
    expect(h.player(0).hand, hasLength(1));
  });

  test('an active hazard is cancelled (no penalty) when the creature hatches', () {
    final h = Harness();
    // Long fuse: placing six cards one per second outlasts the default 5 s.
    h.apply(const DebugForceHazard(0, 'hazard_darkness', fuseMs: 60000));
    final events = h.placeAll(fireCreature);
    expect(has<CreatureHatched>(events), isTrue);
    expect(has<HazardCancelled>(events), isTrue);
    expect(events.whereType<HazardResolved>(), isEmpty);
    expect(h.state.hazard, isNull);
  });
}
