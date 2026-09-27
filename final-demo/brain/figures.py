"""The controls matrix figure: same buttons, same neurons; real wiring vs the Changeling.

Owner: Neil. Run after probes:  python -m brain.figures [--csv team/neil/probes_v2_level10.csv]
Writes team/neil/figures/controls_matrix_light.png and controls_matrix_dark.png (demo M screen, Devpost gallery, slides).

Encoding: one sequential blue ramp (light = near rest, dark = strong), one shared scale for both panels, capped at CAP
so the Giant Fiber's ~99 doesn't wash everything else out; every cell prints its real value. Target cells are outlined.
The Changeling panel shows, for each cell, the value with the largest magnitude across the three Changelings (worst case).
"""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from matplotlib.colors import LinearSegmentedColormap  # noqa: E402

from brain.probes import TARGET  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "team" / "neil" / "figures"
CAP = 20.0

# Reference sequential blue ramp (dataviz skill palette), steps 100 -> 700.
BLUE = ["#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7", "#3987e5",
        "#2a78d6", "#256abf", "#1c5cab", "#184f95", "#104281", "#0d366b"]
THEMES = {
    "light": {"surface": "#fcfcfb", "ink": "#0b0b0b", "ink2": "#52514e", "ramp": BLUE, "ring": "#0b0b0b"},
    "dark": {"surface": "#1a1a19", "ink": "#ffffff", "ink2": "#c3c2b7", "ramp": BLUE[::-1], "ring": "#ffffff"},
}

BUTTONS = [
    ("forward", "FORWARD", "LC9 + LC31a"),
    ("back", "BACK", "SNta02/09 + LC16 + LoVP26"),
    ("left", "LEFT", "LLPC1 (left)"),
    ("right", "RIGHT", "LLPC1 (right)"),
    ("up", "UP", "LPLC1 + LLPC2"),
    ("down", "DOWN", "LPLC4"),
    ("duck", "DUCK", "LC4 + LPLC2"),
    ("serenade", "SERENADE", "LC10a + LC10d (both eyes)"),
    ("lock_L", "LOCK ON (L)", "LC10a + LC10d (left)"),
    ("lock_R", "LOCK ON (R)", "LC10a + LC10d (right)"),
]
OUTPUTS = [
    ("DNp09", "Thrust\nDNp09"), ("MDN", "Back up\nMDN"), ("DNa02_L", "Turn L\nDNa02"), ("DNa02_R", "Turn R\nDNa02"),
    ("DNg02", "Wings\nDNg02"), ("DNp07_10", "Land\nDNp07/10"), ("DNp01", "Escape\nDNp01"), ("pIP10", "Song\npIP10"),
    ("pC1", "Courting\npC1"),
]


def load(csv: Path) -> tuple[pd.DataFrame, pd.DataFrame]:
    df = pd.read_csv(csv, index_col=[0, 1])
    rows, cols = [b for b, _, _ in BUTTONS], [o for o, _ in OUTPUTS]
    true = df.loc["true0"].loc[rows, cols]
    chg = [df.loc[k].loc[rows, cols] for k in df.index.get_level_values(0).unique() if k.startswith("changeling")]
    stack = np.stack([c.to_numpy() for c in chg])
    worst = np.take_along_axis(stack, np.abs(stack).argmax(axis=0)[None], axis=0)[0]
    return true, pd.DataFrame(worst, index=rows, columns=cols)


