export const MOVEMENT_ROLES = Object.freeze({
  helmsman: { axis: "x", negative: "Turn left", positive: "Turn right", glyph: "↔" },
  liftmaster: { axis: "y", negative: "Descend", positive: "Climb", glyph: "↕" },
  wingmaster: { axis: "z", negative: "Brake", positive: "Fly forward", glyph: "⇄" },
});

export function buildControlMessage(role, value) {
  const movement = MOVEMENT_ROLES[role];
  if (movement) return { t: "move", role, axis: movement.axis, value };
  if (role === "seer") return { t: "sense", role: "seer", scan: value };
  throw new Error(`Unknown controller role: ${role}`);
}

export function isPrivateSeerView(message) {
  return message?.t === "seer_view";
}

export function formatNumber(value, digits = 1) {
  return typeof value === "number" && Number.isFinite(value) ? value.toFixed(digits) : "—";
}
