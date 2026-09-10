import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('bots hatch the requested number of creatures', () {
    final report = runSimulation(engine, const SimOptions(players: 3, creatures: 12));
    expect(report.count, 12);
    expect(report.truncated, isFalse);
    expect(report.sessions, 3);
    expect(report.placements, greaterThan(12));
  });

  test('same seed, same report', () {
    String summary(SimReport r) =>
        '${r.durationsMs()} ${r.rarityCounts} ${r.passesSent} ${r.hazardsMet}';
    const options = SimOptions(players: 4, creatures: 10, seed: 3);
    expect(summary(runSimulation(engine, options)), summary(runSimulation(engine, options)));
  });

  test('solo seat works (no passing)', () {
    final report = runSimulation(
      engine,
      const SimOptions(players: 1, creatures: 5, profiles: [KidBotProfile.careful]),
    );
    expect(report.count, 5);
    expect(report.passesSent, 0);
  });

  test('hand-less table only hatches through the incubator', () {
    final report = runSimulation(
      engine,
      const SimOptions(
        players: 2,
        creatures: 3,
        rules: RulesConfig(handSize: 0, dealIntervalMs: 0),
      ),
    );
    expect(report.count, 3);
    expect(report.prematureRate, 1.0);
  });
}
