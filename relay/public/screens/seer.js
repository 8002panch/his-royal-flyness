import { formatNumber } from "./common.js";

// The Royal Seer's private screen, written to be read at a glance and said out loud: where Miranda is and which way to
// steer, and a big red card the moment the fly's brain senses a hand coming. Everything here comes from the brain's own
// reading (seer_view); the phone never adds anything it didn't sense.
const PRINCESS = {
  NW: { arrow: "↖", where: "ahead to the LEFT", call: "Helmsman: steer LEFT" },
  N: { arrow: "↑", where: "straight AHEAD", call: "Wingmaster: fly FORWARD" },
  NE: { arrow: "↗", where: "ahead to the RIGHT", call: "Helmsman: steer RIGHT" },
};
const DISTANCE = { NEAR: "very close", MID: "a little way off", FAR: "far away" };

export function renderSeer(view = {}) {
  const giant = view.giant || {};
  const danger = typeof giant.direction === "string" && giant.direction ? giant.direction.toUpperCase() : "";
  const away = danger === "LEFT" ? "RIGHT" : "LEFT";
  const p = PRINCESS[view.bearing];
  const signal = Math.round(clamp(view.confidence) * 100);
  return `
    <section class="screen controller-screen seer-screen" aria-labelledby="controller-title">
      <header class="controller-header"><span class="crest" aria-hidden="true">◉</span><div><p class="eyebrow">Royal Seer</p><h1 id="controller-title">You see for the fly</h1></div></header>
      <button class="scan-button" data-role="seer" data-value="1" aria-label="Hold to scan"><span aria-hidden="true">◉</span><b>Hold to sense</b><small>Only you see this. Say it out loud.</small></button>
      <div class="seer-grid" aria-live="assertive">
        ${danger ? `
        <article class="seer-card danger-card">
          <span class="seer-label">Danger</span>
          <strong class="seer-big">HAND FROM THE ${escape(danger)}!</strong>
          <p class="seer-call">Shout: <b>“Helmsman, steer ${away}!”</b></p>
          <small>${typeof giant.seconds === "number" ? `About ${formatNumber(giant.seconds)} s` : "Now"}</small>
        </article>` : `
        <article class="seer-card calm-card"><span class="seer-label">Danger</span><strong>No danger sensed</strong><small>Keep holding: a hand shows up here first.</small></article>`}
        ${p ? `
        <article class="seer-card princess-card">
          <span class="seer-label">Miranda</span>
          <div class="seer-arrow" aria-hidden="true">${p.arrow}</div>
          <strong>She is ${p.where}, ${DISTANCE[view.distance] || "somewhere near"}</strong>
          <p class="seer-call">Say: <b>“${p.call}”</b></p>
          <div class="signal"><span style="width:${signal}%"></span></div><small>Signal ${signal}%</small>
        </article>` : `
        <article class="seer-card calm-card"><span class="seer-label">Miranda</span><strong>${view.t === "seer_view" ? "Not sensing Miranda" : "Hold the button to sense"}</strong><small>${view.t === "seer_view" ? "She's not in view of the fly right now." : "The fly's brain reads the court while you hold."}</small></article>`}
      </div>
      ${accessibilityToggle()}
    </section>`;
}

export function seerInput(value) { return { role: "seer", scan: value }; }

function clamp(value) { return typeof value === "number" ? Math.max(0, Math.min(1, value)) : 0; }
function escape(value) {
  return String(value).replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[character]);
}
function accessibilityToggle() {
  return `<label class="toggle"><input id="toggle-mode" type="checkbox"><span>Tap-to-latch controls</span><small>For players who cannot hold buttons continuously.</small></label>`;
}
