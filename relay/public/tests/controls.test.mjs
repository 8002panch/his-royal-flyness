import assert from "node:assert/strict";
import test from "node:test";

import { buildControlMessage, isPrivateSeerView } from "../screens/common.js";
import { normalizeRoom } from "../screens/join.js";

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
