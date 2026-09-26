import { formatNumber, MOVEMENT_ROLES } from "./common.js";

export function renderWingmaster(view = {}) {
    return `
    <section class="screen controller-screen" aria-labelledby="controller-title">
      <header class="controller-header"><span class="crest" aria-hidden="true">⇄</span><div><p class="eyebrow">Royal Wingmaster</p><h1 id="controller-title">Set the pace</h1></div></header>
      <p class="lede">Hold forward to fly; hold brake to slow or reverse. Release to go neutral.</p>
      <div class="feedback-card" aria-label="Wingmaster feedback"><span>Actual speed</span><strong>${formatNumber(view.speed)}</strong><span>${view.braking ? "Braking engaged" : "Flight ready"}</span></div>
      <div class="control-pair" data-role="wingmaster">
        <button class="hold-button negative" data-value="-1" aria-label="Hold to brake"><span aria-hidden="true">▣</span><b>Brake</b><small>Hold</small></button>
        <button class="hold-button positive" data-value="1" aria-label="Hold to fly forward"><span aria-hidden="true">➜</span><b>Forward</b><small>Hold</small></button>
      </div>
      ${accessibilityToggle()}
    </section>`;
}

export function wingmasterInput(value) { return { ...MOVEMENT_ROLES.wingmaster, value }; }

function accessibilityToggle() {
  return `<label class="toggle"><input id="toggle-mode" type="checkbox"><span>Tap-to-latch controls</span><small>For players who cannot hold buttons continuously.</small></label>`;
}
