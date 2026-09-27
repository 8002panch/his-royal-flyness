"""The story campaign against Arnav's acceptance checklist (docs/GAME.md): an autopilot flies, a scripted Seer answers."""

from __future__ import annotations

import json
import math
from pathlib import Path

import pytest

from server import campaign as cm
from server.main import GameSession

DT = 0.02
VOICE_IDS = {e["id"] for e in json.loads((Path(__file__).resolve().parents[2] / "audio/voice/manifest.json").read_text())["lines"]}


class Game:
    def __init__(self, scene: str | None = None) -> None:
        self.s = GameSession("BZKT", campaign=True, join_url="http://192.168.1.5:8000/?room={room}")
        self.c = self.s.campaign
        self.t = 0.0
        self.voices: list[str] = []
        self.results: list[tuple[str, str, int]] = []
        if scene:
            self.c.jump(scene)
            self.drain()

    def drain(self) -> None:
        for e in self.c.events:
            if e["kind"] == "voice":
                self.voices.append(e["id"])
            elif e["kind"] in ("dodge", "hit"):
                self.results.append((e["kind"], e["fight"], e["n"]))
        self.c.events.clear()

    def hold(self, x: int = 0, y: int = 0, z: int = 0) -> None:
        for role, axis, v in (("helmsman", "x", x), ("liftmaster", "y", y), ("wingmaster", "z", z)):
            self.s.apply_input({"t": "move", "role": role, "axis": axis, "value": v}, self.t)

    def step(self, pilot=None) -> None:
        if pilot is not None:
            self.hold(*pilot(self))
        self.s.step(DT, self.t)
        self.t += DT
        self.drain()

    def run(self, seconds: float, pilot=None, until=None) -> bool:
        for _ in range(int(seconds / DT)):
            self.step(pilot)
            if until is not None and until(self):
                return True
        return False

    def read_comic(self) -> None:
        """The presenter reads to the end of this comic (stops at a question)."""
        scene = self.c.scene
        for _ in range(200):
            if self.c.phase != "comic" or self.c.scene != scene:
                return
            self.c.next()
            self.drain()


def toward(fly, target, axis: str) -> int:
    """Bang-bang with braking: head for the target, brake when the stopping distance runs out."""
    pos, vel = getattr(fly, axis), getattr(fly, "v" + axis)
    err = target - pos
    if abs(err) < 0.03 and abs(vel) < 0.15:
        return 0
    want = 1 if err > 0 else -1
    if vel * want > 0 and vel * vel / (2 * 2.0) >= abs(err) - 0.02:
        return -want
    return want


def fly_to(target):
    def pilot(g: Game):
        f = g.s.state.fly
        return toward(f, target[0], "x"), toward(f, target[1], "y"), toward(f, target[2], "z")
    return pilot


def course_pilot(g: Game):
    """Fly through each wall's opening in turn, then to the goal."""
    f = g.s.state.fly
    ahead = [w for w in g.s.simulator.walls if w.z > f.z - 0.02]
    if not ahead:
        return fly_to((0.0, 0.0, 0.97))(g)
    w = ahead[0]
    gx, gy = (w.gap_min_x + w.gap_max_x) / 2, (w.gap_min_y + w.gap_max_y) / 2
    lined_up = abs(f.x - gx) < 0.12 and abs(f.y - gy) < 0.12
    return toward(f, gx, "x"), toward(f, gy, "y"), toward(f, w.z + 0.15 if lined_up else w.z - 0.12, "z")


def dodge_pilot(g: Game):
    """The Seer's call acted on: move away from the side the hand comes from; otherwise drift back to the middle."""
    f, fight = g.s.state.fly, g.c.fight
    a = fight.attack if fight else None
    if a is None:
        return toward(f, 0.0, "x"), toward(f, 0.0, "y"), 0
    away = 0.55 if a.side == "left" else -0.55
    return toward(f, max(-0.95, min(0.95, a.target[0] + away)), "x"), 0, 0


# ------------------------------------------------------------------ lobby and comics

