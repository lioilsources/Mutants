# Mutants

Kooperativní mobilní karetní hra pro děti. Hráči zároveň házejí karty s částmi zvířat do kotlíku
a skládají z nich mutanta; hotový tvor se uloží do bestiáře. Nikdo neprohrává.

- [`Prompts/HANDOFF.md`](Prompts/HANDOFF.md) – **kde se skončilo a čím pokračovat**
- [`Prompts/00-PLAN_MUTANT.md`](Prompts/00-PLAN_MUTANT.md) – plán hry, pravidla a fáze
- [`Prompts/01-PLAN_KOLEKCE.md`](Prompts/01-PLAN_KOLEKCE.md) – další krok: uzavřená sbírka 28 mutantů a 3D figurky
- [`Prompts/02-QWEN_IMAGE_PROMPTS.md`](Prompts/02-QWEN_IMAGE_PROMPTS.md) – prompty pro Qwen Image (figurky, karty, kulisy)
- [`Prompts/03-WAN_LTX_ANIMACE.md`](Prompts/03-WAN_LTX_ANIMACE.md) – prompty pro Wan a LTX (pohyby figurek) a postup srovnání animací
- [`mutant_core/`](mutant_core/) – herní logika v čistém Dartu: karty, engine, pravidla, boti, CLI simulace
- [`app/`](app/) – Flutter aplikace: stůl se sbírkou 28 mutantů, „Kdo to bude?", reveal figurky, sbírka, puppet mode a DebugPanel

```bash
cd mutant_core
dart pub get && dart test
dart run mutant_core:sim --players 3 --creatures 200 --seed 1

cd ../app
flutter pub get && flutter test
flutter run --dart-define=MUTANT_DEMO=true --dart-define=MUTANT_SPEED=3
```
