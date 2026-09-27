import { formatNumber, MOVEMENT_ROLES, tipLine } from "./common.js";

export function renderHelmsman(view = {}) {
  return `
    <section class="screen controller-screen" aria-labelledby="controller-title">
      <header class="controller-header"><span class="crest" aria-hidden="true">↔</span><div><p class="eyebrow">Royal Helmsman</p><h1 id="controller-title">Guide the turn</h1></div></header>
      <p class="lede">Hold a direction to guide horizontal movement. Release to go neutral.</p>
      <div class="feedback-card" aria-label="Helmsman feedback">${tipLine(view.tip)}<span>Actual drift</span><strong>${formatNumber(view.actualX)}</strong><span>Momentum ${formatNumber(view.momentum)}</span></div>
      <div class="control-pair" data-role="helmsman">
        <button class="hold-button negative" data-value="-1" aria-label="Hold to turn left"><span aria-hidden="true">←</span><b>Turn left</b><small>Hold</small></button>
        <button class="hold-button positive" data-value="1" aria-label="Hold to turn right"><span aria-hidden="true">→</span><b>Turn right</b><small>Hold</small></button>
      </div>
      ${accessibilityToggle()}
    </section>`;
}

export function helmsmanInput(value) { return { ...MOVEMENT_ROLES.helmsman, value }; }

function accessibilityToggle() {
  return `<label class="toggle"><input id="toggle-mode" type="checkbox"><span>Tap-to-latch controls</span><small>For players who cannot hold buttons continuously.</small></label>`;
}
