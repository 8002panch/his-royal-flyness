class_name BanquetPal
extends RefCounted

## Extra colours for the Trial II Banquet background only. New constants,
## never edits to scripts/court/pal.gd. Kept warmer and more saturated than
## the base hall (Pal.STONE_* etc.) so the feast side reads as lit by candles
## and torches rather than the cool vault light over the rest of the hall.
## Pixel art only: flat fills + checker dithering, no gradients/blur.

# Warm stone & torchlight (overlay on the base hall's cooler tones)
const TORCH_GLOW := Color("#6B3A14")
const TORCH_GLOW_SOFT := Color("#4A2A12")
const WALL_WARM := Color("#5A4326")
const WALL_WARM_DARK := Color("#3C2C18")

# Wood: table legs, barrels, crates (distinct from Pal.WOOD, more red-brown)
const OAK := Color("#6B4426")
const OAK_DARK := Color("#4A2E19")
const OAK_LIGHT := Color("#8A5C34")

# Barrel iron hoops
const HOOP := Color("#3A342C")
const HOOP_LIGHT := Color("#5C544A")

# Garlands: bay leaves + berries strung between columns and along tables
const LEAF := Color("#3E5A28")
const LEAF_DARK := Color("#28401A")
const BERRY := Color("#9B1C1C")
const BERRY_LIGHT := Color("#D8402E")

# Fermenting fruit pile: overripe colour, plus the flies over it
const FERMENT := Color("#7A3F8C")
const FERMENT_DARK := Color("#4E2860")
const FLY := Color("#1A1410")

# Rich wine and cloth accents
const WINE := Color("#5C1030")
const WINE_LIGHT := Color("#8C2848")
const RUG := Color("#7A3018")
const RUG_DARK := Color("#5A2210")

# Straw / rushes scattered on the feast-side floor
const STRAW := Color("#B99542")
const STRAW_DARK := Color("#8A6D2E")
