extends RefCounted

## State the Great Hall v2 painters read. Whoever drives the scene (the play
## launcher, or the court itself) writes it; nothing here changes the game.
##   loom_p  0..1  how far the Giant's hand has come down (0 = not in the hall)
##   loom_x  -1..1 which way the shadow leans on the back wall
##   alarm   0..1  how frightened the hall is (candles gutter harder)

static var loom_p := 0.0
static var loom_x := 0.35
static var alarm := 0.0
