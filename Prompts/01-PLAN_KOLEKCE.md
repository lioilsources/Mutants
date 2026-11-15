# PLAN — Uzavřená sbírka mutantů a 3D figurky

Navazuje na [`00-PLAN_MUTANT.md`](00-PLAN_MUTANT.md) a **nahrazuje jeho „Fázi 2 – paper-doll"**.
Fáze 0 (`mutant_core`) a Fáze 1 (`app`, zástupná grafika) jsou hotové. Tento dokument je zadání
k implementaci. Prompty pro grafiku jsou v [`02-QWEN_IMAGE_PROMPTS.md`](02-QWEN_IMAGE_PROMPTS.md),
prompty pro rozpohybování figurek videomodelem v [`03-WAN_LTX_ANIMACE.md`](03-WAN_LTX_ANIMACE.md).

## 0. Zadání

Volné slepování šesti libovolných dílů nevypadá dobře: kombinací je milion a žádná není navržená
jako celek. Proto:

- Existuje **uzavřená sbírka mutantů**. Sbírka *je* seznam všech povolených kombinací dílů.
  Co ve sbírce není, nevznikne.
- Hozená karta, která **nepasuje** k žádnému mutantovi, kterého ještě jde postavit, je **odmítnuta**.
- Každý mutant ze sbírky je **hotová figurka**: navržená jako celek, ve finále 3D s pohyby. Po dostavění
  se ukáže jako finální sestava a **předvede, co umí**.

## 1. Co se mění

| | dosud | nově |
|---|---|---|
| tvor | libovolných 6 dílů (10⁶ kombinací) | jeden z **28 mutantů** sbírky |
| hod | díl padne do svého slotu, když je volný | díl se přijme, jen když po něm zůstane možný aspoň jeden mutant |
| vzhled tvora | paper-doll slepený z dílů (plán) | hotová figurka: 2D hero obrázek → 3D GLB s animacemi |
| po vylíhnutí | textová karta | **reveal**: figurka se složí, otočí a předvede pohyby svých dílů |
| bestiář | seznam vylíhnutých | **sbírka** 28 polic: neznámý / viděný / získaný |
| Mutace | díl, který přepisuje slot | **žolík** za chybějící díl |
| fúze, chaos/soulad, pahýly, skládaná jména | ano | ruší se |

Beze změny zůstává: balíček 80 karet (60 částí, 8 Mutací, 6 pečetí, 6 Událostí), inkubátor, předávání
a chytání, synchro a štafeta, pečeť, kotlík jako rozdávající, puppet mode, DebugPanel, deterministický
engine (seed + log commandů = replay).

## 2. Sbírka

Zdroj pravdy: **`mutant_core/assets/collection.json`** (už je v repu). Jména jsou první návrh.

**Stavba.** Karty mají 7 rodů (dino, hmyz, mořský, ptačí, savec, drak, robot). Sbírka je
„každý rod s každým": 7 **prapředků** (všech šest dílů z jednoho rodu) + 21 **kříženců**
(každá dvojice rodů právě jednou) = **28 mutantů**. U křížence platí:

- hlava a přední končetiny jsou z prvního rodu, trup a zadní končetiny z druhého
  (přední půlka jednoho zvířete, zadní půlka druhého – čitelné jako klasická chiméra);
- ocas dává jeden rod, extra druhý;
- každý rod je „předek" ve 3 dvojicích a „zadek" ve 3, stejně tak pro extra/ocas.

Z toho plynou vlastnosti, na kterých stojí pravidla (hlídá je validátor a test):

1. Každá z 60 karet dílů je aspoň ve 2 receptech (36 karet ve 2, 24 ve 4) → žádná mrtvá karta,
   první hod vždy nechá na výběr.
2. Každé dva recepty se liší aspoň ve **3 slotech** → 4 položené díly určují mutanta jednoznačně a
   až 2 žolíci jednoznačnost nerozbijí.
3. Všechny Události jsou splnitelné: křídla 16 mutantů, tesáky 14, vodní díl 12, stínový díl 16.

Jak se výběr zužuje (průměr přes náhodné platné stavby): po 1. kartě zbývá 2,8 mutanta a pasuje
11,5 různých karet; po 2. kartě 1,2 mutanta a 4,6 karty; od 3. karty je mutant prakticky daný.
Hra má tedy dvě části: **„co to bude?"** (první 1–2 karty, volba) a **„dostavba"** (hon na konkrétní díly).

