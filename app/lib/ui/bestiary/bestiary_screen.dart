import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../services/bestiary_store.dart';
import '../../theme.dart';
import '../hatch/creature_card.dart';
import '../hatch/rename_dialog.dart';
import '../labels.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key, required this.store, required this.engine});

  final BestiaryStore store;
  final MutantEngine engine;

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  ElementType? _element;
  Rarity? _minRarity;

  @override
  Widget build(BuildContext context) {
    final catalog = widget.engine.catalog;
    final names = widget.engine.names;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Bestiář')),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final all = widget.store.newestFirst;
          final shown = [
            for (final r in all)
              if ((_element == null || r.element == _element) &&
                  (_minRarity == null || r.rarity.index >= _minRarity!.index))
                r,
          ];
          return Column(
            children: [
              _ChipRow(
                children: [
                  for (final element in ElementType.values)
                    FilterChip(
                      avatar: CircleAvatar(
                        radius: 7,
                        backgroundColor: MutantColors.element(element),
                      ),
                      label: Text(catalog.label('element', element)),
                      selected: _element == element,
                      onSelected: (on) =>
                          setState(() => _element = on ? element : null),
                    ),
                ],
              ),
              _ChipRow(
                children: [
                  for (final rarity in Rarity.values.skip(1))
                    ChoiceChip(
                      label: Text('aspoň ${names.rarityLabel(rarity)}'),
                      selected: _minRarity == rarity,
                      onSelected: (on) =>
                          setState(() => _minRarity = on ? rarity : null),
                    ),
                ],
              ),
              Expanded(
                child: all.isEmpty || shown.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            all.isEmpty
                                ? 'Bestiář je zatím prázdný. Vylíhněte prvního mutanta.'
                                : 'Tomuhle výběru žádný mutant neodpovídá.',
                            textAlign: TextAlign.center,
                            style: text.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _CreatureTile(
                          record: shown[i],
                          names: names,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _CreatureDetail(
                                id: shown[i].id,
                                store: widget.store,
                                engine: widget.engine,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _CreatureTile extends StatelessWidget {
  const _CreatureTile({
    required this.record,
    required this.names,
    required this.onTap,
  });

  final CreatureRecord record;
  final NameTables names;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: MutantColors.board,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 48,
                decoration: BoxDecoration(
                  color: MutantColors.element(record.element),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RarityPips(
                          rarity: record.rarity,
                          color: MutantColors.chalk,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${names.rarityLabel(record.rarity)}, ${formatDate(record.createdAt)}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: MutantColors.mist),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatureDetail extends StatelessWidget {
  const _CreatureDetail({
    required this.id,
    required this.store,
    required this.engine,
  });

  final String id;
  final BestiaryStore store;
  final MutantEngine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final record = store.bestiary.byId(id);
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (record != null)
                IconButton(
                  tooltip: 'Přejmenovat',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final name = await showRenameDialog(context, record.name);
                    if (name != null) store.rename(id, name);
                  },
                ),
            ],
          ),
          body: record == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: CreatureCard(
                    record: record,
                    catalog: engine.catalog,
                    names: engine.names,
                  ),
                ),
        );
      },
    );
  }
}
