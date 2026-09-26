"""The Chronicler: who really moved the Prince? (owner: Neil; called by Arnav's server)

While a chapter plays, one shadow brain per player replays the same button presses **without that player**, plus one shadow with
everyone (the noise-free baseline). They run in separate processes, so the reveal is ready moments after the chapter ends.

Usage from the server:

    chron = Chronicler(players=["Ava", "Ben", "Cy", "Dee"], kind="true", seed=0)   # starts the shadow processes (~3 s)
    chron.start_chapter("ch3_kitchen", roles={"Ava": ["coachman"], "Ben": ["helmsman"], ...})
    chron.record({"Ava": {"forward": 0.6}, "Ben": {"left": 0.7}, "Cy": {}, "Dee": {}})    # every 20 ms tick
    result = chron.finish(events=[{"tick": 812, "kind": "splat", "severity": 3}])        # waits for shadows, returns JSON
    chron.close()

Result JSON (docs/GAME_FLOW.md, "The Chronicle"):
    {"chapter": id, "brain": "true"|"changeling", "ticks": n,
     "players": {name: {"roles": [...], "share": {"thrust", "brake", "turn", "altitude", "escape", "song", "overall"},
                        "events": ["..."]}},
     "knight": name, "blunder": {"player": name, "kind": "...", "tick": n} | null,
     "note": "Replayed open loop: same button presses, one player's removed."}

If a player changes (joins or drops), call `close()` and make a new Chronicler between chapters.
"""

from __future__ import annotations

import multiprocessing as mp
from typing import Any

import numpy as np

from brain.replay import REPLAY_PARAMS, combine, credit, metrics

FULL = "__everyone__"


def _shadow(without: str, kind: str, seed: int, inbox: mp.Queue, outbox: mp.Queue) -> None:
    from brain.brain import OUTPUT_NAMES
    from brain.model import Params, RateModel

    model = RateModel(kind, seed, Params(**REPLAY_PARAMS))
    outbox.put(("ready", without, None))
    rows: list[list[float]] = []
    while True:
        cmd, payload = inbox.get()
        if cmd == "reset":
            model.reset()
            rows = []
        elif cmd == "tick":
            out = model.step(combine(payload, None if without == FULL else without))
            rows.append([out[o] for o in OUTPUT_NAMES])
        elif cmd == "finish":  # always 2-D, even for an empty chapter
            outbox.put(("result", without, np.array(rows, dtype=np.float32).reshape(-1, len(OUTPUT_NAMES))))
        elif cmd == "swap":
            model.load(*payload)
        elif cmd == "stop":
            return


