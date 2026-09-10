import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mutant_core/mutant_core.dart';
import 'package:path_provider/path_provider.dart';

/// Local bestiary persisted as one JSON file (v1).
class BestiaryStore extends ChangeNotifier {
  BestiaryStore._(this._file, this.bestiary);

  /// Not persisted – for tests and previews.
  BestiaryStore.inMemory([Bestiary? bestiary])
    : _file = null,
      bestiary = bestiary ?? Bestiary();

  static Future<BestiaryStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bestiary.json');
    if (!await file.exists()) return BestiaryStore._(file, Bestiary());
    try {
      return BestiaryStore._(
        file,
        Bestiary.fromJsonString(await file.readAsString()),
      );
    } catch (_) {
      // Keep the unreadable file for inspection instead of overwriting it.
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await file.rename('${dir.path}/bestiary.unreadable-$stamp.json');
      return BestiaryStore._(file, Bestiary());
    }
  }

  final File? _file;
  final Bestiary bestiary;
  Future<void> _writes = Future.value();

  List<CreatureRecord> get newestFirst => bestiary.records.reversed.toList();

  void add(CreatureRecord record) {
    if (bestiary.add(record)) _changed();
  }

  void rename(String id, String name) {
    if (bestiary.rename(id, name)) _changed();
  }

  void _changed() {
    notifyListeners();
    final file = _file;
    if (file == null) return;
    final json = bestiary.toJsonString();
    _writes = _writes.then((_) => file.writeAsString(json));
  }
}
