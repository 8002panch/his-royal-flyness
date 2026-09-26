# Controller relay protocol

This protocol is for the **phone-controller platform only**. Phones never render the game world; the Godot application on the
demo laptop is the sole full game display. Phones send role-owned control intent and receive only role-owned feedback.

## Transport and envelope

- Local development: WebSocket server at `ws://<laptop>:8080`.
- Every client message is a JSON object with a strictly increasing, non-negative integer `seq` per connection.
- A malformed, stale, unauthorized, or out-of-range message returns `{"t":"error","code":"...","message":"..."}`.
- Phone inputs must be resent with a `heartbeat` every second. Held inputs expire after 1.2 seconds.

## Connection lifecycle

### Game server host

```json
{"t":"host_join","room":"BZKT","secret":"from-env","seq":1}

{"t":"host_joined","room":"BZKT"}
```

Only one host may claim a room. In production the host must send `ROOM_SECRET`; local development may use an empty secret only
when the environment has no configured `ROOM_SECRET`.

### Phone

```json
{"t":"join","room":"BZKT","name":"Ava","clientId":"stable-browser-uuid","seq":1}
{"t":"joined","room":"BZKT","name":"Ava","roles":["helmsman","liftmaster","wingmaster","seer"]}
{"t":"pick","role":"helmsman","seq":2}
{"t":"assigned","room":"BZKT","role":"helmsman","name":"Ava","restored":false}
```

`clientId` is generated once by the phone app and retained in `localStorage`. If its saved role is not actively occupied when
it reconnects to the same room, the relay restores that role automatically.

## Phone input messages

| Role | Valid message | Accepted values |
|---|---|---|
| Helmsman | `{"t":"move","role":"helmsman","axis":"x","value":-1\|0\|1,"seq":n}` | left, neutral, right |
| Liftmaster | `{"t":"move","role":"liftmaster","axis":"y","value":-1\|0\|1,"seq":n}` | descend, neutral, climb |
| Wingmaster | `{"t":"move","role":"wingmaster","axis":"z","value":-1\|0\|1,"seq":n}` | brake/reverse, neutral, forward |
| Seer | `{"t":"sense","role":"seer","scan":0\|1,"seq":n}` | stop/hold scan |
| Any assigned phone | `{"t":"heartbeat","seq":n}` | liveness only |

A phone may send only the message that belongs to its assigned role. On release, pointer cancellation, page visibility loss, or
socket close, its UI must send neutral input where possible; the relay still clears stale state defensively.

## Host-to-phone feedback

The host sends feedback through the relay using `phone_view`. The relay determines recipients; hosts do not provide client
connection IDs.

```json
{"t":"phone_view","role":"helmsman","seq":2,
 "view":{"t":"control_view","role":"helmsman","actualX":-0.4,"momentum":0.7}}

{"t":"phone_view","role":"seer","seq":3,
 "view":{"t":"seer_view","bearing":"NE","distance":"FAR","confidence":0.82,
          "giant":{"direction":"LEFT","seconds":2.1,"confidence":0.73}}}
```

The production host wrapper must pass the nested `view` into the relay routing function. `seer_view` is routed to the active
Seer only. It must never be broadcast or relayed to a movement role.

## Error codes

| Code | Meaning |
|---|---|
| `INVALID_ROOM` | Room is not four uppercase consonants. |
| `INVALID_NAME` / `INVALID_CLIENT_ID` | Join fields are malformed. |
| `ROLE_TAKEN` | Another active phone has the requested role. |
| `FORBIDDEN_CONTROL` | A phone attempted to control another role or axis. |
| `STALE_SEQUENCE` | The message sequence is not newer than the prior accepted message. |
| `HOST_AUTH_FAILED` / `HOST_EXISTS` | A host attempted an invalid room claim. |
| `FORBIDDEN_ROUTE` | A view type cannot be delivered to phones. |

## Phase 1 limit

This relay validates and forwards controller messages only. It does not host static files, calculate fly movement, render the
game, calculate brain activity, or create Seer cues. Those are Phase 2+ responsibilities.
