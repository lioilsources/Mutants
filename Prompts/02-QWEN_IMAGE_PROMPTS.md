# Prompty pro Qwen Image — sbírka Mutant

> Generováno skriptem `Prompts/qwen/build_prompts.py` z `collection.json`, `cards.json` a
> `Prompts/qwen/bible.json`. **Needituj ručně** — uprav `bible.json` (styl, vzhled dílu) a spusť
> skript znovu. Všechny prompty plně rozepsané jsou i v `Prompts/qwen/batch.jsonl`.

Obsah: 28 hotových mutantů (figurky) · 60 karet dílů · žolíci, pečeti, události ·
úpravy v Qwen-Image-Edit (pohledy pro 3D, opravy) · kulisy · kontrola před 3D.

## 0. Jak s tím pracovat

**Model.** Text→obrázek: Qwen-Image (hodnoty níže jsou z karty modelu Qwen-Image-2512, otevřené váhy).
Úpravy a další pohledy: Qwen-Image-Edit-2511. Prompty nejsou vázané na verzi – fungují i v novějším
Qwen-Image nebo v Qwen Chatu.

| | Qwen-Image (2512) | Qwen-Image-Edit (2511) |
|---|---|---|
| kroky | 50 | 40 |
| `true_cfg_scale` | 4.0 | 4.0 (`guidance_scale` 1.0) |
| rozlišení | figurky, karty: **1328×1328** · kulisy: **928×1664** · rub karty: **1056×1584** | podle vstupu |
| negativní prompt | viz §1 | mezera `" "` |

- Piš anglicky a **nedávej do promptu jména mutantů** – model by je zkoušel napsat do obrázku.
- **Nepouštěj tyhle prompty přes „prompt enhancer / rewrite"** u text→obrázek: přepíše popis dílů a
  stejný díl pak vypadá na každé figurce jinak. U Editu naopak oficiální README říká, že bez přepsání
  bývá výsledek nestabilní – když úprava nedrží, zkus `polish_edit_prompt` z repa Qwen-Image.
- Každý prompt generuj se **4 seedy**, vyber nejlepší a seed si zapiš vedle souboru.
- Světle šedé pozadí je schválně: čistě se z něj odstraňuje pozadí (rembg / BiRefNet) a image→3D
  modely na něm fungují nejlépe.

**Pořadí práce**

1. **Pilot – 3 figurky** (`zralomedved`, `drakobot`, `jelenobrouk`). Laď jen `style` v `bible.json`,
   dokud nevypadají jako tři kusy ze stejné řady hraček. Pak styl zmraz.
2. **Karty dílů** (60) – stejným stylem. Tady se rozhoduje, jak který díl vypadá; když se ti díl
   nelíbí, přepiš jeho větu v `bible.json` → změní se karta i všechny figurky, které ho mají.
3. **Všech 28 figurek.** Kontrola podle §7; co nesedí, oprav Editem (§5, E6).
4. **Pohledy pro 3D** (§5, E1–E4) jen pro figurky, které jdou do 3D výroby.

## 1. Styl

Figurky jsou **kloubové sběratelské hračky**: každý díl je vlastní kus plastu a díly se potkávají ve
viditelném kulovém kloubu. To je odpověď na „merge dílů vypadá špatně" – žraločí hlava a medvědí tělo
se neslévají organicky, ale spojuje je kloub jako u skutečné hračky. Stejná krémová barva kloubů sjednocuje
celou řadu a zároveň ukazuje, kudy figurku rozříznout na pohyblivé díly ve 3D.

Společné bloky (v `bible.json` → `style`):

**Materiál a tvary – figurka**
```text
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
```
**Rám a světlo – figurka**
```text
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```
**Póza** (výchozí: vzpřímeně – lépe vyplní displej na výšku a sedí na dvounohý auto-rig)
```text
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
```
Varianta pro čtyřnohé držení těla (vyměň řádek `Pose:`):
```text
Pose: standing on all four limbs like an animal, body in side three-quarter view facing left, head turned to the viewer, tail lifted, relaxed neutral stance.
```
**Negativní prompt** – figurky
```text
text, letters, numbers, logo, watermark, packaging, box, display stand, pedestal, extra heads, extra limbs, missing limbs, fused limbs, second figure, human, realistic animal, photorealistic fur, loose hair strands, scary, horror, blood, gore, weapons, dark moody lighting, harsh shadows, coloured background, gradient background, scenery, floor texture, motion blur, depth of field, cropped, cut off
```
Karty dílů, žolíci, pečeti, události (jeden předmět; bez zákazu chybějících končetin, jinak by trup dostal ruce):
```text
text, letters, numbers, logo, watermark, packaging, box, second object, human, scary, horror, blood, dark moody lighting, harsh shadows, coloured background, gradient background, scenery, motion blur, depth of field, cropped, cut off
```
Kulisy:
```text
text, letters, numbers, logo, watermark, characters, creatures, people, toy figures, animals, motion blur, cropped
```
Qwen-Image-2512 má v ukázce vlastní čínský negativní prompt; dá se přidat za ten anglický:
```text
低分辨率，低画质，肢体畸形，手指畸形，画面过饱和，蜡像感，人脸无细节，过度光滑，画面具有AI感。构图混乱。文字模糊，扭曲。
```

## 2. Hotoví mutanti (figurky)

Šablona – věty dílů se berou doslova z `bible.json`, proto má stejný díl všude stejný popis:
```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: {head}.
Body: {torso}.
Arms (front limbs): {front}.
Legs (hind limbs): {back}.
Tail: {tail}, curving out behind the body, clearly visible and not touching the legs.
On its back: {extra}{, spread open to both sides | , upright and clearly visible above the shoulders}.
<materiál>
<rám a světlo>
```

### Prapředci (7) — všech šest dílů z jednoho rodu

#### Praještěr · `prajester` · dino

hlava: Hlava T-rexe · trup: Trup stegosaura · přední: Ručičky T-rexe · zadní: Nohy brontosaura · ocas: Palice ankylosaura · extra: Křídla pterodaktyla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a chunky T-rex head with a big toothy grin and small friendly eyes, warm orange-red scales with a darker ember-red ridge on top.
Body: a barrel-shaped stegosaurus body with a row of leaf-shaped plates along the spine, leafy green with a lighter green belly.
Arms (front limbs): a pair of comically tiny T-rex arms with two little claws each, orange-red scales.
Legs (hind limbs): a pair of thick pillar-like brontosaurus legs with round toenails, grey stone-textured skin.
Tail: a thick armored ankylosaurus tail ending in a heavy round stone club, grey-brown, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of pterodactyl wings with smooth skin membrane, sea-blue with teal undersides, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Prabrouk · `prabrouk` · hmyz

