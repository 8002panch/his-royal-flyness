import { buildControlMessage, isPrivateSeerView } from "./screens/common.js";
import { joinScreen, normalizeRoom, randomRoyalName, roleScreen } from "./screens/join.js";
import { renderHelmsman } from "./screens/helmsman.js";
import { renderLiftmaster } from "./screens/liftmaster.js";
import { renderWingmaster } from "./screens/wingmaster.js";
import { renderSeer } from "./screens/seer.js";
import { answerMessage, renderStory, showsStoryScreen, storyKey } from "./screens/phase.js";

const app = document.querySelector("#app");
const reconnectOverlay = document.querySelector("#reconnect-overlay");
const CLIENT_ID_KEY = "his-royal-flyness-client-id";
const PROFILE_KEY = "his-royal-flyness-profile";
const state = { socket: null, seq: 0, room: "", name: "", role: "", joined: false, availableRoles: [], heldValue: 0, latchMode: false, view: {}, reconnectTimer: null,
  phase: null, selected: "", sent: {} };
const toast = document.querySelector("#toast");
let toastTimer = null;

function getClientId() {
  let clientId = localStorage.getItem(CLIENT_ID_KEY);
  if (!clientId) { clientId = crypto.randomUUID?.() || `phone-${Date.now()}-${Math.random()}`; localStorage.setItem(CLIENT_ID_KEY, clientId); }
  return clientId;
}

function relayUrl() {
  const override = new URLSearchParams(location.search).get("relay");
  if (override) return override;
  if (window.RELAY_URL) return window.RELAY_URL;                            // config.js: page hosted apart from the relay
  if (location.protocol === "https:") return `wss://${location.host}/ws`;  // behind Caddy (relay/Caddyfile)
  return `ws://${location.hostname || "localhost"}:8080`;                   // run_local.py on the local network
}

function nextMessage(message) { return { ...message, seq: ++state.seq }; }
function send(message) { if (state.socket?.readyState === WebSocket.OPEN) state.socket.send(JSON.stringify(nextMessage(message))); }
// The room, name and seat live in sessionStorage: a reload (or a dropped connection) in this tab gets the same seat back,
// but a fresh scan of the QR code always starts at the join form with no name and no role picked for you.
function saveProfile() { try { sessionStorage.setItem(PROFILE_KEY, JSON.stringify({ room: state.room, name: state.name, role: state.role })); } catch {} }
function loadProfile() { try { return JSON.parse(sessionStorage.getItem(PROFILE_KEY)) || {}; } catch { return {}; } }

function render() {
  if (!state.role) {
    // joined but not seated: the picker (even when every seat is taken); otherwise the join form
    const screen = state.joined ? "picker" : "join";
    app.dataset.screen = screen;
    app.innerHTML = state.joined ? roleScreen(state.availableRoles) : joinScreen({ room: state.room, name: state.name });
    if (state.joined) bindRolePicker(); else bindJoin();
    return;
  }
  if (showsStoryScreen(state.phase)) return renderStoryScreen();
  const views = { helmsman: renderHelmsman, liftmaster: renderLiftmaster, wingmaster: renderWingmaster, seer: renderSeer };
  const html = views[state.role](state.view);
  if (app.dataset.screen === state.role && patchReadouts(html)) return;
  app.innerHTML = html;
  app.dataset.screen = state.role;
  bindControls();
}

// Comics, questions, the lobby and the end: the story screen replaces the controls (a held control is released first).
function renderStoryScreen() {
  releaseControl();
  const quiz = state.phase.question?.id || "";
  const sent = state.sent[quiz] || "";
  const key = storyKey(state.phase, state.role, state.selected, sent);
  if (app.dataset.screen === key) return;
  app.dataset.screen = key;
  app.innerHTML = renderStory(state.phase, state.role, state.selected, sent);
  app.querySelectorAll("[data-answer]").forEach((button) => button.addEventListener("click", () => { state.selected = button.dataset.answer; render(); }));
  app.querySelector("#confirm-answer")?.addEventListener("click", () => {
    if (!state.selected || !quiz) return;
    send(answerMessage(state.selected));
    state.sent[quiz] = state.selected;
    state.selected = "";
    render();
  });
}

