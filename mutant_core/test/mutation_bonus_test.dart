import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

const mutationBonus = RarityReason('mutation', 1);

List<RarityReason> hatchReasons(Harness h, int ts) =>
    one<CreatureHatched>(h.apply(DebugHatchNow(ts))).record.rarityReasons;

void main() {
  group('mutation bonus only for an overwrite (default rules)', () {
    Harness harness() => Harness(
      rules: RulesConfig.v1.copyWith(
        handSize: 0,
        mutationBonusNeedsOverwrite: true,
      ),
    );

    test('a mutation into an empty slot is just a part', () {
      final h = harness();
      h.place(0, 'mut_forked_tail', 100);
      expect(h.silhouette.mutations, 1);
      expect(h.silhouette.mutationOverwrites, 0);
      expect(hatchReasons(h, 200), isNot(contains(mutationBonus)));
    });

    test('a mutation that replaces a part earns +1', () {
      final h = harness();
      h.place(0, 'tail_fish', 100);
      h.place(1, 'mut_forked_tail', 2000);
      expect(h.silhouette.mutationOverwrites, 1);
      expect(hatchReasons(h, 3000), contains(mutationBonus));
    });

    test('several overwrites still give +1 once', () {
      final h = harness();
      h.place(0, 'tail_fish', 100);
      h.place(1, 'mut_forked_tail', 2000);
      h.place(0, 'head_trex', 3000);
      h.place(1, 'mut_two_heads', 4000);
      expect(h.silhouette.mutationOverwrites, 2);
      expect(
        hatchReasons(h, 5000).where((r) => r.code == 'mutation').toList(),
        [mutationBonus],
      );
    });
  });

  test('v1: any mutation earns +1', () {
    final h = Harness();
    h.place(0, 'mut_forked_tail', 100);
    expect(hatchReasons(h, 200), contains(mutationBonus));
  });

  test('defaults use the overwrite rule, v1 keeps the plan', () {
    expect(const RulesConfig().mutationBonusNeedsOverwrite, isTrue);
    expect(RulesConfig.v1.mutationBonusNeedsOverwrite, isFalse);
  });
}
