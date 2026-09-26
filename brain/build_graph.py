"""Build Prince Hamlet's wiring from the raw MaleCNS v1.0 Feather files.

Owner: Neil. Run once (about a minute):  python -m brain.build_graph

Reads (in data/, git-ignored):
    body-annotations-male-cns-v1.0-minconf-0.5.feather
    body-neurotransmitters-male-cns-v1.0.feather
    connectome-weights-male-cns-v1.0-minconf-0.5.feather   (152M rows, streamed in batches)

Writes:
    data/neurons.parquet   one row per neuron: index, bodyId, type, sides, transmitter, sign, ...
    data/graph_true.npz    edge list sorted by receiving neuron: post, pre, count; plus sign and in_total per neuron

Rules (see docs/TECH_ARCHITECTURE.md, "The brain"):
    neurons   = bodies with a superclass that doesn't contain "tbc" (the Berg et al. rule) -> 166,606
    sign      = +1 acetylcholine; -1 GABA, glutamate, histamine; 0 (silenced) dopamine, octopamine, serotonin;
                +1 for "unclear" or missing predictions (flagged)
    edges     = neuron-to-neuron connections with at least MIN_SYNAPSES synapses
    in_total  = every input synapse a neuron gets from other neurons (any count), used to turn counts into input fractions
"""

from __future__ import annotations

import time
from pathlib import Path

import numpy as np
import pandas as pd
import pyarrow.ipc as ipc

DATA = Path(__file__).resolve().parent.parent / "data"
ANNOTATIONS = DATA / "body-annotations-male-cns-v1.0-minconf-0.5.feather"
TRANSMITTERS = DATA / "body-neurotransmitters-male-cns-v1.0.feather"
WEIGHTS = DATA / "connectome-weights-male-cns-v1.0-minconf-0.5.feather"

MIN_SYNAPSES = 5
EXCITATORY = {"acetylcholine"}
INHIBITORY = {"gaba", "glutamate", "histamine"}
MODULATORY = {"dopamine", "octopamine", "serotonin"}

ANNOTATION_COLUMNS = [
    "bodyId", "superclass", "class", "type", "instance", "somaSide", "rootSide",
    "dimorphism", "receptorType", "entryNerve", "flywireType", "hemibrainType",
]


def load_neurons() -> pd.DataFrame:
    ann = pd.read_feather(ANNOTATIONS, columns=ANNOTATION_COLUMNS)
    keep = ann["superclass"].notna() & ~ann["superclass"].astype(str).str.contains("tbc")
    neurons = ann.loc[keep].sort_values("bodyId").reset_index(drop=True)

    nt = pd.read_feather(TRANSMITTERS, columns=["body", "consensus_nt"])
    neurons = neurons.merge(nt.rename(columns={"body": "bodyId", "consensus_nt": "nt"}), on="bodyId", how="left")
    neurons["nt"] = neurons["nt"].fillna("missing")

    sign = np.ones(len(neurons), dtype=np.int8)
    sign[neurons["nt"].isin(INHIBITORY).to_numpy()] = -1
    sign[neurons["nt"].isin(MODULATORY).to_numpy()] = 0
    neurons["sign"] = sign
    neurons.insert(0, "index", np.arange(len(neurons), dtype=np.int32))
    return neurons


def map_ids(sorted_ids: np.ndarray, ids: np.ndarray) -> np.ndarray:
    """Position of each id in sorted_ids, or -1 if it isn't a neuron."""
    pos = np.searchsorted(sorted_ids, ids)
    pos_clipped = np.minimum(pos, len(sorted_ids) - 1)
    return np.where(sorted_ids[pos_clipped] == ids, pos_clipped, -1).astype(np.int64)


def stream_edges(sorted_ids: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, dict]:
    n = len(sorted_ids)
    in_total = np.zeros(n, dtype=np.int64)
    posts, pres, counts = [], [], []
    stats = {"rows": 0, "neuron_edges": 0, "neuron_synapses": 0}
    reader = ipc.open_file(WEIGHTS)
    for b in range(reader.num_record_batches):
        batch = reader.get_batch(b)
        pre_ids = batch.column(0).to_numpy()
        post_ids = batch.column(1).to_numpy()
        w = batch.column(2).to_numpy()
        stats["rows"] += len(w)

        pre = map_ids(sorted_ids, pre_ids)
        post = map_ids(sorted_ids, post_ids)
        both = (pre >= 0) & (post >= 0)
        stats["neuron_edges"] += int(both.sum())
        stats["neuron_synapses"] += int(w[both].sum())
        np.add.at(in_total, post[both], w[both])

        strong = both & (w >= MIN_SYNAPSES)
        posts.append(post[strong].astype(np.int32))
        pres.append(pre[strong].astype(np.int32))
        counts.append(w[strong].astype(np.int32))

    post = np.concatenate(posts)
    pre = np.concatenate(pres)
    count = np.concatenate(counts)
    order = np.lexsort((pre, post))
    return post[order], pre[order], count[order], in_total, stats


def main() -> None:
    t0 = time.time()
    neurons = load_neurons()
    sorted_ids = neurons["bodyId"].to_numpy()
    print(f"neurons: {len(neurons):,}")
    print("  transmitters:", neurons["nt"].value_counts().to_dict())
    print(f"  signs: +1 {int((neurons.sign == 1).sum()):,}  -1 {int((neurons.sign == -1).sum()):,}  "
          f"silenced {int((neurons.sign == 0).sum()):,}")

    post, pre, count, in_total, stats = stream_edges(sorted_ids)
    dup = len(post) - len(np.unique(post.astype(np.int64) * len(neurons) + pre))
    print(f"weights table rows: {stats['rows']:,}")
    print(f"neuron-to-neuron connections: {stats['neuron_edges']:,} carrying {stats['neuron_synapses']:,} synapses")
    print(f"kept (>= {MIN_SYNAPSES} synapses): {len(post):,} connections, "
          f"{count.sum() / stats['neuron_synapses']:.1%} of synapses; duplicates: {dup}; "
          f"self-connections: {int((post == pre).sum())}")
    print(f"neurons with no input: {int((in_total == 0).sum()):,}")

    DATA.mkdir(exist_ok=True)
    neurons.to_parquet(DATA / "neurons.parquet", index=False)
    np.savez_compressed(
        DATA / "graph_true.npz",
        post=post, pre=pre, count=count,
        sign=neurons["sign"].to_numpy(), in_total=in_total, n=np.int64(len(neurons)),
        min_synapses=np.int64(MIN_SYNAPSES),
    )
    print(f"wrote data/neurons.parquet and data/graph_true.npz in {time.time() - t0:.0f} s")


if __name__ == "__main__":
    main()
