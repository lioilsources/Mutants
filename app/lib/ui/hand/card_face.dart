import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../services/game_assets.dart';
import '../../theme.dart';
import '../widgets/pill.dart';

/// Placeholder card: element colour, slot, name, tags.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.def,
    required this.catalog,
    this.width = 100,
    this.dimmed = false,
    this.glow = false,
  });

  final CardDef def;
  final CardCatalog catalog;
  final double width;

  /// Nowhere to put it right now.
  final bool dimmed;

  /// Fits right now – the card lights up.
  final bool glow;

  static double heightFor(double width) => width * 1.38;

  /// Mutagen = wildcard: slime green, stands in for any part of its slot.
  static const _slime = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8F36B), Color(0xFF52D8A0), Color(0xFF9F7BEA)],
  );

  bool get wild => def.kind == CardKind.mutation;

  @override
  Widget build(BuildContext context) {
    final on = wild ? MutantColors.ink : MutantColors.onElement(def.element);
    final image = def.kind == CardKind.part
        ? GameAssets.instance.art.card(def.id)
        : null;
    final kind = switch (def.kind) {
      CardKind.mutation => 'žolík',
      CardKind.seal => 'pečeť',
      _ => null,
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.5 : 1,
      child: Container(
        width: width,
        height: heightFor(width),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: wild ? null : MutantColors.element(def.element),
          gradient: wild ? _slime : null,
          borderRadius: BorderRadius.circular(width * 0.13),
          border: glow
              ? Border.all(color: MutantColors.hint, width: width * 0.035)
              : null,
          boxShadow: [
            BoxShadow(
              color: MutantColors.ink.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (glow)
              BoxShadow(
                color: MutantColors.hint.withValues(alpha: 0.55),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              catalog.label('slot', def.slot!),
              style: fredoka(
                width * 0.13,
                600,
                color: on.withValues(alpha: 0.75),
              ),
            ),
            if (kind != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Pill(kind, fontSize: width * 0.1),
              ),
            if (image != null)
              Expanded(
                child: Center(child: Image.asset(image, fit: BoxFit.contain)),
              )
            else
              const Spacer(),
            Text(
              def.name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: fredoka(width * 0.15, 600, color: on, height: 1.1),
            ),
            if (def.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  def.tags.map((t) => catalog.label('tag', t)).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fredoka(
                    width * 0.11,
                    500,
                    color: on.withValues(alpha: 0.75),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
