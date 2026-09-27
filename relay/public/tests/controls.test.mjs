import assert from "node:assert/strict";
import test from "node:test";

import { buildControlMessage, isPrivateSeerView } from "../screens/common.js";
import { normalizeRoom } from "../screens/join.js";
import { answerMessage, renderStory, showsStoryScreen, storyKey } from "../screens/phase.js";

test("movement roles produce only their assigned protocol axis", () => {
  assert.deepEqual(buildControlMessage("helmsman", -1), { t: "move", role: "helmsman", axis: "x", value: -1 });
  assert.deepEqual(buildControlMessage("liftmaster", 1), { t: "move", role: "liftmaster", axis: "y", value: 1 });
  assert.deepEqual(buildControlMessage("wingmaster", 0), { t: "move", role: "wingmaster", axis: "z", value: 0 });
});

test("seer produces scan messages and private views are identifiable", () => {
  assert.deepEqual(buildControlMessage("seer", 1), { t: "sense", role: "seer", scan: 1 });
  assert.equal(isPrivateSeerView({ t: "seer_view", bearing: "NE" }), true);
  assert.equal(isPrivateSeerView({ t: "control_view", role: "helmsman" }), false);
});

test("join room codes are normalized before validation", () => {
  assert.equal(normalizeRoom(" bzkt "), "BZKT");
});

test("story phases replace the controls; only the Seer gets answer buttons", () => {
  const q = { t: "phase", phase: "question", scene: "Q01", question: { id: "Q01", text: "Alcohol can make balance...", a: "Worse", b: "More precise" } };
  assert.equal(showsStoryScreen(q), true);
  assert.equal(showsStoryScreen({ t: "phase", phase: "play" }), false);
  assert.match(renderStory(q, "seer"), /data-answer="A"/);
  assert.doesNotMatch(renderStory(q, "helmsman"), /data-answer/);
  assert.match(renderStory(q, "helmsman"), /Discuss with your council/);
  assert.match(renderStory(q, "seer", "", "B"), /Answer sent/);
  assert.match(renderStory({ phase: "comic" }, "wingmaster"), /Watch the main screen/);
  assert.notEqual(storyKey(q, "seer", "A"), storyKey(q, "seer", "B"));
  assert.deepEqual(answerMessage("A"), { t: "answer", role: "seer", choice: "A" });
  assert.throws(() => answerMessage("C"));
  assert.doesNotMatch(renderStory({ ...q, question: { ...q.question, text: "<b>x</b>" } }, "seer"), /<b>x<\/b>/);
});
