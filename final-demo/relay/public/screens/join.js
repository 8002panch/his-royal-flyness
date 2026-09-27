export const ROLE_DETAILS = Object.freeze([
  { role: "helmsman", crest: "↔", title: "Royal Helmsman", copy: "Steer the fly horizontally." },
  { role: "liftmaster", crest: "↕", title: "Royal Liftmaster", copy: "Guide altitude up and down." },
  { role: "wingmaster", crest: "⇄", title: "Royal Wingmaster", copy: "Control forward speed and braking." },
  { role: "seer", crest: "◉", title: "Royal Seer", copy: "Scan for private sensory cues." },
]);

// Kahoot-style name generator: a quick, safe name for anyone who doesn't want to type one
const TITLES = ["Sir", "Lady", "Duke", "Duchess", "Baron", "Baroness", "Count", "Countess", "Lord", "Dame"];
const NAMES = ["Buzzington", "Wingsworth", "Hoverly", "Flutterby", "Buzzby", "Thorax", "Honeydew", "Larvington", "Zumzum", "Swatless", "Nectarine", "Proboscis"];

export function randomRoyalName(random = Math.random) {
  return `${TITLES[Math.floor(random() * TITLES.length)]} ${NAMES[Math.floor(random() * NAMES.length)]}`;
}

export function normalizeRoom(value) {
  return value.trim().toUpperCase();
}

export function joinScreen({ room = "", name = "", error = "" } = {}) {
  return `
    <section class="screen join-screen" aria-labelledby="join-title">
      <p class="eyebrow">His Royal Flyness</p>
      <h1 id="join-title">Take your station</h1>
      <p class="lede">This phone is a controller. The game appears on the shared laptop screen.</p>
      <form id="join-form" class="stack" novalidate>
        <label>Room code
          <input id="room" name="room" inputmode="text" autocapitalize="characters" autocomplete="off" maxlength="4" value="${escapeHtml(room)}" placeholder="BZKT" required>
        </label>
        <label>Your name
          <input id="name" name="name" autocomplete="name" maxlength="32" value="${escapeHtml(name)}" placeholder="Ava" required>
        </label>
        <button class="secondary" type="button" id="random-name">Random royal name</button>
        <button class="primary" type="submit">Enter the court</button>
      </form>
      <p class="form-error" id="form-error" role="alert">${escapeHtml(error)}</p>
      <p class="microcopy">Room codes use four uppercase consonants. No game map or shared scene is shown here.</p>
    </section>`;
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[character]);
}

export function roleScreen(roles = []) {
  const available = new Set(roles);
  const full = available.size === 0;
  return `
    <section class="screen" aria-labelledby="role-title">
      <p class="eyebrow">Choose your station</p>
      <h1 id="role-title">${full ? "The court is full" : "The court awaits"}</h1>
      <p class="lede">${full ? "All four roles are taken. Stay on this page: you can grab a seat the moment one opens." : "Each role owns one control. A crest marked occupied is unavailable."}</p>
      <div class="role-grid">
        ${ROLE_DETAILS.map(({ role, crest, title, copy }) => `
          <button class="role-card" data-role="${role}" ${available.has(role) ? "" : "disabled"}>
            <span class="crest" aria-hidden="true">${crest}</span>
            <span class="role-title">${title}</span>
            <span class="role-copy">${available.has(role) ? copy : "Occupied"}</span>
          </button>`).join("")}
      </div>
      <p class="microcopy">Your role is saved on this phone for reconnecting.</p>
    </section>`;
}
