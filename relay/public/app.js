import { buildControlMessage, isPrivateSeerView } from "./screens/common.js";
import { joinScreen, normalizeRoom, roleScreen } from "./screens/join.js";
import { renderHelmsman } from "./screens/helmsman.js";
import { renderLiftmaster } from "./screens/liftmaster.js";
import { renderWingmaster } from "./screens/wingmaster.js";
import { renderSeer } from "./screens/seer.js";

const app = document.querySelector("#app");
const reconnectOverlay = document.querySelector("#reconnect-overlay");
const CLIENT_ID_KEY = "his-royal-flyness-client-id";
const PROFILE_KEY = "his-royal-flyness-profile";
const state = { socket: null, seq: 0, room: "", name: "", role: "", availableRoles: [], heldValue: 0, latchMode: false, view: {}, reconnectTimer: null };

function getClientId() {
  let clientId = localStorage.getItem(CLIENT_ID_KEY);
  if (!clientId) { clientId = crypto.randomUUID?.() || `phone-${Date.now()}-${Math.random()}`; localStorage.setItem(CLIENT_ID_KEY, clientId); }
  return clientId;
}

function relayUrl() {
  const override = new URLSearchParams(location.search).get("relay");
  if (override) return override;
  return `${location.protocol === "https:" ? "wss" : "ws"}://${location.hostname || "localhost"}:8080`;
}

function nextMessage(message) { return { ...message, seq: ++state.seq }; }
function send(message) { if (state.socket?.readyState === WebSocket.OPEN) state.socket.send(JSON.stringify(nextMessage(message))); }
function saveProfile() { localStorage.setItem(PROFILE_KEY, JSON.stringify({ room: state.room, name: state.name })); }
function loadProfile() { try { return JSON.parse(localStorage.getItem(PROFILE_KEY)) || {}; } catch { return {}; } }

function render() {
  if (!state.role) {
    app.innerHTML = state.availableRoles.length ? roleScreen(state.availableRoles) : joinScreen({ room: state.room, name: state.name });
    if (state.availableRoles.length) bindRolePicker(); else bindJoin();
    return;
  }
  const views = { helmsman: renderHelmsman, liftmaster: renderLiftmaster, wingmaster: renderWingmaster, seer: renderSeer };
  app.innerHTML = views[state.role](state.view);
  bindControls();
}

function bindJoin() {
  const form = document.querySelector("#join-form");
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    state.room = normalizeRoom(form.room.value);
    state.name = form.name.value.trim();
    if (!/^[BCDFGHJKLMNPQRSTVWXYZ]{4}$/.test(state.room)) return showJoinError("Use four uppercase consonants, for example BZKT.");
    if (!state.name) return showJoinError("Enter a name for your station.");
    saveProfile(); connect(true);
  });
}

function showJoinError(message) { document.querySelector("#form-error").textContent = message; }
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
  socket.addEventListener("open", () => { if (state.socket === socket) { reconnectOverlay.hidden = true; state.seq = 0; send({ t: "join", room: state.room, name: state.name, clientId: getClientId() }); } });
  socket.addEventListener("message", ({ data }) => { if (state.socket === socket) handleMessage(data); });
  socket.addEventListener("close", () => { if (state.socket === socket) { releaseControl(); scheduleReconnect(); } });
  socket.addEventListener("error", () => socket.close());
}

function scheduleReconnect() { reconnectOverlay.hidden = false; clearTimeout(state.reconnectTimer); state.reconnectTimer = setTimeout(() => connect(), 1200); }

function handleMessage(data) {
  let message; try { message = JSON.parse(data); } catch { return; }
  if (message.t === "joined") { state.availableRoles = message.roles || []; state.role = ""; render(); return; }
  if (message.t === "assigned") { state.role = message.role; state.availableRoles = []; state.view = {}; render(); return; }
  if (message.t === "control_view" && message.role === state.role) { state.view = message; render(); return; }
  if (isPrivateSeerView(message) && state.role === "seer") { state.view = message; render(); return; }
  if (message.t === "error") { state.role ? alert(message.message) : showJoinError(message.message); }
}

setInterval(() => { if (state.role) send({ t: "heartbeat" }); }, 1000);
document.addEventListener("visibilitychange", () => { if (document.hidden) releaseControl(); });
window.addEventListener("pagehide", releaseControl);

const saved = loadProfile();
state.room = saved.room || "";
state.name = saved.name || "";
if (state.room && state.name) connect();
else render();
