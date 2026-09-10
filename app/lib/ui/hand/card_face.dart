import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

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
  });

  final CardDef def;
  final CardCatalog catalog;
  final double width;

  /// Nowhere to put it right now.
  final bool dimmed;

  static double heightFor(double width) => width * 1.38;

  @override
  Widget build(BuildContext context) {
    final on = MutantColors.onElement(def.element);
    final kind = switch (def.kind) {
      CardKind.mutation => 'mutace',
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
          color: MutantColors.element(def.element),
          borderRadius: BorderRadius.circular(width * 0.13),
          boxShadow: [
            BoxShadow(
              color: MutantColors.ink.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