def test_lobby_shows_the_qr_then_start_reaches_flight():
    g = Game()
    state = g.s.godot_state()
    assert state["phase"] == "lobby" and len(state["joinQr"]) >= 21 and set("".join(state["joinQr"])) <= {"0", "1"}
    g.s.godot_state()  # the QR is cached
    g.c.next()  # Enter in the lobby starts the story
    assert (g.c.scene, g.c.phase) == ("TUTORIAL", "ready") and not g.c.demo
    g.hold(z=1)
    g.run(1.0, pilot=lambda g: (0, 0, 1))
    assert g.s.state.fly.z == pytest.approx(-0.95), "the count-in keeps the fly still"
    g.run(1.5, pilot=lambda g: (0, 0, 1))
    assert g.c.phase == "play" and g.s.state.fly.z > -0.95
    assert "joinQr" not in g.s.godot_state()


def test_comics_play_every_line_on_the_route_and_back_rereads():
    g = Game("C01")
    assert g.c.phase == "comic" and g.voices == ["C01_P1_CLOWN"]
    g.c.next(); g.c.next(); g.c.back(); g.drain()
    assert g.voices[-1] == "C01_P2_HAMLET" and g.c.i == 1
    g.read_comic()
    assert g.c.scene == "Q01"
    assert all(v in VOICE_IDS for v in g.voices)
    state = g.s.godot_state()
    assert state["beat"]["speaker"] == "tinman" and state["backdrop"] == "window_ledge"


# ------------------------------------------------------------------ quizzes

def test_only_the_seer_answers_once_and_skip_never_answers():
    g = Game("Q01")
    g.c.skip()
    assert g.c.phase == "question" and "Q01" not in g.c.answers, "Skip stops at the question"
    g.c.skip(); g.c.next()
    assert g.c.phase == "question", "nothing moves past an unanswered question"
    with pytest.raises(ValueError):
        g.s.apply_input({"t": "answer", "role": "helmsman", "choice": "A"}, 0.0)
    assert g.s.phone_views()[-1] == {"t": "phase", "phase": "question", "scene": "Q01",
                                     "question": {"id": "Q01", "text": cm.QUIZZES["Q01"]["text"], "a": "Worse", "b": "More precise"}}
    g.s.apply_input({"t": "answer", "role": "seer", "choice": "B"}, 0.0)
    assert g.c.answers == {"Q01": "B"} and g.c.dizzy == 1
    g.s.apply_input({"t": "answer", "role": "seer", "choice": "A"}, 0.0)  # a second answer (a reconnect, a double tap)
    g.c.back(); g.c.back()
    assert g.c.answers == {"Q01": "B"} and g.c.dizzy == 1, "applied once, Back can't undo it"
    g.read_comic(); g.drain()
    assert "Q01_P3B_TINMAN" in g.voices and "Q01_P3A_TINMAN" not in g.voices
    assert g.s.simulator.tuning.drag_per_second == pytest.approx(cm.MovementTuning().drag_per_second / 1.1)


def test_a_correct_answer_adds_nothing():
    g = Game("Q02")
    g.c.skip()
    g.s.apply_input({"t": "answer", "role": "seer", "choice": "B"}, 0.0)
    g.read_comic()
    assert g.c.dizzy == 0 and "Q02_P3A_RUTABAGA" in g.voices and "Q02_P3B_RUTABAGA" not in g.voices
    assert g.c.scene == "STAGE2"


# ------------------------------------------------------------------ flight

def test_tutorial_counts_four_unique_deliveries_and_miranda_only_for_the_seer_lesson():
    g = Game("TUTORIAL")
    g.run(2.1)
    for k, grape in enumerate(cm.GRAPES):
        assert g.run(12, pilot=fly_to(grape), until=lambda g: g.c.play.get("carrying")), f"picked up grape {k + 1}"
        assert (g.c.stimuli()["princess"] is not None) == (k == 3)
        assert ("TUT_SEER" in g.c.said) == (k == 3), "the Seer's lesson starts with the last grape"
        g.run(1.0, pilot=fly_to(grape))  # lingering on the grape doesn't count it again
        assert g.c.play["delivered"] == k
        done = g.run(12, pilot=fly_to(cm.CHALICE), until=lambda g, k=k: g.c.play.get("delivered", 4) > k or g.c.scene != "TUTORIAL")
        assert done, f"delivered grape {k + 1}"
    assert g.run(30, until=lambda g: g.c.scene == "C01")
    assert {"TUT_WELCOME", "TUT_FINISH", "TUT_FINISH_MIRANDA"} <= set(g.voices)  # a fast team skips stale tips