hlava: Hlava mouchy · trup: Krovky brouka · přední: Kudlankové pařátky · zadní: Kobylčí nohy · ocas: Štíří ocas · extra: Křídla vážky

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a housefly head with two enormous faceted compound eyes and short antennae, bright yellow with black stripes.
Body: a rounded beetle body covered by two glossy hard wing-case shells, pebble-grey and brown like polished stone.
Arms (front limbs): a pair of folded praying-mantis forelegs with serrated edges, bright leaf green.
Legs (hind limbs): a pair of long folded grasshopper jumping legs, bright green.
Tail: a curled scorpion tail arching upward with a glowing orange-red stinger, dark red segments, curving out behind the body, clearly visible and not touching the legs.
On its back: two pairs of long narrow translucent dragonfly wings with yellow veins, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Pražralok · `prazralok` · mořský

hlava: Žraločí hlava · trup: Krunýř mořské želvy · přední: Krabí klepeta · zadní: Krabí nožky · ocas: Rybí ocas · extra: Žraločí ploutev

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a rounded great white shark head with a wide smile full of blunt triangular teeth, ocean-blue on top and white underneath.
Body: a domed sea-turtle shell body, blue-green shell with a hexagon pattern and a pale yellow belly plate.
Arms (front limbs): a pair of big crab pincer claws, blue shell with lighter teal tips.
Legs (hind limbs): a pair of sturdy pointed crab walking legs, blue shell with teal joints.
Tail: a fish tail with a wide forked fin, shiny blue scales, curving out behind the body, clearly visible and not touching the legs.
On its back: a tall triangular shark dorsal fin, ocean blue, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Prapták · `praptak` · ptačí

hlava: Soví hlava · trup: Papouščí hruď · přední: Orlí pařáty · zadní: Pařáty fénixe · ocas: Paví ocas · extra: Křídla orla skalního

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a round owl head with huge glowing yellow eyes, a small curved beak and two feather ear tufts, deep purple feathers.
Body: a puffed-out parrot chest of layered bright green feathers with yellow-green tips.
Arms (front limbs): a pair of eagle legs with strong yellow scaly feet and sharp dark talons, golden-yellow feathers at the top.
Legs (hind limbs): a pair of phoenix bird legs with fiery orange feather tufts and golden talons.
Tail: a fanned-out peacock tail of green feathers with round eye spots, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of broad feathered eagle wings, grey-brown stone-coloured feathers, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Prachlupáč · `prachlupac` · savec

hlava: Hlava sněžného vlka · trup: Tělo ledního medvěda · přední: Gorilí paže · zadní: Nohy sněžného zajíce · ocas: Liščí ohon · extra: Nosorožčí roh

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a snow wolf head with pointed ears and small white fangs, frosty pale-blue and white fur.
Body: a big round polar bear body with a soft belly, white fur with a pale icy-blue tint.
Arms (front limbs): a pair of huge long gorilla arms with big fists, mossy dark-green fur with lighter green hands.
Legs (hind limbs): a pair of big snow-hare hind legs with oversized feet, white fur with pale blue toe pads.
Tail: a big bushy fox tail, orange-red with a white tip, curving out behind the body, clearly visible and not touching the legs.
On its back: a single thick curved grey rhinoceros horn rising from between the shoulders, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Pradrak · `pradrak` · drak

hlava: Dračí hlava · trup: Dračí hruď · přední: Dračí tlapy · zadní: Dračí nohy · ocas: Ocas ledového draka · extra: Dračí křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a dragon head with two curved golden-orange horns, small fangs and a smoking snout, glossy red scales.
Body: a broad dragon chest with layered red scales and a glowing orange belly plate.
Arms (front limbs): a pair of muscular dragon forepaws with three black claws each, dark purple scales.
Legs (hind limbs): a pair of strong dragon hind legs with orange-clawed feet, red scales.
Tail: a long dragon tail with a row of small icicle spikes, pale icy-blue scales, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of large dragon wings, red scaly arms with orange membrane, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Prarobot · `prarobot` · robot

hlava: Robotí hlava · trup: Kovový trup · přední: Chapadla ponorky · zadní: Tankové pásy · ocas: Kovový ocas · extra: Radarová anténa

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a boxy retro robot head with three round glowing lens eyes and a small bolt antenna, yellow painted metal with grey rivets.
Body: a boxy riveted metal robot torso with a round glowing yellow power core in the chest, yellow and grey painted steel.
Arms (front limbs): a pair of jointed submarine grabber arms with three-finger metal claws, blue painted metal with round rivets.
Legs (hind limbs): a pair of small tank caterpillar tracks in place of hind legs, dark grey treads with stone-brown wheels.
Tail: a segmented metal robot tail ending in a yellow lightning-bolt-shaped plug, curving out behind the body, clearly visible and not touching the legs.
On its back: a small radar dish antenna on a short mast with a blinking light, yellow metal, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

### Kříženci (21) — hlava a ruce z prvního rodu, tělo a nohy z druhého

#### Tricebrouk · `tricebrouk` · dino × hmyz

hlava: Hlava triceratopse · trup: Krovky brouka · přední: Pařáty nočního raptora · zadní: Pavoučí nohy · ocas: Štíří ocas · extra: Křídla pterodaktyla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a triceratops head with three blunt horns and a wide bony neck frill, stone-grey and sandy-brown rocky skin.
Body: a rounded beetle body covered by two glossy hard wing-case shells, pebble-grey and brown like polished stone.
Arms (front limbs): a pair of slim raptor arms with long hooked claws, dark purple-black scales.
Legs (hind limbs): a pair of long arched fuzzy spider legs, dark purple with lighter violet bands.
Tail: a curled scorpion tail arching upward with a glowing orange-red stinger, dark red segments, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of pterodactyl wings with smooth skin membrane, sea-blue with teal undersides, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Rexoželva · `rexozelva` · dino × mořský

