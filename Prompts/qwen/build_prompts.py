#!/usr/bin/env python3
"""Sestaví prompty pro Qwen Image ze sbírky mutantů.

Vstupy:  mutant_core/assets/cards.json       karty (slot, tagy, české názvy)
         mutant_core/assets/collection.json  recepty 28 mutantů
         Prompts/qwen/bible.json             styl + anglický vzhled každého dílu
Výstupy: Prompts/02-QWEN_IMAGE_PROMPTS.md    čitelný dokument
         Prompts/qwen/batch.jsonl            jeden řádek = jeden obrázek (pro dávku v ComfyUI/API)

Spuštění z kořene repa:  python3 Prompts/qwen/build_prompts.py
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SLOTS = ["head", "torso", "front", "back", "tail", "extra"]
SQUARE = (1328, 1328)

cards_doc = json.loads((ROOT / "mutant_core/assets/cards.json").read_text(encoding="utf-8"))
CARDS = {c["id"]: c for c in cards_doc["cards"]}
SLOT_CS = cards_doc["labels"]["slot"]
ELEMENT_CS = cards_doc["labels"]["element"]
ORIGIN_CS = cards_doc["labels"]["origin"]
MUTANTS = json.loads((ROOT / "mutant_core/assets/collection.json").read_text(encoding="utf-8"))["mutants"]
BIBLE = json.loads((ROOT / "Prompts/qwen/bible.json").read_text(encoding="utf-8"))
STYLE = BIBLE["style"]
LOOK = BIBLE["parts"]


def check():
    """Recepty a bible musí sedět na karty, jinak by prompt lhal."""
    problems = []
    for m in MUTANTS:
        for slot in SLOTS:
            pid = m["parts"].get(slot)
            if pid not in CARDS:
                problems.append(f"{m['id']}: neznámá karta {pid}")
            elif CARDS[pid]["slot"] != slot:
                problems.append(f"{m['id']}: {pid} nepatří do slotu {slot}")
            elif pid not in LOOK:
                problems.append(f"bible.json: chybí vzhled pro {pid}")
    used = {p for m in MUTANTS for p in m["parts"].values()}
    for c in CARDS.values():
        if c["kind"] == "part" and c["id"] not in used:
            problems.append(f"karta {c['id']} není v žádném receptu")
    if problems:
        sys.exit("\n".join(problems))


def is_wings(pid):
    return "wings" in CARDS[pid].get("tags", [])


def figure_prompt(m, pose=None):
    p = m["parts"]
    extra_pose = STYLE["extra_pose_wings"] if is_wings(p["extra"]) else STYLE["extra_pose_single"]
    return "\n".join(
        [
            STYLE["figure_intro"],
            pose or STYLE["pose"],
            f"Head: {LOOK[p['head']]}.",
            f"Body: {LOOK[p['torso']]}.",
            f"Arms (front limbs): {LOOK[p['front']]}.",
            f"Legs (hind limbs): {LOOK[p['back']]}.",
            f"Tail: {LOOK[p['tail']]}{STYLE['tail_pose']}.",
            f"On its back: {LOOK[p['extra']]}{extra_pose}.",
            STYLE["material"],
            STYLE["framing"],
        ]
    )


def card_prompt(pid):
    slot = CARDS[pid]["slot"]
    joint = BIBLE["joints"][slot]
    if slot == "extra" and is_wings(pid):
        joint = "The left and right pieces are joined in the middle by a small glossy off-white ball-joint mount."
    return f"{STYLE['card_intro']} {LOOK[pid]}. {joint} {STYLE['card_material']} {STYLE['card_framing']}"


def joker_prompt(slot):
    j = BIBLE["jokers"]
    return f"{j['_template'].format(shape=j[slot])} {STYLE['card_framing']}"


def seal_prompt(element):
    s = BIBLE["seals"]
    emblem, colour = s[element]
    return f"{s['_template'].format(emblem=emblem, colour=colour)} {STYLE['card_framing']}"


def hazard_prompt(hid):
    h = BIBLE["hazards"]
    return f"{h['_template'].format(object=h[hid])} {STYLE['card_framing']}"


def batch_rows():
    rows = []

    def add(group, ident, out, size, prompt):
        neg = {"figure": "negative", "backdrop": "negative_backdrop"}.get(group, "negative_object")
        rows.append(
            {
                "id": ident,
                "group": group,
                "out": out,
                "width": size[0],
                "height": size[1],
                "prompt": prompt,
                "negative": STYLE[neg],
            }
        )

    for m in MUTANTS:
        add("figure", m["id"], f"figures/{m['id']}/hero.png", SQUARE, figure_prompt(m))
    for c in CARDS.values():
        if c["kind"] == "part":
            add("card", c["id"], f"cards/{c['id']}.png", SQUARE, card_prompt(c["id"]))
        elif c["kind"] == "mutation":
            add("joker", c["id"], f"cards/{c['id']}.png", SQUARE, joker_prompt(c["slot"]))
        elif c["kind"] == "seal":
            add("seal", c["id"], f"cards/{c['id']}.png", SQUARE, seal_prompt(c["element"]))
        elif c["kind"] == "hazard":
            add("hazard", c["id"], f"cards/{c['id']}.png", SQUARE, hazard_prompt(c["id"]))
    for name, b in BIBLE["backdrops"].items():
        add("backdrop", name, f"backdrops/{name}.png", tuple(b["size"]), b["prompt"])
    return rows


def code(text):
    return f"```text\n{text}\n```"


def markdown():
    out = []
    w = out.append
    pure = [m for m in MUTANTS if len(m["origins"]) == 1]
    hybrid = [m for m in MUTANTS if len(m["origins"]) == 2]
    part_cards = [c for c in CARDS.values() if c["kind"] == "part"]

    w("# Prompty pro Qwen Image — sbírka Mutant")
    w("")
    w("> Generováno skriptem `Prompts/qwen/build_prompts.py` z `collection.json`, `cards.json` a")
    w("> `Prompts/qwen/bible.json`. **Needituj ručně** — uprav `bible.json` (styl, vzhled dílu) a spusť")
    w("> skript znovu. Všechny prompty plně rozepsané jsou i v `Prompts/qwen/batch.jsonl`.")
    w("")
    w(f"Obsah: {len(MUTANTS)} hotových mutantů (figurky) · {len(part_cards)} karet dílů · žolíci, pečeti, události ·")
    w("úpravy v Qwen-Image-Edit (pohledy pro 3D, opravy) · kulisy · kontrola před 3D.")
    w("")
    w("## 0. Jak s tím pracovat")
    w("")
    w("**Model.** Text→obrázek: Qwen-Image (hodnoty níže jsou z karty modelu Qwen-Image-2512, otevřené váhy).")
    w("Úpravy a další pohledy: Qwen-Image-Edit-2511. Prompty nejsou vázané na verzi – fungují i v novějším")
    w("Qwen-Image nebo v Qwen Chatu.")
    w("")
    w("| | Qwen-Image (2512) | Qwen-Image-Edit (2511) |")
    w("|---|---|---|")
    w("| kroky | 50 | 40 |")
    w("| `true_cfg_scale` | 4.0 | 4.0 (`guidance_scale` 1.0) |")
    w("| rozlišení | figurky, karty: **1328×1328** · kulisy: **928×1664** · rub karty: **1056×1584** | podle vstupu |")
    w("| negativní prompt | viz §1 | mezera `\" \"` |")
    w("")
    w("- Piš anglicky a **nedávej do promptu jména mutantů** – model by je zkoušel napsat do obrázku.")
    w("- **Nepouštěj tyhle prompty přes „prompt enhancer / rewrite\"** u text→obrázek: přepíše popis dílů a")
    w("  stejný díl pak vypadá na každé figurce jinak. U Editu naopak oficiální README říká, že bez přepsání")
    w("  bývá výsledek nestabilní – když úprava nedrží, zkus `polish_edit_prompt` z repa Qwen-Image.")
    w("- Každý prompt generuj se **4 seedy**, vyber nejlepší a seed si zapiš vedle souboru.")
    w("- Světle šedé pozadí je schválně: čistě se z něj odstraňuje pozadí (rembg / BiRefNet) a image→3D")
    w("  modely na něm fungují nejlépe.")
    w("")
    w("**Pořadí práce**")
    w("")
    w("1. **Pilot – 3 figurky** (`zralomedved`, `drakobot`, `jelenobrouk`). Laď jen `style` v `bible.json`,")
    w("   dokud nevypadají jako tři kusy ze stejné řady hraček. Pak styl zmraz.")
    w("2. **Karty dílů** (60) – stejným stylem. Tady se rozhoduje, jak který díl vypadá; když se ti díl")
    w("   nelíbí, přepiš jeho větu v `bible.json` → změní se karta i všechny figurky, které ho mají.")
    w("3. **Všech 28 figurek.** Kontrola podle §7; co nesedí, oprav Editem (§5, E6).")
    w("4. **Pohledy pro 3D** (§5, E1–E4) jen pro figurky, které jdou do 3D výroby.")
    w("")
    w("## 1. Styl")
    w("")
    w("Figurky jsou **kloubové sběratelské hračky**: každý díl je vlastní kus plastu a díly se potkávají ve")
    w("viditelném kulovém kloubu. To je odpověď na „merge dílů vypadá špatně\" – žraločí hlava a medvědí tělo")
    w("se neslévají organicky, ale spojuje je kloub jako u skutečné hračky. Stejná krémová barva kloubů sjednocuje")
    w("celou řadu a zároveň ukazuje, kudy figurku rozříznout na pohyblivé díly ve 3D.")
    w("")
    w("Společné bloky (v `bible.json` → `style`):")
    w("")
    w("**Materiál a tvary – figurka**")
    w(code(STYLE["material"]))
    w("**Rám a světlo – figurka**")
    w(code(STYLE["framing"]))
    w("**Póza** (výchozí: vzpřímeně – lépe vyplní displej na výšku a sedí na dvounohý auto-rig)")
    w(code(STYLE["pose"]))
    w("Varianta pro čtyřnohé držení těla (vyměň řádek `Pose:`):")
    w(code(STYLE["pose_quadruped_alt"]))
    w("**Negativní prompt** – figurky")
    w(code(STYLE["negative"]))
    w("Karty dílů, žolíci, pečeti, události (jeden předmět; bez zákazu chybějících končetin, jinak by trup dostal ruce):")
    w(code(STYLE["negative_object"]))
    w("Kulisy:")
    w(code(STYLE["negative_backdrop"]))
    w("Qwen-Image-2512 má v ukázce vlastní čínský negativní prompt; dá se přidat za ten anglický:")
    w(code(STYLE["negative_zh_2512"]))
    w("")
    w("## 2. Hotoví mutanti (figurky)")
    w("")
    w("Šablona – věty dílů se berou doslova z `bible.json`, proto má stejný díl všude stejný popis:")
    w(
        code(
            "\n".join(
                [
                    STYLE["figure_intro"],
                    STYLE["pose"],
                    "Head: {head}.",
                    "Body: {torso}.",
                    "Arms (front limbs): {front}.",
                    "Legs (hind limbs): {back}.",
                    "Tail: {tail}" + STYLE["tail_pose"] + ".",
                    "On its back: {extra}{, spread open to both sides | , upright and clearly visible above the shoulders}.",
                    "<materiál>",
                    "<rám a světlo>",
                ]
            )
        )
    )

    def figure_section(m):
        origins = " × ".join(ORIGIN_CS[o] for o in m["origins"])
        w(f"#### {m['name']} · `{m['id']}` · {origins}")
        w("")
        w(" · ".join(f"{SLOT_CS[s]}: {CARDS[m['parts'][s]]['name']}" for s in SLOTS))
        w("")
        w(code(figure_prompt(m)))
        w("")

    w("")
    w(f"### Prapředci ({len(pure)}) — všech šest dílů z jednoho rodu")
    w("")
    for m in pure:
        figure_section(m)
    w(f"### Kříženci ({len(hybrid)}) — hlava a ruce z prvního rodu, tělo a nohy z druhého")
    w("")
    for m in hybrid:
        figure_section(m)

    w("## 3. Karty dílů")
    w("")
    w("Jeden díl = jeden obrázek 1328×1328, po odstranění pozadí jde do rámečku karty v aplikaci.")
    w("Šablona:")
    w(code(f"{STYLE['card_intro']} {{vzhled dílu}}. {{kloub podle slotu}} {STYLE['card_material']} {STYLE['card_framing']}"))
    w("Věta o kloubu podle slotu:")
    w("")
    for slot in SLOTS:
        w(f"- **{SLOT_CS[slot]}**: `{BIBLE['joints'][slot]}`")
    w("- **křídla** (extra): `The left and right pieces are joined in the middle by a small glossy off-white ball-joint mount.`")
    w("")
    w("Příklad plně rozepsaného promptu (`head_shark`):")
    w(code(card_prompt("head_shark")))
    w("Vzhled jednotlivých dílů (`{vzhled dílu}`); plné prompty všech 60 karet jsou v `batch.jsonl`:")
    w("")
    for slot in SLOTS:
        w(f"**{SLOT_CS[slot].capitalize()}**")
        w("")
        w("| karta | název | živel | vzhled (EN) |")
        w("|---|---|---|---|")
        for c in part_cards:
            if c["slot"] == slot:
                w(f"| `{c['id']}` | {c['name']} | {ELEMENT_CS[c['element']]} | {LOOK[c['id']]} |")
        w("")

    w("## 4. Žolíci, pečeti, události")
    w("")
    w("**Žolík (dřívější Mutace)** – baňka mutagenu, ze které roste tvar podle slotu. Dvě karty stejného")
    w("slotu rozliš jiným seedem.")
    w("")
    for slot in SLOTS:
        w(f"*{SLOT_CS[slot]}*")
        w(code(joker_prompt(slot)))
    w("**Pečeť** – medailon se znakem živlu (stínová je navíc, v balíčku zatím není).")
    w("")
    for element in BIBLE["seals"]:
        if element.startswith("_"):
            continue
        w(f"*{ELEMENT_CS[element]}*")
        w(code(seal_prompt(element)))
    w("**Události**")
    w("")
    for hid in BIBLE["hazards"]:
        if hid.startswith("_"):
            continue
        w(f"*{CARDS[hid]['name']}* · `{hid}`")
        w(code(hazard_prompt(hid)))

    w("## 5. Qwen-Image-Edit: pohledy pro 3D a opravy")
    w("")
    w("Vstup = vybraný hero obrázek figurky. Kroky 40, `true_cfg_scale` 4.0, negativní prompt mezera.")
    w("")
    w("**E1–E4 Pohledy pro image→3D** (zepředu, zezadu, z boku). Víc pohledů = méně domýšlení zad a boků.")
    w(code("Rotate the camera to show this exact toy figure straight from the front. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. Whole figure in frame, nothing cropped."))
    w(code("Rotate the camera to show this exact toy figure straight from behind. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. The back attachment and the tail are fully visible. Whole figure in frame, nothing cropped."))
    w(code("Rotate the camera to show this exact toy figure in exact left side profile. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. Whole figure in frame, nothing cropped."))
    w(code("Rotate the camera to show this exact toy figure in exact right side profile. Same toy, same colours, same proportions, same pose, same ball joints, same soft lighting, same plain light-grey background. Whole figure in frame, nothing cropped."))
    w("**E5 Rozevřená póza** – když se díly překrývají (křídla přes ruce, ocas za nohou). 3D model i řezání na díly")
    w("potřebují, aby se nic nedotýkalo.")
    w(code("Keep this exact toy figure and its design. Change only the pose: arms held straight out away from the body, legs apart, tail lifted and pointing away from the legs, wings or back attachment fully open and upright, so that no part touches or hides another part. Same colours, same ball joints, same lighting, same plain light-grey background."))
    w("**E6 Oprava dílu podle karty** (dva vstupy: 1 = figurka, 2 = karta dílu). Slovo v závorce nahraď: head / body /")
    w("arms / legs / tail / back attachment.")
    w(code("Image 1 is a toy figure. Image 2 is a loose toy part. Replace the (head) of the figure in image 1 with the part from image 2, matching its shape and colours exactly and connecting it with a glossy off-white ball joint. Keep every other part of the figure, the pose, the lighting and the background unchanged."))
    w("**E7 Rozložený pohled** – volitelné: podklad pro 3D po dílech nebo pro animaci skládání.")
    w(code("Show this exact toy figure taken apart into its separate pieces, laid out neatly side by side with clear gaps between them: head, body, two arms, two legs, tail, back attachment. Every piece keeps its colours and its glossy off-white ball-joint peg. Same soft lighting, same plain light-grey background, all pieces fully in frame."))
    w("**E8 Úklid** – podstavec, text, cizí předmět.")
    w(code("Remove the stand and any text or extra objects. Keep the toy figure exactly as it is, on the same plain light-grey background."))
    w("**E9 Radostná póza** – volitelný druhý snímek pro 2D verzi předvádění, než bude figurka ve 3D.")
    w(code("Keep this exact toy figure and its design. Change only the pose: a joyful little jump with both arms raised and the mouth open in a happy cheer. Same colours, same ball joints, same lighting, same plain light-grey background, whole figure in frame."))

    w("## 6. Kulisy")
    w("")
    for name, b in BIBLE["backdrops"].items():
        w(f"*`{name}`* · {b['size'][0]}×{b['size'][1]}")
        w(code(b["prompt"]))

    w("## 7. Kontrola před 3D")
    w("")
    w("Hero obrázek pustit dál jen když:")
    w("")
    w("- [ ] je vidět **všech šest dílů z receptu** a žádný navíc (nejčastější chyba: chybí ocas, křídla splynou s rukama)")
    w("- [ ] každý díl odpovídá své kartě tvarem i barvou (jinak E6)")
    w("- [ ] v obraze je **jedna** figurka, celá, s okrajem kolem, bez podstavce a bez textu")
    w("- [ ] klouby jsou vidět a jsou krémové; díly se nepřekrývají (jinak E5)")
    w("- [ ] světlo je měkké, bez ostrých stínů; pozadí jednolité šedé")
    w("- [ ] výraz je přátelský – nic, čeho by se šestileté dítě leklo")
    w("- [ ] figurka vypadá jako ze stejné řady hraček jako tři pilotní")
    w("")
    return "\n".join(out)


def main():
    check()
    rows = batch_rows()
    (ROOT / "Prompts/qwen/batch.jsonl").write_text(
        "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8"
    )
    (ROOT / "Prompts/02-QWEN_IMAGE_PROMPTS.md").write_text(markdown(), encoding="utf-8")
    groups = {}
    for r in rows:
        groups[r["group"]] = groups.get(r["group"], 0) + 1
    print("batch.jsonl:", ", ".join(f"{k} {v}" for k, v in groups.items()), f"= {len(rows)} obrázků")


if __name__ == "__main__":
    main()