def test_stage1_walls_block_and_the_course_can_be_flown():
    g = Game("STAGE1")
    g.run(2.1)
    g.run(3, pilot=lambda g: (0, 0, 1))  # straight ahead hits the first wall (its opening is off to the left)
    assert g.c.play["passed"] == 0
    assert g.s.state.fly.z < cm.STAGE1_WALLS[0].z
    assert g.run(40, pilot=course_pilot, until=lambda g: g.c.scene != "STAGE1")
    assert g.c.scene == "Q02"


def test_stage2_clock_freezes_outside_flight_and_max_dizziness_can_still_finish():
    g = Game("STAGE2")
    g.c.dizzy = 3
    g.c._apply_dizziness()
    g.run(1.9)
    assert g.c.phase == "ready" and g.c.play["clock"] == cm.STAGE2_SECONDS, "the clock waits for the count-in"
    g.run(0.2)
    ok = g.run(60, pilot=lambda g: dodge_pilot(g) if g.c.fight and g.c.fight.attack else course_pilot(g),
               until=lambda g: g.c.scene != "STAGE2")
    assert ok and g.c.scene == "Q03"


def test_stage2_timeout_or_a_swat_restarts_without_repeating_anything():
    g = Game("STAGE2")
    g.run(2.1)
    assert g.run(20, until=lambda g: g.c.phase == "ready"), "standing still: the first swat lands on Hamlet"
    assert g.c.play["clock"] == cm.STAGE2_SECONDS and g.c.scene == "STAGE2" and g.c.dizzy == 0
    assert not [r for r in g.results if r[0] == "hit"], "Stage 2 swats never count toward the Giant fight"


# ------------------------------------------------------------------ fights and endings

def test_ten_dodges_choose_c03_then_e01_with_no_extra_attack():
    g = Game("GIANT")
    g.run(2.1)
    assert g.run(90, pilot=dodge_pilot, until=lambda g: g.c.scene != "GIANT")
    assert g.c.scene == "C03" and [r for r in g.results if r[0] == "dodge"] == [("dodge", "giant", n) for n in range(1, 11)]
    assert not [r for r in g.results if r[0] == "hit"]
    g.read_comic()
    assert g.c.scene == "E01" and "E01_P1A_MIRANDA" in [b.id for b in g.c.beat_list]
    g.read_comic()
    assert g.c.phase == "end"


def test_three_hits_choose_c04_and_one_father_hit_chooses_e02():
    g = Game("GIANT")
    g.run(2.1)
    assert g.run(60, until=lambda g: g.c.scene != "GIANT")  # nobody dodges
    assert g.c.scene == "C04" and [r for r in g.results if r[0] == "hit"] == [("hit", "giant", n) for n in (1, 2, 3)]
    g.read_comic()
    assert g.c.scene == "FATHER"
    g.run(2.1)
    assert g.run(30, until=lambda g: g.c.scene != "FATHER")
    assert g.c.scene == "E02" and ("hit", "father", 1) in g.results
    assert len([r for r in g.results if r[1] == "father"]) == 1, "the fight ends at the hit"


def test_five_untouched_father_dodges_choose_e01_second_chance():
    g = Game("FATHER")
    g.run(2.1)
    assert g.run(60, pilot=dodge_pilot, until=lambda g: g.c.scene != "FATHER")
    assert g.c.scene == "E01" and [r for r in g.results if r[1] == "father"] == [("dodge", "father", n) for n in range(1, 6)]
    ids = [b.id for b in g.c.beat_list]
    assert "E01_P1B_MIRANDA" in ids and "E01_P1A_MIRANDA" not in ids


def test_the_seers_secret_nothing_about_an_attack_reaches_the_shared_screen_before_it_lands():
    g = Game("GIANT")
    g.run(2.1)
    seen_warning = False
    for _ in range(int(30 / DT)):
        g.step()
        state = json.dumps(g.s.godot_state())
        phase_views = [v for v in g.s.phone_views() if v["t"] == "phase"]
        a = g.c.fight.attack if g.c.fight else None
        if a is not None:
            seen_warning = True
            assert g.c.stimuli()["giants"], "the brain gets the approaching hand"
            assert "impact" not in g.s.godot_state() or g.s.godot_state()["impact"]["at"] < a.onset
            assert a.side not in state and "giants" not in state
            assert all("side" not in json.dumps(v) for v in phase_views)
    assert seen_warning


