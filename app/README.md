# mutant (aplikace)

Fáze 1 hry Mutant: prototyp pocitu ze hry na jednom telefonu, se zástupnou grafikou.
Herní logika je v `../mutant_core`, aplikace ji jen zobrazuje a ovládá.

```bash
flutter pub get
flutter test
flutter run                                                              # nastavení → stůl
flutter run --dart-define=MUTANT_DEMO=true --dart-define=MUTANT_SPEED=3  # hrají jen boti
flutter run --dart-define=MUTANT_SCREEN=debug                            # stůl s DebugPanelem
flutter run --dart-define=MUTANT_SCREEN=bestiary                         # rovnou bestiář
```

## Jak se hraje

- Dole je ruka hráče, jehož avatar má bílý kruh. Tapnutím na jiný avatar přepneš pohled
  (puppet mode). Oko v horní liště zapne sledování hráče, který má co hodit.
- Přetáhni kartu na tvora a karta sama najde své místo; stačí i rychlý švih nahoru.
  Přetažením na avatar kartu předáš.
- Příchozí karta se objeví vpravo nad rukou s odpočtem – tapni na „Chyť!".
- Zářící avatar znamená, že ten hráč drží kartu na volné místo (zavolej si o ni).
- Vylíhnutý mutant zastaví hodiny, ukáže svou kartu a uloží se do bestiáře
  (`bestiary.json` v dokumentech aplikace). Jde přejmenovat.

## Struktura

| | |
|---|---|
| `lib/host/` | `GameHost` – lokální host: hodiny, boti, log commandů, pauza. Ve Fázi 3 se rozdělí na host a klienta za `Transport` (`cardkit`). |
| `lib/ui/table/` | silueta se sloty, inkubátor, Událost, kotlík, avatary, hlášky |
| `lib/ui/hand/` | vějíř karet, přetahování, chytání |
| `lib/ui/hatch/` | karta mutanta, přejmenování |
| `lib/ui/bestiary/` | seznam, filtr podle elementu a rarity, detail |
| `lib/debug/` | DebugPanel a scénáře z plánu §6.2 |
| `lib/services/` | načtení karet z `mutant_core` (assety balíčku), úložiště bestiáře |

## DebugPanel

Rychlost hodin a pauza; hladina, zmrazení a drain inkubátoru; režim každého hráče (člověk,
Zbrklý, Opatrný, Předávač, pauza); vnucení Události se zvolenou zápalkou; vnucení karty;
simulace předání; vynucení fúze; okamžité líhnutí; scénáře a posledních 25 událostí.

Scénáře: *Chybí jen ocas*, *Bouře, křídla má jen Chobotnice*, *Dvě hlavy, fúze*.
Scénář „expedice krok 5 z 5" čeká na expedice (Fáze 4).

## Zatím chybí

- Animace jsou základní: dosednutí karty do slotu, fúzovaný slot ve dvou barvách, žádný let karty.
- Haptika a zvuky.
- Výstup Fáze 1: ladění na skutečném hraní a první test s dítětem.

Písmo: Fredoka (SIL OFL 1.1, `assets/fonts/OFL.txt`).