hlava: Hlava T-rexe · trup: Krunýř mořské želvy · přední: Ručičky T-rexe · zadní: Krabí nožky · ocas: Velrybí ocas · extra: Ledové ostny

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a chunky T-rex head with a big toothy grin and small friendly eyes, warm orange-red scales with a darker ember-red ridge on top.
Body: a domed sea-turtle shell body, blue-green shell with a hexagon pattern and a pale yellow belly plate.
Arms (front limbs): a pair of comically tiny T-rex arms with two little claws each, orange-red scales.
Legs (hind limbs): a pair of sturdy pointed crab walking legs, blue shell with teal joints.
Tail: a broad whale tail fluke, pale icy-blue with a white underside, curving out behind the body, clearly visible and not touching the legs.
On its back: a row of jagged translucent ice-crystal spikes along the back, pale icy blue, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Tricemedvěd · `tricemedved` · dino × savec

hlava: Hlava triceratopse · trup: Tělo ledního medvěda · přední: Pařáty nočního raptora · zadní: Nohy sněžného zajíce · ocas: Palice ankylosaura · extra: Nosorožčí roh

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a triceratops head with three blunt horns and a wide bony neck frill, stone-grey and sandy-brown rocky skin.
Body: a big round polar bear body with a soft belly, white fur with a pale icy-blue tint.
Arms (front limbs): a pair of slim raptor arms with long hooked claws, dark purple-black scales.
Legs (hind limbs): a pair of big snow-hare hind legs with oversized feet, white fur with pale blue toe pads.
Tail: a thick armored ankylosaurus tail ending in a heavy round stone club, grey-brown, curving out behind the body, clearly visible and not touching the legs.
On its back: a single thick curved grey rhinoceros horn rising from between the shoulders, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Pavoukobotnice · `pavoukobotnice` · hmyz × mořský

hlava: Pavoučí hlava · trup: Chobotničí tělo · přední: Kudlankové pařátky · zadní: Krabí nožky · ocas: Rybí ocas · extra: Křídla vážky

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a fuzzy spider head with eight shiny round eyes and two small fangs, dark purple.
Body: a soft bulbous octopus body with rows of small suction cups, dark violet with lighter purple spots.
Arms (front limbs): a pair of folded praying-mantis forelegs with serrated edges, bright leaf green.
Legs (hind limbs): a pair of sturdy pointed crab walking legs, blue shell with teal joints.
Tail: a fish tail with a wide forked fin, shiny blue scales, curving out behind the body, clearly visible and not touching the legs.
On its back: two pairs of long narrow translucent dragonfly wings with yellow veins, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Mouchopapoušek · `mouchopapousek` · hmyz × ptačí

hlava: Hlava mouchy · trup: Papouščí hruď · přední: Kudlankové pařátky · zadní: Volavčí nohy · ocas: Paví ocas · extra: Motýlí křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a housefly head with two enormous faceted compound eyes and short antennae, bright yellow with black stripes.
Body: a puffed-out parrot chest of layered bright green feathers with yellow-green tips.
Arms (front limbs): a pair of folded praying-mantis forelegs with serrated edges, bright leaf green.
Legs (hind limbs): a pair of very long thin heron legs with webbed feet, blue-grey.
Tail: a fanned-out peacock tail of green feathers with round eye spots, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of big rounded butterfly wings, leaf-green with yellow and pink flower-like spots, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Pavoudrak · `pavoudrak` · hmyz × drak

hlava: Pavoučí hlava · trup: Trup stínového draka · přední: Kudlankové pařátky · zadní: Nohy lesního draka · ocas: Štíří ocas · extra: Dračí křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a fuzzy spider head with eight shiny round eyes and two small fangs, dark purple.
Body: a slim dragon body with smooth matte black-purple scales and a faintly glowing violet belly plate.
Arms (front limbs): a pair of folded praying-mantis forelegs with serrated edges, bright leaf green.
Legs (hind limbs): a pair of dragon hind legs with clawed feet, moss-green scales with small leaves growing at the knees.
Tail: a curled scorpion tail arching upward with a glowing orange-red stinger, dark red segments, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of large dragon wings, red scaly arms with orange membrane, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Žralotučňák · `zralotucnak` · mořský × ptačí

hlava: Žraločí hlava · trup: Tučňáčí bříško · přední: Mroží ploutve · zadní: Volavčí nohy · ocas: Vlaštovčí ocas · extra: Žraločí ploutev

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a rounded great white shark head with a wide smile full of blunt triangular teeth, ocean-blue on top and white underneath.
Body: a plump penguin body with a smooth white belly and an icy blue-black back.
Arms (front limbs): a pair of wide flat walrus flippers, pale grey-blue with frosty white edges.
Legs (hind limbs): a pair of very long thin heron legs with webbed feet, blue-grey.
Tail: a slender deeply forked swallow tail, dark blue feathers with yellow streaks, curving out behind the body, clearly visible and not touching the legs.
On its back: a tall triangular shark dorsal fin, ocean blue, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Žralomedvěd · `zralomedved` · mořský × savec

hlava: Žraločí hlava · trup: Tělo ledního medvěda · přední: Mroží ploutve · zadní: Nohy sněžného zajíce · ocas: Liščí ohon · extra: Žraločí ploutev

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a rounded great white shark head with a wide smile full of blunt triangular teeth, ocean-blue on top and white underneath.
Body: a big round polar bear body with a soft belly, white fur with a pale icy-blue tint.
Arms (front limbs): a pair of wide flat walrus flippers, pale grey-blue with frosty white edges.
Legs (hind limbs): a pair of big snow-hare hind legs with oversized feet, white fur with pale blue toe pads.
Tail: a big bushy fox tail, orange-red with a white tip, curving out behind the body, clearly visible and not touching the legs.
On its back: a tall triangular shark dorsal fin, ocean blue, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Žralobot · `zralobot` · mořský × robot

hlava: Žraločí hlava · trup: Kovový trup · přední: Krabí klepeta · zadní: Tankové pásy · ocas: Velrybí ocas · extra: Radarová anténa

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a rounded great white shark head with a wide smile full of blunt triangular teeth, ocean-blue on top and white underneath.
Body: a boxy riveted metal robot torso with a round glowing yellow power core in the chest, yellow and grey painted steel.
Arms (front limbs): a pair of big crab pincer claws, blue shell with lighter teal tips.
Legs (hind limbs): a pair of small tank caterpillar tracks in place of hind legs, dark grey treads with stone-brown wheels.
Tail: a broad whale tail fluke, pale icy-blue with a white underside, curving out behind the body, clearly visible and not touching the legs.
On its back: a small radar dish antenna on a short mast with a blinking light, yellow metal, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Sovomedvěd · `sovomedved` · ptačí × savec