def test_jumps_mark_demo_and_a_new_story_clears_it():
    g = Game()
    assert g.c.jump("GIANT") and g.c.demo and g.s.godot_state()["storyDemo"] is True
    assert not g.c.jump("NOPE")
    g.c.start()
    assert not g.c.demo and g.c.scene == "TUTORIAL" and g.c.answers == {} and g.c.dizzy == 0


def test_the_free_flight_world_is_unchanged_without_a_campaign():
    s = GameSession("BZKT")
    assert s.campaign is None and s.godot_state()["phase"] == "play"
    s.apply_input({"t": "move", "role": "wingmaster", "axis": "z", "value": 1}, 0.0)
    s.step(0.1, 0.1)
    assert s.state.fly.vz > 0 and math.isfinite(s.state.fly.z)


def test_the_real_brain_warns_the_seer_of_each_attack_and_the_changeling_does_not():
    """The connectome's job in the story: the True Prince's looming neurons and Giant Fiber warn the Seer's phone, from the
    right side, before each hand lands; the Changeling (same neurons, scrambled partners) doesn't. Needs data/ (skips otherwise)."""
    from server.main import make_seer

    warned = {}
    for source in ("true", "changeling"):
        seer = make_seer(source)
        if seer.source != source:
            pytest.skip("the brain's data files aren't built (python -m brain.build_graph && python -m brain.changeling)")
        g = Game()
        g.s.seer, g.s.sense_in_step = seer, False  # as the live server: the brain on its own 20 ms steps
        g.c.jump("GIANT")
        warned[source] = {}
        for _ in range(int(20 / DT)):
            g.s.apply_input({"t": "sense", "role": "seer", "scan": 1}, g.t)
            g.step()
            g.s.cues = seer.sense(g.s.stimuli, dt=DT)
            a = g.c.fight.attack if g.c.fight else None
            views = [v for v in g.s.phone_views() if v["t"] == "seer_view"]  # none during the count-in (inputs clear)
            view = views[-1] if views else {"giant": {"direction": None}}
            if a is not None and view["giant"]["direction"] and a.n not in warned[source]:
                warned[source][a.n] = (view["giant"]["direction"], a.side.upper(), a.impact - g.c.fight.t)
    assert len(warned["true"]) >= 3 and all(d == s and lead > 0.8 for d, s, lead in warned["true"].values()), warned
    assert warned["changeling"] == {}


def test_tutorial_coaching_points_each_mover_at_the_grape_and_stays_off_for_the_seers_lesson():
    g = Game("TUTORIAL")
    g.run(2.5)
    guide = g.c.guide()
    assert guide["goal"] == "grape" and guide["z"] == "forward"  # grape 1 is straight ahead: only the Wingmaster moves
    tips = {v["role"]: v.get("tip") for v in g.s.phone_views() if v["t"] == "control_view"}
    assert tips["wingmaster"] == "Grape: fly forward" and tips["helmsman"] == "Grape: lined up"
    g.c.play.update(grape=len(cm.GRAPES) - 1, delivered=len(cm.GRAPES) - 1, carrying=True)
    assert g.c.guide() == {}  # the last return is the Seer's to call
    assert all("tip" not in v for v in g.s.phone_views() if v["t"] == "control_view")


def test_the_last_return_faces_miranda_so_the_brain_can_see_her():
    """The fly always faces +z; the Seer's lesson needs Miranda in front of it on the way back from the last grape."""
    fly = type("F", (), {"x": cm.GRAPES[-1][0], "y": cm.GRAPES[-1][1], "z": cm.GRAPES[-1][2]})()
    assert abs(cm._cue(fly, cm.MIRANDA_BY_CHALICE)["bearing_deg"]) < 80
    assert cm.GRAPES[-1][2] < cm.CHALICE[2]


def test_a_chapter_jump_drops_the_last_scenes_tips():
    g = Game("TUTORIAL")
    g.c.hints += ["TUT_GRAPE_2", "TUT_GRAPE_3"]  # tips still waiting their turn when the presenter jumps
    g.c.jump("STAGE1")
    assert not any(h.startswith("TUT_") for h in g.c.hints)


def test_no_brain_bars_on_the_shared_screen_during_a_fight():
    g = Game("GIANT")
    g.s.cues = {"source": "true", "activity": {"vision": 1.0, "looming": 3.0, "escape": 2.0}}
    assert g.s.godot_state()["brainActivity"] == {}
    g.c.jump("TUTORIAL")
    assert g.s.godot_state()["brainActivity"]["looming"] == 3.0
