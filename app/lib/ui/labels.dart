import 'package:mutant_core/mutant_core.dart';

String rarityReasonLabel(String code) => switch (code) {
  'chaos' => 'chaos',
  'harmony' => 'soulad',
  'fusion' => 'fúze',
  'mutation' => 'mutace',
  'hazard' => 'události',
  'synchro' => 'synchro',
  'premature' => 'předčasné líhnutí',
  'stumps' => 'pahýly',
  _ => code,
};

String signed(int value) => value >= 0 ? '+$value' : '−${value.abs()}';

/// What a hazard needs, in words a child can act on.
String requirementText(CardCatalog catalog, HazardRequirement req) {
  if (req.tag case final tag?) {
    return 'Potřebujeme: ${catalog.label('tag', tag)}';
  }
  if (req.element case final element?) {
    return 'Potřebujeme element: ${catalog.label('element', element)}';
  }
  if (req.slot case final slot?) {
    return 'Potřebujeme část: ${catalog.label('slot', slot)}';
  }
  return '';
}

String formatClock(int ms) {
  final seconds = ms ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}. ${local.month}. ${local.year}';
}
