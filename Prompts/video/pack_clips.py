#!/usr/bin/env python3
"""Zabalí vybrané klipy z Wan / LTX do aplikace (PLAN-KOLEKCE §6.5).

Vstup:   složka s výstupy pojmenovanými podle `out` v Prompts/video/pilot.jsonl
         (<config>/<mutant>/<clip>_s<seed>.mp4) nebo podle batch_*.jsonl
         (figures/<mutant>/clips/<clip>.mp4), případně --pick JSON
         {"<mutant>/<clip>": "cesta/k/klipu.mp4", …}.
Výstup:  app/assets/figures/<mutant>/clips/<clip>.mp4   čtverec, H.264, bez zvuku
         app/assets/figures/<mutant>/clips/<clip>.m4a   zvuk, má-li ho klip (LTX)
         + adresáře doplní do app/pubspec.yaml (flutter: assets:)

Kontroly (klip se zabalí i tak, jen se ohlásí):
  loop    první a poslední snímek se liší víc než --loop-max (kromě `assemble`)
  camera  rámeček obrazu (okraj 6 %) se během klipu hýbe víc než --edge-max
  budget  výsledný soubor má víc než --budget kB

Spuštění z kořene repa (potřebuje ffmpeg a ffprobe):
  python3 Prompts/video/pack_clips.py run/qwen/out/video --check     # jen kontroly, nic nezapíše
  python3 Prompts/video/pack_clips.py run/qwen/out/video --pick Prompts/video/picks.json
"""

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app"
PILOT = ROOT / "Prompts/video/pilot.jsonl"


def run(*cmd):
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout


def has_audio(path: Path) -> bool:
    out = run("ffprobe", "-v", "error", "-select_streams", "a", "-show_entries",
              "stream=index", "-of", "csv=p=0", str(path))
    return bool(out.strip())


def frames(path: Path, tmp: Path, count: int = 12):
    """`count` evenly spaced greyscale 128² frames, first and last included."""
    # Clips are short (≤ ~100 frames): decode all, then sample.
    run("ffmpeg", "-v", "error", "-y", "-i", str(path), "-vf", "scale=128:128",
        str(tmp / "f%04d.png"))
    files = sorted(tmp.glob("f*.png"))
    if not files:
        raise ValueError(f"{path}: žádné snímky")
    idx = sorted({round(i * (len(files) - 1) / (count - 1)) for i in range(count)})
    return [Image.open(files[i]).convert("L") for i in idx]


def diff(a: Image.Image, b: Image.Image) -> float:
    """Mean absolute difference in 0–255."""
    return ImageStat.Stat(ImageChops.difference(a, b)).mean[0]


def edge_motion(shots) -> float:
    """Largest frame-to-first difference measured only on the image border."""
    w, h = shots[0].size
    m = round(w * 0.06)
    mask = Image.new("L", (w, h), 255)
    mask.paste(0, (m, m, w - m, h - m))
    worst = 0.0
    for s in shots[1:]:
        d = ImageChops.difference(shots[0], s)
        worst = max(worst, ImageStat.Stat(d, mask).mean[0])
    return worst


def encode(src: Path, dest: Path, size: int, crf: int):
    dest.parent.mkdir(parents=True, exist_ok=True)
    run("ffmpeg", "-v", "error", "-y", "-i", str(src), "-an",
        "-vf", f"scale={size}:{size}:flags=lanczos,format=yuv420p",
        "-c:v", "libx264", "-preset", "slow", "-crf", str(crf),
        "-profile:v", "high", "-movflags", "+faststart", str(dest))


def ensure_pubspec(dirs):
    path = APP / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    missing = [d for d in sorted(dirs) if f"    - {d}\n" not in text]
    if not missing:
        return []
    lines = text.splitlines(keepends=True)
    i = lines.index("  assets:\n") + 1
    while i < len(lines) and lines[i].startswith("    - "):
        i += 1
    lines[i:i] = [f"    - {d}\n" for d in missing]
    path.write_text("".join(lines), encoding="utf-8")
    return missing


def sources(src: Path, pick: dict):
    """(mutant, clip, path) for every clip to pack."""
    if pick:
        for key, rel in pick.items():
            mutant, clip = key.split("/")
            p = Path(rel)
            yield mutant, clip, p if p.is_absolute() else src / p
        return
    for p in sorted(src.rglob("*.mp4")):
        parts = p.relative_to(src).parts
        if len(parts) >= 3 and parts[-2] == "clips":  # figures/<m>/clips/<c>.mp4
            yield parts[-3], p.stem, p
        elif len(parts) >= 2:  # <config>/<m>/<clip>_s<seed>.mp4
            yield parts[-2], p.stem.rsplit("_s", 1)[0], p


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", type=Path, help="složka s klipy")
    ap.add_argument("--pick", type=Path, help='JSON {"mutant/clip": "soubor.mp4"}')
    ap.add_argument("--check", action="store_true", help="jen kontroly všech klipů ve složce, nic nezapíše")
    ap.add_argument("--size", type=int, default=512, help="strana čtverce v px (512–768)")
    ap.add_argument("--crf", type=int, default=28)
    ap.add_argument("--budget", type=int, default=300, help="kB na klip")
    ap.add_argument("--loop-max", type=float, default=6.0, help="max. rozdíl prvního a posledního snímku (0–255)")
    ap.add_argument("--edge-max", type=float, default=8.0, help="max. pohyb rámečku (0–255)")
    args = ap.parse_args()

    pick = json.loads(args.pick.read_text(encoding="utf-8")) if args.pick else {}
    dirs, done, warnings = set(), 0, []
    report = []
    for mutant, clip, path in sources(args.src, pick):
        if not path.exists():
            warnings.append(f"{mutant}/{clip}: chybí {path}")
            continue
        with tempfile.TemporaryDirectory() as t:
            shots = frames(path, Path(t))
        loop = diff(shots[0], shots[-1])
        edge = edge_motion(shots)
        flags = []
        if clip != "assemble" and loop > args.loop_max:
            flags.append(f"loop {loop:.1f}")
        if edge > args.edge_max:
            flags.append(f"camera {edge:.1f}")
        rel = path.relative_to(args.src) if path.is_relative_to(args.src) else path
        row = {"clip": str(rel), "loop": round(loop, 1), "edge": round(edge, 1)}
        if not args.check:
            dest_dir = f"assets/figures/{mutant}/clips/"
            dest = APP / dest_dir / f"{clip}.mp4"
            encode(path, dest, args.size, args.crf)
            kb = dest.stat().st_size / 1024
            row["kB"] = round(kb)
            if kb > args.budget:
                flags.append(f"budget {kb:.0f} kB")
            if has_audio(path):
                run("ffmpeg", "-v", "error", "-y", "-i", str(path), "-vn", "-c:a", "aac",
                    "-b:a", "64k", str(dest.with_suffix(".m4a")))
            dirs.add(dest_dir)
            done += 1
        row["flags"] = flags
        report.append(row)
        print(f"{str(rel):48} loop {loop:5.1f}  edge {edge:5.1f}  " + ("  ".join("! " + f for f in flags) or "ok"))

    added = [] if args.check else ensure_pubspec(dirs)
    print(f"\nzabaleno {done}, s výhradou {sum(1 for r in report if r['flags'])}, chybí {len(warnings)}")
    for w in warnings:
        print("  ! " + w)
    if added:
        print("do app/pubspec.yaml přidáno: " + ", ".join(added))
    return 0


if __name__ == "__main__":
    sys.exit(main())
