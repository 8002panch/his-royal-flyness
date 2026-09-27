# v4 art to-do prompt (paste into Codex image generation, one batch at a time)

## MASTER STYLE BLOCK (paste at the top of EVERY batch)

Reference image (style only): host/assets/pixelart/v2/npcs/sir_cheapdate_v2.png, plus v3/characters/hamlet.png for Hamlet's look.
Match the existing "His Royal Flyness" roster exactly: cute squat fruit-fly characters, large head, short body, chunky pixel
clusters, roughly 48x64 native-pixel complexity, dark brown ink outline (#2B2118), broad flat color with restrained 3-tone
shading, simple handheld-RPG look. Palette only: parchment #F3E9D2, ink #2B2118, royal blue #1F3A8A, crimson #9B1C1C,
gold #C9A227, plus the one accent colour I name. Every character keeps their existing costume, colours and proportions from v3.
Output: one PNG per item, transparent background, centered, generous padding, no text or lettering, no scene, no shadow, no glow,
no smooth gradients, no franchise characters. Save under host/assets/pixelart/v4/<folder>/<filename>.png and never overwrite
v1/v2/v3.
CAST LOCK: only Hamlet, Miranda, Prospero, Clown, Lord Tinman, Count Rutabaga, Sir Cheapdate, the Giant and Hamlet's council
(Helmsman, Liftmaster, Wingmaster, Royal Seer). NO Herald, NO Sir Indy, NO guards, NO extra girls, NO crowd characters.

## BATCH 1: character poses (transparent PNG each, same size as v3, filename in brackets)

Prince Hamlet (characters/)
1. [hamlet_stained.png] purple grape stain across his face, crown slipped sideways, embarrassed wobble
2. [hamlet_floor.png] sitting on the floor, crown held in his hands, embarrassed, head down
3. [hamlet_dizzy.png] swaying, swirly eyes, small stars; comic-safe (no drinking shown)
4. [hamlet_relieved.png] relieved smile, arms open to hug

Princess Miranda (characters/)
5. [miranda_worried.png] hands clasped, worried
6. [miranda_hug.png] arms out, hugging pose, warm smile
7. [miranda_firm.png] stepping forward, one hand raised to stop someone, firm and angry
8. [miranda_walkaway.png] walking away, confident, chin up, three-quarter back view

Duke Prospero (characters/)
9. [prospero_point.png] angry, pointing and scolding (keep the mad v3 face)
10. [prospero_gate.png] side view pulling a gate chain with both hands
11. [prospero_spit.png] cheeks puffed, winding up to spit, side view
12. [prospero_sorry.png] head lowered, ashamed, hands folded
13. [prospero_relieved.png] arms crossed, relieved half-smile

Lord Tinman (npcs/) accent: silver tray
14. [tinman_tray.png] leaning elegantly on a ledge, holding a tray with TWO glasses (one purple, one pale green)
15. [tinman_handing.png] handing over one glass, amused
16. [tinman_flyaway.png] flying away, back three-quarter view

Count Rutabaga (npcs/)
17. [rutabaga_glasses.png] nervously balancing two glasses on a tray
18. [rutabaga_card.png] squinting at a small blank card tucked under his tray
19. [rutabaga_startled.png] startled, jumping, tray tipping

Sir Cheapdate (npcs/)
20. [cheapdate_stagger.png] staggering, crooked wings, holding two glasses, nearly spilling
21. [cheapdate_toast.png] proud "expert" pose, one glass raised
22. [cheapdate_hurry.png] hurrying away, one hand pointing back

Clown the Court Jester (npcs/)
23. [clown_cuff.png] gesturing at a grape-stained cuff
24. [clown_announce.png] arms wide, announcing
25. [clown_peek.png] peeking from the side of the frame (cameo)

The Giant (hazards/) accent: royal-blue sleeve, gold cuff (match v3.1 fist)
26. [giant_banquet.png] huge hand and forearm crashing down among furniture, no fingers pointing at anyone (static comic art)
27. [giant_withdraw.png] hand and forearm withdrawing upward, silhouette-like, receding
NOTE: comic art may show the Giant, but NEVER a live target position or route.

Council (council/)
28. [council_group.png] the four council members (Helmsman with wheel, Liftmaster with arrow staff, Wingmaster with goggles, Royal Seer with orb staff) standing together, cheering
29. [council_discuss.png] the same four, heads together, discussing (used for the quiz "Discuss with your council")

## BATCH 2: props (transparent PNG, props/)

30. [chalice.png] Royal Harvest Chalice: gold cup on a low stand, Prospero's crest on the front (a simple crown shape, no letters)
31. [grape.png] one plump purple grape with a small leaf and stem
32. [grapes_four.png] four grapes in a row, for the 0/4 counter
33. [drink_cordial.png] a glass of dark purple fermented grape cordial
34. [drink_nectar.png] a glass of pale gold-green pear nectar
35. [tray_two_glasses.png] silver tray with one purple and one pale-green glass
36. [invitation.png] parchment invitation with two small crests (Hamlet blue-and-gold, Miranda lavender-and-silver), no text
37. [gate_chain.png] iron garden gate with a hanging pull chain, closed
38. [window_low.png] low stone side window, small, slightly open
39. [spitball.png] a round glowing acid-green blob (cartoon, comic use)
40. [ink_splat.png] a crimson ink splat
41. [crate_stack.png] stacked crates and barrels, dim basement props
42. [spikes.png] a row of iron floor spikes
43. [stairs.png] a short stone staircase, side view
44. [banquet_doors.png] grand double doors, gold trim
45. [punch_bowl.png] a big punch bowl with a small chair tipped into it

## BATCH 3: backdrops (opaque PNG, 640x360 native pixel look, backdrops/)

46. [bg_garden.png] royal garden, grape vines, warm evening light
47. [bg_basement.png] dim basement, storage shapes only, NO route or wall edges drawn (the safe path must not be visible)
48. [bg_inner_passage.png] stone inner passage toward banquet doors, neutral, NO route markers
49. [bg_banquet.png] banquet hall, long tables, banners, EMPTY chairs (no people)
50. [bg_arena.png] wide clear banquet floor for the Giant fight, no hazard markings
51. [bg_father_arena.png] a small side chamber, Prospero's side of the room empty
52. [bg_gate_outside.png] outside the closed gate, evening
53. [bg_window_ledge.png] the low window ledge from outside

## BATCH 4: comic and UI kit (transparent PNG, ui/)

54. [comic_frame.png] parchment comic page with a gold frame, three empty panel slots, small corner ornaments
55. [bubble_speech.png] speech bubble with a tail pointing left
56. [bubble_speech_right.png] same, tail pointing right
57. [caption_box.png] Clown's rectangular narrator caption box, parchment with gold edge
58. [btn_next.png] [btn_prev.png] [btn_skip.png] three parchment buttons, arrow icons only, no lettering
59. [steady_icons.png] four small icons in a row: steady, wobbly, very wobbly, extremely wobbly (a fly with growing spiral)
60. [hearts_three.png] three small crown-shaped life pips (full and empty versions)
61. [crest_helmsman.png] [crest_liftmaster.png] [crest_wingmaster.png] [crest_seer.png] four role crests, each a DIFFERENT SHAPE as well as colour (wheel, up-arrow, feather/goggles, eye)
62. [crest_prospero.png] Prospero's crown crest
63. [quiz_panel.png] parchment quiz panel with two empty answer slots (A and B shapes, no text)
