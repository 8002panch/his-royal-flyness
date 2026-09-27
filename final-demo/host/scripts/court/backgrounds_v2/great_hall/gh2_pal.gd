extends RefCounted

## Great Hall v2 ("The Giant's Shadow") colours. Own file, nothing shared is edited.
## Same game palette families as pal.gd (warm stone, royal blue, crimson, gold),
## stepped down to a dim night ramp, with cold moon-glass as the only cool light
## and guttering amber as the only warm light. Flat colours only: light and shade
## come from dithering these steps against each other, never from alpha.

# Stone, deepest to lit (warm brown, like the concept art)
const DEEP := Color("#15100E")
const DARK := Color("#1E1814")
const WALL := Color("#2A221C")      # = Pal.STONE_DEEP
const MID := Color("#362C24")
const STONE := Color("#443829")
const LIT := Color("#58493B")
const HI := Color("#72604C")
const RIM := Color("#8C7860")
const VOID := Color("#07060C")      # the Giant's shadow

# Floor
const FA := Color("#2C231B")
const FA2 := Color("#251C15")
const FB := Color("#3A2E24")
const FB2 := Color("#46382B")
const GROUT := Color("#1A130F")
const CRACK := Color("#140E0B")
const SCUFF := Color("#4E3F31")

# Moon (the cold light)
const GLASS_D := Color("#111B29")
const GLASS := Color("#1F3350")
const GLASS_M := Color("#2F4F78")
const GLASS_L := Color("#7FA3C4")
const PALE := Color("#C9DCE8")
const TRACE := Color("#0B111B")
const MOON_A := Color("#33445A")    # moonlit floor / shaft dither tints
const MOON_B := Color("#4B617C")
const MOON_C := Color("#6E8AA8")

# Candle (the warm light)
const F_HOT := Color("#F6D774")
const F_MID := Color("#E2791F")
const F_LOW := Color("#8C3E12")
const GLOW_A := Color("#4A2E12")
const GLOW_B := Color("#7A5024")
const GLOW_C := Color("#A8742E")

# Cloth
const CR_D := Color("#2E0B0B")
const CR := Color("#4E1616")
const CR_L := Color("#742424")
const RY_D := Color("#0A1230")
const RY := Color("#15235A")
const RY_L := Color("#243887")

# Brass
const BR_D := Color("#453711")
const BR := Color("#6B5620")
const BR_L := Color("#9A7E2A")
const BR_HI := Color("#C9A227")

# Wood / iron / linen
const W_D := Color("#24170D")
const W := Color("#3B2616")
const W_L := Color("#5A3A22")
const W_HI := Color("#7C5232")
const IR := Color("#17130F")
const IR_L := Color("#2B241E")
const T_D := Color("#3F3829")
const T := Color("#665C48")
const T_L := Color("#8C8068")
const T_HI := Color("#B3A88A")
const INK := Color("#2B2118")