hlava: Soví hlava · trup: Tělo ledního medvěda · přední: Orlí pařáty · zadní: Nohy sněžného zajíce · ocas: Liščí ohon · extra: Křídla orla skalního

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a round owl head with huge glowing yellow eyes, a small curved beak and two feather ear tufts, deep purple feathers.
Body: a big round polar bear body with a soft belly, white fur with a pale icy-blue tint.
Arms (front limbs): a pair of eagle legs with strong yellow scaly feet and sharp dark talons, golden-yellow feathers at the top.
Legs (hind limbs): a pair of big snow-hare hind legs with oversized feet, white fur with pale blue toe pads.
Tail: a big bushy fox tail, orange-red with a white tip, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of broad feathered eagle wings, grey-brown stone-coloured feathers, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Sovodrak · `sovodrak` · ptačí × drak

hlava: Soví hlava · trup: Trup stínového draka · přední: Orlí pařáty · zadní: Nohy lesního draka · ocas: Ocas ledového draka · extra: Křídla orla skalního

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a round owl head with huge glowing yellow eyes, a small curved beak and two feather ear tufts, deep purple feathers.
Body: a slim dragon body with smooth matte black-purple scales and a faintly glowing violet belly plate.
Arms (front limbs): a pair of eagle legs with strong yellow scaly feet and sharp dark talons, golden-yellow feathers at the top.
Legs (hind limbs): a pair of dragon hind legs with clawed feet, moss-green scales with small leaves growing at the knees.
Tail: a long dragon tail with a row of small icicle spikes, pale icy-blue scales, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of broad feathered eagle wings, grey-brown stone-coloured feathers, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Sovosaurus · `sovosaurus` · ptačí × dino

hlava: Soví hlava · trup: Trup stegosaura · přední: Orlí pařáty · zadní: Nohy brontosaura · ocas: Vlaštovčí ocas · extra: Ledové ostny

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a round owl head with huge glowing yellow eyes, a small curved beak and two feather ear tufts, deep purple feathers.
Body: a barrel-shaped stegosaurus body with a row of leaf-shaped plates along the spine, leafy green with a lighter green belly.
Arms (front limbs): a pair of eagle legs with strong yellow scaly feet and sharp dark talons, golden-yellow feathers at the top.
Legs (hind limbs): a pair of thick pillar-like brontosaurus legs with round toenails, grey stone-textured skin.
Tail: a slender deeply forked swallow tail, dark blue feathers with yellow streaks, curving out behind the body, clearly visible and not touching the legs.
On its back: a row of jagged translucent ice-crystal spikes along the back, pale icy blue, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Vlkodrak · `vlkodrak` · savec × drak

hlava: Hlava sněžného vlka · trup: Dračí hruď · přední: Gorilí paže · zadní: Dračí nohy · ocas: Ocas ledového draka · extra: Netopýří křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a snow wolf head with pointed ears and small white fangs, frosty pale-blue and white fur.
Body: a broad dragon chest with layered red scales and a glowing orange belly plate.
Arms (front limbs): a pair of huge long gorilla arms with big fists, mossy dark-green fur with lighter green hands.
Legs (hind limbs): a pair of strong dragon hind legs with orange-clawed feet, red scales.
Tail: a long dragon tail with a row of small icicle spikes, pale icy-blue scales, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of leathery bat wings, dark purple membrane with black finger bones, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Jelenobot · `jelenobot` · savec × robot

hlava: Jelení hlava · trup: Kovový trup · přední: Gorilí paže · zadní: Tankové pásy · ocas: Ocas nindža robota · extra: Netopýří křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a gentle deer head with branching antlers sprouting small green leaves, moss-green and light-brown fur.
Body: a boxy riveted metal robot torso with a round glowing yellow power core in the chest, yellow and grey painted steel.
Arms (front limbs): a pair of huge long gorilla arms with big fists, mossy dark-green fur with lighter green hands.
Legs (hind limbs): a pair of small tank caterpillar tracks in place of hind legs, dark grey treads with stone-brown wheels.
Tail: a thin flexible robot tail of black-purple segments ending in a small throwing-star tip, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of leathery bat wings, dark purple membrane with black finger bones, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Jelenobrouk · `jelenobrouk` · savec × hmyz

hlava: Jelení hlava · trup: Krovky brouka · přední: Gorilí paže · zadní: Kobylčí nohy · ocas: Liščí ohon · extra: Motýlí křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a gentle deer head with branching antlers sprouting small green leaves, moss-green and light-brown fur.
Body: a rounded beetle body covered by two glossy hard wing-case shells, pebble-grey and brown like polished stone.
Arms (front limbs): a pair of huge long gorilla arms with big fists, mossy dark-green fur with lighter green hands.
Legs (hind limbs): a pair of long folded grasshopper jumping legs, bright green.
Tail: a big bushy fox tail, orange-red with a white tip, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of big rounded butterfly wings, leaf-green with yellow and pink flower-like spots, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Drakobot · `drakobot` · drak × robot

hlava: Dračí hlava · trup: Kovový trup · přední: Dračí tlapy · zadní: Tankové pásy · ocas: Kovový ocas · extra: Dračí křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a dragon head with two curved golden-orange horns, small fangs and a smoking snout, glossy red scales.
Body: a boxy riveted metal robot torso with a round glowing yellow power core in the chest, yellow and grey painted steel.
Arms (front limbs): a pair of muscular dragon forepaws with three black claws each, dark purple scales.
Legs (hind limbs): a pair of small tank caterpillar tracks in place of hind legs, dark grey treads with stone-brown wheels.
Tail: a segmented metal robot tail ending in a yellow lightning-bolt-shaped plug, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of large dragon wings, red scaly arms with orange membrane, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Drakosaurus · `drakosaurus` · drak × dino

hlava: Dračí hlava · trup: Trup stegosaura · přední: Dračí tlapy · zadní: Nohy brontosaura · ocas: Palice ankylosaura · extra: Dračí křídla

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a dragon head with two curved golden-orange horns, small fangs and a smoking snout, glossy red scales.
Body: a barrel-shaped stegosaurus body with a row of leaf-shaped plates along the spine, leafy green with a lighter green belly.
Arms (front limbs): a pair of muscular dragon forepaws with three black claws each, dark purple scales.
Legs (hind limbs): a pair of thick pillar-like brontosaurus legs with round toenails, grey stone-textured skin.
Tail: a thick armored ankylosaurus tail ending in a heavy round stone club, grey-brown, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of large dragon wings, red scaly arms with orange membrane, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Drakobotnice · `drakobotnice` · drak × mořský