class Chronicler:
    def __init__(self, players: list[str], kind: str = "true", seed: int = 0) -> None:
        self.players = list(players)
        self.kind, self.seed = kind, seed
        ctx = mp.get_context("spawn")
        self._outbox: mp.Queue = ctx.Queue()
        self._inboxes: dict[str, mp.Queue] = {}
        self._procs: list[Any] = []
        for who in [FULL, *self.players]:
            q = ctx.Queue()
            p = ctx.Process(target=_shadow, args=(who, kind, seed, q, self._outbox), daemon=True)
            p.start()
            self._inboxes[who], self._procs = q, [*self._procs, p]
        for _ in self._inboxes:  # wait until every shadow has loaded its brain
            self._outbox.get()
        self.chapter: str | None = None
        self.roles: dict[str, list[str]] = {}
        self.ticks = 0
        self._drives_log: list[dict[str, dict[str, float]]] = []

    def swap(self, kind: str, seed: int = 0) -> None:
        """Follow the TRUE PRINCE / CHANGELING toggle."""
        self.kind, self.seed = kind, seed
        for q in self._inboxes.values():
            q.put(("swap", (kind, seed)))

    def start_chapter(self, chapter: str, roles: dict[str, list[str]] | None = None) -> None:
        self.chapter, self.roles, self.ticks = chapter, roles or {}, 0
        self._drives_log = []
        for q in self._inboxes.values():
            q.put(("reset", None))

    def record(self, drives_by_player: dict[str, dict[str, float]]) -> None:
        tick = {p: dict(drives_by_player.get(p, {})) for p in self.players}
        self._drives_log.append(tick)
        for q in self._inboxes.values():
            q.put(("tick", tick))
        self.ticks += 1

    def finish(self, events: list[dict] | None = None, timeout_s: float = 60.0) -> dict:
        for q in self._inboxes.values():
            q.put(("finish", None))
        outs: dict[str, np.ndarray] = {}
        while len(outs) < len(self._inboxes):
            _, who, rows = self._outbox.get(timeout=timeout_s)
            outs[who] = rows
        full = outs.pop(FULL)
        shares = credit(full, outs)
        knight = max(shares, key=lambda p: shares[p]["overall"]) if shares else None
        per_player_events = self._player_events(full, outs)
        blunder = self._blunder(events or [], full, outs)
        return {
            "chapter": self.chapter,
            "brain": self.kind,
            "ticks": self.ticks,
            "players": {p: {"roles": self.roles.get(p, []), "share": {k: round(v, 3) for k, v in shares[p].items()},
                            "events": per_player_events.get(p, [])} for p in shares},
            "knight": knight,
            "blunder": blunder,
            "note": "Replayed open loop: same button presses, one player's removed.",
        }

    def close(self) -> None:
        for q in self._inboxes.values():
            q.put(("stop", None))
        for p in self._procs:
            p.join(timeout=2)

    # --- helpers ------------------------------------------------------------------------------------------
    def _player_events(self, full: np.ndarray, outs: dict[str, np.ndarray]) -> dict[str, list[str]]:
        """Short human-readable facts per player (escapes and song time that vanish without them)."""
        m_full = metrics(full)
        notes: dict[str, list[str]] = {}
        for p, out in outs.items():
            m = metrics(out)
            lost_escapes = int(max(0.0, (np.diff(m_full["escape"], prepend=0) > 0).sum() - (np.diff(m["escape"], prepend=0) > 0).sum()))
            lost_song = float((m_full["song"].sum() - m["song"].sum()) * 0.02)
            items = []
            if lost_escapes:
                items.append(f"{lost_escapes} escape{'s' if lost_escapes > 1 else ''} happened because of you")
            if lost_song > 0.2:
                items.append(f"{lost_song:.1f} s of the serenade was yours")
            notes[p] = items
        return notes

    def _blunder(self, events: list[dict], full: np.ndarray, outs: dict[str, np.ndarray]) -> dict | None:
        """The worst game event, blamed on the player whose inputs changed the flight most in the second before it."""
        if not events:
            return None
        worst = max(events, key=lambda e: e.get("severity", 1))
        t = int(worst.get("tick", len(full) - 1))
        lo = max(0, t - 50)
        m_full = metrics(full)
        blame = {p: sum(float(np.abs(m_full[k][lo:t + 1] - metrics(out)[k][lo:t + 1]).sum()) for k in ("thrust", "turn", "altitude"))
                 for p, out in outs.items()}
        who = max(blame, key=blame.get) if blame else None
        return {"player": who, "kind": worst.get("kind", "?"), "tick": t}


def _demo() -> None:
    """Self-test: four players, 20 s of scripted presses. Expect Ava (forward) to own thrust, Ben (left) to own turning."""
    import time

    players = ["Ava", "Ben", "Cy", "Dee"]
    t0 = time.time()
    chron = Chronicler(players)
    print(f"4 + 1 shadows ready in {time.time() - t0:.1f} s")
    chron.start_chapter("demo", roles={"Ava": ["coachman"], "Ben": ["helmsman"], "Cy": ["falconer"], "Dee": ["spymaster"]})
    t0 = time.time()
    for t in range(1000):
        chron.record({
            "Ava": {"forward": 0.6} if t % 200 < 150 else {},
            "Ben": {"left": 0.7} if 300 <= t < 450 else {},
            "Cy": {"up": 0.8} if 500 <= t < 700 else {},
            "Dee": {"duck": 1.0} if t in range(800, 815) else ({"serenade": 1.0} if t >= 900 else {}),
        })
    sent = time.time() - t0
    result = chron.finish(events=[{"tick": 820, "kind": "crash", "severity": 2}])
    print(f"sent 1000 ticks in {sent:.1f} s; result {time.time() - t0:.1f} s after the first tick")
    for p, info in result["players"].items():
        print(f"  {p:4s} {info['roles']}: {info['share']}  {info['events']}")
    print("  knight:", result["knight"], "| blunder:", result["blunder"])
    chron.close()


if __name__ == "__main__":
    _demo()
