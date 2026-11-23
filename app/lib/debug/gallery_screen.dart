import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../services/game_assets.dart';
import '../theme.dart';
import '../ui/figure/figure_view.dart';
import '../ui/hand/card_face.dart';

/// Every card and every figure in all looks, to check the art (PLAN-KOLEKCE
/// §5.5). Missing art shows the placeholder and is counted in the header.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, required this.engine});

  final MutantEngine engine;

  @override
  Widget build(BuildContext context) {
    final catalog = engine.catalog;
    final collection = engine.collection;
    final art = GameAssets.instance.art;
    final cards = catalog.cards.where((d) => d.isPlaceable).toList();
    final text = Theme.of(context).textTheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Galerie'),
          bottom: TabBar(
            tabs: [
              Tab(
                text:
                    'Karty ${art.cardCount}/${catalog.ofKind(CardKind.part).length}',
              ),
              Tab(text: 'Figurky ${art.heroCount}/${collection?.length ?? 0}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1 / 1.6,
              ),
              itemCount: cards.length,
              itemBuilder: (context, i) => Column(
                children: [
                  CardFace(def: cards[i], catalog: catalog, width: 96),
                  const SizedBox(height: 2),
                  Text(
                    cards[i].id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall,
                  ),
                ],
              ),
            ),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final m in collection?.mutants ?? const <MutantDef>[])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        for (final look in FigureLook.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              color: MutantColors.board,
                              child: FigureView(
                                mutant: m,
                                catalog: catalog,
                                look: look,
                                size: 92,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: text.titleSmall),
                              Text(
                                art.hero(m.id) == null
                                    ? '${m.id} · bez obrázku'
                                    : m.id,
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
