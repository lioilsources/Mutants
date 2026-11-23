#!/usr/bin/env python3
"""Importuje vybrané obrázky z Qwen Image do aplikace (PLAN-KOLEKCE §5.6).

Vstup:   složka s výstupy pojmenovanými podle `out` v Prompts/qwen/batch.jsonl
         (figures/<id>/hero.png, cards/<id>.png, backdrops/<name>.png),
         nebo --pick JSON {"<id>": "cesta/k/souboru.png", …} pro výběr ze seedů.
Výstup:  app/assets/figures/<id>/hero.webp    1024², průhledné pozadí
         app/assets/figures/<id>/shadow.webp  černá silueta z alfa kanálu
         app/assets/cards/<id>.webp           512², průhledné pozadí
         app/assets/backdrops/<name>.webp     beze změny pozadí
         + chybějící adresáře doplní do app/pubspec.yaml (flutter: assets:)

Pozadí: leží-li vedle obrázku `<jméno>.rgba.png` (výřez z BiRefNet), použije se ten.
Jinak výchozí `flood` zaplaví šedé studiové pozadí od okrajů a sleduje jeho
přechod i měkký stín pod nohama (jen PIL, ~1 s na obrázek). `--remover rembg` použije rembg, je-li
nainstalovaný (`pip install rembg`), hodí se na obrázky s nečistým pozadím.

Spuštění z kořene repa:
  python3 Prompts/qwen/import_art.py run/qwen/out
  python3 Prompts/qwen/import_art.py run/qwen/pilot --pick run/qwen/pilot-pick.json
  python3 Prompts/qwen/import_art.py run/qwen/out --pick-seed 1   # <id>_s1.png ke všem
  python3 Prompts/qwen/import_art.py run/qwen/out --only figure --dry-run
"""

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
BATCH = ROOT / "Prompts/qwen/batch.jsonl"
APP = ROOT / "app"


def load_batch():
    rows = [json.loads(line) for line in BATCH.read_text(encoding="utf-8").splitlines() if line.strip()]
    return {r["id"] if r["group"] != "backdrop" else Path(r["out"]).stem: r for r in rows}


def remove_flood(img: Image.Image, thresh: int) -> Image.Image:
    """Alpha from a background fill that starts at the border and follows the
    grey studio backdrop through its vignette and the soft floor shadow.

    A pixel joins the background when it is greyish (low saturation), not
    darker than the backdrop allows, and close in colour to the neighbour it
    was reached from. Works on a reduced copy; the mask is scaled back up.
    """
    rgb = img.convert("RGB")
    w, h = rgb.size
    scale = min(1.0, 640 / max(w, h))
    sw, sh = max(1, round(w * scale)), max(1, round(h * scale))
    small = rgb.resize((sw, sh), Image.BILINEAR)
    px = small.load()
    step_tol = max(4, thresh // 3)

    stack = []
    for x in range(sw):
        stack += [(x, 0), (x, sh - 1)]
    for y in range(sh):
        stack += [(0, y), (sw - 1, y)]
    # The backdrop is never brighter than its brightest border (+ a little):
    # white ball joints and highlights stay on the figure.
    border = sorted(max(px[x, y]) for x, y in stack)
    ceiling = border[int(len(border) * 0.98)] + 4

    def greyish(c):
        return max(c) - min(c) <= 22 and min(c) >= 120 and max(c) <= ceiling

    bg = bytearray(sw * sh)
    for x, y in stack:
        if greyish(px[x, y]):
            bg[y * sw + x] = 1
    stack = [(x, y) for x, y in stack if bg[y * sw + x]]
    while stack:
        x, y = stack.pop()
        c = px[x, y]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < sw and 0 <= ny < sh and not bg[ny * sw + nx]:
                n = px[nx, ny]
                if greyish(n) and max(abs(n[0] - c[0]), abs(n[1] - c[1]), abs(n[2] - c[2])) <= step_tol:
                    bg[ny * sw + nx] = 1
                    stack.append((nx, ny))
    mask = Image.frombytes("L", (sw, sh), bytes(0 if v else 255 for v in bg))
    # Close pin holes, scale up, feather the edge.
    mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    mask = mask.resize((w, h), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))
    mask = mask.point(lambda v: 0 if v < 40 else (255 if v > 215 else v))
    out = rgb.convert("RGBA")
    out.putalpha(mask)
    return out


def remove_rembg(img: Image.Image) -> Image.Image:
    try:
        from rembg import remove  # type: ignore
    except ImportError:
        sys.exit("rembg není nainstalovaný: pip install rembg (nebo --remover flood)")
    return remove(img.convert("RGBA"))


