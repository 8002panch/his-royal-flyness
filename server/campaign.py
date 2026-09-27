"""The story campaign (docs/GAME.md, "Story campaign and comic cutscenes"): comics, quizzes, courses, fights and endings.

A GameSession owns one Campaign. The comic and quiz beats come from audio/lines.csv (scene, panel, branch, speaker, caption),
so the script lives in one place. Everything here is scripted story logic: the brain only ever supplies the Seer's senses, and
the attacks only reach it as looming stimuli while they approach. Nothing about an attack reaches the shared screen before it
lands (the Seer's secret).

Flow: lobby -> TUTORIAL -> C01 -> Q01 -> STAGE1 -> Q02 -> STAGE2 -> Q03 -> C02 -> GIANT -> C03 | C04 -> [FATHER] -> E01 | E02
-> END. Phases: lobby, comic, question (a comic beat waiting for the Seer's answer), ready (a short count-in), play, end.
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass, field, replace
from typing import Any

from .movement import MovementTuning, WallGate

try:  # the script bank; the campaign still runs (without comics) if audio/ is missing
    from audio.gen_voices import TAG, load_lines
except Exception:  # pragma: no cover
    load_lines, TAG = None, None

UNIT_CM = 220.0
READY_S = 2.0
WARN_S = 2.0            # an attack's warning window: target locked at onset, impact WARN_S later
HIT_RADIUS = 0.30       # server units: still this close to the locked target at impact = hit
SIDE_OFFSET = 0.12      # the hand lands a little to its own side of Hamlet, so moving away from that side escapes
GIANT_DODGES, GIANT_HITS = 10, 3
FATHER_DODGES = 5
STAGE2_SECONDS = 60.0
STAGE2_SWATS = (14.0, 30.0, 46.0)
GOAL_Z = 0.9
PICKUP_R, DELIVER_R, PICKUP_SPEED = 0.2, 0.22, 0.8

# Ved's wall course, with each opening moved off the centre line so flying straight never gets through (his openings all
# overlapped the middle): (name, z, gap x0, x1, gap y0, y1), server units. Stage 2 is the mirror, in a new order.
STAGE1_WALLS = (
    WallGate("left_gate", -0.50, -1.00, -0.20, -0.80, 0.80),
    WallGate("right_gate", -0.10, 0.20, 1.00, -0.80, 0.80),
    WallGate("low_gate", 0.35, -0.75, 0.75, -1.00, -0.20),
    WallGate("high_gate", 0.75, -0.75, 0.75, 0.20, 1.00),
)
STAGE2_WALLS = (
    WallGate("right_gate", -0.50, 0.20, 1.00, -0.80, 0.80),
    WallGate("high_gate", -0.10, -0.75, 0.75, 0.20, 1.00),
    WallGate("left_gate", 0.35, -1.00, -0.20, -0.80, 0.80),
    WallGate("low_gate", 0.75, -0.75, 0.75, -1.00, -0.20),
)

# Tutorial: one grape at a time, then back to the chalice (docs/GAME.md, "Tutorial")
CHALICE = (0.0, -0.35, -0.72)
GRAPES = ((0.0, 0.0, -0.35), (0.65, 0.0, -0.45), (0.0, 0.7, -0.5), (-0.6, 0.55, -0.25))
MIRANDA_BY_CHALICE = (0.3, -0.2, -0.66)

QUIZZES = {  # docs/GAME.md, "The three drink questions" (NIAAA facts; general human health, not fly results)
    "Q01": {"text": "Alcohol can make balance and coordination...", "a": "Worse", "b": "More precise", "correct": "A"},
    "Q02": {"text": "Can heavy drinking interfere with forming new memories?", "a": "No", "b": "Yes", "correct": "B"},
    "Q03": {"text": "Does coffee remove alcohol's effects on judgment and coordination?", "a": "Yes", "b": "No", "correct": "B"},
}
STEADINESS = ("steady", "wobbly", "very wobbly", "extremely wobbly")

# (scene, kind, backdrop); C03/C04 and E01/E02 are chosen by the fights
ORDER = ("TUTORIAL", "C01", "Q01", "STAGE1", "Q02", "STAGE2", "Q03", "C02", "GIANT", "C03", "C04", "FATHER", "E01", "E02", "END")
KIND = {"TUTORIAL": "play", "STAGE1": "play", "STAGE2": "play", "GIANT": "play", "FATHER": "play", "END": "end"}
BACKDROP = {"TUTORIAL": "garden", "C01": "garden", "Q01": "window_ledge", "STAGE1": "basement", "Q02": "basement",
            "STAGE2": "inner_passage", "Q03": "banquet", "C02": "banquet", "GIANT": "arena", "C03": "banquet",
            "C04": "father_arena", "FATHER": "father_arena", "E01": "banquet", "E02": "banquet", "END": "banquet"}
PANEL_BACKDROP = {("C01", "p3.7"): "gate_outside", ("C01", "p3.8"): "window_ledge"}
OBJECTIVE = {
    "TUTORIAL": "Deliver four grapes to the Royal Harvest Chalice",
    "STAGE1": "Find the way through: fly through each wall's opening",
    "STAGE2": "Reach the banquet doors before the gate closes",
    "GIANT": "Outlast the Giant: dodge ten swats",
    "FATHER": "Prospero's Last Word: dodge five throws without a hit",
}
GESTURES = {  # the line's first audio tag -> a cast-rig gesture (host/assets/pixelart/animation_v1)
    "angry": "angry", "furious": "angry", "indignant": "angry", "out of breath, furious": "angry", "scoffs": "angry",
    "delighted": "celebrate", "triumphantly": "celebrate", "excited": "celebrate", "excitedly": "celebrate",
    "cheerfully": "celebrate", "proudly, tipsy": "toast", "hiccups": "toast", "confused": "confused", "flustered": "confused",
    "nervously": "confused", "startled": "confused", "squinting": "confused", "reading slowly": "confused",
    "politely": "bow", "smugly": "approve", "coolly": "approve", "airily": "approve", "amused": "approve",
    "gently": "wave", "warmly": "wave", "softly": "wave", "passionately": "point", "calm, resolute": "point",
    "matter-of-factly": "point", "crisply": "point", "alarmed": "point", "worried": "point",
}


@dataclass
class Beat:
    id: str
    speaker: str
    name: str
    caption: str
    panel: str
    branch: str
    gesture: str


@dataclass
class Attack:
    n: int
    side: str
    onset: float
    impact: float
    target: tuple[float, float, float]
    resolved: bool = False


@dataclass
class Fight:
    kind: str                     # "giant", "father" or "swat" (Stage 2)
    t: float = 0.0                # active time in this fight
    next_onset: float = 2.5
    attack: Attack | None = None
    n: int = 0
    dodges: int = 0
    hits: int = 0
    impact: dict | None = None    # the last impact, shown for a moment after it lands
    rng: random.Random = field(default_factory=lambda: random.Random(7))


def _load_beats() -> dict[str, list[Beat]]:
    beats: dict[str, list[Beat]] = {}
    if load_lines is None:
        return beats
    names = {"clown": "Clown", "hamlet": "Hamlet", "miranda": "Miranda", "prospero": "Prospero", "tinman": "Lord Tinman",
             "cheapdate": "Sir Cheapdate", "rutabaga": "Count Rutabaga"}
    for ln in load_lines():
        tag = TAG.match(ln.line)
        first = tag.group(0)[1:-1].strip().lower() if tag else ""
        beats.setdefault(ln.scene, []).append(Beat(ln.id, ln.speaker, names.get(ln.speaker, ln.speaker), ln.caption,
                                                   ln.panel, ln.branch, GESTURES.get(first, "talk")))
    return beats


def _cue(fly: Any, target: tuple[float, float, float]) -> dict[str, float]:
    """Where a target sits relative to the fly (heading +z), as projected_stimuli describes it."""
    dx, dy, dz = target[0] - fly.x, target[1] - fly.y, target[2] - fly.z
    return {"bearing_deg": math.degrees(math.atan2(dx, dz)), "elevation_deg": math.degrees(math.atan2(dy, math.hypot(dx, dz))),
            "distance_cm": max(1.0, math.sqrt(dx * dx + dy * dy + dz * dz) * UNIT_CM)}


class Campaign:
    """The story, driven by the presenter's Next / Back / Skip, the Seer's answers and the flight itself."""

    def __init__(self, session: Any) -> None:
        self.session = session
        self.beats = _load_beats()
        self.base_tuning = session.simulator.tuning
        self.events: list[dict[str, Any]] = []   # voice / dodge / hit events for the screens, drained by the server
        self.demo = False
        self._reset_run()
        self.scene, self.phase = "LOBBY", "lobby"

    # ---------------------------------------------------------------- run state

    def _reset_run(self) -> None:
        self.answers: dict[str, str] = {}      # quiz id -> "A" | "B", applied once
        self.dizzy = 0
        self.route: set[str] = set()           # giant_win / giant_loss / father_win / father_loss
        self.scene, self.phase = "LOBBY", "lobby"
        self.beat_list: list[Beat] = []
        self.i = 0
        self.ready_left = 0.0
        self.play: dict[str, Any] = {}
        self.fight: Fight | None = None
        self.said: set[str] = set()
        self.hints: list[str] = []            # play-time lines, one at a time so none cuts another off
        self.hint_wait = 0.0
        self.leave_in: float | None = None    # a finished play scene lingers so its last line or shout can play
        self._dizzy_told = 0
        self._apply_dizziness()

    def _apply_dizziness(self) -> None:
        """Each wrong answer: about 10% more stopping distance (docs/GAME.md). Not alcohol in the nervous system."""
        drag = self.base_tuning.drag_per_second / (1.0 + 0.1 * self.dizzy)
        self.session.simulator.tuning = replace(self.base_tuning, drag_per_second=drag)

    def _hint(self, line_id: str, once: bool = True) -> None:
        """A play-time line (tutorial tips, Stage 2 notices): queued, so lines never talk over each other. A newer tutorial
        step drops tips for steps the team has already finished, so a fast team never hears stale advice."""
        if once and line_id in self.said:
            return
        self.said.add(line_id)
        if line_id.startswith("TUT_GRAPE_"):
            self.hints = [h for h in self.hints if not (h.startswith("TUT_GRAPE_") or h == "TUT_WELCOME")]
        elif line_id == "TUT_FINISH":
            self.hints = [h for h in self.hints if not h.startswith(("TUT_GRAPE_", "TUT_SEER", "TUT_WELCOME"))]
        self.hints.append(line_id)

    def _beat(self, line_id: str) -> Beat | None:
        for scene in self.beats.values():
            for b in scene:
                if b.id == line_id:
                    return b
        return None

    def _voice(self, b: Beat) -> None:
        self.events.append({"t": "event", "kind": "voice", "id": b.id, "speaker": b.name, "caption": b.caption})

    def _tick_hints(self, dt: float) -> None:
        self.hint_wait -= dt
        if self.hint_wait > 0 or not self.hints:
            return
        b = self._beat(self.hints.pop(0))
        if b is not None:
            self._voice(b)
            self.hint_wait = 1.2 + 0.4 * len(b.caption.split())  # about the line's length at 150 words a minute

    # ---------------------------------------------------------------- flow

    def start(self) -> None:
        """Lobby -> the tutorial. A new campaign also clears the DEMO stamp."""
        self._reset_run()
        self.demo = False
        self._hint("H_TITLE")
        self.enter("TUTORIAL")

    def enter(self, scene: str) -> None:
        self.scene = scene
        self.fight = None
        self.play = {}
        self.leave_in = None
        self.session.simulator.walls = ()
        kind = KIND.get(scene, "comic")
        self._clear_inputs()
        if kind == "end":
            self.phase = "end"
            return
        if kind == "play":
            self._start_play(scene)
            return
        self.hints.clear()
        self.beat_list = [b for b in self.beats.get(scene, []) if self._on_route(scene, b)]
        self.i = 0
        if not self.beat_list:  # no script for it: move on
            self._finish_scene()
            return
        self.phase = "comic"
        self._enter_beat()

    def _on_route(self, scene: str, b: Beat) -> bool:
        if b.branch in ("correct", "wrong"):
            return scene in self.answers and (self.answers[scene] == QUIZZES[scene]["correct"]) == (b.branch == "correct")
        return b.branch == "" or b.branch in self.route

    def _gate(self) -> int:
        """Index of the last question beat: the Seer must answer before the comic moves past it."""
        idx = [k for k, b in enumerate(self.beat_list) if b.panel == "question"]
        return idx[-1] if idx else -1

    def _enter_beat(self) -> None:
        self.phase = "question" if self.scene in QUIZZES and self.i == self._gate() and self.scene not in self.answers else "comic"
        self._voice(self.beat_list[self.i])

    def next(self) -> None:
        """Presenter: the next bubble. Never past an unanswered question."""
        if self.phase == "lobby":
            self.start()
            return
        if self.phase not in ("comic", "question"):
            return
        if self.scene in QUIZZES and self.i >= self._gate() and self.scene not in self.answers:
            return
        if self.i + 1 < len(self.beat_list):
            self.i += 1
            self._enter_beat()
        else:
            self._finish_scene()

    def back(self) -> None:
        """Presenter: reread the previous bubble of this comic. It can't undo an answer."""
        if self.phase in ("comic", "question") and self.i > 0:
            self.i -= 1
            self.phase = "comic"
            self._voice(self.beat_list[self.i])

    def skip(self) -> None:
        """Presenter: to the end of this comic, stopping at an unanswered question; never answers or wins anything."""
        if self.phase not in ("comic", "question"):
            return
        gate = self._gate()
        if self.scene in QUIZZES and self.scene not in self.answers:
            if self.i < gate:
                self.i = gate
                self._enter_beat()
            return
        self._finish_scene()

    def answer(self, choice: str) -> bool:
        """The Seer's answer (phones: only the Seer can send one). Applied once per quiz, only at the question."""
        if self.phase != "question" or self.scene not in QUIZZES or self.scene in self.answers or choice not in ("A", "B"):
            return False
        self.answers[self.scene] = choice
        if choice != QUIZZES[self.scene]["correct"]:
            self.dizzy = min(3, self.dizzy + 1)
            self._apply_dizziness()
        # the rest of the comic, now on the chosen branch; what's been read stays as it was
        full = self.beats.get(self.scene, [])
        at = next(k for k, b in enumerate(full) if b.id == self.beat_list[self.i].id)
        self.beat_list = self.beat_list[: self.i + 1] + [b for b in full[at + 1:] if self._on_route(self.scene, b)]
        self.phase = "comic"
        self.next()
        return True

    def _finish_scene(self) -> None:
        s = self.scene
        if s == "GIANT":
            self.enter("C03" if "giant_win" in self.route else "C04")
        elif s == "C03":
            self.enter("E01")
        elif s == "C04":
            self.enter("FATHER")
        elif s == "FATHER":
            self.enter("E01" if "father_win" in self.route else "E02")
        elif s in ("E01", "E02"):
            self.enter("END")
        else:
            nxt = ORDER[ORDER.index(s) + 1] if s in ORDER and ORDER.index(s) + 1 < len(ORDER) else "END"
            self.enter(nxt)

    def jump(self, scene: str) -> bool:
        """Presenter: straight to a chapter for judging. Marks the run DEMO; a jump never grants a story result."""
        if scene not in ORDER:
            return False
        self.demo = True
        if scene in ("C04", "FATHER", "E02"):
            self.route = {"giant_loss"} | ({"father_loss"} if scene == "E02" else set())
        elif scene in ("C03", "E01"):
            self.route = {"giant_win"}
        else:
            self.route = set()
        self.enter(scene)
        return True

    def restart_stage(self) -> None:
        if KIND.get(self.scene) == "play":
            self.enter(self.scene)

    def _clear_inputs(self) -> None:
        for inp in self.session.state.inputs.values():
            inp.value = 0

    # ---------------------------------------------------------------- play

    def _start_play(self, scene: str) -> None:
        fly = self.session.state.fly
        fly.vx = fly.vy = fly.vz = 0.0
        fly.x, fly.y, fly.z = 0.0, 0.0, -0.95
        if self.dizzy > self._dizzy_told:  # a wrong answer since the last flight: say so once, before flying
            self._dizzy_told = self.dizzy
            self._hint("UI_DIZZY", once=False)
        if scene == "TUTORIAL":
            self.play = {"grape": 0, "carrying": False, "delivered": 0}
            self._hint("TUT_WELCOME")
        elif scene == "STAGE1":
            self.session.simulator.walls = STAGE1_WALLS
            self.play = {"passed": 0}
        elif scene == "STAGE2":
            self.session.simulator.walls = STAGE2_WALLS
            self.play = {"passed": 0, "clock": STAGE2_SECONDS}
            self.fight = Fight("swat", next_onset=STAGE2_SWATS[0])
            self._hint("S2_INTRO")
        elif scene in ("GIANT", "FATHER"):
            fly.z = -0.3
            self.fight = Fight("giant" if scene == "GIANT" else "father")
        self.phase, self.ready_left = "ready", READY_S

    @property
    def flying(self) -> bool:
        return self.phase == "play"

    def step(self, dt: float) -> None:
        if self.phase in ("ready", "play"):
            self._tick_hints(dt)
        if self.leave_in is not None:
            self.leave_in -= dt
            if self.leave_in <= 0 and not self.hints and self.hint_wait <= 0:
                self._finish_scene()
            return
        if self.phase == "ready":
            self.ready_left -= dt
            self._clear_inputs()  # fresh presses after the count-in
            if self.ready_left <= 0:
                self.phase = "play"
            return
        if self.phase != "play":
            return
        fly = self.session.state.fly
        if self.scene == "TUTORIAL":
            self._tutorial(fly)
        elif self.scene in ("STAGE1", "STAGE2"):
            self._course(fly, dt)
        if self.fight is not None and self.phase == "play":
            self._fight(fly, dt)

    def _tutorial(self, fly: Any) -> None:
        p = self.play
        k = p["grape"]
        if k >= len(GRAPES):
            return
        self._hint(f"TUT_GRAPE_{k + 1}")
        speed = math.sqrt(fly.vx ** 2 + fly.vy ** 2 + fly.vz ** 2)
        if not p["carrying"]:
            if _dist(fly, GRAPES[k]) < PICKUP_R and speed < PICKUP_SPEED:
                p["carrying"] = True
                if k == len(GRAPES) - 1:  # the Seer's lesson: Miranda waits by the chalice for the last return
                    self._hint("TUT_SEER")
                    self._hint("TUT_SEER_MIRANDA")
        elif _dist(fly, CHALICE) < DELIVER_R:
            p["carrying"] = False
            p["grape"] = k + 1
            p["delivered"] = k + 1
            if p["delivered"] == len(GRAPES):
                self._hint("TUT_FINISH")
                self._hint("TUT_FINISH_MIRANDA")
                self.leave_in = 0.5

    def _course(self, fly: Any, dt: float) -> None:
        p = self.play
        p["passed"] = sum(1 for w in self.session.simulator.walls if fly.z > w.z)
        if "clock" in p:
            p["clock"] = max(0.0, p["clock"] - dt)
            if p["clock"] <= 0.0:
                self._hint("S2_TIMEOUT", once=False)
                self._restart_play()
                return
        if fly.z >= GOAL_Z:
            self.leave_in = 1.0

    def _restart_play(self) -> None:
        """A timeout or a hit in Stage 2: the stage from the top. No quiz is repeated and no dizziness added."""
        self._start_play(self.scene)

    def _fight(self, fly: Any, dt: float) -> None:
        f = self.fight
        f.t += dt
        if f.impact is not None and f.t - f.impact["at"] > 1.0:
            f.impact = None
        if self.scene == "STAGE2":
            clock_t = STAGE2_SECONDS - self.play["clock"]
            if f.attack is None and f.n < len(STAGE2_SWATS) and clock_t >= STAGE2_SWATS[f.n]:
                self._launch(fly, f)
        elif f.attack is None and f.t >= f.next_onset and not self._fight_over(f):
            self._launch(fly, f)
        a = f.attack
        if a is None or f.t < a.impact:
            return
        # resolution: hit or dodge, atomically, once per attack
        a.resolved = True
        f.attack = None
        hit = _dist(fly, a.target) < HIT_RADIUS
        f.impact = {"x": a.target[0], "y": a.target[1], "z": a.target[2], "hit": hit, "at": f.t, "fight": f.kind}
        fight = "father" if f.kind == "father" else "giant"
        if f.kind == "swat":  # Stage 2's swats: sounds only (the Giant fight's shouts and counts come later)
            self.events.append({"t": "event", "kind": "sfx", "id": "GIANT_SPLAT" if hit else "GIANT_SWAT"})
            if hit:
                self._restart_play()
            return
        if hit:
            f.hits += 1
            self.events.append({"t": "event", "kind": "hit", "fight": fight, "n": f.hits})
        else:
            f.dodges += 1
            self.events.append({"t": "event", "kind": "dodge", "fight": fight, "n": f.dodges})
        if hit:  # back to a safe spot, a moment to recover
            fly.vx = fly.vy = fly.vz = 0.0
            fly.x, fly.y = 0.0, 0.0
        f.next_onset = f.t + (3.0 if hit else self._gap(f))
        if f.kind == "giant" and f.dodges >= GIANT_DODGES:
            self.route |= {"giant_win"}
            self.leave_in = 3.0
        elif f.kind == "giant" and f.hits >= GIANT_HITS:
            self.route |= {"giant_loss"}
            self.leave_in = 3.0
        elif f.kind == "father" and f.dodges >= FATHER_DODGES:
            self.route |= {"father_win"}
            self.leave_in = 3.0
        elif f.kind == "father" and f.hits >= 1:
            self.route |= {"father_loss"}
            self.leave_in = 3.0

    def _fight_over(self, f: Fight) -> bool:
        if f.kind == "giant":
            return f.dodges >= GIANT_DODGES or f.hits >= GIANT_HITS
        return f.dodges >= FATHER_DODGES or f.hits >= 1

    def _gap(self, f: Fight) -> float:
        """Recovery between attacks: slower first, shorter at the end (docs/GAME.md progression)."""
        if f.kind == "father":
            return 2.6
        return 2.6 if f.n <= 3 else (2.2 if f.n <= 7 else 1.6)

    def _launch(self, fly: Any, f: Fight) -> None:
        f.n += 1
        side = f.rng.choice(("left", "right"))
        warn = WARN_S + (0.4 if f.kind == "giant" and f.n <= 3 else 0.0)
        off = -SIDE_OFFSET if side == "left" else SIDE_OFFSET
        target = (max(-0.85, min(0.85, fly.x + off)), max(-0.85, min(0.85, fly.y)), fly.z)
        f.attack = Attack(f.n, side, f.t, f.t + warn, target)

    # ---------------------------------------------------------------- senses and screens

    def stimuli(self) -> dict[str, Any]:
        """What Hamlet's senses get this tick: Miranda where the story puts her, and an approaching attack as a looming hand."""
        fly = self.session.state.fly
        princess = None
        if self.scene == "TUTORIAL" and self.play.get("grape") == len(GRAPES) - 1 and self.play.get("carrying"):
            princess = _cue(fly, MIRANDA_BY_CHALICE)
        giants = []
        f = self.fight
        if self.phase == "play" and f is not None and f.attack is not None:
            remaining = max(0.0, f.attack.impact - f.t)
            giants.append({"bearing_deg": -60.0 if f.attack.side == "left" else 60.0, "elevation_deg": 15.0,
                           "distance_cm": 40.0 + remaining * 150.0, "approach_cm_s": 150.0, "size_cm": 40.0})
        return {"princess": princess, "giants": giants}

    def princess_render(self) -> dict | None:
        """Miranda on the shared screen: only where the story places her in view (never a hidden target)."""
        s = self.stimuli()
        return s["princess"]

    def state_fields(self) -> dict[str, Any]:
        """The campaign's part of Godot's state message (docs/TECH.md, "Campaign")."""
        out: dict[str, Any] = {"phase": self.phase, "scene": self.scene, "storyDemo": self.demo,
                               "backdrop": BACKDROP.get(self.scene, ""), "objective": OBJECTIVE.get(self.scene, ""),
                               "dizzy": self.dizzy, "steadiness": STEADINESS[self.dizzy]}
        if self.phase in ("comic", "question") and self.beat_list:
            b = self.beat_list[self.i]
            panel_cast = [x.speaker for x in self.beat_list if x.panel == b.panel and x.speaker != "clown"]
            out["beat"] = {"id": b.id, "speaker": b.speaker, "name": b.name, "caption": b.caption, "panel": b.panel,
                           "gesture": b.gesture, "index": self.i + 1, "count": len(self.beat_list),
                           "cast": list(dict.fromkeys(panel_cast))}
            if b.speaker == "clown":  # the Clown's narration sits over the line it reacts to, as in a comic panel
                prev = [x for x in self.beat_list[: self.i] if x.panel == b.panel and x.speaker != "clown"]
                if prev:
                    out["beat"]["prev"] = {"speaker": prev[-1].speaker, "name": prev[-1].name, "caption": prev[-1].caption}
            out["backdrop"] = PANEL_BACKDROP.get((self.scene, b.panel), out["backdrop"])
        if self.scene in QUIZZES and self.phase in ("comic", "question") and self.i >= self._gate() >= 0:
            q = QUIZZES[self.scene]
            chosen = self.answers.get(self.scene)
            out["question"] = {"id": self.scene, "text": q["text"], "a": q["a"], "b": q["b"], "chosen": chosen,
                               "correct": q["correct"] if chosen else None}
        if self.phase == "ready":
            out["ready"] = round(self.ready_left, 2)
        counters: dict[str, Any] = {}
        if self.scene == "TUTORIAL" and self.play:
            counters = {"grapes": self.play["delivered"], "grapes_total": len(GRAPES), "carrying": self.play["carrying"]}
            k = self.play["grape"]
            out["props"] = {"chalice": list(CHALICE), "grape": list(GRAPES[k]) if k < len(GRAPES) and not self.play["carrying"] else None}
        elif self.scene in ("STAGE1", "STAGE2") and self.play:
            counters = {"gates": self.play["passed"], "gates_total": 4}
            if "clock" in self.play:
                counters["clock"] = round(self.play["clock"], 1)
        if self.fight is not None and self.fight.kind != "swat":
            f = self.fight
            counters.update({"dodges": f.dodges, "hits": f.hits,
                             "dodges_needed": GIANT_DODGES if f.kind == "giant" else FATHER_DODGES,
                             "hits_allowed": GIANT_HITS if f.kind == "giant" else 1})
        if self.fight is not None and self.fight.impact is not None:
            out["impact"] = self.fight.impact  # only after an attack has landed
        out["counters"] = counters
        out["walls"] = [[w.z, w.gap_min_x, w.gap_max_x, w.gap_min_y, w.gap_max_y] for w in self.session.simulator.walls]
        return out

    def phone_phase(self) -> dict[str, Any]:
        """Every phone's screen mode ({"t": "phase"} goes to all phones; the question text isn't secret)."""
        view: dict[str, Any] = {"t": "phase", "phase": self.phase, "scene": self.scene}
        if self.phase == "question":
            q = QUIZZES[self.scene]
            view["question"] = {"id": self.scene, "text": q["text"], "a": q["a"], "b": q["b"]}
        return view


def _dist(fly: Any, p: tuple[float, float, float]) -> float:
    return math.sqrt((fly.x - p[0]) ** 2 + (fly.y - p[1]) ** 2 + (fly.z - p[2]) ** 2)
