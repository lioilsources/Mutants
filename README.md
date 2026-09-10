# Mutants

Kooperativní mobilní karetní hra pro děti. Hráči zároveň házejí karty s částmi zvířat do kotlíku
a skládají z nich mutanta; hotový tvor se uloží do bestiáře. Nikdo neprohrává.

- [`Prompts/00-PLAN_MUTANT.md`](Prompts/00-PLAN_MUTANT.md) – plán hry, pravidla a fáze
- [`mutant_core/`](mutant_core/) – herní logika v čistém Dartu: karty, engine, pravidla, boti, CLI simulace
- [`app/`](app/) – Flutter prototyp (Fáze 1): stůl, ruka, líhnutí, bestiář, puppet mode a DebugPanel

```bash
cd mutant_core
dart pub get && dart test
dart run mutant_core:sim --players 3 --creatures 200 --seed 1

cd ../app
flutter pub get && flutter test
flutter run --dart-define=MUTANT_DEMO=true --dart-define=MUTANT_SPEED=3
```
