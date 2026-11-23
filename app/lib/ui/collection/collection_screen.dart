import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../services/bestiary_store.dart';
import '../../services/game_assets.dart';
import '../../theme.dart';
import '../figure/figure_view.dart';
import '../hatch/creature_card.dart';
import '../hatch/rename_dialog.dart';
import '../labels.dart';
import '../reveal/reveal_overlay.dart';

/// Sbírka: 28 shelves – unknown / seen / owned (PLAN-KOLEKCE §5.4).
/// Replaces the bestiary list; records without a mutant are "Staré pokusy".
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({
    super.key,
    required this.store,
    required this.engine,
  });

  final BestiaryStore store;
  final MutantEngine engine;

  @override
  Widget build(BuildContext context) {
    final collection = engine.collection!;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final progress = CollectionProgress(collection, store.bestiary);
        final ancestors = [
          for (final s in progress.shelves)
            if (s.mutant.isAncestor) s,
        ];
        final byOrigin = <Origin, List<MutantShelf>>{};
        for (final s in progress.shelves) {
          if (s.mutant.isAncestor) continue;
          byOrigin.putIfAbsent(s.mutant.origins.first, () => []).add(s);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sbírka'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${progress.owned} / ${progress.total}',
                    key: const ValueKey('collection-counter'),
                    style: text.titleLarge?.copyWith(color: MutantColors.hint),
                  ),
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              _header('Prapředci', text),
              _grid(context, ancestors),
              for (final MapEntry(key: origin, value: shelves)
                  in byOrigin.entries) ...[
                _header(
                  'Kříženci – ${engine.catalog.label('origin', origin)}',
                  text,
                ),
                _grid(context, shelves),
              ],
              if (progress.oldAttempts.isNotEmpty) ...[
                _header('Staré pokusy', text),
                SliverList.separated(
                  itemCount: progress.oldAttempts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CreatureCard(
                      record: progress.oldAttempts[i],
                      catalog: engine.catalog,
                      names: engine.names,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  Widget _header(String title, TextTheme text) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(title, style: text.titleMedium),
    ),
  );

  Widget _grid(BuildContext context, List<MutantShelf> shelves) =>
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: shelves.length,
          itemBuilder: (context, i) => ShelfTile(
            shelf: shelves[i],
            catalog: engine.catalog,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ShelfDetail(
                  mutantId: shelves[i].mutant.id,
                  store: store,
                  engine: engine,
                ),
              ),
            ),
          ),
        ),
      );
}

FigureLook lookOf(ShelfState state) => switch (state) {
  ShelfState.unknown => FigureLook.shadow,
  ShelfState.seen => FigureLook.grey,
  ShelfState.owned => FigureLook.painted,
};

class ShelfTile extends StatelessWidget {
  const ShelfTile({
    super.key,
    required this.shelf,
    required this.catalog,
    required this.onTap,
  });

  final MutantShelf shelf;
  final CardCatalog catalog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final unknown = shelf.state == ShelfState.unknown;
    return Material(
      color: MutantColors.board,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('shelf-${shelf.mutant.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    alignment: Alignment.center,
                    children: [
                      FigureView(
                        mutant: shelf.mutant,
                        catalog: catalog,
                        look: lookOf(shelf.state),
                        size: box.biggest.shortestSide,
                      ),
                      if (unknown)
                        Text(
                          '?',
                          style: fredoka(32, 700, color: MutantColors.mist),
                        ),
                      if (shelf.count > 1)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Text(
                            '×${shelf.count}',
                            style: text.labelMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!unknown) Pedestal(rarity: shelf.bestRarity, width: 72),
              const SizedBox(height: 4),
              Text(
                unknown ? '???' : shelf.mutant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One shelf: the figure to turn and play with, and every piece of it.
class ShelfDetail extends StatefulWidget {
  const ShelfDetail({
    super.key,
    required this.mutantId,
    required this.store,
    required this.engine,
  });

  final String mutantId;
  final BestiaryStore store;
  final MutantEngine engine;

  @override
  State<ShelfDetail> createState() => _ShelfDetailState();
}

class _ShelfDetailState extends State<ShelfDetail> {
  final _figure = FigureController();

  @override
  void dispose() {
    _figure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final progress = CollectionProgress(
          engine.collection!,
          widget.store.bestiary,
        );
        final shelf = progress.shelfOf(widget.mutantId)!;
        final mutant = shelf.mutant;
        final unknown = shelf.state == ShelfState.unknown;
        return Scaffold(
          appBar: AppBar(title: Text(unknown ? '???' : mutant.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Center(
                child: FigureView(
                  mutant: mutant,
                  catalog: engine.catalog,
                  look: lookOf(shelf.state),
                  controller: _figure,
                  size: 260,
                ),
              ),
              Center(
                child: Pedestal(
                  rarity: shelf.state == ShelfState.owned
                      ? shelf.bestRarity
                      : null,
                  width: 220,
                ),
              ),
              const SizedBox(height: 16),
              if (unknown)
                Text(
                  'Tohohle mutanta jste ještě nepotkali.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge,
                )
              else ...[
                if (shelf.state == ShelfState.seen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Zatím jen nedopečený. Postavte ho celého a dostane barvy.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium,
                    ),
                  ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final slot in Slot.values)
                      ActionChip(
                        label: Text(
                          GameAssets.instance.moveLabel(mutant.parts[slot]!),
                        ),
                        onPressed: () => _figure.play(
                          slot,
                          GameAssets.instance.moveOf(mutant.parts[slot]!, slot),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Kusy', style: text.titleMedium),
                const SizedBox(height: 6),
                for (final r in shelf.records.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      r.name == mutant.name
                          ? mutant.name
                          : '${r.name} (${mutant.name})',
                    ),
                    subtitle: Text(
                      '${r.premature ? 'nedopečený' : engine.names.rarityLabel(r.rarity)}'
                      ' · ${formatDate(r.createdAt)}'
                      ' · ${r.creators.map((c) => c.name).join(', ')}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Dát přezdívku',
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () async {
                        final name = await showRenameDialog(context, r.name);
                        if (name != null) widget.store.rename(r.id, name);
                      },
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
