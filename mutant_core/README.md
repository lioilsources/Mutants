# mutant_core

Herní logika hry **Mutant** (viz `../Prompts/00-PLAN_MUTANT.md`) – čistý Dart bez Flutteru.
Fáze 0: karty, engine, pravidla, rarita, jména, bestiář, KidBot, CLI simulace a kalibrace.
Milník M1 z `../Prompts/01-PLAN_KOLEKCE.md`: **uzavřená sbírka 28 mutantů** je výchozí režim
(`RulesConfig.closedCollection`), volné skládání zůstává jako `RulesConfig.free` a `RulesConfig.v1`.

```bash
dart pub get
dart test
dart analyze
dart run mutant_core:sim --players 3 --creatures 200 --seed 1
dart run mutant_core:sim --players 3 --sweep deal=4000,6000,8000   # sweep libovolného pravidla
dart run mutant_core:sim --rules free                               # volné skládání (Fáze 1)
dart run mutant_core:sim --rules v1                                 # původní čísla z plánu
dart run mutant_core:sim --players 4 --sweep fit-bias=0.2,0.3,0.5   # chytrý kotlík
dart run mutant_core:sim --profiles careful,passer --reaction-scale 3
```

Klíče pro `--sweep KEY=a,b,c` i samostatné přepínače: `hand`, `refill`, `deal`, `max-hand`,
`drain`, `drain-per-hatch`, `chaos`, `mutation-overwrite`; v režimu sbírky navíc `fit-bias`,
`max-wild`, `reject`, `synchro-rare`.

## Struktura

| | |
|---|---|
| `assets/cards.json` | 80 karet + české názvosloví os – jediná definice pro engine i UI |
| `assets/names.json` | tabulky jmen (prefix/kořen/sufix), schopnosti podle elementu, názvy rarit |
| `assets/collection.json` | 28 receptů sbírky (`MutantCollection`, validuje se při startu enginu) |
| `assets/moves.json` | pohyb a titulek každého dílu (`MoveTable`) – pro reveal, engine ho nepoužívá |
| `lib/src/model/` | `CardDef`, `CardCatalog`, `GameState` (+ `Silhouette`, `SlotFill`…), `CreatureRecord`, `RulesConfig` |
| `lib/src/rules/` | čisté funkce: `candidates` (kandidáti, chybějící díly, splnitelné Události), `resolveCollectionPlacement`, `evaluateCollectionRarity`, `resolvePlacement` (volný režim: hod, fúze, mutace, pečeť), `hazard_check`, `pass_catch`, `evaluateRarity`, `naming`, `hints` (zavolej si / auto-follow) |
| `lib/src/engine/` | `MutantEngine.apply(state, command) → (state, events)`, commandy vč. debug, eventy |
| `lib/src/bots/` | `KidBot` + profily Zbrklý / Opatrný / Předávač |
| `lib/src/bestiary/` | `Bestiary` – JSON schema v2 (načte i v1), idempotentní `add`, přejmenování, filtr; `CollectionProgress` – police sbírky neznámý / viděný / získaný |
| `lib/src/sim/` | `runSimulation` – boti proti enginu v diskrétním čase |
| `lib/io.dart` | načtení assetů ze souboru (CLI, testy); Flutter použije `fromJsonString` |

Engine nikdy nemění stav, který dostal – pracuje na kopii. Nečte hodiny ani `dart:math`
Random: čas přichází v `Command.ts` od hostu, náhoda z vlastního `Rng` v `GameState`,
takže seed + log commandů = přesný replay (ověřeno testem).

## Režim sbírky (M1)

Pravidla podle `01-PLAN_KOLEKCE.md` §3: díl se přijme, jen když ho má aspoň jeden kandidát;
Mutace je žolík (max. 2 na tvora, nepřepisuje); fúze ani pahýly nejsou; Událost, kterou žádný
kandidát nesplní, jde na dno kotlíku; předčasné líhnutí dá náhodného kandidáta jako
„nedopečeného" (rarita 0, ve sbírce jen *viděný*), bez dílu prázdné vejce (`EggEmpty`).
Chytrý kotlík: s pravděpodobností `fitDealBias` rozdá nejvýš položený pasující díl.

**Kalibrace** (3 profily botů, seed 1, 400 mutantů, sezení po 5). Výchozí hodnoty:
`fitDealBias` **0,3** (plán navrhoval 0,5 – tvor byl hotový za 48–54 s), rarita
`tier` prapředka **2** (plán: 1) a +1 za **≥ 2** synchro hody (`raritySynchroThreshold`, plán: 3).
S `tier` 1 a prahem 3 vycházel vzácný+ jen 5–10 %.

| hráči | medián na mutanta | předčasně | vzácný+ | různých mutantů | nejčastější |
|---|---|---|---|---|---|
| 2 | 60,7 s | 9,5 % | 25,8 % | 28 | 5,5 % |
| 3 | 72,1 s | 7 % | 26,8 % | 28 | 6,5 % |
| 4 | 71,9 s | 17,8 % | 29 % | 28 | 5,5 % |
| 5 | 67,2 s | 8,8 % | 28,7 % | 28 | 6,3 % |
| **cíl** | **60–90 s** | **< 25 %** | **~30 %** | **28** | **≤ 10 %** |

Další čísla ze `sim` (3 hráči): po 1.–5. kartě zbývá 5,0 · 1,9 · 1,2 · 1,0 · 1,0 kandidáta
(první karta bývá žolík nebo pečeť, které nezužují); „co to bude?" trvá v mediánu 4 s,
dostavba 60 s – hra je hlavně hon na konkrétní díly. Prázdné vejce nenastalo.
Odmítnutých hodů je 82–87 %, ale ve volném režimu se odráží 75 %: dělá to hlavně Zbrklý bot
(30 % náhodných hodů každých ~0,45 s). S boty Opatrný + Předávač je to 51 %.

## Změny oproti plánu v1 (výsledek kalibrace Fáze 0)

Platí pro volné skládání (`RulesConfig.free`, `--rules free`). S pravidly v1 byl tvor hotový
za ~2,4 s místo 60–90 s: ruce po 5 kartách s doplňováním pokryjí 6 slotů skoro hned a
`drainPerSec` mění jen počet předčasných líhnutí, ne tempo. Tempo proto řídí kotlík;
`RulesConfig.v1` (`--rules v1`) drží původní čísla.

| | v1 (plán) | free |
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