def draw(true: pd.DataFrame, chg: pd.DataFrame, theme: str, level: str, out: Path) -> None:
    t = THEMES[theme]
    cmap = LinearSegmentedColormap.from_list("seq", t["ramp"])
    plt.rcParams.update({"font.family": "DejaVu Sans", "text.color": t["ink"], "axes.labelcolor": t["ink"],
                         "xtick.color": t["ink2"], "ytick.color": t["ink"]})
    fig, axes = plt.subplots(1, 2, figsize=(16, 7.2), facecolor=t["surface"], gridspec_kw={"wspace": 0.04})
    for ax, data, title in ((axes[0], true, "True Prince: the real MaleCNS wiring"),
                            (axes[1], chg, "Changeling: same neurons, scrambled partners (worst of 3)")):
        ax.set_facecolor(t["surface"])
        vals = data.to_numpy()
        ax.imshow(np.clip(vals, 0, CAP), cmap=cmap, vmin=0, vmax=CAP, aspect="auto")
        for i in range(vals.shape[0]):
            for j in range(vals.shape[1]):
                v = vals[i, j]
                shade = np.clip(v, 0, CAP) / CAP
                ink = "#ffffff" if (shade > 0.45) == (theme == "light") else t["ink"]
                if theme == "dark":
                    ink = t["ink"] if shade < 0.55 else "#0b0b0b"
                label = "0" if abs(v) < 0.05 else (f"{v:.0f}" if abs(v) >= 10 else f"{v:.1f}")
                ax.text(j, i, label, ha="center", va="center", fontsize=10.5, color=ink, zorder=6,
                        fontweight="bold" if data.columns[j] == TARGET[data.index[i]] else "normal")
        for i, b in enumerate(data.index):  # outline each button's target cell
            j = list(data.columns).index(TARGET[b])
            ax.add_patch(plt.Rectangle((j - 0.46, i - 0.46), 0.92, 0.92, fill=False, lw=2.2, ec=t["ring"], zorder=5, clip_on=False))
        ax.set_xticks(range(len(OUTPUTS)), [lab for _, lab in OUTPUTS], fontsize=10)
        ax.xaxis.tick_top()
        ax.set_title(title, fontsize=13, pad=44, color=t["ink"], loc="left")
        ax.tick_params(length=0)
        for s in ax.spines.values():
            s.set_visible(False)
        ax.set_xticks(np.arange(-0.5, len(OUTPUTS)), minor=True)
        ax.set_yticks(np.arange(-0.5, len(BUTTONS)), minor=True)
        ax.grid(which="minor", color=t["surface"], linewidth=2, zorder=3)  # 2px surface gap between cells
        ax.set_axisbelow(False)
        ax.tick_params(which="minor", length=0)
    axes[0].set_yticks(range(len(BUTTONS)), [f"{name}\n{cells}" for _, name, cells in BUTTONS], fontsize=10)
    axes[1].set_yticks(range(len(BUTTONS)), [""] * len(BUTTONS))
    sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(0, CAP))
    fig.subplots_adjust(left=0.13, right=0.905, top=0.80, bottom=0.08)
    cax = fig.add_axes([0.925, 0.12, 0.011, 0.58])
    cb = fig.colorbar(sm, cax=cax)
    cb.set_label(f"Response (z-score vs rest; scale capped at {CAP:.0f}, cells show real values)", color=t["ink2"], fontsize=10)
    cb.outline.set_visible(False)
    cb.ax.tick_params(colors=t["ink2"], length=0)
    fig.suptitle("Each phone button stimulates real sensory neurons. Only the real wiring turns each one into its own movement.",
                 fontsize=15, x=0.07, ha="left", y=0.985, color=t["ink"])
    fig.text(0.07, 0.015, f"His Royal Flyness · MaleCNS v1.0 (Berg et al., Cell 2026, CC-BY 4.0) · rate model, button drive {level}, "
             "mean over the last 0.4 s of a 0.8 s press · outlined = the button's intended target",
             fontsize=9, color=t["ink2"])
    out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out, dpi=150, facecolor=t["surface"], bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default=str(ROOT / "team" / "neil" / "probes_v2_level10.csv"))
    args = ap.parse_args()
    level = "1.0" if "level10" in args.csv else ("0.6" if "level06" in args.csv else "?")
    true, chg = load(Path(args.csv))
    for theme in THEMES:
        out = OUT_DIR / f"controls_matrix_{theme}.png"
        draw(true, chg, theme, level, out)
        print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
