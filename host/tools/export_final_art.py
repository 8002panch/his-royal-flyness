"""Crop the approved hand-drawn asset sheets in assets/final/ into individual
transparent runtime frames under assets/final/runtime/, per
assets/final/FINAL_INTEGRATION_PROMPT.md.

Each sheet is a 4-column grid of labelled poses over a checkerboard or
parchment display background. This script locates each cell, strips the
display background (checkerboard / parchment / labels) by keying out
low-saturation and known panel colors, autocrops to the sprite's opaque
pixels, and rescales with nearest-neighbour to the required native size.

Usage: python tools/export_final_art.py
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FINAL = ROOT / "assets" / "final"
RUNTIME = FINAL / "runtime"

# (sheet path, output subfolder, target size, [(row, col, frame_name), ...])
HAMLET_FRAMES = [
    (0, 0, "rear"),
    (0, 2, "front"),
    (1, 0, "hover"),
    (1, 1, "wings_raised"),
    (1, 2, "wings_lowered"),
    (1, 3, "buzz"),
    (2, 0, "bank_left"),
    (2, 1, "bank_right"),
    (2, 2, "hit"),
    (2, 3, "victory"),
]

SHEETS = {
    "hamlet": (FINAL / "characters" / "hamlet_asset_sheet_final.png", (48, 48), HAMLET_FRAMES),
    "miranda": (FINAL / "characters" / "miranda_asset_sheet_final.png", (64, 80), None),
    "prospero": (FINAL / "characters" / "prospero_asset_sheet_final.png", (64, 80), None),
    "helmsman": (FINAL / "characters" / "helmsman_asset_sheet_final.png", (64, 80), None),
    "liftmaster": (FINAL / "characters" / "liftmaster_asset_sheet_final.png", (64, 80), None),
    "wingmaster": (FINAL / "characters" / "wingmaster_asset_sheet_final.png", (64, 80), None),
    "royal_seer": (FINAL / "characters" / "royal_seer_asset_sheet_final.png", (64, 80), None),
    "lord_tinman": (FINAL / "characters" / "lord_tinman_asset_sheet_final.png", (64, 80), None),
    "sir_cheapdate": (FINAL / "characters" / "sir_cheapdate_asset_sheet_final.png", (64, 80), None),
    "count_rutabaga": (FINAL / "characters" / "count_rutabaga_asset_sheet_final.png", (64, 80), None),
    "clown_jester": (FINAL / "characters" / "clown_jester_asset_sheet_final.png", (64, 80), None),
    "giant_hand": (FINAL / "hazards" / "giant_hand_asset_sheet_final.png", (96, 96), None),
}

GRID_ROWS = 3
GRID_COLS = 4
HEADER_PX = 60  # title band at the top of every sheet
ROW_LABEL_PX = 90  # caption band under each row's sprite art
SAT_THRESHOLD = 18  # max(channel) - min(channel) below this counts as background (grey/parchment/checker)


def _cell_box(sheet_size: tuple[int, int], row: int, col: int) -> tuple[int, int, int, int]:
    w, h = sheet_size
    col_w = w // GRID_COLS
    row_h = (h - HEADER_PX) // GRID_ROWS
    x0 = col * col_w
    y0 = HEADER_PX + row * row_h
    return x0, y0, x0 + col_w, y0 + row_h - ROW_LABEL_PX


def _is_background(px, x: int, y: int) -> bool:
    r, g, b, _ = px[x, y]
    return max(r, g, b) - min(r, g, b) < SAT_THRESHOLD


def _strip_background(cell: Image.Image) -> Image.Image:
    """Flood-fill the checkerboard/parchment display background from the cell's
    border inward, so enclosed low-saturation sprite regions (pale wings, white
    highlights) are left alone as long as an ink outline separates them from
    the outer background."""
    cell = cell.convert("RGBA")
    px = cell.load()
    w, h = cell.size
    seen = bytearray(w * h)
    from collections import deque

    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        idx = y * w + x
        if seen[idx]:
            continue
        if not _is_background(px, x, y):
            continue
        seen[idx] = 1
        r, g, b, a = px[x, y]
        px[x, y] = (r, g, b, 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))
    return cell


def _autocrop(cell: Image.Image) -> Image.Image | None:
    bbox = cell.getbbox()
    if bbox is None:
        return None
    return cell.crop(bbox)


def _fit(cell: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    scale = min(tw / cell.width, th / cell.height)
    nw = max(1, round(cell.width * scale))
    nh = max(1, round(cell.height * scale))
    resized = cell.resize((nw, nh), Image.NEAREST)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2), resized)
    return canvas


def export_sheet(name: str, sheet_path: Path, size: tuple[int, int], frames: list | None) -> list[str]:
    if not sheet_path.exists():
        print(f"  ! missing sheet: {sheet_path}")
        return []
    sheet = Image.open(sheet_path).convert("RGBA")
    out_dir = RUNTIME / name
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    cells = frames if frames is not None else [(r, c, f"pose_{r}_{c}") for r in range(GRID_ROWS) for c in range(GRID_COLS)]
    for row, col, frame_name in cells:
        box = _cell_box(sheet.size, row, col)
        cell = sheet.crop(box)
        cell = _strip_background(cell)
        cropped = _autocrop(cell)
        if cropped is None or cropped.width < 2 or cropped.height < 2:
            continue
        framed = _fit(cropped, size)
        out_path = out_dir / f"{frame_name}.png"
        framed.save(out_path)
        written.append(frame_name)
    return written


def main() -> None:
    manifest: dict[str, list[str]] = {}
    for name, (sheet_path, size, frames) in SHEETS.items():
        print(f"exporting {name} <- {sheet_path.relative_to(ROOT)}")
        manifest[name] = export_sheet(name, sheet_path, size, frames)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    (RUNTIME / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("wrote", RUNTIME / "manifest.json")


if __name__ == "__main__":
    main()