hlava: Dračí hlava · trup: Chobotničí tělo · přední: Dračí tlapy · zadní: Krabí nožky · ocas: Ocas ledového draka · extra: Žraločí ploutev

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a dragon head with two curved golden-orange horns, small fangs and a smoking snout, glossy red scales.
Body: a soft bulbous octopus body with rows of small suction cups, dark violet with lighter purple spots.
Arms (front limbs): a pair of muscular dragon forepaws with three black claws each, dark purple scales.
Legs (hind limbs): a pair of sturdy pointed crab walking legs, blue shell with teal joints.
Tail: a long dragon tail with a row of small icicle spikes, pale icy-blue scales, curving out behind the body, clearly visible and not touching the legs.
On its back: a tall triangular shark dorsal fin, ocean blue, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Robosaurus · `robosaurus` · robot × dino

hlava: Robotí hlava · trup: Trup stegosaura · přední: Vrtákové ruce · zadní: Nohy brontosaura · ocas: Palice ankylosaura · extra: Radarová anténa

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a boxy retro robot head with three round glowing lens eyes and a small bolt antenna, yellow painted metal with grey rivets.
Body: a barrel-shaped stegosaurus body with a row of leaf-shaped plates along the spine, leafy green with a lighter green belly.
Arms (front limbs): a pair of robot arms ending in cone-shaped spiral drill bits, grey steel dusted with brown rock dust.
Legs (hind limbs): a pair of thick pillar-like brontosaurus legs with round toenails, grey stone-textured skin.
Tail: a thick armored ankylosaurus tail ending in a heavy round stone club, grey-brown, curving out behind the body, clearly visible and not touching the legs.
On its back: a small radar dish antenna on a short mast with a blinking light, yellow metal, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Robobrouk · `robobrouk` · robot × hmyz

hlava: Robotí hlava · trup: Krovky brouka · přední: Vrtákové ruce · zadní: Pavoučí nohy · ocas: Štíří ocas · extra: Radarová anténa

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a boxy retro robot head with three round glowing lens eyes and a small bolt antenna, yellow painted metal with grey rivets.
Body: a rounded beetle body covered by two glossy hard wing-case shells, pebble-grey and brown like polished stone.
Arms (front limbs): a pair of robot arms ending in cone-shaped spiral drill bits, grey steel dusted with brown rock dust.
Legs (hind limbs): a pair of long arched fuzzy spider legs, dark purple with lighter violet bands.
Tail: a curled scorpion tail arching upward with a glowing orange-red stinger, dark red segments, curving out behind the body, clearly visible and not touching the legs.
On its back: a small radar dish antenna on a short mast with a blinking light, yellow metal, upright and clearly visible above the shoulders.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

#### Robotučňák · `robotucnak` · robot × ptačí

hlava: Robotí hlava · trup: Tučňáčí bříško · přední: Chapadla ponorky · zadní: Pařáty fénixe · ocas: Ocas nindža robota · extra: Křídla orla skalního

```text
Studio product photo of ONE collectible designer vinyl toy for kids: a friendly chimera monster built as a ball-jointed action figure from six mismatched toy parts.
Pose: standing upright on its two hind limbs like a small kaiju toy, body turned three-quarters to the left, face looking at the viewer, arms held slightly out from the sides, legs apart, relaxed neutral stance.
Head: a boxy retro robot head with three round glowing lens eyes and a small bolt antenna, yellow painted metal with grey rivets.
Body: a plump penguin body with a smooth white belly and an icy blue-black back.
Arms (front limbs): a pair of jointed submarine grabber arms with three-finger metal claws, blue painted metal with round rivets.
Legs (hind limbs): a pair of phoenix bird legs with fiery orange feather tufts and golden talons.
Tail: a thin flexible robot tail of black-purple segments ending in a small throwing-star tip, curving out behind the body, clearly visible and not touching the legs.
On its back: a pair of broad feathered eagle wings, grey-brown stone-coloured feathers, spread open to both sides.
Chunky rounded proportions, oversized head, short thick limbs, friendly expression, big simple eyes. Every body part is its own smooth molded plastic piece in its own colours; the pieces meet at clearly visible glossy off-white ball joints at the neck, shoulders, hips, tail base and back mount. Matte soft-touch vinyl with simple painted details, a few bold colours per piece. Fur, feathers and scales are sculpted as smooth stylised shapes, no loose hair.
Soft even studio lighting from the front, faint soft contact shadow under the feet, seamless plain light-grey background, the whole figure centred in frame with empty margin on all sides, nothing cropped, sharp focus, no text.
```

## 3. Karty dílů

Jeden díl = jeden obrázek 1328×1328, po odstranění pozadí jde do rámečku karty v aplikaci.
Šablona:
```text
Studio product photo of ONE loose toy part from a build-a-figure set of collectible designer vinyl toys, shown alone: {vzhled dílu}. {kloub podle slotu} Smooth molded matte soft-touch vinyl with simple painted details, chunky rounded kid-friendly shapes, fur, feathers and scales sculpted as smooth stylised forms. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
Věta o kloubu podle slotu:

- **hlava**: `Under the head is a glossy off-white ball-joint peg for the neck.`
- **trup**: `It has glossy off-white ball-joint sockets at the neck, both shoulders, both hips and the tail base, and no head or limbs attached.`
- **přední**: `The two matching left and right pieces lie side by side, each with a glossy off-white ball-joint peg at the shoulder end.`
- **zadní**: `The two matching left and right pieces stand side by side, each with a glossy off-white ball-joint peg at the hip end.`
- **ocas**: `At its base is a glossy off-white ball-joint peg.`
- **extra**: `At its base is a small glossy off-white ball-joint mount.`
- **křídla** (extra): `The left and right pieces are joined in the middle by a small glossy off-white ball-joint mount.`

Příklad plně rozepsaného promptu (`head_shark`):
```text
Studio product photo of ONE loose toy part from a build-a-figure set of collectible designer vinyl toys, shown alone: a rounded great white shark head with a wide smile full of blunt triangular teeth, ocean-blue on top and white underneath. Under the head is a glossy off-white ball-joint peg for the neck. Smooth molded matte soft-touch vinyl with simple painted details, chunky rounded kid-friendly shapes, fur, feathers and scales sculpted as smooth stylised forms. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
Vzhled jednotlivých dílů (`{vzhled dílu}`); plné prompty všech 60 karet jsou v `batch.jsonl`:

