class_name GardenPal
extends RefCounted

## NEW colours for the Garden background only (Trial I, "The Garden Audience").
## Kept separate from scripts/court/pal.gd, which other people own; nothing
## here is added to that file. Flat colours only, same rules as the hall:
## no gradients, no blur, pixel-art dithering for shade.
## Where the hall's own palette already fits (Pal.WOOD for trellis timber,
## Pal.FLAME for lantern light, Pal.GRAPE for the fruit, Pal.STONE_* for the
## fountain) the garden reuses it directly instead of duplicating it here.

# Evening sky, high to low
const SKY_DEEP := Color("#1B2A52")
const SKY_MID := Color("#33447A")
const SKY_DUSK := Color("#7A5A72")
const SKY_GLOW := Color("#C97B4A")
const SKY_GLOW_LOW := Color("#E7A15C")

const STAR := Color("#F3E9D2")
const MOON := Color("#F3E4C4")
const MOON_SHADE := Color("#D9C39A")

# Hedges (the garden's "walls")
const HEDGE_DEEP := Color("#152A19")
const HEDGE_DARK := Color("#1F3B24")
const HEDGE := Color("#2C5530")
const HEDGE_LIGHT := Color("#3F7A44")
const HEDGE_HI := Color("#5FA05E")

# Lawn / path
const GRASS_A := Color("#375F33")
const GRASS_B := Color("#436B3C")
const GRASS_DEEP := Color("#274625")
const PATH := Color("#BFA772")
const PATH_DARK := Color("#9C875A")
const PATH_LIGHT := Color("#D6C08C")

# Fountain water
const WATER_DEEP := Color("#1E4A5C")
const WATER := Color("#2F5C73")
const WATER_LIGHT := Color("#5A93A8")
const WATER_FOAM := Color("#CFE8ED")

# Grapes and vine
const GRAPE_LIGHT := Color("#5F63C4")
const GRAPE_DARK := Color("#26295E")
const VINE_LEAF := Color("#4A7A3C")
const VINE_LEAF_DARK := Color("#2F5227")
const VINE_STEM := Color("#5A3A22")
