import 'package:mutant_core/io.dart';
import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

final collection = engine.collection!;

/// Collection rules with no dealing, so hands hold only what a test gives.
RulesConfig closed({
  double fitDealBias = 0,
  int dealIntervalMs = 0,
  bool rejectToPot = false,
}) => RulesConfig(
  handSize: 0,
  dealIntervalMs: dealIntervalMs,
  fitDealBias: fitDealBias,
  rejectToPot: rejectToPot,
);

const zralomedved = [
  'head_shark',
  'torso_polar_bear',
  'front_walrus',
  'back_hare',
  'tail_fox',
  'extra_shark_fin',
];

List<String> candidateIds(Harness h) => [
  for (final m in candidatesOf(h.silhouette, h.state.defIdOf, collection)) m.id,
];

void main() {
  group('collection data', () {
    test('28 mutants: 7 ancestors and 21 hybrids, every origin pair once', () {
      expect(collection.length, 28);
      expect(collection.mutants.where((m) => m.isAncestor), hasLength(7));
      final pairs = <String>{};
      for (final m in collection.mutants.where((m) => !m.isAncestor)) {
        expect(m.origins, hasLength(2));
        final key = ([for (final o in m.origins) o.name]..sort()).join('+');
        expect(pairs.add(key), isTrue, reason: 'pair $key twice');
      }
      expect(pairs, hasLength(21));
    });

    test('every part card is in at least two recipes', () {
      for (final def in engine.catalog.ofKind(CardKind.part)) {
        expect(
          collection.withPart(def.slot!, def.id).length,
          greaterThanOrEqualTo(2),
          reason: def.id,
        );
      }
    });

    test('any two recipes differ in at least 3 slots', () {
      final ms = collection.mutants;
      for (var i = 0; i < ms.length; i++) {
        for (var j = i + 1; j < ms.length; j++) {
          expect(ms[i].distanceTo(ms[j]), greaterThanOrEqualTo(3));
        }
      }
    });

    test('every hazard can be met by some mutant', () {
      for (final hazard in engine.catalog.ofKind(CardKind.hazard)) {
        final req = hazard.requires!;
        final ok = collection.mutants.any(
          (m) => m.parts.values.any(
            (id) => cardMeetsRequirement(engine.catalog[id], req),
          ),
        );
        expect(ok, isTrue, reason: hazard.id);
      }
    });

    test('validation names the broken mutant', () {
      final broken = MutantCollection([
        ...collection.mutants,
        MutantDef(
          id: 'kopie',
          name: 'Kopie',
          origins: const [Origin.marine, Origin.mammal],
          tier: 0,
          parts: {...collection['zralomedved'].parts, Slot.tail: 'tail_whale'},
        ),
      ]);
      expect(
        () => broken.validate(engine.catalog),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('kopie'),
          ),
        ),
      );
    });

    test('move table covers every part', () {
      final moves = loadMoveTable();
      for (final def in engine.catalog.ofKind(CardKind.part)) {
        final move = moves[def.id];
        expect(move, isNotNull, reason: def.id);
        expect(moves.moveSlots[move!.move], def.slot, reason: def.id);
      }
    });
  });

  group('candidates', () {
    test('narrow with every part; wildcards are not compared', () {
      final h = Harness(rules: closed());
      expect(candidateIds(h), hasLength(28));
      h.place(0, 'head_shark', 100);
      expect(
        candidateIds(h),
        unorderedEquals([
          'prazralok',
          'zralotucnak',
          'zralomedved',
          'zralobot',
        ]),
      );
      h.place(0, 'mut_eyes_everywhere', 200);
      expect(candidateIds(h), hasLength(4));
      h.place(0, 'back_hare', 300);
      expect(candidateIds(h), ['zralomedved']);
      expect(
        neededParts(
          h.silhouette,
          collection.mutants.where((m) => m.id == 'zralomedved').toList(),
        ),
        {
          Slot.front: 'front_walrus',
          Slot.tail: 'tail_fox',
          Slot.extra: 'extra_shark_fin',
        },
      );
    });
  });

  group('placement', () {
    test('a fitting part lands, a part no candidate uses is rejected', () {
      final h = Harness(rules: closed());
      h.place(0, 'head_shark', 100);
      final crab = h.give(0, 'back_crab');
      final grasshopper = h.give(0, 'back_grasshopper');
      final events = h.throwCard(0, grasshopper, 200);
      expect(one<CardBounced>(events).reason, BounceReason.noFit);
      expect(
        h.player(0).hand,
        contains(grasshopper),
        reason: 'back to the hand',
      );
      expect(has<CardPlaced>(h.throwCard(0, crab, 300)), isTrue);
    });

    test('second throw into the same slot is rejected – no fusion', () {
      final h = Harness(rules: closed());
      h.place(0, 'head_shark', 100);
      final events = h.place(1, 'head_owl', 110);
      expect(one<CardBounced>(events).reason, BounceReason.slotOccupied);
      expect(h.silhouette.slots[Slot.head]!.cards, hasLength(1));
    });

    test('wildcard fills an empty slot, never overwrites, max two', () {
      final h = Harness(rules: closed());
      h.place(0, 'head_shark', 100);
      expect(
        one<CardBounced>(h.place(0, 'mut_two_heads', 200)).reason,
        BounceReason.slotOccupied,
      );
      h.place(0, 'mut_eyes_everywhere', 300);
      h.place(0, 'mut_six_arms', 400);
      expect(h.silhouette.wildCount, 2);
      expect(
        one<CardBounced>(h.place(0, 'mut_spring_legs', 500)).reason,
        BounceReason.wildLimit,
      );
    });

    test('seal is stamped once', () {
      final h = Harness(rules: closed());
      expect(
        one<CardPlaced>(h.place(0, 'seal_fire', 100)).kind,
        PlacementKind.seal,
      );
      expect(
        one<CardBounced>(h.place(0, 'seal_ice', 200)).reason,
        BounceReason.sealTaken,
      );
    });

    test('rejectToPot drops the rejected card into the pot', () {
      final h = Harness(rules: closed(rejectToPot: true));
      h.place(0, 'head_shark', 100);
      final card = h.give(0, 'back_grasshopper');
      final events = h.throwCard(0, card, 200);
      expect(one<CardBounced>(events).toPot, isTrue);
      expect(h.player(0).hand, isNot(contains(card)));
      expect(h.state.pot, contains(card));
    });

    test('hints follow the collection', () {
      final h = Harness(rules: closed());
      h.place(0, 'head_shark', 100);
      final crab = h.give(0, 'back_crab');
      h.give(0, 'back_grasshopper');
      expect(fittingCards(h.state, engine.catalog, 0), [crab]);
      expect(cardsForEmptySlots(h.state, engine.catalog, 0), [crab]);
      h.give(1, 'back_spider');
      expect(playersToCall(h.state, engine.catalog), {0});
    });
  });

  group('hatching', () {
    test('complete silhouette hatches its single mutant', () {
      final h = Harness(rules: closed());
      final events = h.placeAll(zralomedved);
      final record = one<CreatureHatched>(events).record;
      expect(record.mutantId, 'zralomedved');
      expect(record.name, 'Žralomedvěd');
      expect(record.premature, isFalse);
      expect(record.isOwned, isTrue);
      expect(
        record.rarity,
        Rarity.common,
        reason: 'hybrid, no synchro, no hazard',
      );
      expect(record.rarityReasons, isEmpty);
    });

    test('ancestor tier counts toward rarity', () {
      final h = Harness(rules: closed());
      final record = one<CreatureHatched>(
        h.placeAll(collection['prazralok'].parts.values.toList()),
      ).record;
      expect(record.mutantId, 'prazralok');
      expect(record.rarityReasons, [const RarityReason('tier', 2)]);
      expect(record.rarity, Rarity.rare);
    });

    test('wildcards stand in for recipe parts', () {
      final h = Harness(rules: closed());
      final events = h.placeAll([
        'head_shark',
        'mut_eyes_everywhere',
        'front_walrus',
        'back_hare',
        'mut_forked_tail',
        'extra_shark_fin',
      ]);
      final record = one<CreatureHatched>(events).record;
      expect(record.mutantId, 'zralomedved');
      expect(record.wildSlots, {Slot.torso, Slot.tail});
      expect(record.parts[Slot.torso], ['mut_eyes_everywhere']);
      final recipeStats = [
        for (final id in collection['zralomedved'].parts.values)
          engine.catalog[id].stats,
      ].fold(Stats.zero, (a, b) => a + b);
      expect(record.stats, recipeStats);
    });

    test(
      'premature hatch picks a candidate from the state RNG, half-baked',
      () {
        String? hatchWith(int seed) {
          final h = Harness(rules: closed(), seed: seed, frozen: false);
          h.setIncubator(5);
          h.apply(const DebugSetIncubator(0, frozen: false));
          h.place(0, 'head_shark', 100);
          final events = h.apply(const Tick(60000));
          final record = one<CreatureHatched>(events).record;
          expect(record.premature, isTrue);
          expect(record.isOwned, isFalse);
          expect(record.rarity, Rarity.common);
          expect(record.rarityReasons.single.code, 'premature');
          return record.mutantId;
        }

        final a = hatchWith(11);
        expect([
          'prazralok',
          'zralotucnak',
          'zralomedved',
          'zralobot',
        ], contains(a));
        expect(hatchWith(11), a, reason: 'same seed, same mutant');
      },
    );

    test('incubator empty with nothing placed lays an empty egg', () {
      final h = Harness(rules: closed(), frozen: false);
      h.setIncubator(5);
      h.apply(const DebugSetIncubator(0, frozen: false));
      final events = h.apply(const Tick(60000));
      expect(has<EggEmpty>(events), isTrue);
      expect(has<CreatureHatched>(events), isFalse);
      expect(h.state.hatchedCount, 0);
    });

    test('DebugHatchMutant builds and hatches a recipe', () {
      final h = Harness(rules: closed());
      final record = one<CreatureHatched>(
        h.apply(const DebugHatchMutant(0, 'drakobot')),
      ).record;
      expect(record.mutantId, 'drakobot');
      expect(record.premature, isFalse);
      final grey = one<CreatureHatched>(
        h.apply(const DebugHatchMutant(10, 'drakobot', premature: true)),
      ).record;
      expect(grey.premature, isTrue);
      expect(
        has<CommandRejected>(h.apply(const DebugHatchMutant(20, 'nikdo'))),
        isTrue,
      );
    });
  });

  group('hazards', () {
    test('a hazard no candidate can meet does not surface', () {
      final h = Harness(rules: closed(dealIntervalMs: 1000));
      h.place(0, 'head_owl', 100); // owl has no fangs → Hlad impossible
      final pot = h.state.pot;
      final hunger = pot.firstWhere(
        (c) => h.state.defIdOf(c) == 'hazard_hunger',
      );
      pot
        ..remove(hunger)
        ..add(hunger);
      final events = h.apply(const Tick(1500));
      expect(has<HazardSurfaced>(events), isFalse);
      expect(h.state.pot.first, hunger, reason: 'went to the bottom');
    });

    test('a hazard some candidate can meet surfaces', () {
      final h = Harness(rules: closed(dealIntervalMs: 1000));
      h.place(0, 'torso_turtle', 100);
      final pot = h.state.pot;
      final hunger = pot.firstWhere(
        (c) => h.state.defIdOf(c) == 'hazard_hunger',
      );
      pot
        ..remove(hunger)
        ..add(hunger);
      expect(has<HazardSurfaced>(h.apply(const Tick(1500))), isTrue);
    });
  });

  group('smart pot', () {
    test('fitDealBias 1 always deals a fitting part when the pot has one', () {
      for (var seed = 1; seed <= 20; seed++) {
        final h = Harness(
          rules: closed(fitDealBias: 1, dealIntervalMs: 1000),
          seed: seed,
        );
        h.place(0, 'head_shark', 100);
        h.place(0, 'back_hare', 200);
        final drawn = h.apply(const Tick(1500)).whereType<CardDrawn>().single;
        final def = engine.catalog[h.state.defIdOf(drawn.card)];
        expect(
          partFits(
                candidatesOf(h.silhouette, h.state.defIdOf, collection),
                def,
              ) &&
              !h.silhouette.slots.containsKey(def.slot),
          isTrue,
          reason: 'seed $seed drew ${def.id}',
        );
      }
    });

    test('fitDealBias 0 deals the top card as before', () {
      final h = Harness(rules: closed(dealIntervalMs: 1000));
      h.place(0, 'head_shark', 100);
      final top = h.state.pot.lastWhere(
        (c) => engine.catalog[h.state.defIdOf(c)].kind != CardKind.hazard,
      );
      final drawn = h.apply(const Tick(1500)).whereType<CardDrawn>().single;
      expect(drawn.card, top);
    });
  });

  group('determinism', () {
    test('seed + command log replays a collection game', () {
      String run() {
        final report = runSimulation(
          engine,
          const SimOptions(players: 3, creatures: 10, seed: 9),
        );
        return [
          for (final c in report.creatures)
            '${c.record.mutantId}:${c.record.durationMs}:${c.record.rarity.index}',
        ].join(',');
      }

      expect(run(), run());
    });

    test('free rules ignore the collection', () {
      final h = Harness(
        rules: RulesConfig.free.copyWith(handSize: 0, dealIntervalMs: 0),
      );
      final record = one<CreatureHatched>(h.placeAll(fireCreature)).record;
      expect(record.mutantId, isNull);
    });
  });

  group('bestiary and collection progress', () {
    test('v1 file still loads; v2 round-trips mutant id and wildcards', () {
      final v1 = Bestiary.fromJson({'schema': 1, 'creatures': []});
      expect(v1.length, 0);

      final h = Harness(rules: closed());
      final record = one<CreatureHatched>(
        h.placeAll([
          'head_shark',
          'mut_eyes_everywhere',
          ...zralomedved.skip(2),
        ]),
      ).record;
      final copy = Bestiary.fromJsonString(
        Bestiary([record]).toJsonString(),
      ).records.single;
      expect(copy.mutantId, 'zralomedved');
      expect(copy.wildSlots, {Slot.torso});
    });

    test('shelves are unknown, seen or owned', () {
      final h = Harness(rules: closed());
      final owned = one<CreatureHatched>(
        h.apply(const DebugHatchMutant(0, 'drakobot')),
      ).record;
      final grey = one<CreatureHatched>(
        h.apply(const DebugHatchMutant(10, 'zralomedved', premature: true)),
      ).record;
      final old = one<CreatureHatched>(
        Harness(seed: 8).placeAll(fireCreature),
      ).record;
      final progress = CollectionProgress(
        collection,
        Bestiary([owned, grey, old]),
      );
      expect(progress.total, 28);
      expect(progress.owned, 1);
      expect(progress.shelfOf('drakobot')!.state, ShelfState.owned);
      expect(progress.shelfOf('drakobot')!.count, 1);
      expect(progress.shelfOf('drakobot')!.bestRarity, owned.rarity);
      expect(progress.shelfOf('zralomedved')!.state, ShelfState.seen);
      expect(progress.shelfOf('prazralok')!.state, ShelfState.unknown);
      expect(progress.oldAttempts.single.id, old.id);
    });
  });
}
