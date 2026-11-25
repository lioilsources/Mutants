import 'package:flutter/services.dart';
import 'package:mutant_core/mutant_core.dart';

/// Which generated art is bundled (PLAN-KOLEKCE §5.6). Every visual has a
/// phase-1 placeholder, so the game runs with an empty index.
class ArtIndex {
  ArtIndex(Iterable<String> assets) : _assets = assets.toSet();

  ArtIndex.empty() : _assets = const {};

  final Set<String> _assets;

  static Future<ArtIndex> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return ArtIndex(manifest.listAssets());
  }

  String? _ifPresent(String path) => _assets.contains(path) ? path : null;

  /// `assets/cards/<card_id>.webp`, 512², transparent.
  String? card(String cardId) => _ifPresent('assets/cards/$cardId.webp');

  /// `assets/figures/<mutant_id>/hero.webp`, 1024², transparent.
  String? hero(String mutantId) =>
      _ifPresent('assets/figures/$mutantId/hero.webp');

  /// Black silhouette generated from the hero's alpha channel.
  String? shadow(String mutantId) =>
      _ifPresent('assets/figures/$mutantId/shadow.webp');

  /// Video clip of a figure (PLAN-KOLEKCE §6.5): `idle`, `assemble`,
  /// `show_<slot>`, `cheer`. Square H.264 on a grey backdrop.
  String? clip(String mutantId, String name) =>
      _ifPresent('assets/figures/$mutantId/clips/$name.mp4');

  /// A figure plays from clips once it has at least an idle loop.
  bool hasClips(String mutantId) => clip(mutantId, 'idle') != null;

  /// `assets/backdrops/<name>.webp`: `reveal_stage`, `collection_shelf`,
  /// `card_back`. Portrait, opaque.
  String? backdrop(String name) => _ifPresent('assets/backdrops/$name.webp');

  int get cardCount =>
      _assets.where((a) => a.startsWith('assets/cards/')).length;

  int get heroCount => _assets.where((a) => a.endsWith('/hero.webp')).length;
}

/// Static data the UI needs next to the engine: part moves for the reveal
/// and the art index. Set once in `main`; tests may replace it.
class GameAssets {
  GameAssets({required this.moves, required this.art});

  GameAssets.empty()
    : moves = MoveTable(moveSlots: const {}, parts: const {}),
      art = ArtIndex.empty();

  final MoveTable moves;
  final ArtIndex art;

  static GameAssets instance = GameAssets.empty();

  /// Caption for a part's move, falling back to the slot's basic move.
  String moveLabel(String cardId) => moves[cardId]?.label ?? 'Předvede se';

  String moveOf(String cardId, Slot slot) =>
      moves[cardId]?.move ?? MoveTable.basicMoves[slot]!;
}
