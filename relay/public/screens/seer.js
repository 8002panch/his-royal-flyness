import { formatNumber } from "./common.js";

export function renderSeer(view = {}) {
  const giant = view.giant || {};
  return `
    <section class="screen controller-screen seer-screen" aria-labelledby="controller-title">
      <header class="controller-header"><span class="crest" aria-hidden="true">◉</span><div><p class="eyebrow">Royal Seer</p><h1 id="controller-title">Read the court</h1></div></header>
      <p class="lede">Hold scan to request a private sensory reading.</p>
      <button class="scan-button" data-role="seer" data-value="1" aria-label="Hold to scan"><span aria-hidden="true">◉</span><b>Hold to scan</b><small>Private Seer signal</small></button>
      <div class="seer-grid" aria-live="polite">
        <article class="sense-card"><span class="sense-label">Bearing</span><strong>${safeText(view.bearing, "Awaiting scan")}</strong><div class="compass" aria-hidden="true">N<br><span>◈</span><br>S</div></article>
        <article class="sense-card"><span class="sense-label">Distance</span><strong>${safeText(view.distance, "—")}</strong><meter min="0" max="1" value="${clamp(view.confidence)}">${formatNumber(view.confidence, 2)}</meter><small>Confidence ${formatNumber(view.confidence, 2)}</small></article>
        <article class="warning-card"><span class="sense-label">Giant warning</span><strong>${safeText(giant.direction, "No warning")}</strong><small>${typeof giant.seconds === "number" ? `${formatNumber(giant.seconds)} seconds` : "Stay watchful"}</small></article>
      </div>
      ${accessibilityToggle()}
    </section>`;
}

export function seerInput(value) { return { role: "seer", scan: value }; }

function clamp(value) { return typeof value === "number" ? Math.max(0, Math.min(1, value)) : 0; }
function safeText(value, fallback) {
  const text = typeof value === "string" && value ? value : fallback;
  return text.replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[character]);
}
function accessibilityToggle() {
  return `<label class="toggle"><input id="toggle-mode" type="checkbox"><span>Tap-to-latch controls</span><small>For players who cannot hold buttons continuously.</small></label>`;
}
