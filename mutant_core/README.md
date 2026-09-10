# mutant_core

Herní logika hry **Mutant** (viz `../Prompts/00-PLAN_MUTANT.md`) – čistý Dart bez Flutteru.
Fáze 0: karty, engine, pravidla v1, rarita, jména, bestiář, KidBot, CLI simulace.

```bash
dart pub get
dart test                                   # všechna pravidla z §2–§4
dart analyze
dart run mutant_core:sim --players 3 --creatures 200 --seed 1
dart run mutant_core:sim --players 3 --sweep 1,2,4,8          # kalibrace drainPerSec
dart run mutant_core:sim --profiles careful,passer --reaction-scale 3
```

## Struktura

| | |
|---|---|
| `assets/cards.json` | 80 karet + české názvosloví os – jediná definice pro engine i UI |
| `assets/names.json` | tabulky jmen (prefix/kořen/sufix), schopnosti podle elementu, názvy rarit |
| `lib/src/model/` | `CardDef`, `CardCatalog`, `GameState` (+ `Silhouette`, `SlotFill`…), `CreatureRecord`, `RulesConfig` |
| `lib/src/rules/` | čisté funkce: `resolvePlacement` (hod, fúze, mutace, pečeť), `hazard_check`, `pass_catch`, `evaluateRarity`, `naming`, `hints` (zavolej si / auto-follow) |
| `lib/src/engine/` | `MutantEngine.apply(state, command) → (state, events)`, commandy vč. debug, eventy |
| `lib/src/bots/` | `KidBot` + profily Zbrklý / Opatrný / Předávač |
| `lib/src/bestiary/` | `Bestiary` – JSON schema v1, idempotentní `add`, přejmenování, filtr |
| `lib/src/sim/` | `runSimulation` – boti proti enginu v diskrétním čase |
| `lib/io.dart` | načtení assetů ze souboru (CLI, testy); Flutter použije `fromJsonString` |

Engine nikdy nemění stav, který dostal – pracuje na kopii. Nečte hodiny ani `dart:math`
Random: čas přichází v `Command.ts` od hostu, náhoda z vlastního `Rng` v `GameState`,
takže seed + log commandů = přesný replay (ověřeno testem).

## Výklad pravidel v1

Místa, kde plán nechává prostor, a jak jsou teď implementovaná. Vše je snadné změnit.

**Čas**
- Drain, fuse Událostí a timeout předání se dopočítají chronologicky až do `ts` commandu.
- Deadline je včetně: hod přesně v 5000 ms ještě splní Událost, chycení přesně ve 2 s platí.

**Ruka a kotlík**
- Po hodu i po předání se hráč hned dobere na 5. Chycená karta ruku zvětší (limit není).
- Vytažená Událost se vynoří; když už jedna běží, jde nová na dno kotlíku.
  Při rozdávání se Události přeskakují.
- Karty z vylíhnutého tvora a spadlá předání se zamíchají zpět; Události jdou na dno
  (jinak by šla okamžitě splněná Událost vytáhnout znovu a farmit raritu).

**Synchro, štafeta, fúze**
- Každý hod v synchru dává +25 místo +10; první hod dvojice dostane dorovnání +15.
- „≥ 3 synchro hody" počítá hody, ne dvojice. Štafeta je synchro jen pro ten jeden hod.
- Fúze: dvě obyčejné části od různých hráčů do 80 ms. Je to zároveň synchro.
  Na mutaci ani na už fúzovaný slot nejde.

**Mutace a pečeť**
- Mutace je plnohodnotná část (slot, element, původ) se zvláštností. Padne i do prázdného
  slotu; obsazený přepíše a staré karty vrátí do kotlíku.
- Pečeť je razítko na trupu, slot neobsazuje; druhá se odrazí. Určuje element tvora
  (a tím prefix jména a schopnost) a splňuje Záplavu/Tmu, ale do souladu (+2) se nepočítá.

**Události**
- Testují tvora, ne jen nový hod: Bouře je splněná, i když křídla už visí (i hned při vynoření).
- Když se tvor vylíhne s běžící Událostí, zruší se bez trestu.

**Rarita, jméno, záznam**
- Chaos = počet různých původů ÷ 3 (dolů); soulad jen u kompletního tvora; bere se vyšší.
- Fúze a Mutace +1 jednou bez ohledu na počet; každá splněná Událost +1.
- Dominantní element: pečeť › nejčastější element › dřívější slot (hlava → extra).
- Chybějící hlava/trup/element: `Šedo-Bezhlavo-bezbřichák`. Kolize jmen → římská číslice
  (`Pyro-Rexo-dračák II`), kontroluje se i proti bestiáři hostu (`GameConfig.takenNames`).
- Tvůrci = všichni hráči u stolu. `createdAt = GameConfig.epochMs + herní čas`.

**Obsah (návrh k přepsání)**
- 6. karta Události je druhá Bouře (plán vyjmenovává 5 druhů).
- 6 pečetí na 7 elementů – chybí stínová.
- Jména karet, tabulky jmen a schopnosti jsou první návrh.

## Simulace – co boti umí

Bot se každých `reactionMs ± 30 %` podívá na stůl a udělá nejvýš jednu věc: chytí
příchozí kartu (`catchRate`), s `mistakeRate` hodí náhodnou kartu, jinak hodí pasující kartu
(přednostně tu, která splní Událost) – nebo ji s `passRate` pošle kamarádovi. Když nic
nepasuje, s `passRate` pošle pryč nepotřebnou kartu. Po chycení hází rychleji (štafeta).
Simulace běží po sezeních (`--session`, výchozí 5), protože drain roste s každým mutantem.