// Feedback arrives 10 times a second: update only the readouts, so the button under a player's finger is never
// replaced in the middle of a hold (which can drop or stick the input on phones).
function patchReadouts(html) {
  const next = document.createElement("template");
  next.innerHTML = html;
  const fresh = next.content.querySelectorAll(".feedback-card, .seer-grid");
  const current = app.querySelectorAll(".feedback-card, .seer-grid");
  if (!fresh.length || fresh.length !== current.length) return false;
  current.forEach((element, index) => element.replaceWith(fresh[index]));
  return true;
}

function bindJoin() {
  const form = document.querySelector("#join-form");
  document.querySelector("#random-name")?.addEventListener("click", () => { form.name.value = randomRoyalName(); });
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    state.room = normalizeRoom(form.room.value);
    state.name = form.name.value.trim();
    if (!/^[BCDFGHJKLMNPQRSTVWXYZ]{4}$/.test(state.room)) return showJoinError("Use four uppercase consonants, for example BZKT.");
    if (!state.name) return showJoinError("Enter a name for your station.");
    saveProfile(); connect(true);
  });
}

function showNotice(message) {
  toast.textContent = message;
  toast.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { toast.hidden = true; }, 4000);
}

// Errors never replace or freeze the screen: on the join form they show under it, anywhere else as a short notice.
function showJoinError(message) {
  const slot = document.querySelector("#form-error");
  if (slot) slot.textContent = message; else showNotice(message);
}
function bindRolePicker() { document.querySelectorAll("[data-role]").forEach((button) => button.addEventListener("click", () => send({ t: "pick", role: button.dataset.role }))); }

function bindControls() {
  const toggle = document.querySelector("#toggle-mode");
  toggle.checked = state.latchMode;
  toggle.addEventListener("change", () => {
    state.latchMode = toggle.checked;
    if (!state.latchMode) releaseControl();
  });
  document.querySelectorAll("[data-value]").forEach((button) => {
    const value = Number(button.dataset.value);
    const press = (event) => {
      event.preventDefault();
      if (toggle.checked) return state.heldValue ? releaseControl() : activateControl(value, button);
      activateControl(value, button);
      button.setPointerCapture?.(event.pointerId);
    };
    button.addEventListener("pointerdown", press);
    ["pointerup", "pointercancel", "lostpointercapture"].forEach((type) => button.addEventListener(type, () => { if (!toggle.checked) releaseControl(); }));
  });
  if (state.heldValue) document.querySelector(`[data-value="${state.heldValue}"]`)?.classList.add("is-active");
}

function activateControl(value, button) {
  if (state.heldValue && state.heldValue !== value) releaseControl();
  state.heldValue = value;
  document.querySelectorAll("[data-value]").forEach((element) => element.classList.toggle("is-active", Number(element.dataset.value) === value));
  send(buildControlMessage(state.role, value));
}

function releaseControl() {
  if (!state.heldValue) return;
  state.heldValue = 0;
  document.querySelectorAll("[data-value]").forEach((element) => element.classList.remove("is-active"));
  send(buildControlMessage(state.role, 0));
  if (state.role === "seer") { state.view = {}; render(); }  // no reading while not sensing: never a stale warning
}

function connect(isNewJoin = false) {
  clearTimeout(state.reconnectTimer);
  reconnectOverlay.hidden = !state.room || isNewJoin;
  const oldSocket = state.socket;
  state.socket = null;
  oldSocket?.close();
  let socket;
  try { socket = new WebSocket(relayUrl()); } catch { scheduleReconnect(); return; }
  state.socket = socket;
  socket.addEventListener("open", () => {
    if (state.socket !== socket) return;
    reconnectOverlay.hidden = true; state.seq = 0;
    const lastRole = loadProfile().role;  // lets the relay give this phone its role back even after a restart
    send({ t: "join", room: state.room, name: state.name, clientId: getClientId(), ...(lastRole && isNewJoin === false ? { role: lastRole } : {}) });
  });
  socket.addEventListener("message", ({ data }) => { if (state.socket === socket) handleMessage(data); });
  socket.addEventListener("close", () => { if (state.socket === socket) { releaseControl(); scheduleReconnect(); } });
  socket.addEventListener("error", () => socket.close());
}

