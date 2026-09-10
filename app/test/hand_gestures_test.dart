import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutant/host/seat.dart';
import 'package:mutant/services/bestiary_store.dart';
import 'package:mutant/theme.dart';
import 'package:mutant/ui/hand/card_face.dart';
import 'package:mutant/ui/hand/hand_area.dart';
import 'package:mutant/ui/hand/incoming_passes.dart';
import 'package:mutant/ui/table/player_avatar.dart';
import 'package:mutant/ui/table/table_screen.dart';
import 'package:mutant_core/io.dart';

/// Two human seats, so nothing moves unless the test touches it.
Future<void> pumpTable(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildMutantTheme(),
      home: TableScreen(
        // flutter_tester can't resolve package URIs.
        engine: loadEngine(assets: Directory('../mutant_core/assets')),
        store: BestiaryStore.inMemory(),
        seats: const [SeatMode.human, SeatMode.human],
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

Finder handCards() => find.descendant(
  of: find.byType(HandArea),
  matching: find.byType(CardFace),
);

void main() {
  testWidgets('dragging a card onto the creature throws it', (tester) async {
    await pumpTable(tester);
    expect(handCards(), findsNWidgets(3));

    await tester.timedDragFrom(
      tester.getCenter(handCards().first),
      const Offset(0, -380),
      const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(handCards(), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dragging onto an avatar passes; tapping the card catches it', (
    tester,
  ) async {
    await pumpTable(tester);
    final from = tester.getCenter(handCards().first);
    final friend = find.byType(PlayerAvatar).at(1);

    await tester.timedDragFrom(
      from,
      tester.getCenter(friend) - from,
      const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(handCards(), findsNWidgets(2));
    expect(find.text('chyť!'), findsOneWidget);

    await tester.tap(friend);
    await tester.pump(const Duration(milliseconds: 50));
    final incoming = find.descendant(
      of: find.byType(IncomingPasses),
      matching: find.byType(CardFace),
    );
    expect(incoming, findsOneWidget);

    await tester.tap(incoming);
    await tester.pump(const Duration(milliseconds: 50));
    expect(handCards(), findsNWidgets(4));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
