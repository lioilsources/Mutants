import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutant/host/seat.dart';
import 'package:mutant/services/bestiary_store.dart';
import 'package:mutant/theme.dart';
import 'package:mutant/ui/hand/card_face.dart';
import 'package:mutant/ui/table/table_screen.dart';
import 'package:mutant_core/io.dart';

void main() {
  testWidgets('table shows the viewed hand and the creature slots', (
    tester,
  ) async {
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
          seats: const [SeatMode.human, SeatMode.careful],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mutant č. 1'), findsOneWidget);
    expect(find.byType(CardFace), findsNWidgets(3));
    for (final slot in ['hlava', 'trup', 'přední', 'zadní', 'ocas', 'extra']) {
      expect(find.text(slot), findsWidgets);
    }

    // Dispose the host so its timer doesn't outlive the test.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
