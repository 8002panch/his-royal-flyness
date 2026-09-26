# Four-player phone platform architecture

> **Implementation authority for the redesigned controller platform.** This document records the public-repo implementation
> boundary for the front-facing first-person 2D design. It does not replace historical game-design documents; those remain
> planning context until their owners update them.

## Product boundary

One laptop hosts the authoritative Python game server and the Godot 2D renderer. Four phones connect to the same room through
a WebSocket relay.

**The phones are controllers, not game clients.** A phone may show joining, role selection, its own touch controls, connection
state, and small role-specific feedback. It must never render the hall, fly, Princess, Giant, map, shared game HUD, or any
other full-game view. The Godot application on the demo laptop is the sole full-game display for players and audience.

| Role | Owned input | Phone-visible feedback |
|---|---|---|
| Royal Helmsman | `x`: left/right horizontal turn | actual horizontal drift and momentum |
| Royal Liftmaster | `y`: climb/descend altitude | actual altitude and vertical velocity |
| Royal Wingmaster | `z`: forward/back speed and braking | actual speed and braking state |
| Royal Seer | `scan`: request sensory reading | coarse Princess bearing/distance/confidence and Giant warning |

The three movement roles directly supply **intent**, not final physics. Python validates, smooths, expires, and applies inputs.
The Seer never controls movement. Only the Seer receives target/hazard information.

## Ownership boundary

- **Ved / relay:** room membership, role assignment, reconnect identity, phone UI, role-filtered outbound messages, protocol docs,
  local and DigitalOcean relay configuration.
- **Arnav / server:** authoritative movement, room game state, phase transitions, collision, scoring, keyboard fallback, and Godot feed.
- **Neil / brain:** sensory adapter that converts world stimuli into coarse Seer cues for True Prince and Changeling modes.
- **Anshul / host:** Godot 4 first-person 2D renderer, HUD, visual feedback, and sound/captions.

No component may infer an unowned responsibility. In particular, Godot does not decide outcomes and the relay does not calculate motion.

## Data flow

```text
Phone role UI -- WebSocket --> relay -- WebSocket --> Python game server -- local WebSocket --> Godot
                                      ^                     |
                                      |                     +-- Seer adapter (placeholder, then neural model)
                                      +-- role-filtered feedback
```

The relay forwards only validated messages for an assigned role. The game server emits generic feedback to the three movement
roles and private `seer_view` feedback to the Seer socket only.

## Protocol baseline

Every client message includes a monotonic sequence number. Movement values are constrained to `-1`, `0`, or `1`.

```json
{"t":"join","room":"BZKT","name":"Ava","clientId":"uuid","seq":1}
{"t":"pick","role":"helmsman","seq":2}
{"t":"move","role":"helmsman","axis":"x","value":-1,"seq":3}
{"t":"sense","role":"seer","scan":1,"seq":4}
```

A release, pointer cancellation, visibility loss, disconnect, or stale heartbeat clears held input. Stale input expires after
1.2 seconds. Exact message schemas will live in `relay/PROTOCOL.md` during Phase 1.

## Privacy and reliability requirements

- Only the Seer can receive Princess bearing/distance or Giant direction/countdown.
- A client may control only the role the room assigned it.
- Rooms are isolated by their four-letter code.
- Reconnect uses a locally persisted `clientId`; a matching open role is restored only within the same room.
- Secrets live only in untracked `.env`; `.env.example` holds blank keys.
- Local development precedes DigitalOcean/Caddy deployment. Deployment and DNS changes require explicit approval and credentials.

## Planned local development surface

The project will use plain HTML/CSS/JavaScript for controller phones, Python 3.11+ and `websockets` for the relay/game-server
boundary, and Godot 4 in 2D mode. Phase 1 establishes the first runnable relay. No runtime command exists at Phase 0.