**Hlava**

| karta | název | živel | vzhled (EN) |
|---|---|---|---|
| `head_trex` | Hlava T-rexe | oheň | a chunky T-rex head with a big toothy grin and small friendly eyes, warm orange-red scales with a darker ember-red ridge on top |
| `head_shark` | Žraločí hlava | voda | a rounded great white shark head with a wide smile full of blunt triangular teeth, ocean-blue on top and white underneath |
| `head_owl` | Soví hlava | stín | a round owl head with huge glowing yellow eyes, a small curved beak and two feather ear tufts, deep purple feathers |
| `head_triceratops` | Hlava triceratopse | kámen | a triceratops head with three blunt horns and a wide bony neck frill, stone-grey and sandy-brown rocky skin |
| `head_fly` | Hlava mouchy | blesk | a housefly head with two enormous faceted compound eyes and short antennae, bright yellow with black stripes |
| `head_wolf` | Hlava sněžného vlka | led | a snow wolf head with pointed ears and small white fangs, frosty pale-blue and white fur |
| `head_dragon` | Dračí hlava | oheň | a dragon head with two curved golden-orange horns, small fangs and a smoking snout, glossy red scales |
| `head_robot` | Robotí hlava | blesk | a boxy retro robot head with three round glowing lens eyes and a small bolt antenna, yellow painted metal with grey rivets |
| `head_deer` | Jelení hlava | rostlina | a gentle deer head with branching antlers sprouting small green leaves, moss-green and light-brown fur |
| `head_spider` | Pavoučí hlava | stín | a fuzzy spider head with eight shiny round eyes and two small fangs, dark purple |

**Trup**

| karta | název | živel | vzhled (EN) |
|---|---|---|---|
| `torso_turtle` | Krunýř mořské želvy | voda | a domed sea-turtle shell body, blue-green shell with a hexagon pattern and a pale yellow belly plate |
| `torso_polar_bear` | Tělo ledního medvěda | led | a big round polar bear body with a soft belly, white fur with a pale icy-blue tint |
| `torso_beetle` | Krovky brouka | kámen | a rounded beetle body covered by two glossy hard wing-case shells, pebble-grey and brown like polished stone |
| `torso_stegosaurus` | Trup stegosaura | rostlina | a barrel-shaped stegosaurus body with a row of leaf-shaped plates along the spine, leafy green with a lighter green belly |
| `torso_dragon` | Dračí hruď | oheň | a broad dragon chest with layered red scales and a glowing orange belly plate |
| `torso_robot` | Kovový trup | blesk | a boxy riveted metal robot torso with a round glowing yellow power core in the chest, yellow and grey painted steel |
| `torso_penguin` | Tučňáčí bříško | led | a plump penguin body with a smooth white belly and an icy blue-black back |
| `torso_octopus` | Chobotničí tělo | stín | a soft bulbous octopus body with rows of small suction cups, dark violet with lighter purple spots |
| `torso_parrot` | Papouščí hruď | rostlina | a puffed-out parrot chest of layered bright green feathers with yellow-green tips |
| `torso_shadow_dragon` | Trup stínového draka | stín | a slim dragon body with smooth matte black-purple scales and a faintly glowing violet belly plate |

**Přední**

| karta | název | živel | vzhled (EN) |
|---|---|---|---|
| `front_crab` | Krabí klepeta | voda | a pair of big crab pincer claws, blue shell with lighter teal tips |
| `front_mantis` | Kudlankové pařátky | rostlina | a pair of folded praying-mantis forelegs with serrated edges, bright leaf green |
| `front_trex` | Ručičky T-rexe | oheň | a pair of comically tiny T-rex arms with two little claws each, orange-red scales |
| `front_drill` | Vrtákové ruce | kámen | a pair of robot arms ending in cone-shaped spiral drill bits, grey steel dusted with brown rock dust |
| `front_eagle` | Orlí pařáty | blesk | a pair of eagle legs with strong yellow scaly feet and sharp dark talons, golden-yellow feathers at the top |
| `front_submarine` | Chapadla ponorky | voda | a pair of jointed submarine grabber arms with three-finger metal claws, blue painted metal with round rivets |
| `front_dragon` | Dračí tlapy | stín | a pair of muscular dragon forepaws with three black claws each, dark purple scales |
| `front_walrus` | Mroží ploutve | led | a pair of wide flat walrus flippers, pale grey-blue with frosty white edges |
| `front_raptor` | Pařáty nočního raptora | stín | a pair of slim raptor arms with long hooked claws, dark purple-black scales |
| `front_gorilla` | Gorilí paže | rostlina | a pair of huge long gorilla arms with big fists, mossy dark-green fur with lighter green hands |

**Zadní**

| karta | název | živel | vzhled (EN) |
|---|---|---|---|
| `back_forest_dragon` | Nohy lesního draka | rostlina | a pair of dragon hind legs with clawed feet, moss-green scales with small leaves growing at the knees |
| `back_grasshopper` | Kobylčí nohy | rostlina | a pair of long folded grasshopper jumping legs, bright green |
| `back_phoenix` | Pařáty fénixe | oheň | a pair of phoenix bird legs with fiery orange feather tufts and golden talons |
| `back_brontosaurus` | Nohy brontosaura | kámen | a pair of thick pillar-like brontosaurus legs with round toenails, grey stone-textured skin |
| `back_tracks` | Tankové pásy | kámen | a pair of small tank caterpillar tracks in place of hind legs, dark grey treads with stone-brown wheels |
| `back_dragon` | Dračí nohy | oheň | a pair of strong dragon hind legs with orange-clawed feet, red scales |
| `back_crab` | Krabí nožky | voda | a pair of sturdy pointed crab walking legs, blue shell with teal joints |
| `back_hare` | Nohy sněžného zajíce | led | a pair of big snow-hare hind legs with oversized feet, white fur with pale blue toe pads |
| `back_heron` | Volavčí nohy | voda | a pair of very long thin heron legs with webbed feet, blue-grey |
| `back_spider` | Pavoučí nohy | stín | a pair of long arched fuzzy spider legs, dark purple with lighter violet bands |

