import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import 'host/seat.dart';
import 'launch_options.dart';
import 'services/bestiary_store.dart';
import 'theme.dart';
import 'ui/bestiary/bestiary_screen.dart';
import 'ui/setup/setup_screen.dart';
import 'ui/table/table_screen.dart';

class MutantApp extends StatelessWidget {
  const MutantApp({super.key, required this.engine, required this.store});

  final MutantEngine engine;
  final BestiaryStore store;

  @override
  Widget build(BuildContext context) {
    final screen = LaunchOptions.screen;
    return MaterialApp(
      title: 'Mutant',
      debugShowCheckedModeBanner: false,
      theme: buildMutantTheme(),
      home: switch (screen) {
        'bestiary' => BestiaryScreen(store: store, engine: engine),
        _ when LaunchOptions.demo || screen == 'table' || screen == 'debug' =>
          TableScreen(
            engine: engine,
            store: store,
            seats: const [SeatMode.hasty, SeatMode.careful, SeatMode.passer],
            demo: LaunchOptions.demo,
            openDebug: screen == 'debug',
          ),
        _ => SetupScreen(engine: engine, store: store),
      },
    );
  }
}
