# Prompty pro Wan a LTX — animace figurek a jejich srovnání

> Generováno skriptem `Prompts/video/build_video_prompts.py` ze sbírky, `moves.json` a
> `Prompts/video/motion.json`. **Needituj ručně** – uprav `motion.json` a spusť skript znovu.
> Prompty pro všech 28 figurek × 9 klipů jsou v `Prompts/video/batch_wan.jsonl` a `batch_ltx.jsonl`.

## 0. Co to řeší

Figurku jde rozpohybovat i bez 3D: videomodel dostane hotový hero obrázek (z
[`02-QWEN_IMAGE_PROMPTS.md`](02-QWEN_IMAGE_PROMPTS.md)) a udělá z něj krátký klip, ve kterém figurka
předvede pohyb jednoho svého dílu. Tenhle dokument dává stejné zadání dvěma modelům – **Wan** a **LTX** –
a v §6 popisuje, jak jejich animace férově porovnat. Klipy se jmenují stejně jako klipy 3D figurky
(`idle`, `assemble`, `show_<slot>`, `cheer`), takže hra může hrát video i GLB stejným kódem
(viz [`01-PLAN_KOLEKCE.md`](01-PLAN_KOLEKCE.md) §6.5).

Žádný klip jsem negeneroval. Čísla nastavení jsou z oficiálních repozitářů a dokumentace; která
animace vyjde líp, ukáže až pilot z §6. Očekávání v §6.4 jsou hypotézy k ověření, ne výsledky.