| # | id | jméno | rody (hlava+ruce × tělo+nohy) | hlava | trup | přední | zadní | ocas | extra | živel |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `prajester` | Praještěr | dino | trex | stegosaurus | trex | brontosaurus | ankylosaurus | pterodactyl | oheň |
| 2 | `prabrouk` | Prabrouk | hmyz | fly | beetle | mantis | grasshopper | scorpion | dragonfly | blesk |
| 3 | `prazralok` | Pražralok | mořský | shark | turtle | crab | crab | fish | shark_fin | voda |
| 4 | `praptak` | Prapták | ptačí | owl | parrot | eagle | phoenix | peacock | eagle | rostlina |
| 5 | `prachlupac` | Prachlupáč | savec | wolf | polar_bear | gorilla | hare | fox | rhino | led |
| 6 | `pradrak` | Pradrak | drak | dragon | dragon | dragon | dragon | ice_dragon | dragon | oheň |
| 7 | `prarobot` | Prarobot | robot | robot | robot | submarine | tracks | metal | antenna | blesk |
| 8 | `tricebrouk` | Tricebrouk | dino × hmyz | triceratops | beetle | raptor | spider | scorpion | pterodactyl | kámen |
| 9 | `rexozelva` | Rexoželva | dino × mořský | trex | turtle | trex | crab | whale | ice_spikes | oheň |
| 10 | `tricemedved` | Tricemedvěd | dino × savec | triceratops | polar_bear | raptor | hare | ankylosaurus | rhino | kámen |
| 11 | `pavoukobotnice` | Pavoukobotnice | hmyz × mořský | spider | octopus | mantis | crab | fish | dragonfly | stín |
| 12 | `mouchopapousek` | Mouchopapoušek | hmyz × ptačí | fly | parrot | mantis | heron | peacock | butterfly | rostlina |
| 13 | `pavoudrak` | Pavoudrak | hmyz × drak | spider | shadow_dragon | mantis | forest_dragon | scorpion | dragon | stín |
| 14 | `zralotucnak` | Žralotučňák | mořský × ptačí | shark | penguin | walrus | heron | swallow | shark_fin | voda |
| 15 | `zralomedved` | Žralomedvěd | mořský × savec | shark | polar_bear | walrus | hare | fox | shark_fin | led |
| 16 | `zralobot` | Žralobot | mořský × robot | shark | robot | crab | tracks | whale | antenna | voda |
| 17 | `sovomedved` | Sovomedvěd | ptačí × savec | owl | polar_bear | eagle | hare | fox | eagle | led |
| 18 | `sovodrak` | Sovodrak | ptačí × drak | owl | shadow_dragon | eagle | forest_dragon | ice_dragon | eagle | stín |
| 19 | `sovosaurus` | Sovosaurus | ptačí × dino | owl | stegosaurus | eagle | brontosaurus | swallow | ice_spikes | blesk |
| 20 | `vlkodrak` | Vlkodrak | savec × drak | wolf | dragon | gorilla | dragon | ice_dragon | bat | led |
| 21 | `jelenobot` | Jelenobot | savec × robot | deer | robot | gorilla | tracks | ninja_robot | bat | rostlina |
| 22 | `jelenobrouk` | Jelenobrouk | savec × hmyz | deer | beetle | gorilla | grasshopper | fox | butterfly | rostlina |
| 23 | `drakobot` | Drakobot | drak × robot | dragon | robot | dragon | tracks | metal | dragon | oheň |
| 24 | `drakosaurus` | Drakosaurus | drak × dino | dragon | stegosaurus | dragon | brontosaurus | ankylosaurus | dragon | oheň |
| 25 | `drakobotnice` | Drakobotnice | drak × mořský | dragon | octopus | dragon | crab | ice_dragon | shark_fin | stín |
| 26 | `robosaurus` | Robosaurus | robot × dino | robot | stegosaurus | drill | brontosaurus | ankylosaurus | antenna | kámen |
| 27 | `robobrouk` | Robobrouk | robot × hmyz | robot | beetle | drill | spider | scorpion | antenna | blesk |
| 28 | `robotucnak` | Robotučňák | robot × ptačí | robot | penguin | submarine | phoenix | ninja_robot | eagle | blesk |

Díly v tabulce jsou id karty bez předpony slotu (`trex` ve sloupci hlava = `head_trex`).
„Živel" je dominantní živel receptu (nejčastější, při shodě dřívější slot) – neukládá se, počítá se.

**Rozšíření později** (jen data + nové figurky, pravidla se nemění):
*zrcadlová vlna* +21 (každý kříženec obráceně: hlava z druhého rodu) → 49; *tajní mutanti* s vlastními
díly („Druhá hlava", „Šest rukou").

## 3. Pravidla v režimu sbírky

### 3.1 Kandidáti a přijetí karty
`kandidáti(silueta)` = mutanti, jejichž recept se shoduje se všemi položenými díly (slot se žolíkem se
neporovnává). Prázdná silueta → všech 28.

