#!/usr/bin/env python3
"""Sestaví prompty pro rozpohybování figurek ve Wan a LTX (obrázek → video).

Vstupy:  mutant_core/assets/cards.json, collection.json, moves.json
         Prompts/video/motion.json          anglický popis každého pohybu, zvuk, společné bloky
Výstupy: Prompts/03-WAN_LTX_ANIMACE.md      čitelný dokument + srovnávací protokol
         Prompts/video/batch_wan.jsonl      jeden řádek = jeden klip (všech 28 figurek × 9 klipů)
         Prompts/video/batch_ltx.jsonl
         Prompts/video/srovnani.csv         prázdná hodnoticí tabulka pro pilot

Spuštění z kořene repa:  python3 Prompts/video/build_video_prompts.py
"""

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SLOTS = ["head", "torso", "front", "back", "tail", "extra"]
CLIPS = ["idle", "assemble"] + [f"show_{s}" for s in SLOTS] + ["cheer"]
PILOT_MUTANTS = ["zralomedved", "drakobot"]
PILOT_CLIPS = ["idle", "assemble"] + [f"show_{s}" for s in SLOTS]
PILOT_CONFIGS = ["wan-lightning", "ltx-distilled"]
PILOT_SEEDS = [1, 2]


def load(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


cards_doc = load("mutant_core/assets/cards.json")
CARDS = {c["id"]: c for c in cards_doc["cards"]}
SLOT_CS = cards_doc["labels"]["slot"]
MUTANTS = {m["id"]: m for m in load("mutant_core/assets/collection.json")["mutants"]}
MOVES = load("mutant_core/assets/moves.json")["parts"]
M = load("Prompts/video/motion.json")


def clip_info(mutant, clip):
    """Co se v klipu děje: pohyb, zvuk, rozsah, český titulek, druh (délka klipu)."""
    if clip.startswith("show_"):
        part = mutant["parts"][clip[5:]]
        move = M["moves"][MOVES[part]["move"]]
        motion = move["motion"].format(part=M["part_noun"][part])
        if part in M["part_fx"]:
            motion += " " + M["part_fx"][part]
        return {
            "motion": motion,
            "sound": move["sound"],
            "scope": M["scope"][move["scope"]],
            "label": f"{MOVES[part]['label']} ({CARDS[part]['name']})",
            "move": MOVES[part]["move"],
            "kind": "move",
        }
    c = M["clips"][clip]
    return {"motion": c["motion"], "sound": c["sound"], "scope": "", "label": c["label"], "move": clip, "kind": c["kind"]}


def join(*parts):
    return " ".join(p for p in parts if p)


def blocks(model, kind):
    """Úvod, věta o tuhých dílech a zámek kamery; sestava začíná rozloženými díly, proto má vlastní."""
    suffix = "_assemble" if kind == "assemble" else ""
    return M[model]["intro" + suffix], M["rigid" + suffix], M[model]["lock" + suffix]


def wan_prompt(mutant, clip):
    i = clip_info(mutant, clip)
    intro, rigid, lock = blocks("wan", i["kind"])
    return join(intro, i["motion"], i["scope"], rigid, lock)


def ltx_prompt(mutant, clip):
    i = clip_info(mutant, clip)
    intro, rigid, lock = blocks("ltx", i["kind"])
    return join(intro, i["motion"], i["scope"], rigid, lock, M["ltx"]["audio"].format(sound=i["sound"]))


def frames_in(mutant, clip):
    hero = f"figures/{mutant['id']}/hero.png"
    first = f"figures/{mutant['id']}/exploded.png" if clip == "assemble" else hero
    return first, hero


def batch(model, prompt_fn):
    s = M["settings"][model]
    rows = []
    for m in MUTANTS.values():
        for clip in CLIPS:
            kind = clip_info(m, clip)["kind"]
            first, last = frames_in(m, clip)
            rows.append(
                {
                    "id": f"{m['id']}/{clip}",
                    "mutant": m["id"],
                    "clip": clip,
                    "first_frame": first,
                    "last_frame": last,
                    "out": f"figures/{m['id']}/clips/{clip}.mp4",
                    "width": s["width"],
                    "height": s["height"],
                    "frames": s["frames"][kind],
                    "fps": s["fps"],
                    "prompt": prompt_fn(m, clip),
                    "negative": M[model]["negative"],
                }
            )
    return rows


def code(text):
    return f"```text\n{text}\n```"


def markdown():
    out = []
    w = out.append
    sw, sl = M["settings"]["wan"], M["settings"]["ltx"]

    w("# Prompty pro Wan a LTX — animace figurek a jejich srovnání")
    w("")
    w("> Generováno skriptem `Prompts/video/build_video_prompts.py` ze sbírky, `moves.json` a")
    w("> `Prompts/video/motion.json`. **Needituj ručně** – uprav `motion.json` a spusť skript znovu.")
    w("> Prompty pro všech 28 figurek × 9 klipů jsou v `Prompts/video/batch_wan.jsonl` a `batch_ltx.jsonl`.")
    w("")
    w("## 0. Co to řeší")
    w("")
    w("Figurku jde rozpohybovat i bez 3D: videomodel dostane hotový hero obrázek (z")
    w("[`02-QWEN_IMAGE_PROMPTS.md`](02-QWEN_IMAGE_PROMPTS.md)) a udělá z něj krátký klip, ve kterém figurka")
    w("předvede pohyb jednoho svého dílu. Tenhle dokument dává stejné zadání dvěma modelům – **Wan** a **LTX** –")
    w("a v §6 popisuje, jak jejich animace férově porovnat. Klipy se jmenují stejně jako klipy 3D figurky")
    w("(`idle`, `assemble`, `show_<slot>`, `cheer`), takže hra může hrát video i GLB stejným kódem")
    w("(viz [`01-PLAN_KOLEKCE.md`](01-PLAN_KOLEKCE.md) §6.5).")
    w("")
    w("Žádný klip jsem negeneroval. Čísla nastavení jsou z oficiálních repozitářů a dokumentace; která")
    w("animace vyjde líp, ukáže až pilot z §6. Očekávání v §6.4 jsou hypotézy k ověření, ne výsledky.")
    w("")
    w("**Které verze.** Poslední Wan s otevřenými vahami je **Wan 2.2** (Apache 2.0); novější řady jsou podle")
    w("dostupných zpráv jen přes API. U LTX uvádí repozitář Lightricks jako aktuální **LTX-2.5** (váhy pod")
    w("licencí „LTX-2.x Community License\" – před vydáním hry si ji přečti, není to Apache).")
    w("")
    w("## 1. Vstupní obrázky")
    w("")
    w("- **Hero obrázek figurky** zmenšený na čtverec " + f"{sw['width']}×{sw['height']}" + ", na jednolitém šedém pozadí.")
    w("- **První i poslední snímek klipu = tentýž hero obrázek.** Oba modely umí podmínit začátek i konec.")
    w("  Figurka se tak vždy vrátí do výchozí pózy a klipy jdou řadit za sebe bez cuknutí")
    w("  (klid → pohyb → klid).")
    w("- **`assemble`** je výjimka: první snímek je rozložený pohled (`exploded.png`, úprava E7 v dokumentu")
    w("  pro Qwen), poslední je hero. Díly se slétnou do figurky.")
    w("- Jeden klip = **jeden pohyb**. Oficiální návod LTX výslovně říká, že víc akcí v promptu znamená,")
    w("  že se některé neobjeví.")
    w("")
    w("## 2. Nastavení")
    w("")
    w("| | Wan 2.2 I2V-A14B | LTX-2.5 |")
    w("|---|---|---|")
    w("| první + poslední snímek | ComfyUI uzel `WanFirstLastFrameToVideo` (modely I2V 14B high/low noise) | podmínky na snímku 0 a −1 (`LTX2VideoCondition` v diffusers; v ComfyUI šablona s klíčovými snímky) |")
    w(f"| rozlišení | {sw['width']}×{sw['height']} (násobky 16) | {sl['width']}×{sl['height']} (násobky 64 pro dvoustupňové generování) |")
    w(f"| snímky – pohyb, sestava | **{sw['frames']['move']}** (tvar 4n+1) ≈ 3 s | **{sl['frames']['move']}** (tvar 8n+1) ≈ 3 s |")
    w(f"| snímky – klid | **{sw['frames']['idle']}** ≈ 4 s | **{sl['frames']['idle']}** ≈ 4 s |")
    w(f"| fps | {sw['fps']} | {sl['fps']} |")
    w("| kvalitní běh | 40 kroků, CFG 3,5, shift 5,0 | plný model: 30 kroků, guidance 3,0 |")
    w("| rychlý běh | Lightning LoRA: 4 kroky, CFG 1 | distilovaný model: 8 kroků, guidance 1 |")
    w("| zvuk | ne | ano, vzniká spolu s obrazem |")
    w("")
    w("- Výchozí délka Wanu je 81 snímků, LTX 121. Kratší klipy jsou tu schválně: pohyb má být svižný a")
    w("  soubor malý. Když model pohyb na 3 s nestihne, vrať se k výchozí délce.")
    w("- **Při CFG / guidance 1 se negativní prompt nepoužije** (Lightning LoRA i distilovaný LTX). Všechna")
    w("  omezení proto musí být v kladném promptu – a jsou.")
    w("- U LTX obrázková podmínka podle dokumentace drží obraz nehybný zhruba 8 snímků. Na začátku a konci")
    w("  klipu to nevadí, je to přirozená pauza.")
    w("- Wan má i menší model TI2V-5B (704×1280, 24 fps), podle ComfyUI se vejde do 8 GB VRAM. Není čtvercový,")
    w("  proto není v hlavním srovnání; hodí se jako nouzová varianta na slabší kartu.")
    w("- 16 fps Wanu vypadá trochu jako stop-motion, což k hračkám sedí. Na 32 fps jde dopočítat interpolací.")
    w("")
    w("## 3. Stavba promptu")
    w("")
    w("U obrázek→video se **nepopisuje vzhled** – ten nese obrázek. Popisuje se jen pohyb, co zůstává")
    w("v klidu, kamera a (u LTX) zvuk. Díl se jmenuje krátce („shark head\"), aby model věděl, čím hýbat.")
    w("")
    w("**Wan** – jedna úvodní věta a hned pohyb, krátké věty:")
    w(code(join(M["wan"]["intro"], "{pohyb}", "{rozsah}", M["rigid"], M["wan"]["lock"])))
    w("**LTX** – podle oficiálního návodu: nejdřív záběr a scéna, pak děj popořadě v přítomném čase,")
    w("kamera, nakonec zvuk; jeden odstavec, 4–8 vět:")
    w(code(join(M["ltx"]["intro"], "{pohyb}", "{rozsah}", M["rigid"], M["ltx"]["lock"], M["ltx"]["audio"].format(sound="{zvuk}"))))
    w("`{rozsah}` říká, jestli se hýbe jen díl, nebo celá figurka:")
    w("")
    w(f"- díl: `{M['scope']['part']}`")
    w(f"- celé tělo: `{M['scope']['body']}`")
    w("")
    w("**Negativní prompt – Wan** (jen pro běh se CFG > 1). Vychází z výchozího v repozitáři Wan 2.2, ale")
    w("bez „整体发灰\" („celkově zašedlé\" – naše pozadí je šedé schválně) a bez položek o prstech a davu;")
    w("přidán je pohyb kamery, zoom, deformace, tavení, končetiny a hlavy navíc, nové předměty a text:")
    w(code(M["wan"]["negative"]))
    w("Pro porovnání výchozí negativní prompt z `wan/configs/shared_config.py`:")
    w(code(M["wan"]["negative_default"]))
    w("**Negativní prompt – LTX** (jen pro plný model):")
    w(code(M["ltx"]["negative"]))
    w("")
    w("## 4. Pohybový slovník")
    w("")
    w("Každý díl má pohyb (`mutant_core/assets/moves.json`). `{part}` se nahradí krátkým názvem dílu.")
    w("")
    w("| pohyb | rozsah | co se děje (EN) | zvuk pro LTX (EN) |")
    w("|---|---|---|---|")
    for name, mv in M["moves"].items():
        w(f"| `{name}` | {'tělo' if mv['scope'] == 'body' else 'díl'} | {mv['motion']} | {mv['sound']} |")
    for name, c in M["clips"].items():
        w(f"| `{name}` | – | {c['motion']} | {c['sound']} |")
    w("")
    w("Doplňky u konkrétních dílů (přidají se za popis pohybu):")
    w("")
    for part, fx in M["part_fx"].items():
        w(f"- `{part}` ({CARDS[part]['name']}): {fx}")
    w("")
    w("## 5. Pilot: plné prompty")
    w("")
    w(f"Dvě figurky × {len(PILOT_CLIPS)} klipů. Pokrývají čelist, náklon těla, obě ruce, výskok, jízdu tam a zpět,")
    w("ocas, křídla, kouř a skládání z dílů.")
    w("")
    for mid in PILOT_MUTANTS:
        m = MUTANTS[mid]
        w(f"### {m['name']} · `{mid}`")
        w("")
        for clip in PILOT_CLIPS:
            i = clip_info(m, clip)
            first, last = frames_in(m, clip)
            frames = f"{sw['frames'][i['kind']]} / {sl['frames'][i['kind']]} snímků"
            w(f"#### `{clip}` — {i['label']}")
            w("")
            w(f"první snímek `{first}` · poslední `{last}` · Wan / LTX: {frames}")
            w("")
            w("Wan")
            w(code(wan_prompt(m, clip)))
            w("LTX")
            w(code(ltx_prompt(m, clip)))
            w("")
    w("## 6. Srovnání animací")
    w("")
    w("### 6.1 Co se pouští")
    w("")
    n = len(PILOT_MUTANTS) * len(PILOT_CLIPS) * len(PILOT_CONFIGS) * len(PILOT_SEEDS)
    w(f"**Rychlé kolo** – {len(PILOT_MUTANTS)} figurky × {len(PILOT_CLIPS)} klipů × 2 konfigurace × {len(PILOT_SEEDS)} seedy = **{n} klipů**:")
    w("")
    w("- `wan-lightning`: Wan 2.2 I2V-A14B + Lightning LoRA, 4 kroky")
    w("- `ltx-distilled`: LTX-2.5 distilovaný, 8 kroků")
    w("")
    w("Stejný hero obrázek, stejné rozlišení, stejné seedy (1 a 2), prompty beze změny z §5.")
    w("")
    w("**Kvalitní kolo** – jen klipy, které v rychlém kole u obou modelů propadly: Wan na 40 kroků, LTX plný")
    w("model. Odpoví na otázku, jestli je chyba v modelu, nebo v destilaci.")
    w("")
    w("### 6.2 Jak se hodnotí")
    w("")
    w("Každý klip dostane 0 / 1 / 2 (0 = nepoužitelné, 1 = s výhradou, 2 = dobré). Tabulka je připravená")
    w("v `Prompts/video/srovnani.csv`.")
    w("")
    w("| sloupec | otázka | brána |")
    w("|---|---|---|")
    w("| `identita` | Drží díly tvar a barvu po celý klip? Nic neteče, nepřebarvuje se, nepřibývá? | 0 = klip vyřazen |")
    w("| `smycka` | Je poslední snímek stejný jako první, takže klip naváže na `idle`? | 0 = klip vyřazen |")
    w("| `pohyb_ok` | Hýbe se to, co má, a je z toho poznat titulek („Zařve\")? | |")
    w("| `hrackovost` | Otáčejí se díly v kloubech, nebo se ohýbají jako guma? | |")
    w("| `kamera` | Stojí kamera i pozadí? | |")
    w("| `citelnost` | Je pohyb výrazný a vtipný i na displeji telefonu? | |")
    w("| `zvuk` | Jen LTX: sedí zvuk na pohyb? Do součtu se nepočítá. | |")
    w("| `cas_s` | Kolik sekund trvalo vygenerování. | |")
    w("| `pouzitelny` | 1, když klip prošel oběma branami a má součet aspoň 8 z 12. | |")
    w("")
    w("Hodnoť naslepo, pokud to jde: přejmenuj soubory na čísla a konfiguraci si odkryj až po zapsání bodů.")
    w("")
    w("### 6.3 Co z toho vypadne")
    w("")
    w("Pro každou konfiguraci tři čísla:")
    w("")
    w("1. **Výtěžnost** – podíl použitelných klipů (kolik seedů je potřeba na jeden dobrý klip).")
    w("2. **Cena použitelného klipu** – průměrný čas na klip ÷ výtěžnost. Tohle číslo rozhoduje, protože celá")
    w("   sbírka je 28 × 9 = 252 klipů.")
    w("3. **Průměrné body podle typu pohybu** – díl (čelist, ruce, ocas, křídla) vs. celé tělo (výskok, jízda,")
    w("   schování) vs. `idle` vs. `assemble`.")
    w("")
    w("Rozhodnutí: vyhrává konfigurace s nižší cenou použitelného klipu, pokud má průměrný součet (z 12) nejvýš")
    w("o 1 bod horší.")
    w("Když každý model vyhraje jiný typ pohybu, dá se míchat – klipy jsou samostatné soubory. Míchat má smysl")
    w("jen tehdy, když figurka v obou vypadá stejně (stejný hero obrázek to z velké části zaručí).")
    w("Když propadne `assemble` u obou, zůstane sestava ve hře 2D animací karet a video se použije jen na pohyby.")
    w("")
    w("### 6.4 Co čekat (hypotézy k ověření)")
    w("")
    w("| | Wan 2.2 | LTX-2.5 |")
    w("|---|---|---|")
    w("| výskok, rychlý pohyb celého těla (`hop`, `cheer`) | bez známého omezení | oficiální návod uvádí skákání a rychlé kroucení jako zdroj artefaktů |")
    w("| malý pohyb jednoho dílu | negativní prompt obsahuje „statický obraz\" (platí jen při CFG > 1) – může hýbat i tím, co má stát | návod uvádí jemná gesta jednoho subjektu jako silnou stránku (píše o lidech; u hračky ověřit) |")
    w("| šedé pozadí | výchozí negativní prompt obsahuje „zašedlé\" – proto je tu upravený | bez známého omezení |")
    w("| rychlost | jeden návod uvádí pro první+poslední snímek asi 26 min bez LoRA a 3 min s Lightning LoRA na RTX 4090 | distilovaný model na 8 kroků; změřit |")
    w("| zvuk k pohybu | není | ano – ušetří samostatnou výrobu zvuků |")
    w("| licence vah | Apache 2.0 | LTX-2.x Community License |")
    w("")
    w("## 7. Z klipu do hry")
    w("")
    w("- Klip je čtverec s neprůhledným šedým pozadím. Nejjednodušší je hrát ho v kulatém „okně inkubátoru\"")
    w("  s měkkým okrajem – pak průhlednost není potřeba a stačí běžné H.264 MP4.")
    w("- Má-li figurka stát volně nad pozadím hry, musí se z každého snímku odstranit pozadí a klip uložit")
    w("  jako sekvence s průhledností (animovaný WebP). Je to větší a pracnější; rozhodnout až po pilotu.")
    w("- Rozpočet: do 300 kB na klip, tedy zhruba 75 MB na celou sbírku. Zvuk z LTX uložit zvlášť.")
    w("- Formát, názvy souborů a přehrávání popisuje `01-PLAN_KOLEKCE.md` §6.5.")
    w("")
    return "\n".join(out)


def score_sheet():
    rows = []
    for mid in PILOT_MUTANTS:
        for clip in PILOT_CLIPS:
            move = clip_info(MUTANTS[mid], clip)["move"]
            for config in PILOT_CONFIGS:
                for seed in PILOT_SEEDS:
                    rows.append([mid, clip, move, config, seed] + [""] * 10)
    return rows


def main():
    for name, fn in (("wan", wan_prompt), ("ltx", ltx_prompt)):
        rows = batch(name, fn)
        (ROOT / f"Prompts/video/batch_{name}.jsonl").write_text(
            "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8"
        )
        longest = max(len(r["prompt"].split()) for r in rows)
        print(f"batch_{name}.jsonl: {len(rows)} klipů, nejdelší prompt {longest} slov")
    with open(ROOT / "Prompts/video/srovnani.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["figurka", "klip", "pohyb", "konfigurace", "seed", "identita", "smycka", "pohyb_ok", "hrackovost",
             "kamera", "citelnost", "zvuk", "cas_s", "pouzitelny", "poznamka"]
        )
        writer.writerows(score_sheet())
    (ROOT / "Prompts/03-WAN_LTX_ANIMACE.md").write_text(markdown(), encoding="utf-8")


if __name__ == "__main__":
    main()
