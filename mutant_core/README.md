# mutant_core

Herní logika hry **Mutant** (viz `../Prompts/00-PLAN_MUTANT.md`) – čistý Dart bez Flutteru.
Fáze 0: karty, engine, pravidla, rarita, jména, bestiář, KidBot, CLI simulace a kalibrace.

```bash
dart pub get
dart test
dart analyze
dart run mutant_core:sim --players 3 --creatures 200 --seed 1
dart run mutant_core:sim --players 3 --sweep deal=4000,6000,8000   # sweep libovolného pravidla
dart run mutant_core:sim --rules v1                                 # původní čísla z plánu
dart run mutant_core:sim --profiles careful,passer --reaction-scale 3
```

Klíče pro `--sweep KEY=a,b,c` i samostatné přepínače: `hand`, `refill`, `deal`, `max-hand`,
`drain`, `drain-per-hatch`, `chaos`, `mutation-overwrite`.

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

## Změny oproti plánu v1 (výsledek kalibrace)

S pravidly v1 byl tvor hotový za ~2,4 s místo 60–90 s: ruce po 5 kartách s doplňováním pokryjí
6 slotů skoro hned a `drainPerSec` mění jen počet předčasných líhnutí, ne tempo. Výchozí
`RulesConfig()` proto tempo řídí kotlíkem; `RulesConfig.v1` (`--rules v1`) drží původní čísla.

| | v1 (plán) | výchozí |
|---|---|---|
| ruka na začátku | 5 | 3 |
| doplnění po hodu / předání | ano | ne |
| kotlík rozdává | – | 1 kartu každých 6 s hráči s nejméně kartami |
| max. ruka | – | 5 (kotlík si vezme zpět nejstarší nepasující kartu) |
| `drainPerSec` | 4 | 0,85 |
| drain za vylíhnutého mutanta | +0,5 | +0,2 |
| chaos (rarita) | +1 za 3 původy | +1 za 5 původů |
| bonus za Mutaci (rarita) | za jakoukoli mutaci | jen když přepíše obsazený slot |

Výsledek se 3 profily botů (seed 1, 400 mutantů, sezení po 5):

| hráči | medián na mutanta | předčasně | vzácný+ |
|---|---|---|---|
| 2 | 54,2 s | 8,5 % | 34,5 % |
| 3 | 66,7 s | 7 % | 40,8 % |
| 4 | 68,9 s | 18,8 % | 38,3 % |
| 5 | 58,9 s | 8 % | 40,5 % |
| **cíl** | **60–90 s** | **< 25 %** | **~30 %** |

**Otevřené:** vzácný+ je pořád o 5–11 bodů nad cílem. Bonus za Mutaci i po změně padá
u 53–56 % tvorů (dřív 68–77 %), protože se mutace hrají většinou až do obsazených slotů.
Chaos zpátky na 3 původy nejde (vzácný+ 59–66 %). Další páky by opět měnily pravidla z plánu.

## Výklad pravidel

Místa, kde plán nechává prostor, a jak jsou teď implementovaná. Vše je snadné změnit.

**Čas**
- Drain, fuse Událostí, timeout předání a rozdávání kotlíku se dopočítají chronologicky až do
  `ts` commandu.
- Deadline je včetně: hod přesně v 5000 ms ještě splní Událost, chycení přesně ve 2 s platí.

**Ruka a kotlík**
- Kotlík rozdá kartu každých `dealIntervalMs` hráči s nejméně kartami (remíza náhodně). Má-li
  i ten plnou ruku, kotlík si nejdřív vezme zpět jeho nejstarší kartu, která nikam nepasuje;
  když pasují všechny, nerozdává.
- v1 (`refillOnPlay`): po hodu i předání se hráč hned dobere na 5. Chycená karta ruku zvětší.
- Vytažená Událost se vynoří; když už jedna běží, jde nová na dno kotlíku.
  Při rozdávání na začátku se Události přeskakují.
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
- Chaos = počet různých původů ÷ `chaosOriginsPerPoint` (dolů); soulad jen u kompletního tvora;
  bere se vyšší.
- Fúze +1 jednou bez ohledu na počet. Mutace +1 jednou – ve výchozích pravidlech jen tehdy,
  když přepsala obsazený slot (`mutationBonusNeedsOverwrite`), ve v1 za jakoukoli.
  Každá splněná Událost +1.
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
Boti jsou model dětí, ne děti – čísla jsou orientační, rozhodne test s dítětem ve Fázi 1.