Hod karty:

| karta | přijme se, když | jinak |
|---|---|---|
| část | její slot je prázdný **a** aspoň jeden kandidát má v tom slotu právě tuhle kartu | odmítnutí |
| žolík (Mutace) | její slot je prázdný **a** na tvorovi jsou zatím méně než 2 žolíci | odmítnutí |
| pečeť | na trupu ještě žádná není (beze změny) | odmítnutí |
| Událost | nikdy (beze změny) | – |

Invariant po každém přijetí: množina kandidátů není prázdná.

### 3.2 Odmítnutí
Karta se vrátí **do ruky**, bez trestu (jako dnes odraz od obsazeného slotu). Důvod jde do eventu:
`slotOccupied` („Tohle místo už je obsazené"), `noFit` („Tenhle díl k němu nepasuje"), `sealTaken`,
`wildLimit`. Ruku čistí stávající pravidlo: při rozdávání do plné ruky si kotlík vezme nejstarší kartu,
která nepasuje. Přepínač `rejectToPot` (odmítnutá karta spadne do kotlíku) existuje jen pro simulaci.

Dva hody na stejný slot těsně po sobě: první platí, druhý je odmítnut. **Fúze se ruší.**
Synchro a štafeta zůstávají (týkají se času hodů, ne slotu).