**Ocas**

| karta | název | živel | vzhled (EN) |
|---|---|---|---|
| `tail_metal` | Kovový ocas | blesk | a segmented metal robot tail ending in a yellow lightning-bolt-shaped plug |
| `tail_scorpion` | Štíří ocas | oheň | a curled scorpion tail arching upward with a glowing orange-red stinger, dark red segments |
| `tail_fish` | Rybí ocas | voda | a fish tail with a wide forked fin, shiny blue scales |
| `tail_ankylosaurus` | Palice ankylosaura | kámen | a thick armored ankylosaurus tail ending in a heavy round stone club, grey-brown |
| `tail_peacock` | Paví ocas | rostlina | a fanned-out peacock tail of green feathers with round eye spots |
| `tail_fox` | Liščí ohon | oheň | a big bushy fox tail, orange-red with a white tip |
| `tail_ice_dragon` | Ocas ledového draka | led | a long dragon tail with a row of small icicle spikes, pale icy-blue scales |
| `tail_whale` | Velrybí ocas | led | a broad whale tail fluke, pale icy-blue with a white underside |
| `tail_ninja_robot` | Ocas nindža robota | stín | a thin flexible robot tail of black-purple segments ending in a small throwing-star tip |
| `tail_swallow` | Vlaštovčí ocas | blesk | a slender deeply forked swallow tail, dark blue feathers with yellow streaks |

**Extra**

| karta | název | živel | vzhled (EN) |
|---|---|---|---|
| `extra_dragonfly` | Křídla vážky | blesk | two pairs of long narrow translucent dragonfly wings with yellow veins |
| `extra_bat` | Netopýří křídla | stín | a pair of leathery bat wings, dark purple membrane with black finger bones |
| `extra_dragon` | Dračí křídla | oheň | a pair of large dragon wings, red scaly arms with orange membrane |
| `extra_eagle` | Křídla orla skalního | kámen | a pair of broad feathered eagle wings, grey-brown stone-coloured feathers |
| `extra_rhino` | Nosorožčí roh | kámen | a single thick curved grey rhinoceros horn rising from between the shoulders |
| `extra_shark_fin` | Žraločí ploutev | voda | a tall triangular shark dorsal fin, ocean blue |
| `extra_antenna` | Radarová anténa | blesk | a small radar dish antenna on a short mast with a blinking light, yellow metal |
| `extra_pterodactyl` | Křídla pterodaktyla | voda | a pair of pterodactyl wings with smooth skin membrane, sea-blue with teal undersides |
| `extra_ice_spikes` | Ledové ostny | led | a row of jagged translucent ice-crystal spikes along the back, pale icy blue |
| `extra_butterfly` | Motýlí křídla | rostlina | a pair of big rounded butterfly wings, leaf-green with yellow and pink flower-like spots |

## 4. Žolíci, pečeti, události

**Žolík (dřívější Mutace)** – baňka mutagenu, ze které roste tvar podle slotu. Dvě karty stejného
slotu rozliš jiným seedem.

*hlava*
```text
Studio product photo of ONE toy laboratory flask full of glowing green mutagen slime. A blob of slime rises out of the flask and forms the rough wobbly shape of a monster head with two round eyes. Glossy translucent lime-green goo with small bubbles and a soft inner glow, round glass flask, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*trup*
```text
Studio product photo of ONE toy laboratory flask full of glowing green mutagen slime. A blob of slime rises out of the flask and forms the rough wobbly shape of a round monster belly. Glossy translucent lime-green goo with small bubbles and a soft inner glow, round glass flask, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*přední*
```text
Studio product photo of ONE toy laboratory flask full of glowing green mutagen slime. A blob of slime rises out of the flask and forms the rough wobbly shape of two grabbing arms. Glossy translucent lime-green goo with small bubbles and a soft inner glow, round glass flask, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*zadní*
```text
Studio product photo of ONE toy laboratory flask full of glowing green mutagen slime. A blob of slime rises out of the flask and forms the rough wobbly shape of two stomping legs. Glossy translucent lime-green goo with small bubbles and a soft inner glow, round glass flask, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*ocas*
```text
Studio product photo of ONE toy laboratory flask full of glowing green mutagen slime. A blob of slime rises out of the flask and forms the rough wobbly shape of a long curling tail. Glossy translucent lime-green goo with small bubbles and a soft inner glow, round glass flask, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*extra*
```text
Studio product photo of ONE toy laboratory flask full of glowing green mutagen slime. A blob of slime rises out of the flask and forms the rough wobbly shape of a pair of small wings. Glossy translucent lime-green goo with small bubbles and a soft inner glow, round glass flask, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
**Pečeť** – medailon se znakem živlu (stínová je navíc, v balíčku zatím není).