// The game this phone was in is gone (a new code, or the host removed it): back to the join form, forget the old code and
// role so the phone never keeps retrying a dead room, and say what happened.
function leaveCourt(message) {
  releaseControl();
  state.role = ""; state.joined = false; state.availableRoles = []; state.room = "";
  try { sessionStorage.setItem(PROFILE_KEY, JSON.stringify({ name: state.name })); } catch {}
  const url = new URL(location.href);
  url.searchParams.delete("room");
  history.replaceState(null, "", url);
  render();
  showJoinError(message);
}

function scheduleReconnect() { reconnectOverlay.hidden = false; clearTimeout(state.reconnectTimer); state.reconnectTimer = setTimeout(() => connect(), 1200); }

function handleMessage(data) {
  let message; try { message = JSON.parse(data); } catch { return; }
  if (message.t === "joined") { state.joined = true; state.availableRoles = message.roles || []; state.role = ""; render(); return; }
  if (message.t === "room_closed") return leaveCourt("That game has ended. Enter the new code from the main screen.");
  if (message.t === "kicked") return leaveCourt("The host removed you from this court.");
  if (message.t === "seat_moved") { releaseControl(); state.role = ""; state.joined = true; render(); showNotice("Your seat moved to your newer page."); return; }
  if (message.t === "roles") { state.availableRoles = message.roles || []; if (!state.role && state.joined) render(); return; }
  if (message.t === "assigned") { state.joined = true; state.role = message.role; state.availableRoles = []; state.view = {}; saveProfile(); render(); return; }
  if (message.t === "phase") {
    if (message.question?.id !== state.phase?.question?.id) state.selected = "";
    state.phase = message; if (state.role) render(); return;
  }
  if (message.t === "control_view" && message.role === state.role) { state.view = message; render(); return; }
  if (isPrivateSeerView(message) && state.role === "seer") {
    if (!state.heldValue) return;  // a reading that arrives after letting go
    const danger = message.giant?.direction;
    const before = state.view?.giant || {};
    // A new hand: a warning where there was none, or the brain's time-to-impact jumping back up (the next hand of a volley)
    const fresh = danger && (!before.direction || (typeof message.giant.seconds === "number" && typeof before.seconds === "number"
      && message.giant.seconds > before.seconds + 0.5));
    if (fresh) { navigator.vibrate?.([120, 60, 120]); state.againUntil = before.direction ? Date.now() + 1500 : 0; }
    state.view = { ...message, again: danger && Date.now() < (state.againUntil || 0) };
    render(); return;
  }
  if (message.t === "error") {
    if (message.code === "ROLE_TAKEN") return showNotice("Someone just took that role. Pick another.");
    if (["ROOM_NOT_FOUND", "REMOVED"].includes(message.code)) return leaveCourt(message.message);  // an old or closed code
    if (message.code === "NAME_TAKEN" || message.code === "ROOM_LOCKED") { state.joined = false; state.role = ""; render(); return showJoinError(message.message); }
    if (!state.joined) render();  // back to the join form, never a blank page
    showJoinError(message.message);
  }
}

// While a control is held, resend it every 400 ms: the game server drops any input it hasn't heard about for 1.2 s,
// and heartbeats stop at the relay. Otherwise send a plain heartbeat once a second.
let lastBeat = 0;
setInterval(() => {
  if (!state.role) return;
  if (state.heldValue) { send(buildControlMessage(state.role, state.heldValue)); lastBeat = Date.now(); }
  else if (Date.now() - lastBeat >= 1000) { send({ t: "heartbeat" }); lastBeat = Date.now(); }
}, 400);
document.addEventListener("visibilitychange", () => { if (document.hidden) releaseControl(); });
window.addEventListener("pagehide", releaseControl);

// A join link or QR code (http://<laptop>:8000/?room=BZKT) fills in the room code; a saved profile only auto-joins its own room.
const saved = loadProfile();
const linkedRoom = normalizeRoom(new URLSearchParams(location.search).get("room") || "");
state.room = linkedRoom || saved.room || "";
state.name = saved.name || "";
render();  // always draw the join form first, so the page is never blank while it connects
if (state.room && state.name && (!linkedRoom || linkedRoom === saved.room)) connect();