### 3.3 Žolík (dřívější Mutace)
8 karet Mutací zůstává v balíčku se svými sloty, ale mění význam: žolík zastoupí **jakýkoli** díl svého
slotu. Nepřepisuje obsazený slot. Hotová figurka má na tom místě díl podle receptu; záznam si pamatuje,
že tam byl žolík (figurka dostane „slizový lesk"). Na raritu nemá vliv. Karty přejmenovat na
„Mutagen: hlava" atd. a pole `quirk` přestat zobrazovat.

### 3.4 Pečeť
Beze změny: razítko na trupu, neobsazuje slot, určuje živel tvora. Na figurce se projeví jako
živlová aura a barva podstavce (M6), tvar se nemění.

### 3.5 Události
Událost se vynoří jen tehdy, když ji **aspoň jeden kandidát může splnit** (nebo už splněná je);
jinak jde na dno kotlíku jako dnes, když jiná běží. Žolík splní jen podmínku „slot je obsazený"
(Zemětřesení), ne tag ani živel.

### 3.6 Líhnutí
- **Hotovo** (6 slotů): zbývá právě jeden kandidát → líhne se on.
- **Předčasně** (inkubátor na 0) s aspoň jedním dílem: vylíhne se náhodný z kandidátů (RNG ze stavu)
  jako **„nedopečený"**: rarita 0, figurka šedá jako nenabarvený odlitek, ve sbírce stav *viděný*,
  ne *získaný*. Je to ochutnávka, co šlo postavit.
- **Předčasně bez dílu**: prázdné vejce – event `EggEmpty`, žádný záznam, nové kolo.

Pahýly už neexistují.

### 3.7 Rarita
Rarita teď říká, **jak dobře se kousek povedl** (ve sbírce se drží nejlepší dosažená). Výchozí vzorec:

`tier mutanta (kříženec 0, prapředek 1) + 1 za ≥ 3 synchro hody + 1 za každou splněnou Událost`,
oříznuto na 0–5; předčasně = 0. Cíl ze simulace zůstává „vzácný+ ~30 %". Ladit prahy a `tier`,
nepřidávat nové mechaniky. Kódy důvodů: `tier`, `synchro`, `hazard`, `premature`.

### 3.8 Chytrý kotlík
Bez něj režim sbírky nefunguje: v dostavbě pasuje 1–4 karty z ~60 a náhodné rozdávání je nedodá
včas. Hrubý model mimo engine (2–4 boti, bez Událostí a synchra) dal bez nápovědy 40–90 % předčasných
líhnutí a medián 110–145 s na mutanta.

`fitDealBias` (0–1, výchozí **0,5**): když kotlík rozdává kartu, s touto pravděpodobností vytáhne
**nejvýš položenou část, která právě pasuje** (pokud v kotlíku nějaká je), jinak vrchní kartu jako dnes.
Události na vrchu se vynořují stejně jako dnes. Náhoda jde z RNG ve stavu. Tentýž hrubý model dává
pro 0,5 medián ~55–66 s a ~7–10 % předčasných; skutečnou hodnotu určí kalibrace v `sim` na cíle z §4.5.

### 3.9 Jméno
Jméno tvora = jméno mutanta ze sbírky. Přejmenování zůstává jako přezdívka jednoho kousku.
Tabulky prefix/kořen/sufix a římské číslice se v režimu sbírky nepoužívají.

## 4. `mutant_core`

Režim sbírky je přepínač `RulesConfig.closedCollection` (výchozí `true`). Volné skládání zůstává jako
`RulesConfig.free` (dnešní výchozí čísla) a `RulesConfig.v1` – kvůli stávajícím testům a porovnání
v simulaci. Až bude M2 hotový, volný režim smazat samostatným commitem.

### 4.1 Data a model
- `assets/collection.json` → `lib/src/model/collection.dart`: `MutantDef {id, name, origins, tier, parts}`,
  `MutantCollection` (`fromJsonString`, index karta → mutanti, `dominantElement`). Přidat do `flutter: assets`.
- Validace při načtení (chyba = `FormatException` se jménem mutanta): každá karta receptu existuje,
  je `part` a sedí slot; recepty jsou unikátní; **min. vzdálenost dvou receptů > `maxWildPerCreature`**;
  `origins` odpovídá dílům.
- `assets/moves.json` (už je v repu) → `lib/src/model/move_table.dart`: `MoveTable` (karta → `move`,
  `label`). Engine ho nepotřebuje; čte ho reveal v aplikaci a Blender skript (§6.2). Přidat do `flutter: assets`.
- `RulesConfig`: `closedCollection`, `fitDealBias = 0.5`, `maxWildPerCreature = 2`, `rejectToPot = false`.
- `SlotFill.wild`, `Silhouette.wildCount`.
- `CreatureRecord`: + `mutantId` (null u starých záznamů), + `wildSlots`; `parts` = položené karty;
  `stats` a `element` z receptu (živel přebíjí pečeť). Bestiář JSON `version` 1 → 2, v1 se dál načte.
- `MutantEngine(catalog, names, collection)`; balíček = karty jako dnes, části mimo recepty se vynechají.

### 4.2 Pravidla (čisté funkce)
- `rules/candidates.dart`: `candidatesOf(silhouette, defOf, collection)`, `neededParts(...)`
  (slot → karta, když zbývá jediný kandidát), `hazardSatisfiable(...)`.
- `rules/placement.dart`: větev pro režim sbírky podle §3.1; nové výsledky `rejectNoFit`, `rejectWildLimit`.
- `rules/rarity.dart`: `evaluateCollectionRarity` podle §3.7.
- `rules/hints.dart`: `fittingCards` podle nového pravidla (tím se samo opraví vracení karet do kotlíku
  i boti); `playersToCall` = hráči s pasující částí.
- `bestiary/`: `CollectionProgress` – pro každého mutanta stav `unknown | seen | owned`, počet kusů,
  nejlepší rarita, nasbírané živly, první datum a tvůrci.

### 4.3 Engine
- `_throw`: bez fúze a bez přepisu; odmítnutí → `CardBounced` s důvodem.
- `_drawOne`: `fitDealBias` podle §3.8.
- `_surfaceHazard`: jen splnitelné (§3.5).
- `_hatch`: určení mutanta podle §3.6, `EggEmpty`.
- Debug: `DebugHatchMutant(mutantId)` – naplní siluetu receptem a vylíhne (pro reveal a sbírku).

### 4.4 Testy
Nové soubory. Stávající testy běží dál ve volném režimu: `Harness` už používá `RulesConfig.v1`, testy
s výchozím `RulesConfig()` přepnout na `RulesConfig.free`.
- sbírka: 28 mutantů, vlastnosti 1–3 z §2, každá dvojice rodů právě jednou;
- kandidáti: zužování, žolík se neporovnává;
- přijetí/odmítnutí všech řádků tabulky §3.1, limit žolíků, druhý hod na stejný slot;
- líhnutí: jednoznačný mutant, se žolíky, předčasné (stejný seed → stejný mutant), prázdné vejce;
- Událost, kterou žádný kandidát nesplní, se nevynoří;
- kotlík: `fitDealBias = 1` vždy dá pasující část, když v kotlíku je; `0` se chová jako dřív;
- determinismus a replay v režimu sbírky; načtení bestiáře v1; `CollectionProgress`.

### 4.5 Simulace a kalibrace
`sim` navíc hlásí: podíl odmítnutých hodů, kandidáty po 1.–6. kartě, čas „co to bude" vs. „dostavba",
prázdná vejce, použité žolíky, **kolik různých mutantů se vylíhlo** a podíl nejčastějšího.
Nové klíče pro `--sweep`: `fit-bias`, `max-wild`, `reject`; `--rules free|v1` pro porovnání.

Cíle (2–5 hráčů, 400 mutantů, sezení po 5): medián **60–90 s** na mutanta, předčasně **< 25 %**,
vzácný+ **~30 %**, vylíhne se **všech 28**, žádný mutant nemá přes 10 % všech líhnutí.
Výsledek kalibrace zapsat do `mutant_core/README.md` stejnou tabulkou jako dnes.

## 5. `app`

Aplikace musí být **hratelná bez jediného obrázku** – každý vizuál má zástupce z Fáze 1.

### 5.1 Stůl
- `SilhouetteBoard`: sloty rozmístit pro **vzpřímenou postavu** (hlava nahoře, trup uprostřed, přední po
  straně, zadní dole, ocas vzadu dole, extra za ramenem). Dlaždice ukazuje obrázek karty
  (`assets/cards/<id>.webp`); když chybí, dnešní barevná dlaždice s textem.
- **„Kdo to bude?"**: pruh se stíny kandidátů. 28 → jen otazník; 2–4 → jejich siluety; 1 → velký stín
  za sloty a zvýrazněné chybějící sloty s názvem dílu („Chybí: Krabí klepeta").
- Odmítnutí: karta odskočí zpět do ruky, silueta se zatřese, hláška podle důvodu.
- Bez emoji (v iOS simulátoru se nevykreslí) – Material ikony.

### 5.2 Ruka
Karta, která právě pasuje, svítí; ostatní jsou ztlumené. Žolík má vlastní vzhled.

### 5.3 Reveal (nahrazuje `HatchOverlay`)
`ui/reveal/`. Hodiny hry stojí jako dnes. Sekvence, kdykoli přeskočitelná tapnutím:

1. **Sběr** (1,5 s) – šest karet ze siluety vletí do inkubátoru, záblesk.
2. **Sestava** (1,5 s) – figurka se složí z dílů (3D: klip `assemble`; 2D: díly karet se slétnou a
   prolnou do hero obrázku).
3. **Otočka** (2 s) – figurka na podstavci, jmenovka, rarita = barva podstavce, tvůrci.
4. **Předvedení** (~8 s) – po slotech hlava → extra: pohyb dílu + titulek z `moves.json`
   („Zařve", „Nafoukne břicho", …) + částice živlu.
5. **Volně** – tahem otáčet, tlačítka dílů přehrají pohyb znovu; „Přejmenovat", „Další mutant".

Nedopečený: šedá figurka (barevný filtr přes widget), krok 4 se přeskočí, text
„Nestihli jsme ho dopéct – zkuste ho postavit celého".

`FigureView(mutantId, look: painted|grey|shadow, controller)` je jediné místo, které ví, čím se figurka
kreslí: `StandeeFigure` (2D hero obrázek, pohyby = squash/poskok/naklonění obrázku), `ClipFigure`
(klipy z videomodelu, §6.5) a `GlbFigure` (3D, §6.1). Výběr podle toho, co je v `assets/figures/<id>/`:
`figure.glb`, jinak `clips/`, jinak jen `hero.webp`.

### 5.4 Sbírka (nahrazuje seznam bestiáře)
`ui/collection/`. Mřížka 28 polic: řada prapředků + kříženci po rodech. Stav: neznámý (černý stín
s otazníkem) / viděný (šedá figurka) / získaný (barevná, podstavec podle nejlepší rarity, počet kusů).
Počitadlo „12 / 28". Detail: figurka k otáčení, přehrání pohybů, seznam kusů (kdo, kdy, rarita,
přezdívka). Záznamy bez `mutantId` v oddílu „Staré pokusy" s dnešní textovou kartou.

### 5.5 Debug
„Vylíhni mutanta…" (výběr z 28, i nedopečeného), galerie všech karet a figurek pro kontrolu grafiky,
scénáře z Fáze 1 přepsat na recepty („Chybí jen ocas" = Žralomedvěd bez ocasu).

### 5.6 Grafika v repu
```
app/assets/cards/<card_id>.webp            512×512, průhledné pozadí
app/assets/figures/<mutant_id>/hero.webp   1024×1024, průhledné pozadí
app/assets/figures/<mutant_id>/shadow.webp silueta (generuje se z alfa kanálu hero)
app/assets/figures/<mutant_id>/clips/<klip>.mp4  varianta video, od M3b (§6.5)
app/assets/figures/<mutant_id>/figure.glb  varianta 3D, od M4
```
`Prompts/qwen/import_art.py`: vezme složku s výstupy Qwenu (názvy podle `out` v `batch.jsonl`),
odstraní pozadí (rembg), ořízne, zmenší, uloží webp a vyrobí `shadow.webp`. Skript vznikne v M2,
spouští ho člověk.

## 6. Figurka ve 3D

### 6.1 Kontrakt GLB
Aplikace nezná jednotlivé figurky, zná jen tenhle kontrakt (hlídá ho validátor):

- **Kloubová figurka z pevných dílů**, žádný skinning. Uzly: `Root > Torso > {Head, Front.L, Front.R,
  Back.L, Back.R, Tail, Extra}` (křídla `Extra.L` + `Extra.R`). Počátek každého uzlu je v kloubu.
- Klipy se jmény: `idle` (smyčka), `assemble`, `show_head`, `show_torso`, `show_front`, `show_back`,
  `show_tail`, `show_extra`, `cheer`.
- +Y nahoru, čelem k +Z, chodidla na y = 0, výška 1,0.
- Rozpočet: ≤ 25 000 trojúhelníků, 1 materiál, textura 1024², soubor ≤ 2 MB.

Proč pevné díly: figurka je navržená jako hračka s klouby (viz styl v promptech), takže řez v kloubu
je vidět schválně; pohyby jsou rotace dílů kolem kloubů a jdou **jednou** naanimovat a přenést na všech
28 figurek; „sestava" dílů je pak doslova animace `assemble`.

### 6.2 Pohybový slovník
Co figurka „umí", plyne z jejích dílů: každá část má pohyb (`assets/moves.json`). Klip `show_<slot>`
konkrétní figurky = pohyb dílu, který v tom slotu má.

| slot | pohyb | díly (titulek) |
|---|---|---|
| hlava | `roar` | trex („Zařve“), dragon („Zařve a zakouří“) |
| hlava | `howl` | wolf („Zavyje“) |
| hlava | `chomp` | shark („Cvakne zuby“), spider („Cvakne kusadly“) |
| hlava | `headspin` | owl („Otočí hlavu dokola“) |
| hlava | `headbutt` | triceratops („Trkne rohy“), deer („Trkne parohy“) |
| hlava | `scan` | fly („Zakoulí očima“), robot („Zabliká očima“) |
| trup | `hide` | turtle („Schová se do krunýře“), beetle („Schová se do krovek“), robot („Zaklapne pancíř“) |
| trup | `puff` | polar_bear („Nafoukne břicho“), stegosaurus („Naježí pláty“), dragon („Rozžhaví hruď“), shadow_dragon („Rozsvítí břicho“) |
| trup | `wobble` | penguin („Zakolébá se“), parrot („Načepýří se“), octopus („Zavlní se“) |
| přední | `snap` | crab („Cvakne klepety“), submarine („Cvakne chapadly“) |
| přední | `slash` | mantis („Sekne pařátky“), trex („Zamává ručičkami“), eagle („Sekne pařáty“), dragon („Sekne drápy“), raptor („Sekne drápy“) |
| přední | `drill` | drill („Roztočí vrtáky“) |
| přední | `clap` | walrus („Zatleská ploutvemi“) |
| přední | `pound` | gorilla („Zabuší do hrudi“) |
| zadní | `hop` | grasshopper („Vyskočí do výšky“), hare („Vyskočí do výšky“), phoenix („Poskočí v plamenech“) |
| zadní | `stomp` | brontosaurus („Zadupe“), dragon („Zadupe“), forest_dragon („Zadupe“) |
| zadní | `roll` | tracks („Projede se na pásech“) |
| zadní | `scuttle` | crab („Zacupitá bokem“), heron („Přešlápne na dlouhých nohách“), spider („Zacupitá“) |
| ocas | `whip` | metal („Švihne ocasem“), ice_dragon („Švihne ocasem“), ninja_robot („Švihne ocasem“) |
| ocas | `sting` | scorpion („Bodne žihadlem“) |
| ocas | `smash` | ankylosaurus („Bouchne palicí“) |
| ocas | `fan` | peacock („Rozevře vějíř“) |
| ocas | `wag` | fox („Zavrtí ohonem“), swallow („Zavrtí ocáskem“) |
| ocas | `splash` | fish („Plácne ploutví“), whale („Plácne ploutví“) |
| extra | `hover` | dragonfly („Vznese se“), butterfly („Vznese se“) |
| extra | `flap` | bat („Zamává křídly“), dragon („Zamává křídly“), eagle („Zamává křídly“), pterodactyl („Zamává křídly“) |
| extra | `charge` | rhino („Vyrazí rohem napřed“) |
| extra | `slice` | shark_fin („Zakrouží ploutví“) |
| extra | `beam` | antenna („Vyšle signál“) |
| extra | `bristle` | ice_spikes („Naježí ostny“) |

M4 stačí 6 základních pohybů (jeden na slot: `roar`, `puff`, `slash`, `hop`, `whip`, `flap`) + `idle`,
`assemble`, `cheer`; chybějící pohyb spadne na základní pohyb svého slotu. Zbytek v M5.

### 6.3 Výroba jedné figurky
| krok | kdo | čím |
|---|---|---|
| 1. hero obrázek + pohledy zepředu/zezadu/z boku | člověk | Qwen-Image, Qwen-Image-Edit (`02-QWEN_IMAGE_PROMPTS.md`) |
| 2. obrázek → 3D síť s texturou | člověk | image→3D dle výběru (např. Hunyuan3D, Tripo) |
| 3. rozdělení na díly v kloubech, počátky do kloubů, jména uzlů | člověk | segmentace dílů v nástroji nebo ručně v Blenderu |
| 4. normalizace, decimace, zapečení klipů, export | skript | `tools/blender/build_figure.py` |
| 5. kontrola kontraktu | skript | `tools/validate_glb` |

`tools/blender/build_figure.py` napíše Opus: načte rozdělenou figurku, srovná měřítko a osy, zdecimuje
na rozpočet, podle `collection.json` + `moves.json` vybere pro každý slot akci ze sdílené knihovny
`tools/blender/figure_actions.blend` (akce jsou rotace kolem kloubů → přenositelné mezi figurkami),
zapeče je jako klipy a vyexportuje GLB. Knihovnu akcí v Blenderu animuje člověk; skript k ní vytvoří
prázdnou kostru se správnými jmény uzlů a akcí.

### 6.4 Vykreslení ve Flutteru (spike v M4)
Protože jsou klipy zapečené v GLB, stačí renderer, který umí: načíst GLB z assetů, přehrát klip podle
jména, průhledné pozadí nad Flutter UI, otáčení tahem. Platformy: iOS, Android, macOS.

Vyzkoušet na pilotní figurce v tomto pořadí a změřit start, fps, paměť a přírůstek velikosti aplikace:
1. **Thermion** (Filament) – přehrává glTF animace, iOS/Android/macOS.
2. **flutter_scene** (Flutter GPU / Impeller) – čistý Dart, mladší projekt.
3. **flutter_3d_controller** (model-viewer ve WebView) – nejjednodušší, macOS v betě.
4. Nouzově předrenderované sekvence z Blenderu (bez otáčení tahem).

Stav balíčků ověřit na pub.dev v den implementace. Rozhodnutí a čísla zapsat do `app/README.md`.
`GlbFigure` schovat za `FigureView`, aby šel renderer vyměnit.

### 6.5 Varianta: video figurka
Pohyby figurky jde místo 3D vyrobit videomodelem přímo z hero obrázku. Prompty pro Wan a LTX a postup,
jak jejich animace porovnat, jsou v [`03-WAN_LTX_ANIMACE.md`](03-WAN_LTX_ANIMACE.md).

Kontrakt klipů:
- `app/assets/figures/<id>/clips/<klip>.mp4`, jména klipů stejná jako v §6.1 (`idle`, `assemble`,
  `show_<slot>`, `cheer`); čtverec 512–768 px, H.264, bez zvukové stopy. Zvuk volitelně zvlášť jako
  `<klip>.m4a`.
- Každý klip kromě `assemble` začíná i končí stejným snímkem (hero obrázek) → klipy jdou řadit:
  `idle` ve smyčce, na povel `show_*`, zpět `idle`.
- Rozpočet ≤ 300 kB na klip (28 × 9 = 252 klipů ≈ 75 MB).

`ClipFigure` přehrává klipy přes `video_player` v kulatém „okně inkubátoru" s měkkým okrajem, takže
průhlednost není potřeba. Klip se střídá vždy na své hranici a následující je přednačtený, aby přechod
neblikl. Vzhled `grey` = `ColorFiltered` přes video. Varianta s průhledností (snímky bez pozadí jako
animovaný WebP dekódovaný přes `ui.Codec`) jen když pilot ukáže, že okno nestačí.

`Prompts/video/pack_clips.py` (vznikne v M3b, spouští člověk): vezme výstupy pojmenované podle `out`
v `batch_*.jsonl`, zmenší a překóduje je (ffmpeg), oddělí zvuk a ohlásí klipy, které neprojdou –
příliš velký rozdíl prvního a posledního snímku, pohyb okrajů obrazu (kamera), překročený rozpočet.

| | video (Wan / LTX) | 3D (GLB) |
|---|---|---|
| práce na figurku | 9 klipů: strojový čas + výběr ze seedů | obrázek → 3D, řezání na díly, export – hlavně ruční práce |
| otáčení tahem | ne, jeden úhel | ano |
| pohyb | měkký a „živý"; kvalita kolísá podle seedu | přesný, u všech figurek stejný |
| sestava z dílů | klip z rozloženého pohledu, výsledek nejistý | animace `assemble` |
| zvuk | LTX ho vyrobí s klipem | zvlášť |
| velikost sbírky | ~75 MB | ~56 MB |
| hlavní riziko | tvary během klipu „tečou", klipy téže figurky se liší | pracnost a kvalita sítí |

## 7. Milníky

Každý milník = samostatný commit(y), zelené `dart test`, `dart analyze`, `flutter test`.

**M1 – Sbírka v enginu** (`mutant_core`)
- [ ] model + validace sbírky, `MoveTable`
- [ ] pravidla §3.1–3.7, engine §4.3, testy §4.4
- [ ] chytrý kotlík, sim metriky, kalibrace na cíle §4.5, README
- Hotovo, když: cíle §4.5 platí pro 2–5 hráčů a staré testy běží beze změny chování.

**M2 – Hra se sbírkou ve 2D** (`app`, bez nové grafiky)
- [ ] stůl: vzpřímená silueta, „Kdo to bude?", odmítnutí, svítící karty v ruce
- [ ] reveal se `StandeeFigure` (bez obrázku = jmenovka + barevný stín), sbírka 28 polic
- [ ] debug: vylíhni mutanta, galerie; `import_art.py`
- Hotovo, když: partie s boty (`MUTANT_DEMO`) doběhne k revealu a zaplní sbírku; widget testy pro
  odmítnutí, kandidáty a stavy sbírky.

**M3 – Grafika 2D** (člověk generuje, Opus zapojuje)
- [ ] pilot 3 figurky + zmrazení stylu, 60 karet, 28 hero obrázků
- [ ] import, stíny, kontrola v galerii
- Hotovo, když: každá karta a každý mutant má obrázek a hra nikde neukazuje zástupnou dlaždici.

**M3b – Video pilot** (člověk generuje a boduje, Opus zapojuje)
- [ ] 2 figurky × 8 klipů ve Wan i LTX podle `03-WAN_LTX_ANIMACE.md`, vyplněný `Prompts/video/srovnani.csv`
- [ ] `pack_clips.py`, `ClipFigure`
- Hotovo, když: je vybraná konfigurace se změřenou cenou použitelného klipu a obě pilotní figurky
  předvádějí pohyby v revealu z klipů.

**M4 – 3D pilot** (rozhodovací bod)
- [ ] 2 figurky celou cestou §6.3 (`zralomedved`, `drakobot`)
- [ ] `build_figure.py`, `validate_glb`, 6 základních pohybů
- [ ] spike rendererů §6.4, `GlbFigure`
- Hotovo, když: obě figurky běží v revealu na iOS, Androidu i macOS a je změřeno, kolik práce stojí
  jedna figurka. **Tady se rozhodne** mezi videem (M3b) a 3D: zůstat u klipů, převést všech 28 do 3D,
  nebo dát 3D jen vybraným figurkám.

**M5 – Výroba pohybů** podle rozhodnutí z M4 – figurky po vlnách (rod po rodu), celý pohybový slovník,
částice živlů.

**M6 – Dotažení** – aura pečeti a slizový lesk žolíka, zvuky pohybů, obrázek/video figurky ke sdílení.

Fáze 3 (síť) a 4 (expedice) z původního plánu se nemění a jdou až potom.

## 8. Rozhodnutí k potvrzení

Plán s nimi počítá takhle; změna kteréhokoli je levná před M1, drahá po M3.

1. **28 mutantů = každý rod s každým.** Víc figurek = víc 3D práce; méně by znamenalo vyřadit karty z balíčku.
2. **Mutace je žolík**, ne díl s vlastním tvarem. Jinak by každá potřebovala vlastní figurky.
3. **Odmítnutá karta se vrací do ruky** bez trestu.
4. **Předčasné líhnutí dá šedou „nedopečenou" figurku**, která se nepočítá jako získaná.
5. **Figurky stojí vzpřímeně** (dvounohý postoj) – lépe vyplní displej na výšku.
6. **Kloubová figurka z pevných dílů** místo měkkého riggingu.
7. **Jména mutantů** v `collection.json`.
8. **Pohyby videem, nebo ve 3D** – neřeší se teď; rozhodnou piloty M3b a M4.

## 9. Pracovní pravidla pro implementaci

- Engine zůstává čistý Dart bez hodin a bez `dart:math` Random; každá náhoda z `Rng` ve stavu.
- Žádné generování obrázků ani 3D – to dělá člověk podle `02-QWEN_IMAGE_PROMPTS.md`. Kde grafika
  chybí, musí fungovat zástupce.
- `collection.json`, `moves.json` a `Prompts/qwen/bible.json` jsou data: měnit je jen s důvodem a po
  změně receptů spustit `python3 Prompts/qwen/build_prompts.py`.
- M3b a dál nezačínat bez výslovného pokynu.
- Po každém milníku aktualizovat `README.md`, `mutant_core/README.md`, `app/README.md` a odškrtnout
  položky tady.
