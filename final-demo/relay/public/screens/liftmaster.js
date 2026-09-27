import { formatNumber, MOVEMENT_ROLES, tipLine } from "./common.js";

export function renderLiftmaster(view = {}) {
  return `
    <section class="screen controller-screen" aria-labelledby="controller-title">
      <header class="controller-header"><span class="crest" aria-hidden="true">↕</span><div><p class="eyebrow">Royal Liftmaster</p><h1 id="controller-title">Guide the climb</h1></div></header>
      <p class="lede">Hold a direction to guide altitude. Release to go neutral.</p>
      <div class="feedback-card" aria-label="Liftmaster feedback">${tipLine(view.tip)}<span>Altitude</span><strong>${formatNumber(view.altitude)}</strong><span>Vertical velocity ${formatNumber(view.verticalVelocity)}</span></div>
      <div class="control-pair vertical" data-role="liftmaster">
        <button class="hold-button positive" data-value="1" aria-label="Hold to climb"><span aria-hidden="true">↑</span><b>Climb</b><small>Hold</small></button>
        <button class="hold-button negative" data-value="-1" aria-label="Hold to descend"><span aria-hidden="true">↓</span><b>Descend</b><small>Hold</small></button>
      </div>
      ${accessibilityToggle()}
    </section>`;
}

export function liftmasterInput(value) { return { ...MOVEMENT_ROLES.liftmaster, value }; }

function accessibilityToggle() {
  return `<label class="toggle"><input id="toggle-mode" type="checkbox"><span>Tap-to-latch controls</span><small>For players who cannot hold buttons continuously.</small></label>`;
}
