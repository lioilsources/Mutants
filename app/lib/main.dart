import 'package:flutter/material.dart';

import 'app.dart';
import 'services/bestiary_store.dart';
import 'services/engine_loader.dart';
import 'services/game_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final engine = await loadEngineFromBundle();
  GameAssets.instance = await loadGameAssets();
  final store = await BestiaryStore.open();
  runApp(MutantApp(engine: engine, store: store));
}
