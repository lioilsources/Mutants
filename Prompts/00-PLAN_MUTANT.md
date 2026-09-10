# PLAN.md — Coop skládací hra (pracovní název: **Mutant**)

## 1. Cíl
Kooperativní mobilní karetní hra pro děti. Hráči zároveň házejí karty s částmi zvířat do kotlíku
uprostřed, ze kterého roste nový tvor (mutant). Rychlost a spolupráce = hezčí a vzácnější mutant.
Hotový mutant se ukládá do **bestiáře**. Lokální multiplayer přes MultipeerConnectivity, lobby.

Sdílí technický základ s hrou Fuse (viz PLAN Fuse) → společný package `cardkit`.

Paper-doll vizuál mutanta je **fáze 2**; fáze 1 běží s placeholder siluetou a textovými částmi.

---

## 2. Pravidla v1

**Setup**
- 1–5 hráčů (1 hráč = sólo s botem "kamarád"). 5 karet do ruky.
- Uprostřed silueta se sloty: `hlava`, `trup`, `přední`, `zadní`, `ocas`, `extra` (křídla/rohy/ploutev).
- Kotlík = deck; z něj se dobírá a z něj se samy vynořují Události.

**Inkubátor** (společný ukazatel 0–100, start 60)
- Klesá konstantně (`drainPerSec`, start 4/s, každý vylíhnutý mutant +0,5/s).
- Platný hod do slotu: +10. Synchro (dva hráči v okně 80 ms): +25.
- Chycení předané karty: +5. Štafeta (chycená karta hozena do slotu ≤ 1 s): počítá se jako synchro.
- Nesplněná Událost: −25 skokem.
- Na 0 → **předčasné líhnutí**: mutant vznikne z obsazených slotů, prázdné = pahýly, rarita −1.

**Hod části**
- Swipe nahoru na siluetu → karta sama najde svůj slot (slot je dán kartou). Obsazený slot → karta
  se odrazí zpět (bez trestu), pokud nejde o Mutaci.
- Slot plný všech 6 → **líhnutí**, zápis do bestiáře, nová silueta, inkubátor reset na 60.

**Předání**
- Swipe do strany na avatar. Příjemce chytá tapem ≤ 2 s, jinak karta spadne do kotlíku.
- Hra rozsvítí avatar hráče, který má kartu pasující do volného slotu (nápověda "zavolej si").
- Max 1 předání na hráče za `passCooldown` = 4 s.

**Konflikt o slot**
- Dva hody na stejný slot: host timestamp rozhodne, druhý se odrazí.
- Oba v synchro okně → **Fúze**: slot obsadí dvojitá část (dvě hlavy…), rarita +1.

**Události** (vynoří se z kotlíku, 5 s fuse)
- *Bouře* → potřebuje `extra` = křídla; *Zemětřesení* → `zadní`; *Hlad* → `hlava` s vlastností tesáky;
  *Záplava* → jakoukoli vodní část; *Tma* → jakoukoli stínovou část.
- Splněno = rarita +1, inkubátor +15. Nesplněno = inkubátor −25.

**Konec partie**
- Režim *Volná hra*: hraje se, dokud děti chtějí; každý mutant do bestiáře.
- Režim *Expedice*: 5 mutantů se zadáním tématu (viz §7), na konci "expediční deník".
- Nikdo neprohrává. Jediný "špatný" výsledek je ošklivý mutant – a ten je taky zábavný.

---

## 3. Deck v1 (80 karet)

**Osy**
- Slot: hlava / trup / přední / zadní / ocas / extra
- Element: oheň, voda, led, blesk, rostlina, kámen, stín (7)
- Původ: dino, hmyz, mořský, ptačí, savec, drak, robot (7)
- Vlastnosti (tagy pro Události/bonusy): tesáky, drápy, křídla, ploutve, krunýř, rohy, oči-navíc

**Části (60)** — 10 na slot, mix elementů a původů tak, aby každý element měl ≥ 8 karet a každý původ ≥ 8
- příklad: *Hlava T-rexe* (hlava, oheň, dino, tesáky), *Křídla vážky* (extra, blesk, hmyz, křídla),
  *Krabí klepeta* (přední, voda, mořský, drápy), *Kovový ocas* (ocas, blesk, robot)