**Které verze.** Poslední Wan s otevřenými vahami je **Wan 2.2** (Apache 2.0); novější řady jsou podle
dostupných zpráv jen přes API. U LTX uvádí repozitář Lightricks jako aktuální **LTX-2.5** (váhy pod
licencí „LTX-2.x Community License" – před vydáním hry si ji přečti, není to Apache).

## 1. Vstupní obrázky

- **Hero obrázek figurky** zmenšený na čtverec 768×768, na jednolitém šedém pozadí.
- **První i poslední snímek klipu = tentýž hero obrázek.** Oba modely umí podmínit začátek i konec.
  Figurka se tak vždy vrátí do výchozí pózy a klipy jdou řadit za sebe bez cuknutí
  (klid → pohyb → klid).
- **`assemble`** je výjimka: první snímek je rozložený pohled (`exploded.png`, úprava E7 v dokumentu
  pro Qwen), poslední je hero. Díly se slétnou do figurky.
- Jeden klip = **jeden pohyb**. Oficiální návod LTX výslovně říká, že víc akcí v promptu znamená,
  že se některé neobjeví.

## 2. Nastavení

| | Wan 2.2 I2V-A14B | LTX-2.5 |
|---|---|---|
| první + poslední snímek | ComfyUI uzel `WanFirstLastFrameToVideo` (modely I2V 14B high/low noise) | podmínky na snímku 0 a −1 (`LTX2VideoCondition` v diffusers; v ComfyUI šablona s klíčovými snímky) |
| rozlišení | 768×768 (násobky 16) | 768×768 (násobky 64 pro dvoustupňové generování) |
| snímky – pohyb, sestava | **49** (tvar 4n+1) ≈ 3 s | **73** (tvar 8n+1) ≈ 3 s |
| snímky – klid | **65** ≈ 4 s | **97** ≈ 4 s |
| fps | 16 | 24 |
| kvalitní běh | 40 kroků, CFG 3,5, shift 5,0 | plný model: 30 kroků, guidance 3,0 |
| rychlý běh | Lightning LoRA: 4 kroky, CFG 1 | distilovaný model: 8 kroků, guidance 1 |
| zvuk | ne | ano, vzniká spolu s obrazem |

- Výchozí délka Wanu je 81 snímků, LTX 121. Kratší klipy jsou tu schválně: pohyb má být svižný a
  soubor malý. Když model pohyb na 3 s nestihne, vrať se k výchozí délce.
- **Při CFG / guidance 1 se negativní prompt nepoužije** (Lightning LoRA i distilovaný LTX). Všechna
  omezení proto musí být v kladném promptu – a jsou.
- U LTX obrázková podmínka podle dokumentace drží obraz nehybný zhruba 8 snímků. Na začátku a konci
  klipu to nevadí, je to přirozená pauza.
- Wan má i menší model TI2V-5B (704×1280, 24 fps), podle ComfyUI se vejde do 8 GB VRAM. Není čtvercový,
  proto není v hlavním srovnání; hodí se jako nouzová varianta na slabší kartu.
- 16 fps Wanu vypadá trochu jako stop-motion, což k hračkám sedí. Na 32 fps jde dopočítat interpolací.

## 3. Stavba promptu

U obrázek→video se **nepopisuje vzhled** – ten nese obrázek. Popisuje se jen pohyb, co zůstává
v klidu, kamera a (u LTX) zvuk. Díl se jmenuje krátce („shark head"), aby model věděl, čím hýbat.

**Wan** – jedna úvodní věta a hned pohyb, krátké věty:
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. {pohyb} {rozsah} Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
**LTX** – podle oficiálního návodu: nejdřív záběr a scéna, pak děj popořadě v přítomném čase,
kamera, nakonec zvuk; jeden odstavec, 4–8 vět:
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. {pohyb} {rozsah} Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: {zvuk}, no music, no speech.
```
`{rozsah}` říká, jestli se hýbe jen díl, nebo celá figurka:

- díl: `Only that part moves; the rest of the toy stays still.`
- celé tělo: `The whole toy moves together and keeps its shape.`

**Negativní prompt – Wan** (jen pro běh se CFG > 1). Vychází z výchozího v repozitáři Wan 2.2, ale
bez „整体发灰" („celkově zašedlé" – naše pozadí je šedé schválně) a bez položek o prstech a davu;
přidán je pohyb kamery, zoom, deformace, tavení, končetiny a hlavy navíc, nové předměty a text:
```text
色调艳丽，过曝，静态，细节模糊不清，字幕，风格，作品，画作，画面，静止，最差质量，低质量，JPEG压缩残留，丑陋的，残缺的，畸形的，毁容的，形态畸形的肢体，静止不动的画面，杂乱的背景，镜头移动，镜头推拉，变焦，物体变形，融化，多余的肢体，多余的头，新出现的物体，文字
```
Pro porovnání výchozí negativní prompt z `wan/configs/shared_config.py`:
```text
色调艳丽，过曝，静态，细节模糊不清，字幕，风格，作品，画作，画面，静止，整体发灰，最差质量，低质量，JPEG压缩残留，丑陋的，残缺的，多余的手指，画得不好的手部，画得不好的脸部，畸形的，毁容的，形态畸形的肢体，手指融合，静止不动的画面，杂乱的背景，三条腿，背景人很多，倒着走
```
**Negativní prompt – LTX** (jen pro plný model):
```text
shaky, glitchy, low quality, worst quality, deformed, distorted, disfigured, motion smear, motion artifacts, morphing, melting, extra limbs, camera movement, zoom, cut, transition, text, music, speech
```

## 4. Pohybový slovník

Každý díl má pohyb (`mutant_core/assets/moves.json`). `{part}` se nahradí krátkým názvem dílu.

| pohyb | rozsah | co se děje (EN) | zvuk pro LTX (EN) |
|---|---|---|---|
| `roar` | díl | The toy tilts its {part} back, opens its mouth wide and lets out a roar while the head shakes slightly, then closes its mouth and lowers the head back. | a short cute cartoon roar |
| `howl` | díl | The toy lifts its {part} to point straight up, opens its mouth and howls, then lowers the head back. | a small wolf howl |
| `chomp` | díl | The toy leans its {part} forward and snaps its jaws open and shut twice, then pulls the head back. | two hollow plastic clacks of teeth |
| `headspin` | díl | The toy turns its {part} smoothly all the way around in one full circle on the neck joint, blinks once, and faces forward again. | a ratcheting plastic click as the head turns |
| `headbutt` | díl | The toy lowers its {part}, thrusts it forward in one quick butt, then lifts the head back up. | a soft plastic thud |
| `scan` | díl | The toy turns its {part} slowly to the left and then to the right while its big eyes flicker with light, then faces forward again. | soft electronic beeps |
| `hide` | tělo | The toy pulls its head, arms and legs in toward its {part} until they are tucked tightly against the body, holds for a moment, then pops them back out. | a hollow plastic clunk, then a pop |
| `puff` | tělo | The toy leans back and pushes its {part} proudly forward and up as if taking a huge breath, holds for a moment, then relaxes back. | a deep breath in and a long breath out |
| `wobble` | tělo | The toy rocks its {part} from side to side three times like a wobbling toy, then settles upright. | a soft plastic rattle |
| `snap` | díl | The toy raises both {part} in front of its chest and snaps them open and shut twice, then lowers them back to its sides. | two sharp plastic clicks |
| `slash` | díl | The toy raises both {part} and swipes them downward one after the other in two quick slashes, then lowers them back to its sides. | two quick whooshes |
| `drill` | díl | The toy points both {part} forward and the drill bits spin fast for a moment, then stop, and the arms lower back to its sides. | a small electric drill whirring |
| `clap` | díl | The toy brings both {part} together in front of its belly and claps them three times, then lowers them back to its sides. | three wet slapping claps |
| `pound` | díl | The toy raises both {part} and drums its fists on its chest four times, then lowers them back to its sides. | four hollow drum thumps on plastic |
| `hop` | tělo | The toy crouches on its {part}, springs straight up into the air in one hop, lands on the same spot with a small bounce, and stands still again. | a springy boing and a plastic thud on landing |
| `stomp` | tělo | The toy lifts one of its {part} and stomps it down, then does the same with the other, and stands still again. | two heavy plastic thuds |
| `roll` | tělo | The toy rolls a short way forward on its {part} with the treads turning, then rolls back to exactly where it started and stops. | a small toy motor hum and rattling treads |
| `scuttle` | tělo | The toy takes three quick small steps to the side on its {part}, then three quick steps back to exactly where it started. | quick light plastic tapping |
| `whip` | díl | The toy swings its {part} out to one side and cracks it like a whip, then lets it settle back behind the body. | a whoosh and a sharp snap |
| `sting` | díl | The toy curls its {part} up over its shoulder and jabs the stinger forward once, then curls it back behind the body. | a quick whoosh and a tiny ping |
| `smash` | díl | The toy lifts its {part} high and slams the club down on the ground behind it, then lifts it back to where it was. | one heavy thud |
| `fan` | díl | The toy folds its {part} halfway closed, then spreads it wide open again into a full fan and shimmers the feathers. | a soft rustle like a paper fan opening |
| `wag` | díl | The toy wags its {part} quickly from side to side four times, then lets it settle back behind the body. | soft quick swishing |
| `splash` | díl | The toy lifts its {part} and slaps it down flat on the ground twice, then lifts it back to where it was. | two wet slaps |
| `hover` | tělo | The toy beats its {part} very fast, rises a little off the ground and hovers for a moment, then sinks back down onto the same spot and the wings stop. | a soft buzzing flutter |
| `flap` | díl | The toy flaps its {part} down and up three times in big slow beats, then holds them open as before. | three soft whooshes of wings |
| `charge` | tělo | The toy leans forward to point its {part} ahead, makes one short charging lunge forward, then steps back to exactly where it started and straightens up. | a short rumble and a thud |
| `slice` | tělo | The toy leans to the left and then to the right so that its {part} sweeps through the air like a fin cutting water, then straightens up. | two clean swishes |
| `beam` | díl | The dish of its {part} spins around twice while its little light blinks, then stops in the starting position. | rising radio beeps |
| `bristle` | díl | The toy shivers and its {part} flare outward and sparkle, then settle back to how they were. | a crackle of ice |
| `idle` | – | The toy stands in place and breathes gently: its body rises and falls slightly, it blinks once and its tail sways a little. Nothing else happens. | quiet room tone and a faint plastic creak |
| `cheer` | – | The toy throws both arms up, does one small happy hop on the spot with its mouth open in a cheer, lands, and lowers its arms back to its sides. | a happy little squeak and a plastic thud on landing |
| `assemble` | – | The loose parts slide toward the body one after another and snap onto their ball joints: first the legs, then the arms, the tail, the back attachment and finally the head. The finished toy stands upright in its final pose and holds still. | a series of satisfying plastic clicks as each part snaps on |

Doplňky u konkrétních dílů (přidají se za popis pohybu):

- `head_dragon` (Dračí hlava): A small puff of grey smoke drifts from its nostrils.
- `torso_dragon` (Dračí hruď): The orange belly plate glows brighter while it holds the pose.
- `torso_shadow_dragon` (Trup stínového draka): The violet belly plate glows brighter while it holds the pose.
- `torso_stegosaurus` (Trup stegosaura): The plates along its back stand up straighter while it holds the pose.
- `back_phoenix` (Pařáty fénixe): Small orange flames flicker around its feet during the jump.
- `front_trex` (Ručičky T-rexe): The arms are comically short, so the slashes are tiny.

## 5. Pilot: plné prompty

Dvě figurky × 8 klipů. Pokrývají čelist, náklon těla, obě ruce, výskok, jízdu tam a zpět,
ocas, křídla, kouř a skládání z dílů.

### Žralomedvěd · `zralomedved`

#### `idle` — klid (smyčka)

první snímek `figures/zralomedved/hero.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 65 / 97 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy stands in place and breathes gently: its body rises and falls slightly, it blinks once and its tail sways a little. Nothing else happens. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy stands in place and breathes gently: its body rises and falls slightly, it blinks once and its tail sways a little. Nothing else happens. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: quiet room tone and a faint plastic creak, no music, no speech.
```

#### `assemble` — sestava

první snímek `figures/zralomedved/exploded.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
The separate parts of a collectible vinyl toy monster figure lie apart on a plain light-grey studio background. The loose parts slide toward the body one after another and snap onto their ball joints: first the legs, then the arms, the tail, the back attachment and finally the head. The finished toy stands upright in its final pose and holds still. The parts are rigid plastic pieces; they never bend, stretch, melt or change shape, and no new parts appear. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation: the separate parts of a collectible vinyl toy monster figure lie apart on a seamless light-grey studio background in soft even light. The loose parts slide toward the body one after another and snap onto their ball joints: first the legs, then the arms, the tail, the back attachment and finally the head. The finished toy stands upright in its final pose and holds still. The parts are rigid plastic pieces; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, and the background stays plain and empty. Audio: a series of satisfying plastic clicks as each part snaps on, no music, no speech.
```

#### `show_head` — Cvakne zuby (Žraločí hlava)

první snímek `figures/zralomedved/hero.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy leans its shark head forward and snaps its jaws open and shut twice, then pulls the head back. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy leans its shark head forward and snaps its jaws open and shut twice, then pulls the head back. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: two hollow plastic clacks of teeth, no music, no speech.
```

#### `show_torso` — Nafoukne břicho (Tělo ledního medvěda)

první snímek `figures/zralomedved/hero.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy leans back and pushes its polar bear belly proudly forward and up as if taking a huge breath, holds for a moment, then relaxes back. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy leans back and pushes its polar bear belly proudly forward and up as if taking a huge breath, holds for a moment, then relaxes back. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: a deep breath in and a long breath out, no music, no speech.
```

#### `show_front` — Zatleská ploutvemi (Mroží ploutve)

první snímek `figures/zralomedved/hero.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy brings both walrus flippers together in front of its belly and claps them three times, then lowers them back to its sides. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy brings both walrus flippers together in front of its belly and claps them three times, then lowers them back to its sides. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: three wet slapping claps, no music, no speech.
```

#### `show_back` — Vyskočí do výšky (Nohy sněžného zajíce)

první snímek `figures/zralomedved/hero.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy crouches on its hare legs, springs straight up into the air in one hop, lands on the same spot with a small bounce, and stands still again. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy crouches on its hare legs, springs straight up into the air in one hop, lands on the same spot with a small bounce, and stands still again. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: a springy boing and a plastic thud on landing, no music, no speech.
```

#### `show_tail` — Zavrtí ohonem (Liščí ohon)

první snímek `figures/zralomedved/hero.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy wags its fox tail quickly from side to side four times, then lets it settle back behind the body. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy wags its fox tail quickly from side to side four times, then lets it settle back behind the body. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: soft quick swishing, no music, no speech.
```

#### `show_extra` — Zakrouží ploutví (Žraločí ploutev)

první snímek `figures/zralomedved/hero.png` · poslední `figures/zralomedved/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy leans to the left and then to the right so that its shark fin sweeps through the air like a fin cutting water, then straightens up. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy leans to the left and then to the right so that its shark fin sweeps through the air like a fin cutting water, then straightens up. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: two clean swishes, no music, no speech.
```

### Drakobot · `drakobot`

#### `idle` — klid (smyčka)

první snímek `figures/drakobot/hero.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 65 / 97 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy stands in place and breathes gently: its body rises and falls slightly, it blinks once and its tail sways a little. Nothing else happens. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy stands in place and breathes gently: its body rises and falls slightly, it blinks once and its tail sways a little. Nothing else happens. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: quiet room tone and a faint plastic creak, no music, no speech.
```

#### `assemble` — sestava

první snímek `figures/drakobot/exploded.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
The separate parts of a collectible vinyl toy monster figure lie apart on a plain light-grey studio background. The loose parts slide toward the body one after another and snap onto their ball joints: first the legs, then the arms, the tail, the back attachment and finally the head. The finished toy stands upright in its final pose and holds still. The parts are rigid plastic pieces; they never bend, stretch, melt or change shape, and no new parts appear. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation: the separate parts of a collectible vinyl toy monster figure lie apart on a seamless light-grey studio background in soft even light. The loose parts slide toward the body one after another and snap onto their ball joints: first the legs, then the arms, the tail, the back attachment and finally the head. The finished toy stands upright in its final pose and holds still. The parts are rigid plastic pieces; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, and the background stays plain and empty. Audio: a series of satisfying plastic clicks as each part snaps on, no music, no speech.
```

#### `show_head` — Zařve a zakouří (Dračí hlava)

první snímek `figures/drakobot/hero.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy tilts its dragon head back, opens its mouth wide and lets out a roar while the head shakes slightly, then closes its mouth and lowers the head back. A small puff of grey smoke drifts from its nostrils. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy tilts its dragon head back, opens its mouth wide and lets out a roar while the head shakes slightly, then closes its mouth and lowers the head back. A small puff of grey smoke drifts from its nostrils. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: a short cute cartoon roar, no music, no speech.
```

#### `show_torso` — Zaklapne pancíř (Kovový trup)

první snímek `figures/drakobot/hero.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy pulls its head, arms and legs in toward its robot torso until they are tucked tightly against the body, holds for a moment, then pops them back out. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy pulls its head, arms and legs in toward its robot torso until they are tucked tightly against the body, holds for a moment, then pops them back out. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: a hollow plastic clunk, then a pop, no music, no speech.
```

#### `show_front` — Sekne drápy (Dračí tlapy)

první snímek `figures/drakobot/hero.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy raises both dragon forepaws and swipes them downward one after the other in two quick slashes, then lowers them back to its sides. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy raises both dragon forepaws and swipes them downward one after the other in two quick slashes, then lowers them back to its sides. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: two quick whooshes, no music, no speech.
```

#### `show_back` — Projede se na pásech (Tankové pásy)

první snímek `figures/drakobot/hero.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy rolls a short way forward on its tank tracks with the treads turning, then rolls back to exactly where it started and stops. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy rolls a short way forward on its tank tracks with the treads turning, then rolls back to exactly where it started and stops. The whole toy moves together and keeps its shape. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: a small toy motor hum and rattling treads, no music, no speech.
```

#### `show_tail` — Švihne ocasem (Kovový ocas)

první snímek `figures/drakobot/hero.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy swings its metal tail out to one side and cracks it like a whip, then lets it settle back behind the body. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy swings its metal tail out to one side and cracks it like a whip, then lets it settle back behind the body. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: a whoosh and a sharp snap, no music, no speech.
```

#### `show_extra` — Zamává křídly (Dračí křídla)

první snímek `figures/drakobot/hero.png` · poslední `figures/drakobot/hero.png` · Wan / LTX: 49 / 73 snímků

Wan
```text
A collectible vinyl toy monster figure stands on a plain light-grey studio background. The toy flaps its dragon wings down and up three times in big slow beats, then holds them open as before. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The toy stays on the same spot and ends in exactly the same pose as it started. Static shot, fixed camera, no zoom, no pan, no cut. The plain light-grey background and the soft even lighting do not change.
```
LTX
```text
Static frame. Stop-motion style toy animation of a collectible vinyl toy monster figure standing on a seamless light-grey studio background in soft even light. The toy flaps its dragon wings down and up three times in big slow beats, then holds them open as before. Only that part moves; the rest of the toy stays still. Its parts are rigid plastic pieces that rotate at their ball joints like a stop-motion toy; they never bend, stretch, melt or change shape, and no new parts appear. The camera is locked off and never moves or zooms, the background stays plain and empty, and the toy ends in exactly the same pose as it started. Audio: three soft whooshes of wings, no music, no speech.
```

## 6. Srovnání animací

### 6.1 Co se pouští

**Rychlé kolo** – 2 figurky × 8 klipů × 2 konfigurace × 2 seedy = **64 klipů**:

- `wan-lightning`: Wan 2.2 I2V-A14B + Lightning LoRA, 4 kroky
- `ltx-distilled`: LTX-2.5 distilovaný, 8 kroků

Stejný hero obrázek, stejné rozlišení, stejné seedy (1 a 2), prompty beze změny z §5.

**Kvalitní kolo** – jen klipy, které v rychlém kole u obou modelů propadly: Wan na 40 kroků, LTX plný
model. Odpoví na otázku, jestli je chyba v modelu, nebo v destilaci.

### 6.2 Jak se hodnotí

Každý klip dostane 0 / 1 / 2 (0 = nepoužitelné, 1 = s výhradou, 2 = dobré). Tabulka je připravená
v `Prompts/video/srovnani.csv`.

| sloupec | otázka | brána |
|---|---|---|
| `identita` | Drží díly tvar a barvu po celý klip? Nic neteče, nepřebarvuje se, nepřibývá? | 0 = klip vyřazen |
| `smycka` | Je poslední snímek stejný jako první, takže klip naváže na `idle`? | 0 = klip vyřazen |
| `pohyb_ok` | Hýbe se to, co má, a je z toho poznat titulek („Zařve")? | |
| `hrackovost` | Otáčejí se díly v kloubech, nebo se ohýbají jako guma? | |
| `kamera` | Stojí kamera i pozadí? | |
| `citelnost` | Je pohyb výrazný a vtipný i na displeji telefonu? | |
| `zvuk` | Jen LTX: sedí zvuk na pohyb? Do součtu se nepočítá. | |
| `cas_s` | Kolik sekund trvalo vygenerování. | |
| `pouzitelny` | 1, když klip prošel oběma branami a má součet aspoň 8 z 12. | |

Hodnoť naslepo, pokud to jde: přejmenuj soubory na čísla a konfiguraci si odkryj až po zapsání bodů.

### 6.3 Co z toho vypadne

Pro každou konfiguraci tři čísla:

1. **Výtěžnost** – podíl použitelných klipů (kolik seedů je potřeba na jeden dobrý klip).
2. **Cena použitelného klipu** – průměrný čas na klip ÷ výtěžnost. Tohle číslo rozhoduje, protože celá
   sbírka je 28 × 9 = 252 klipů.
3. **Průměrné body podle typu pohybu** – díl (čelist, ruce, ocas, křídla) vs. celé tělo (výskok, jízda,
   schování) vs. `idle` vs. `assemble`.

Rozhodnutí: vyhrává konfigurace s nižší cenou použitelného klipu, pokud má průměrný součet (z 12) nejvýš
o 1 bod horší.
Když každý model vyhraje jiný typ pohybu, dá se míchat – klipy jsou samostatné soubory. Míchat má smysl
jen tehdy, když figurka v obou vypadá stejně (stejný hero obrázek to z velké části zaručí).
Když propadne `assemble` u obou, zůstane sestava ve hře 2D animací karet a video se použije jen na pohyby.

### 6.4 Co čekat (hypotézy k ověření)

| | Wan 2.2 | LTX-2.5 |
|---|---|---|
| výskok, rychlý pohyb celého těla (`hop`, `cheer`) | bez známého omezení | oficiální návod uvádí skákání a rychlé kroucení jako zdroj artefaktů |
| malý pohyb jednoho dílu | negativní prompt obsahuje „statický obraz" (platí jen při CFG > 1) – může hýbat i tím, co má stát | návod uvádí jemná gesta jednoho subjektu jako silnou stránku (píše o lidech; u hračky ověřit) |
| šedé pozadí | výchozí negativní prompt obsahuje „zašedlé" – proto je tu upravený | bez známého omezení |
| rychlost | jeden návod uvádí pro první+poslední snímek asi 26 min bez LoRA a 3 min s Lightning LoRA na RTX 4090 | distilovaný model na 8 kroků; změřit |
| zvuk k pohybu | není | ano – ušetří samostatnou výrobu zvuků |
| licence vah | Apache 2.0 | LTX-2.x Community License |

## 7. Z klipu do hry

- Klip je čtverec s neprůhledným šedým pozadím. Nejjednodušší je hrát ho v kulatém „okně inkubátoru"
  s měkkým okrajem – pak průhlednost není potřeba a stačí běžné H.264 MP4.
- Má-li figurka stát volně nad pozadím hry, musí se z každého snímku odstranit pozadí a klip uložit
  jako sekvence s průhledností (animovaný WebP). Je to větší a pracnější; rozhodnout až po pilotu.
- Rozpočet: do 300 kB na klip, tedy zhruba 75 MB na celou sbírku. Zvuk z LTX uložit zvlášť.
- Formát, názvy souborů a přehrávání popisuje `01-PLAN_KOLEKCE.md` §6.5.
