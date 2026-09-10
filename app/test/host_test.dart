import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mutant/host/local_host.dart';
import 'package:mutant/host/seat.dart';
import 'package:mutant_core/io.dart';
import 'package:mutant_core/mutant_core.dart';

void main() {
  // flutter_tester can't resolve package URIs, so point at the assets directly.
  final engine = loadEngine(assets: Directory('../mutant_core/assets'));

  test('bots play, and the clock stops while a hatched creature is shown', () {
    final hatched = <CreatureRecord>[];
    final host = GameHost(
      engine: engine,
      seats: const [SeatMode.hasty, SeatMode.careful, SeatMode.passer],
      onHatched: hatched.add,
    );
    for (var i = 0; i < 20000 && host.pendingHatch == null; i++) {
      host.advanceBy(50);
    }
    expect(host.pendingHatch, isNotNull);
    expect(hatched, hasLength(1));

    final stoppedAt = host.now;
    host.advanceBy(5000);
    expect(host.now, stoppedAt);

    host.acknowledgeHatch();
    host.advanceBy(100);
    expect(host.now, stoppedAt + 100);
    host.dispose();
  });

  test('two seats throwing a head at the same moment fuse', () {
    final host = GameHost(
      engine: engine,
      seats: const [SeatMode.human, SeatMode.human],
      rules: const RulesConfig(handSize: 0, dealIntervalMs: 0),
    );
    final a = host.giveCard(0, 'head_trex')!;
    final b = host.giveCard(1, 'head_shark')!;
    host
      ..throwCard(0, a)
      ..throwCard(1, b);
    expect(host.state.silhouette.slots[Slot.head]!.fused, isTrue);
    host.dispose();
  });

  test('humans and paused seats never act on their own', () {
    final host = GameHost(
      engine: engine,
      seats: const [SeatMode.human, SeatMode.paused],
    );
    final hands = [for (final p in host.state.players) List.of(p.hand)];
    host.advanceBy(3000);
    expect([for (final p in host.state.players) p.hand], hands);
    host.dispose();
  });

  test('renaming the shown creature keeps it pending', () {
    final host = GameHost(
      engine: engine,
      seats: const [SeatMode.human],
      rules: const RulesConfig(handSize: 0, dealIntervalMs: 0),
    );
    host.debug((ts) => DebugHatchNow(ts));
    host.renamePendingHatch('Ohnivák');
    expect(host.pendingHatch!.name, 'Ohnivák');
    host.dispose();
  });
}