**Mutace (8)** — jde hodit na obsazený slot; přepíše ho a přidá zvláštnost (druhá hlava, ocas na hlavě,
oči navíc). Rarita +1. Nutí házet i pozdě ve fázi skládání.

**Elementární pečeť (6)** — na `trup`; celý mutant dostane element pečeti bez ohledu na části.

**Události (6)** — viz §2. Nejsou v ruce, jen v kotlíku.

Data: `assets/cards.json` – jedna definice pro engine i UI. Ilustrace fáze 2.

---

## 4. Skládání mutanta (výstup engine, vizuál fáze 2)

**Rarita** (0–5): běžný / neobvyklý / vzácný / epický / legendární / mýtický
- +1 za každé 3 různé původy (chaos) *nebo* +2 za jednotný element všech částí (soulad)
- +1 Fúze, +1 Mutace, +1 každá splněná Událost, +1 ≥ 3 synchro hody
- −1 předčasné líhnutí, −1 za každé 2 pahýly

**Statistiky**: síla/rychlost/obrana = součet částí; element ovlivňuje "schopnost" (text z tabulky).
V1 jen zobrazujeme; boj není v plánu.

**Jméno**: `prefix[dominantní element] + kořen[původ hlavy] + sufix[původ trupu]`
→ *Pyro-Rexo-dračák*. Tabulky v `assets/names.json`, dětsky přejmenovatelné.

**Bestiář záznam**: id, seed, seznam částí (karta id per slot), element, rarita, statistiky, jméno,
tvůrci (playerId + jméno + avatar), datum, expedice (pokud). Vizuál se **renderuje ze seznamu částí**
(fáze 2), neukládá se obrázek → bestiář je malý a přenosný.
Sdílení: po líhnutí host pošle záznam všem klientům; každý si ho uloží lokálně.

---

## 5. Technologie a architektura

- Flutter, widget tree. Herní logika v čistém Dartu.
- **`cardkit`** (sdílené s Fuse): `Transport` (Loopback / MPC / LatencyInjector), `HostSession`,
  `ClientSession`, `GameClock`, timestampy + remízové okno, replay log, puppet mode, DebugPanel kostra,
  lobby UI. Vytáhnout z Fuse až ve chvíli, kdy je Fuse fáze 1 hotová – nekopírovat dřív.
- **`mutant_core`**: model karet, sloty, inkubátor, události, rarita, jména, bestiář schema, boti.
- Bestiář: lokálně `sqlite` (drift) nebo JSON soubor; v1 JSON.

```
mutant_core/
  model/     Card(slot, element, origin, tags), Slots, Creature, Incubator, Event
  rules/     Placement, Fusion, PassCatch, EventCheck, Rarity, Naming
  engine/    apply(Command) -> (State, [Event])
  bots/      KidBot(reactionMs, catchRate, passRate, mistakeRate)
  bestiary/  schema + serializace
app/
  ui/table    silueta se sloty, kotlík, inkubátor bar, avatary
  ui/hand     vějíř, swipe-to-slot, swipe-to-pass, catch tap
  ui/hatch    animace líhnutí + karta mutanta + přejmenování
  ui/bestiary seznam, detail, filtr podle elementu/rarity
  ui/expedition
```

**Principy** shodné s Fuse: host autoritativní, inkubátor a fuse Událostí tikají na hostu, klient
odhaduje a animuje optimisticky; deterministický seed + log commandů.

---

## 6. Testovací flow — hraju sám za víc hráčů

### 6.1 Unit + CLI simulace
- Testy: obsazení slotu, odraz, fúze v okně, mutace přepíše, pečeť přebije element, předání timeout,
  štafeta = synchro, každá událost, každé pravidlo rarity, generování jmen bez kolizí.
- `dart run mutant_core:sim --players 3 --creatures 200 --seed 1`
  → rozložení rarit, % předčasných líhnutí, průměrná doba na mutanta, kolik událostí se stíhá.
  Cíl v1: medián 60–90 s na mutanta, předčasně < 25 %, rarita "vzácný+" ~ 30 %.