def fit_square(img: Image.Image, size: int, margin: float) -> Image.Image:
    """Crop to the alpha bounding box and centre it on a transparent square."""
    box = img.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    if box is None:
        raise ValueError("po odstranění pozadí nic nezbylo")
    img = img.crop(box)
    inner = round(size * (1 - 2 * margin))
    scale = inner / max(img.size)
    img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(img, ((size - img.width) // 2, (size - img.height) // 2))
    return canvas


def shadow_of(img: Image.Image) -> Image.Image:
    black = Image.new("RGBA", img.size, (14, 10, 26, 255))
    black.putalpha(img.getchannel("A"))
    return black


def ensure_pubspec(dirs):
    """Adds asset directories missing from app/pubspec.yaml under flutter: assets:."""
    path = APP / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    missing = [d for d in sorted(dirs) if f"    - {d}\n" not in text]
    if not missing:
        return []
    lines = text.splitlines(keepends=True)
    if "  assets:\n" not in text:
        i = lines.index("flutter:\n") + 1
        lines.insert(i, "  assets:\n")
    i = lines.index("  assets:\n") + 1
    while i < len(lines) and lines[i].startswith("    - "):
        i += 1
    lines[i:i] = [f"    - {d}\n" for d in missing]
    path.write_text("".join(lines), encoding="utf-8")
    return missing


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", type=Path, help="složka s výstupy Qwenu")
    ap.add_argument("--pick", type=Path, help='JSON {"id": "soubor.png"} – vybraný seed ke každému id')
    ap.add_argument("--pick-seed", type=int, help="ke každému id bez výběru vezmi <id>_s<seed>.png")
    ap.add_argument("--only", choices=["figure", "card", "joker", "seal", "hazard", "backdrop"], action="append")
    ap.add_argument("--remover", choices=["flood", "rembg"], default="flood")
    ap.add_argument("--thresh", type=int, default=18, help="tolerance kroku zaplavení pozadí (flood)")
    ap.add_argument("--quality", type=int, default=86, help="kvalita webp")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    batch = load_batch()
    picks = json.loads(args.pick.read_text(encoding="utf-8")) if args.pick else {}
    if args.pick_seed is not None:
        # Flat output of a seed batch: <id>_s<seed>.png; explicit picks win.
        picks = {key: f"{key}_s{args.pick_seed}.png" for key in batch} | picks
    dirs, done, missing, failed = set(), 0, [], []

    for key, row in batch.items():
        group = row["group"]
        if args.only and group not in args.only:
            continue
        if picks:
            if key not in picks:
                continue
            src = (args.src / picks[key]) if not Path(picks[key]).is_absolute() else Path(picks[key])
        else:
            src = args.src / row["out"]
            if not src.exists():
                src = src.with_suffix(".webp") if src.with_suffix(".webp").exists() else src
        if not src.exists():
            missing.append(key)
            continue

        if group == "figure":
            dest_dir = f"assets/figures/{key}/"
            targets = [(APP / dest_dir / "hero.webp", 1024)]
        elif group == "backdrop":
            dest_dir = "assets/backdrops/"
            targets = [(APP / dest_dir / f"{key}.webp", None)]
        else:
            dest_dir = "assets/cards/"
            targets = [(APP / dest_dir / f"{key}.webp", 512)]
        print(f"{key:24} {src.relative_to(ROOT) if src.is_relative_to(ROOT) else src} → {dest_dir}")
        if args.dry_run:
            continue
        try:
            img = Image.open(src)
            if group == "backdrop":
                out = img.convert("RGB")
                out.thumbnail((928, 1664), Image.LANCZOS)
            else:
                cutout = src.with_name(src.stem + ".rgba.png")
                if cutout.exists():
                    # BiRefNet cutout made next to the generation (L40S ComfyUI-RMBG).
                    cut = Image.open(cutout).convert("RGBA")
                elif args.remover == "rembg":
                    cut = remove_rembg(img)
                else:
                    cut = remove_flood(img, args.thresh)
                out = fit_square(cut, targets[0][1], 0.04 if group == "figure" else 0.06)
            targets[0][0].parent.mkdir(parents=True, exist_ok=True)
            out.save(targets[0][0], "WEBP", quality=args.quality, method=6)
            if group == "figure":
                shadow_of(out).save(targets[0][0].parent / "shadow.webp", "WEBP", quality=80, method=6)
            dirs.add(dest_dir)
            done += 1
        except Exception as e:  # report and go on with the rest
            failed.append(f"{key}: {e}")

    added = [] if args.dry_run else ensure_pubspec(dirs)
    print(f"\nhotovo {done}, chybí {len(missing)}, selhalo {len(failed)}")
    if added:
        print("do app/pubspec.yaml přidáno: " + ", ".join(added))
    for f in failed:
        print("  ! " + f)
    if missing and not picks:
        print("  chybí: " + ", ".join(missing[:20]) + (" …" if len(missing) > 20 else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
