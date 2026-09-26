# Implementation status

## Phase 0 — inspected and prepared

**Status:** complete  
**Branch:** `ved/phase-0-foundation`  
**Scope:** architecture/status documentation, safe skeleton preparation, and secret-template normalization only.

### Repository inventory

- Public repository already contains the top-level component folders: `relay/`, `server/`, `host/`, `brain/`,
  `agents/`, `audio/`, `data/`, `levels/`, `docs/`, and `team/`.
- `relay/`, `server/`, and `host/` currently contain owner README files only; no runnable relay, phone UI, game server, or Godot
  project has been added.
- The phone web app is controller-only: it will provide room/role flow, touch inputs, connection status, and constrained
  role feedback, while the laptop's Godot application remains the only full-game screen.
- The existing copied game-design and architecture docs describe the prior top-down/four-senses concept. The new controller-platform
  boundary is recorded in [WEBAPP_ARCHITECTURE.md](WEBAPP_ARCHITECTURE.md) so existing history is preserved while implementation
  follows the first-person four-role redesign.
- `.env.example` contains variable names only and no secret or deployment values.

### Files prepared

- `docs/WEBAPP_ARCHITECTURE.md`: controller-platform architecture, ownership, privacy boundary, and baseline protocol.
- `docs/IMPLEMENTATION_STATUS.md`: this handoff/status record.
- `relay/public/.gitkeep` and `relay/public/screens/.gitkeep`: empty Ved-owned UI directories ready for Phase 2.
- `relay/README.md`: points at the new implementation architecture.
- `.env.example`: leaves every value blank.

### Verification performed

| Check | Result |
|---|---|
| Existing root component folders inspected | Pass |
| Ved ownership boundaries reviewed in `AGENTS.md` and `team/ved/README.md` | Pass |
| Existing relay/server/host contents inspected without overwrite | Pass |
| `.env.example` reviewed for committed values | Pass after normalization |
| No runtime code added in this phase | Pass |
| Runtime/unit-test command | Not applicable: Phase 0 intentionally adds no executable code or test suite |

### Known limitations

- The public repository's historical game docs have not been rewritten by this phase. `WEBAPP_ARCHITECTURE.md` is the
  implementation boundary until the owning teammates update their component documentation.
- `server/tests/` is intentionally not created here because `server/` belongs to Arnav. Phase 1's relay tests belong inside
  Ved-owned `relay/` unless Arnav creates a shared test location.
- No DigitalOcean, Caddy, DNS, API, or local runtime setup was attempted.

## Phase 1 — rooms, roles, and safe relay

**Status:** complete
**Branch:** `ved/phase-1-relay-rooms`
**Scope:** controller-only WebSocket relay, room/role safety, protocol reference, and automated relay tests.

### Delivered

- `relay/relay.py`: runnable relay state and WebSocket server. It creates isolated four-letter rooms, permits one game-server
  host per room, caps a room at four phones, assigns each of the four roles uniquely, restores an unoccupied saved role after
  reconnect, validates monotonic message sequence numbers, and clears stale held input after 1.2 seconds.
- `relay/PROTOCOL.md`: exact JSON messages, safety/error behaviors, and the explicit phone-controller-only display boundary.
- `relay/tests/test_relay.py`: focused state tests for room isolation, unique roles, the four-phone cap, reconnect, stale input,
  role-owned axes, stale sequences, and Seer-only feedback routing.
- `relay/tests/test_network.py`: starts the relay and connects two real WebSocket test clients to join one room and select
  different roles.
- `docs/WEBAPP_ARCHITECTURE.md`: now explicitly forbids a phone from rendering any full-game scene or shared map/HUD; Godot on
  the laptop is the single full-game display.

### Verification performed

| Check | Result |
|---|---|
| `python3 -m unittest discover -s relay/tests -v` | Pass: state and two-client network relay coverage |
| Room isolation and four-phone limit | Pass |
| Role uniqueness and reconnect restoration | Pass |
| Stale-input clear and role/axis validation | Pass |
| Seer-only feedback routing | Pass |
| Controller-only product boundary documented | Pass |

### Handoff

Phase 2 can implement the small controller pages in `relay/public/`. It must use this relay protocol and must not add a phone
game view, shared world render, shared map, or gameplay HUD. Godot remains the sole game display.

## Phase 2 — four phone screens

**Status:** complete
**Branch:** `ved/phase-2-phone-controller`
**Scope:** a portrait, controller-only browser interface for joining a room, selecting one role, and transmitting touch input.

### Delivered

- `relay/public/index.html`, `styles.css`, and `app.js`: a no-build vanilla JavaScript phone app with join, role selection,
  role restoration on reconnect, reconnect overlay, role-scoped feedback, errors, and one-second heartbeats.
- `relay/public/screens/`: one renderer for each role. Movement roles have large press-and-hold controls; the Seer has a private
  scan control and private bearing/distance/confidence/warning cards. The movement screens contain no target or hazard UI.
- Touch safety: pointer release, pointer cancellation, lost pointer capture, page hide, and socket-close paths neutralize a
  held control. The optional tap-to-latch mode provides an accessible alternative to continuous holding.
- `relay/public/tests/controls.test.mjs`: browser-module tests for role-owned protocol message shape, private Seer-view detection,
  and room-code normalization.
- `relay/public/MANUAL_TEST_CHECKLIST.md`: repeatable four-phone local verification instructions.

### Verification performed

| Check | Result |
|---|---|
| `npm test --prefix relay/public` | Pass: 3 browser-module tests |
| `python3 -m unittest discover -s relay/tests -v` | Pass: 10 relay tests, including a two-client WebSocket test |
| `python3 relay/relay.py` + `python3 -m http.server 8000 --directory relay/public` | Pass: local relay and static controller page started |
| Browser smoke test | Pass: join screen → role picker → Helmsman-only controller screen, then reload → saved role restored over local WebSocket relay |
| Phone-controller boundary | Pass: the app renders no game scene, map, shared HUD, Princess, fly, or Giant outside the Seer’s private warning card |

### Known limitations

- Phase 2 provides only controller interfaces. It deliberately does not calculate movement, render the game, or generate real
  role feedback; these begin with the authoritative Python server in Phase 3.
- The relay and static files are launched as separate local processes for now. Static serving through Caddy is a later deployment
  task.
- The four-device flow has a repeatable checklist but was not exercised on physical phones in this workstation session.

### Exact next phase prompt

```text
Implement Phase 3: authoritative movement on the Python game server.

Create a deterministic x/y/z body simulator. The Helmsman owns x (horizontal/yaw), Liftmaster owns y (altitude), and Wingmaster
owns z (forward/back and braking). Inputs must be smoothed with acceleration, drag, speed limits, and a small dead zone.
The server, not the browser, calculates the actual state.

Build a local fake world with a Princess target and a test Giant hazard. Broadcast role-specific control_view feedback and an
authoritative shared state. Add tests proving one role cannot alter another axis, held input changes motion predictably,
release and stale input stop acceleration, and identical input traces produce identical outcomes.

Keep the Seer signal deterministic placeholder data. Run all prior tests, perform a four-client manual control test, update
IMPLEMENTATION_STATUS.md, and stop.
```

## Next phase

Run **Phase 3 — authoritative movement graybox** from the private planning repository's
`docs/WEBAPP_BUILD_PLAYBOOK.md`.
