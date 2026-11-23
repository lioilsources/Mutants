import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutant/host/local_host.dart';
import 'package:mutant/host/seat.dart';
import 'package:mutant/services/bestiary_store.dart';
import 'package:mutant/services/game_assets.dart';
import 'package:mutant/theme.dart';
import 'package:mutant/ui/collection/collection_screen.dart';
import 'package:mutant/ui/figure/figure_view.dart';
import 'package:mutant/ui/reveal/reveal_overlay.dart';
import 'package:mutant/ui/table/event_messages.dart';
import 'package:mutant/ui/table/silhouette_board.dart';
import 'package:mutant_core/io.dart';
import 'package:mutant_core/mutant_core.dart';

// flutter_tester can't resolve package URIs, so point at the assets directly.
final assets = Directory('../mutant_core/assets');
final engine = loadEngine(assets: assets);

GameHost humanHost({int seats = 2}) => GameHost(
  engine: engine,
  seats: List.filled(seats, SeatMode.human),
  rules: const RulesConfig(handSize: 0, dealIntervalMs: 0),
);

Widget wrap(Widget child) => MaterialApp(
  theme: buildMutantTheme(),
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() {
    GameAssets.instance = GameAssets(
      moves: loadMoveTable(assets: assets),
      art: ArtIndex.empty(),
    );
  });

  testWidgets('a part that fits no candidate is rejected with a message', (
    tester,
  ) async {
    final host = humanHost();
    await tester.pumpWidget(
      wrap(
        Column(
          children: [Expanded(child: SilhouetteBoard(host: host))],
        ),
      ),
    );
    host.throwCard(0, host.giveCard(0, 'head_shark')!);
    final wrong = host.giveCard(0, 'back_grasshopper')!;
    final events = host.debug((ts) => ThrowCard(ts, player: 0, card: wrong));
    final bounce = events.whereType<CardBounced>().single;
    expect(bounce.reason, BounceReason.noFit);
    expect(messageFor(bounce, host), 'Tenhle díl k němu nepasuje');
    expect(host.state.players[0].hand, contains(wrong));
    await tester.pump(const Duration(milliseconds: 500));
    host.dispose();
  });

  testWidgets('"Kdo to bude?" narrows from a question mark to one mutant', (
    tester,
  ) async {
    final host = humanHost();
    Future<void> pumpTable() async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              CandidateStrip(host: host),
              Expanded(child: SilhouetteBoard(host: host)),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pumpTable();
    expect(find.text('?'), findsOneWidget);
    expect(find.byType(FigureView), findsNothing);

    host.throwCard(0, host.giveCard(0, 'head_shark')!);
    await pumpTable();
    expect(
      find.byType(FigureView),
      findsNWidgets(4),
      reason: '4 shark mutants',
    );

    host.throwCard(0, host.giveCard(0, 'back_hare')!);
    await pumpTable();
    expect(find.text('Už víme, kdo to bude!'), findsOneWidget);
    expect(find.textContaining('Chybí:'), findsNWidgets(4));
    expect(
      find.textContaining('Liščí'),
      findsOneWidget,
      reason: 'missing tail named',
    );
    host.dispose();
  });

  testWidgets(
    'bots play to a reveal that runs to the end and fills the collection',
    (tester) async {
      tester.view.physicalSize = const Size(1206, 2622);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final store = BestiaryStore.inMemory();
      final host = GameHost(
        engine: engine,
        seats: const [SeatMode.hasty, SeatMode.careful, SeatMode.passer],
        onHatched: store.add,
      );
      for (var i = 0; i < 40000 && host.pendingHatch == null; i++) {
        host.advanceBy(50);
      }
      final record = host.pendingHatch!;
      expect(record.mutantId, isNotNull);
      expect(store.bestiary.length, 1);

      await tester.pumpWidget(
        wrap(
          RevealOverlay(
            record: record,
            mutant: engine.collection![record.mutantId!],
            host: host,
            store: store,
          ),
        ),
      );
      expect(find.text('Líhne se…'), findsOneWidget);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Další mutant'), findsOneWidget);
      await tester.tap(find.text('Další mutant'));
      expect(host.pendingHatch, isNull);

      final progress = CollectionProgress(engine.collection!, store.bestiary);
      expect(
        progress.shelfOf(record.mutantId!)!.state,
        record.premature ? ShelfState.seen : ShelfState.owned,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      host.dispose();
    },
  );

  testWidgets('a tap skips the reveal step by step', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final host = humanHost();
    final store = BestiaryStore.inMemory();
    host.debug((ts) => DebugHatchMutant(ts, 'zralomedved'));
    final record = host.pendingHatch!;
    await tester.pumpWidget(
      wrap(
        RevealOverlay(
          record: record,
          mutant: engine.collection!['zralomedved'],
          host: host,
          store: store,
        ),
      ),
    );
    for (
      var i = 0;
      i < 10 && find.text('Další mutant').evaluate().isEmpty;
      i++
    ) {
      await tester.tapAt(const Offset(200, 300));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Další mutant'), findsOneWidget);
    expect(
      find.text('Cvakne zuby'),
      findsWidgets,
      reason: 'shark head move button',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    host.dispose();
  });

  testWidgets('collection shelves are unknown, seen or owned', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final host = humanHost();
    final store = BestiaryStore.inMemory();
    for (final event in [
      ...host.debug((ts) => DebugHatchMutant(ts, 'pradrak')),
      ...host.debug(
        (ts) => DebugHatchMutant(ts + 1, 'prazralok', premature: true),
      ),
    ]) {
      if (event is CreatureHatched) store.add(event.record);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: buildMutantTheme(),
        home: CollectionScreen(store: store, engine: engine),
      ),
    );
    await tester.pump();
    expect(find.text('1 / 28'), findsOneWidget);
    expect(find.text('Pradrak'), findsOneWidget);
    expect(
      find.text('Pražralok'),
      findsOneWidget,
      reason: 'seen shows the name',
    );

    ShelfState stateOf(String id) => tester
        .widget<ShelfTile>(
          find.ancestor(
            of: find.byKey(ValueKey('shelf-$id')),
            matching: find.byType(ShelfTile),
          ),
        )
        .shelf
        .state;
    expect(stateOf('pradrak'), ShelfState.owned);
    expect(stateOf('prazralok'), ShelfState.seen);
    expect(stateOf('prajester'), ShelfState.unknown);

    await tester.tap(find.byKey(const ValueKey('shelf-pradrak')));
    // Figures idle forever, so no pumpAndSettle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ShelfDetail), findsOneWidget);
    expect(find.text('Zařve a zakouří'), findsOneWidget, reason: 'move chip');
    host.dispose();
  });
}
