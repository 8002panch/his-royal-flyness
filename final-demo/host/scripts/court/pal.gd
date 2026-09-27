class_name Pal
extends RefCounted

## The court palette. Five brand colours (the brief) plus a few flat ramps
## derived from them. Pixel art only: no gradients, no alpha blending except
## fully transparent pixels.

# Brand
const PARCHMENT := Color("#F3E9D2")
const INK := Color("#2B2118")
const ROYAL := Color("#1F3A8A")
const CRIMSON := Color("#9B1C1C")
const GOLD := Color("#C9A227")

# Ramps
const PARCHMENT_DARK := Color("#D9C7A0")
const PARCHMENT_SHADE := Color("#B39A70")
const INK_SOFT := Color("#4A3A2C")
const ROYAL_DARK := Color("#14265C")
const ROYAL_LIGHT := Color("#3A5CC0")
const CRIMSON_DARK := Color("#651212")
const CRIMSON_LIGHT := Color("#C8402E")
const GOLD_DARK := Color("#8A6D14")
const GOLD_LIGHT := Color("#EDD36A")

# The hall (kept darker and warmer than the actors so they read first)
const VAULT := Color("#141F48")
const STONE_DEEP := Color("#2A221C")
const STONE_DARK := Color("#3A3028")
const STONE := Color("#4E4136")
const STONE_LIGHT := Color("#665545")
const STONE_HI := Color("#83705A")
const FLOOR_A := Color("#43362B")
const FLOOR_B := Color("#56473A")
const GROUT := Color("#30271F")
const WOOD := Color("#5A3A22")
const WOOD_LIGHT := Color("#7C5232")

# Actors
const AMBER := Color("#D8923F")
const AMBER_DARK := Color("#945A27")
const AMBER_LIGHT := Color("#F6C46E")
const STRIPE := Color("#4E2E16")
const EYE := Color("#CC2A1E")
const EYE_DARK := Color("#7C1610")
const WING := Color("#F3E9D2")
const WING_VEIN := Color("#B7A07A")
const FLESH := Color("#E6B38D")
const FLESH_DARK := Color("#B97E5B")
const FLESH_LIGHT := Color("#F7D5B5")
const FLAME := Color("#F8D44C")
const FLAME_OUT := Color("#E2791F")
const GRAPE := Color("#3B3F9A")

const CLEAR := Color(0, 0, 0, 0)

# One colour per role, on-palette. Names match relay/PROTOCOL.md.
const ROLE_ORDER := ["helmsman", "liftmaster", "wingmaster", "seer"]


static func role_color(role: String) -> Color:
	match role:
		"helmsman":
			return ROYAL
		"liftmaster":
			return GOLD_DARK
		"wingmaster":
			return CRIMSON
		"seer":
			return ROYAL_DARK
	return INK_SOFT


static func role_title(role: String) -> String:
	match role:
		"helmsman":
			return "HELMSMAN"
		"liftmaster":
			return "LIFTMASTER"
		"wingmaster":
			return "WINGMASTER"
		"seer":
			return "ROYAL SEER"
	return role.to_upper()