*oheň*
```text
Studio product photo of ONE round toy wax-seal medallion: a thick disc with a soft wavy edge, embossed in the centre with a simple bold flame symbol, warm orange-red matte vinyl with a glossy off-white rim, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*voda*
```text
Studio product photo of ONE round toy wax-seal medallion: a thick disc with a soft wavy edge, embossed in the centre with a simple bold water drop symbol, ocean blue matte vinyl with a glossy off-white rim, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*led*
```text
Studio product photo of ONE round toy wax-seal medallion: a thick disc with a soft wavy edge, embossed in the centre with a simple bold snowflake symbol, pale icy blue matte vinyl with a glossy off-white rim, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*blesk*
```text
Studio product photo of ONE round toy wax-seal medallion: a thick disc with a soft wavy edge, embossed in the centre with a simple bold lightning bolt symbol, bright yellow matte vinyl with a glossy off-white rim, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*rostlina*
```text
Studio product photo of ONE round toy wax-seal medallion: a thick disc with a soft wavy edge, embossed in the centre with a simple bold leaf symbol, leafy green matte vinyl with a glossy off-white rim, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*kámen*
```text
Studio product photo of ONE round toy wax-seal medallion: a thick disc with a soft wavy edge, embossed in the centre with a simple bold mountain rock symbol, warm grey-brown matte vinyl with a glossy off-white rim, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*stín*
```text
Studio product photo of ONE round toy wax-seal medallion: a thick disc with a soft wavy edge, embossed in the centre with a simple bold crescent moon symbol, deep purple matte vinyl with a glossy off-white rim, collectible designer vinyl toy style, chunky rounded kid-friendly shapes. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
**Události**

*Bouře* · `hazard_storm`
```text
Studio product photo of ONE small collectible designer vinyl toy object: a chubby dark-grey storm cloud with a yellow lightning bolt underneath and three curly wind swirls. Matte soft-touch vinyl with simple painted details, chunky rounded kid-friendly shapes, slightly mischievous but not scary. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*Zemětřesení* · `hazard_earthquake`
```text
Studio product photo of ONE small collectible designer vinyl toy object: a chunk of brown ground split by a zig-zag crack, with three small rocks bouncing above it. Matte soft-touch vinyl with simple painted details, chunky rounded kid-friendly shapes, slightly mischievous but not scary. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*Hlad* · `hazard_hunger`
```text
Studio product photo of ONE small collectible designer vinyl toy object: an empty dinner plate with a fork and a knife and one small bitten bone on it. Matte soft-touch vinyl with simple painted details, chunky rounded kid-friendly shapes, slightly mischievous but not scary. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*Záplava* · `hazard_flood`
```text
Studio product photo of ONE small collectible designer vinyl toy object: a tall curling blue wave with white foam tips. Matte soft-touch vinyl with simple painted details, chunky rounded kid-friendly shapes, slightly mischievous but not scary. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
*Tma* · `hazard_darkness`
```text
Studio product photo of ONE small collectible designer vinyl toy object: a dark purple night cloud covering a small crescent moon, with two tiny glowing eyes peeking out. Matte soft-touch vinyl with simple painted details, chunky rounded kid-friendly shapes, slightly mischievous but not scary. Three-quarter view, soft even studio lighting, faint soft contact shadow, seamless plain light-grey background, centred with empty margin on all sides, nothing cropped, sharp focus, no text.
```
## 5. Qwen-Image-Edit: pohledy pro 3D a opravy

Vstup = vybraný hero obrázek figurky. Kroky 40, `true_cfg_scale` 4.0, negativní prompt mezera.

**E1–E4 Pohledy pro image→3D** (zepředu, zezadu, z boku). Víc pohledů = méně domýšlení zad a boků.
```text
Rotate the camera to show this exact toy figure straight from the front. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. Whole figure in frame, nothing cropped.
```
```text
Rotate the camera to show this exact toy figure straight from behind. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. The back attachment and the tail are fully visible. Whole figure in frame, nothing cropped.
```
```text
Rotate the camera to show this exact toy figure in exact left side profile. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. Whole figure in frame, nothing cropped.
```
```text
Rotate the camera to show this exact toy figure in exact right side profile. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. Whole figure in frame, nothing cropped.
```
**E5 Rozevřená póza** – když se díly překrývají (křídla přes ruce, ocas za nohou). 3D model i řezání na díly
potřebují, aby se nic nedotýkalo.
```text
Keep this exact toy figure and its design. Change only the pose: arms held straight out away from the body, legs apart, tail lifted and pointing away from the legs, wings or back attachment fully open and upright, so that no part touches or hides another part. Same colours, same ball joints, same lighting, same plain light-grey background.
```
**E6 Oprava dílu podle karty** (dva vstupy: 1 = figurka, 2 = karta dílu). Slovo v závorce nahraď: head / body /
arms / legs / tail / back attachment.
```text
Image 1 is a toy figure. Image 2 is a loose toy part. Replace the (head) of the figure in image 1 with the part from image 2, matching its shape and colours exactly and connecting it with a glossy off-white ball joint. Keep every other part of the figure, the pose, the lighting and the background unchanged.
```
**E7 Rozložený pohled** – volitelné: podklad pro 3D po dílech nebo pro animaci skládání.
```text
Show this exact toy figure taken apart into its separate pieces, laid out neatly side by side with clear gaps between them: head, body, two arms, two legs, tail, back attachment. Every piece keeps its colours and its glossy off-white ball-joint peg. Same soft lighting, same plain light-grey background, all pieces fully in frame.
```
**E8 Úklid** – podstavec, text, cizí předmět.
```text
Remove the stand and any text or extra objects. Keep the toy figure exactly as it is, on the same plain light-grey background.
```
**E9 Radostná póza** – volitelný druhý snímek pro 2D verzi předvádění, než bude figurka ve 3D.
```text
Keep this exact toy figure and its design. Change only the pose: a joyful little jump with both arms raised and the mouth open in a happy cheer. Same colours, same ball joints, same lighting, same plain light-grey background, whole figure in frame.
```
## 6. Kulisy

*`reveal_stage`* · 928×1664
```text
Empty toy display stage inside a kids' mad-scientist laboratory at night: a round podium in the centre under a soft warm spotlight, glass incubator tubes with glowing green liquid on the left and right, deep purple walls, rounded cartoonish shapes in collectible vinyl toy style. No characters, no creatures, no text. The middle of the image above the podium is empty space for a figure. Portrait composition, podium in the lower third.
```
*`collection_shelf`* · 928×1664
```text
Empty collector display cabinet seen straight from the front: five rows of small round podiums on dark wooden shelves, each podium lit by a tiny warm lamp, deep purple laboratory wall behind, rounded cartoonish shapes in collectible vinyl toy style. No figures, no creatures, no text. Portrait composition, evenly spaced, symmetrical.
```
*`card_back`* · 1056×1584
```text
Playing card back design, flat front view filling the whole frame: a bubbling green cauldron emblem in the centre, a symmetrical ornamental border made of bones, leaves, gears, feathers and fish scales, deep purple background with lighter purple pattern, bold simple shapes like a printed toy package illustration. No text, no letters.
```
## 7. Kontrola před 3D

Hero obrázek pustit dál jen když:

- [ ] je vidět **všech šest dílů z receptu** a žádný navíc (nejčastější chyba: chybí ocas, křídla splynou s rukama)
- [ ] každý díl odpovídá své kartě tvarem i barvou (jinak E6)
- [ ] v obraze je **jedna** figurka, celá, s okrajem kolem, bez podstavce a bez textu
- [ ] klouby jsou vidět a jsou krémové; díly se nepřekrývají (jinak E5)
- [ ] světlo je měkké, bez ostrých stínů; pozadí jednolité šedé
- [ ] výraz je přátelský – nic, čeho by se šestileté dítě leklo
- [ ] figurka vypadá jako ze stejné řady hraček jako tři pilotní
