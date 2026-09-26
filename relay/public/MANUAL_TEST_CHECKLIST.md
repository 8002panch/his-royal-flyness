# Phase 2 phone-controller checklist

Run these steps from four portrait-oriented phones or browser device emulators. The shared laptop runs the relay; it remains the
only full-game display.

1. Start the relay with `python3 relay/relay.py` and serve `relay/public/` with `python3 -m http.server 8000 --directory relay/public`.
2. On each phone, open `http://<laptop-lan-ip>:8000/?relay=ws://<laptop-lan-ip>:8080` and enter the same four-consonant room code.
3. Pick Helmsman, Liftmaster, Wingmaster, and Seer once each. Confirm every phone displays only its own role controller.
4. Hold then release both movement buttons on each movement controller. In relay logs or a connected host test client, confirm the
   matching `move` event uses only that role's `x`, `y`, or `z` axis and that release sends value `0`.
5. Hold then release the Seer's scan button. Confirm it emits `sense` values `1` then `0`.
6. With one phone holding a control, background the browser or cancel the touch. Confirm a neutral event is emitted. Leave it
   idle for more than 1.2 seconds and confirm the relay clears the held input.
7. Close or disable networking on one phone, then restore it. Confirm the reconnect overlay appears and the saved `clientId`
   restores that phone's role when it is still open.
8. Send a sample `seer_view` through the host. Confirm only the Seer's screen shows bearing, distance, confidence, or a Giant
   warning. Movement screens must never show any of those fields.
9. Enable **Tap-to-latch controls** on each role. Tap once to activate and once to neutralize; confirm the same messages as the
   hold/release path.
10. Repeat the screen check in portrait orientation at narrow width. Verify all controls remain large, labeled, and reachable.
