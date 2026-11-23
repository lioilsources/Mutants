# Handoff — pokračování v lokální session

Stav k 23. 11. 2026. Větev **`claude/gifted-clarke-0z4g75`**, dva commity nad `main`, bez PR.

## Jak začít

```bash
git fetch origin && git switch claude/gifted-clarke-0z4g75
cd mutant_core && dart pub get && dart test && dart analyze
cd ../app && flutter pub get && flutter test
```

Testy pusť jako první. V cloudové session nebyl Dart ani Flutter, takže je od Fáze 1 nikdo nespustil.
Oba commity na větvi přidaly jen dokumenty a dva JSON soubory, které kód nenačítá – kdyby něco
neprošlo, je to stav z `main`, ne z téhle větve.

## Co je hotové

| | kde | stav |
|---|---|---|
| hra Fáze 0 + 1 (engine, boti, simulace, Flutter prototyp) | `mutant_core/`, `app/` | hotové z dřívějška, beze změny |
| návrh uzavřené sbírky a zadání k implementaci | `Prompts/01-PLAN_KOLEKCE.md` | hotové, **nepotvrzené** (viz níže) |
| recepty 28 mutantů, pohyb každého dílu | `mutant_core/assets/collection.json`, `moves.json` | data, kód je zatím nenačítá |
| prompty pro Qwen Image (110 obrázků) | `Prompts/02-QWEN_IMAGE_PROMPTS.md`, `Prompts/qwen/` | vygenerované, **nevyzkoušené** |
| prompty pro Wan a LTX (252 klipů na model) + srovnání | `Prompts/03-WAN_LTX_ANIMACE.md`, `Prompts/video/` | vygenerované, **nevyzkoušené** |

## Co hotové není

- **Žádný kód pro sbírku.** Hra se pořád chová podle původních pravidel (volné skládání, fúze, pahýly).
- **Žádný obrázek ani klip.** Prompty vznikly z dokumentace modelů, na modelu je nikdo nepustil.
- **Tempo hry je odhad.** Čísla v plánu §3.8 jsou z hrubého modelu v Pythonu mimo engine (skript se
  neuchoval). Platí až to, co vyjde ze `sim` v M1.
- **Rozhodnutí z plánu §8 nikdo nepotvrdil.** Jsou to návrhy, ne zadání.

## Další krok

Dvě linky, které na sobě nezávisí – dají se dělat souběžně.

**A. Kód: milník M1** (`01-PLAN_KOLEKCE.md` §3, §4, §7). Sbírka v enginu, chytrý kotlík, kalibrace
v simulaci. Než se začne, potvrdit čtyři rozhodnutí, která M1 zadrátuje do pravidel:

1. Mutace je žolík za chybějící díl (ne díl s vlastním tvarem).
2. Fúze se ruší.
3. Odmítnutá karta se vrací do ruky bez trestu.
4. Předčasné líhnutí dá šedou „nedopečenou" figurku náhodného kandidáta.

Zbylá rozhodnutí (vzpřímený postoj, jména, video vs. 3D) se M1 netýkají.

**B. Grafika: pilot tří figurek v Qwen Image** (`02-QWEN_IMAGE_PROMPTS.md` §0). Figurky `zralomedved`,
`drakobot`, `jelenobrouk`. Ladí se jen `style` v `Prompts/qwen/bible.json`, dokud nevypadají jako
jedna řada hraček. Teprve potom karty dílů a zbylých 25 figurek. Video pilot (`03-…` §6) až na hotových
hero obrázcích.

## Co potřebuje lokální stroj

- Dart a Flutter, simulátor iOS / Android, macOS build – testy a aplikace
- GPU a ComfyUI s Qwen-Image, Qwen-Image-Edit, Wan 2.2 I2V-A14B a LTX-2.5 – linka B
- Blender – až pro 3D pilot M4

## Pravidla, která se snadno přehlédnou

- `02-QWEN_IMAGE_PROMPTS.md`, `03-WAN_LTX_ANIMACE.md` a soubory `batch*.jsonl` jsou **generované**.
  Upravuje se `Prompts/qwen/bible.json` nebo `Prompts/video/motion.json` a pak:
  `python3 Prompts/qwen/build_prompts.py` a `python3 Prompts/video/build_video_prompts.py`.
  Po změně receptů v `collection.json` spustit oba.
- Engine zůstává čistý Dart: žádné hodiny, žádný `dart:math` Random, náhoda jen z `Rng` ve stavu.
- Aplikace musí být hratelná bez jediného obrázku – každý vizuál má zástupce z Fáze 1.
- Milník M3b a dál nezačínat bez výslovného pokynu.
- Po každém milníku aktualizovat README soubory a odškrtnout položky v plánu §7.

## První zpráva pro lokální session

```text
Přečti Prompts/HANDOFF.md a Prompts/01-PLAN_KOLEKCE.md.
1. Pusť testy v mutant_core a app a řekni mi výsledek.
2. Implementuj milník M1 podle §3 a §4 plánu, drž se §9.
Čtyři rozhodnutí z handoffu potvrzuji / měním takhle: …
```
