# mutant (aplikace)

Fáze 1 hry Mutant: prototyp pocitu ze hry na jednom telefonu. Od milníku M2
(`../Prompts/01-PLAN_KOLEKCE.md`) se hraje **uzavřená sbírka 28 mutantů**: stůl ukazuje, kdo z toho
bude, vylíhnutý mutant se předvede v revealu a uloží na polici ve sbírce. Herní logika je v
`../mutant_core`, aplikace ji jen zobrazuje a ovládá. Hra jde hrát bez jediného obrázku – kde
grafika chybí, kreslí se zástupce.

```bash
flutter pub get
flutter test
flutter run                                                              # nastavení → stůl
flutter run --dart-define=MUTANT_DEMO=true --dart-define=MUTANT_SPEED=3  # hrají jen boti
flutter run --dart-define=MUTANT_SCREEN=debug                            # stůl s DebugPanelem
flutter run --dart-define=MUTANT_SCREEN=collection                       # rovnou sbírka
flutter run --dart-define=MUTANT_SCREEN=gallery                          # galerie karet a figurek
```

## Jak se hraje

- Dole je ruka hráče, jehož avatar má bílý kruh. Tapnutím na jiný avatar přepneš pohled
  (puppet mode). Oko v horní liště zapne sledování hráče, který má co hodit.
- Přetáhni kartu na tvora a karta sama najde své místo; stačí i rychlý švih nahoru.
  Přetažením na avatar kartu předáš.
- Příchozí karta se objeví vpravo nad rukou s odpočtem – tapni na „Chyť!".
- Zářící avatar znamená, že ten hráč drží díl, který tvor potřebuje (zavolej si o ni).
  Karty, které právě pasují, svítí; ostatní jsou ztlumené. Mutagen (žolík) je slizově zelený.
- Díl, který k žádnému možnému mutantovi nepasuje, se vrátí do ruky a silueta se zatřese.
- Pruh „Kdo to bude?" ukazuje otazník, pak stíny 2–4 možných mutantů. Když zbývá jeden,
  jeho stín je za sloty a prázdné sloty píšou, který díl chybí.
- Vylíhnutý mutant zastaví hodiny a předvede se (reveal): karty vletí do inkubátoru, figurka se
  složí, otočí na podstavci (barva = rarita) a předvede pohyb každého dílu. Ťuknutí přeskočí krok.
  Na konci jde figurku otáčet tahem, přehrát pohyby, dát přezdívku.
- Nedopečený mutant (inkubátor vychladl) je šedý a ve sbírce jen *viděný*.
- Sbírka (`bestiary.json` v dokumentech aplikace, schema 2) má 28 polic: neznámý / viděný /
  získaný, počitadlo „12 / 28". Záznamy z volného skládání jsou v oddílu „Staré pokusy".
- V nastavení jde přepnout na volné skládání (Fáze 1) nebo pravidla plánu v1.

## Struktura

| | |
|---|---|
| `lib/host/` | `GameHost` – lokální host: hodiny, boti, log commandů, pauza. Ve Fázi 3 se rozdělí na host a klienta za `Transport` (`cardkit`). |
| `lib/ui/table/` | silueta se sloty, inkubátor, Událost, kotlík, avatary, hlášky |
| `lib/ui/hand/` | vějíř karet, přetahování, chytání |
| `lib/ui/figure/` | `FigureView` – jediné místo, které ví, čím se figurka kreslí (`StandeeFigure`: hero obrázek, nebo zástupná kloubová hračka z barev dílů); vzhledy barevný / šedý / stín |
| `lib/ui/reveal/` | reveal vylíhnutého mutanta, podstavec podle rarity |
| `lib/ui/collection/` | sbírka 28 polic, detail police |
| `lib/ui/hatch/` | karta mutanta (volný režim, staré pokusy), přejmenování |
| `lib/ui/bestiary/` | seznam pro volný režim |
| `lib/debug/` | DebugPanel a scénáře z plánu §6.2 |
| `lib/services/` | načtení karet, sbírky a pohybů z `mutant_core` (assety balíčku), `ArtIndex` (která grafika je v balíčku), úložiště bestiáře |

## DebugPanel

Rychlost hodin a pauza; hladina, zmrazení a drain inkubátoru; režim každého hráče (člověk,
Zbrklý, Opatrný, Předávač, pauza); vnucení Události se zvolenou zápalkou; vnucení karty;
simulace předání; vynucení fúze (jen volný režim); okamžité líhnutí; **Vylíhni mutanta…**
(kteréhokoli z 28, i nedopečeného); **galerie** všech karet a figurek ve všech vzhledech
s počtem hotových obrázků; scénáře a posledních 25 událostí.

Scénáře sbírky: *Chybí jen ocas* (Žralomedvěd), *Kdo to bude? Čtyři žraloci*, *Bouře, křídla má
jen Chobotnice*, *Žolíci*. Volný režim: *Chybí jen ocas (volně)*, *Dvě hlavy, fúze*.

## Grafika

`assets/cards/<card_id>.webp` (512², průhledné), `assets/figures/<mutant_id>/hero.webp` (1024²)
a `shadow.webp`. Plní je `python3 Prompts/qwen/import_art.py <složka s výstupy Qwenu>` z kořene
repa; skript odstraní pozadí, ořízne, uloží webp a doplní adresáře do `pubspec.yaml`.
Co chybí, nahradí zástupce – stav ukazuje galerie v DebugPanelu.
Scénář „expedice krok 5 z 5" čeká na expedice (Fáze 4).

## Zatím chybí

- Animace jsou základní: dosednutí karty do slotu, žádný let karty; pohyby figurky jsou zatím
  posuny a natažení 2D obrázku (video M3b, 3D M4).
- Haptika a zvuky.
- Výstup Fáze 1: ladění na skutečném hraní a první test s dítětem.

Písmo: Fredoka (SIL OFL 1.1, `assets/fonts/OFL.txt`).