### 6.2 Puppet mode na jednom telefonu (Loopback)
- Přepínač pohledu mezi hráči, `auto-follow` na hráče, který má na ruce nejvíc pasujících karet.
- Boti `KidBot` s profily: *Zbrklý* (rychlý, 30 % chyb, nechytá), *Opatrný* (pomalý, chytá vždy),
  *Předávač* (přednostně posílá karty ostatním). Kombinace profilů = hlavní test coop dynamiky.
- DebugPanel navíc k základu z cardkit:
  - `drainPerSec` slider, inkubátor set/freeze
  - vnutit Událost s vybraným fuse
  - vnutit kartu do ruky libovolného hráče
  - "simuluj předání" mezi dvěma boty (ověřit chycení/timeout animace)
  - vynutit fúzi (dva hody do okna) jedním tlačítkem
  - `hatch now` → okamžité líhnutí pro test bestiáře a jmen
- Scénáře: "plný mutant chybí ocas, inkubátor 5", "Bouře, nikdo nemá křídla, jen bot 2",
  "dvě hlavy na ruce → fúze", "expedice krok 5 z 5".

### 6.3 Více instancí
- Stejně jako Fuse: simulátory + fyzické zařízení, LatencyInjector 0–300 ms.
- Specificky ověřit: předání pod latencí (kdy se zobrazí "chyť to" a kdy vyprší), bestiář dorazí
  všem klientům, klient odpojen během líhnutí → záznam dostane při reconnectu.

### 6.4 Test s dětmi (ruční)
- Od fáze 1 konec: 2 zařízení, já + dítě. Sleduju: rozumí "chyť to"? volá si o karty? co dělá,
  když kotlík vyplivne Událost? Zápisník pozorování do `playtests/`.

---

## 7. Expedice (v1 jednoduché)
- Seznam témat v `assets/expeditions.json`: název, 5 zadání, každé = podmínka (element / původ /
  rarita ≥ / tag), např. *Ledová jeskyně*: 2× ledový, 1× s krunýřem, 1× vzácný+, 1× libovolný.
- Splnění zadání → razítko do expedičního deníku. Nesplnění → mutant se stejně uloží, razítko ne.
- Žádný fail state.

---

## 8. Fáze

**Fáze 0 – core**
- [x] cards.json + názvosloví, model, engine, pravidla v1, testy
- [x] rarita + jména
- [x] KidBot profily, CLI sim, kalibrace `drainPerSec`

**Fáze 1 – feel, placeholder vizuál**
- [ ] silueta se sloty (barevné obdélníky + text), inkubátor bar, kotlík
- [ ] swipe-to-slot, swipe-to-pass, catch tap, fúze animace (placeholder)
- [ ] líhnutí → karta mutanta (text) → bestiář JSON
- [ ] puppet mode + DebugPanel + scénáře (přes cardkit)
- ✅ Výstup: drain rychlost, okno chycení, zda cooldown předání sedí, první test s dítětem

**Fáze 2 – paper-doll a vizuál** (samostatný plán)
- [ ] kotevní body per slot, vrstvení, element overlay
- [ ] asset pipeline (ComfyUI) pro 60 částí v jednotném stylu
- [ ] animace líhnutí, karta mutanta jako obrázek ke sdílení

**Fáze 3 – síť** (z cardkit, stejně jako Fuse) + sdílení bestiáře

**Fáze 4 – expedice, zvuky, onboarding**

---

## 9. Otevřené otázky
- 1 hráč sólo: bot "kamarád" viditelný jako postava, nebo jen tišší drain?
- Má Mutace umět i "vymazat" slot (návrat k pahýlu) pro záměrně bizarní tvory?
- Předání: 1 karta, nebo lze poslat i 2 najednou pro starší děti?
- Bestiář: jen lokální, nebo i export/sdílení obrázkem mimo hru (fáze 2)?
- Hrací délka Expedice – 5 mutantů ≈ 6–8 min; je to pro cílový věk (6–10?) správně?
