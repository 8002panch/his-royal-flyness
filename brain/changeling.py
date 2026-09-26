"""The Changeling: same neurons, same connection counts, same input to every neuron, scrambled partners.

Owner: Neil. Run after build_graph:  python -m brain.changeling
Writes data/graph_changeling_{0,1,2}.npz.

For each sign group of senders (excitatory, inhibitory, silenced), the sender of every connection is shuffled among
connections from that group, while each connection's receiver and synapse count stay fixed. So:
  - every neuron keeps exactly the same total input and the same excitatory/inhibitory mix (identical W row sums),
  - every neuron keeps the same number of outgoing connections,
  - only who talks to whom changes.
Duplicates created by the shuffle are summed when the matrix is built, which keeps row sums exact.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np

from brain.model import load_weights

DATA = Path(__file__).resolve().parent.parent / "data"
SEEDS = (0, 1, 2)


def shuffle_senders(pre: np.ndarray, sign: np.ndarray, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    new_pre = pre.copy()
    edge_sign = sign[pre]
    for s in np.unique(edge_sign):
        where = np.flatnonzero(edge_sign == s)
        new_pre[where] = pre[where[rng.permutation(len(where))]]
    return new_pre


def main() -> None:
    g = dict(np.load(DATA / "graph_true.npz"))
    true_rows = np.asarray(load_weights(DATA / "graph_true.npz").sum(axis=1)).ravel()
    for seed in SEEDS:
        new_pre = shuffle_senders(g["pre"], g["sign"], seed)
        out = DATA / f"graph_changeling_{seed}.npz"
        np.savez_compressed(out, **{**g, "pre": new_pre.astype(np.int32)})
        rows = np.asarray(load_weights(out).sum(axis=1)).ravel()
        pairs = np.unique(g["post"].astype(np.int64) * int(g["n"]) + new_pre)
        print(f"seed {seed}: kept partners {np.mean(new_pre == g['pre']):.2%}; "
              f"duplicate pairs merged {len(new_pre) - len(pairs):,}; self-connections {int((g['post'] == new_pre).sum())}; "
              f"max row-sum difference vs True Prince {np.abs(rows - true_rows).max():.2e}")


if __name__ == "__main__":
    main()
