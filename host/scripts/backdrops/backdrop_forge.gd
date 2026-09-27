extends RefCounted
## Native 640x360 scenes, using the exact v4 brief palette. Build-time only.
const INK := Color("2B2118")
const PAPER := Color("F3E9D2")
const BLUE := Color("1F3A8A")
const RED := Color("9B1C1C")
const GOLD := Color("C9A227")
const DEEP := Color("2A221C")
const DARK := Color("3A3028")
const STONE := Color("4E4136")
const LIGHT := Color("665545")
const HIGH := Color("83705A")
const FLOOR_A := Color("43362B")
const FLOOR_B := Color("56473A")
const GROUT := Color("30271F")
const WOOD := Color("5A3A22")
const WOOD_HI := Color("7C5232")
const VAULT := Color("141F48")
const PALETTE := [INK,PAPER,BLUE,RED,GOLD,DEEP,DARK,STONE,LIGHT,HIGH,FLOOR_A,FLOOR_B,GROUT,WOOD,WOOD_HI,VAULT]
const IDS := ["garden","gate_outside","window_ledge","basement","inner_passage","banquet","arena","father_arena"]

var c: PixelCanvas

func make(id: String) -> Image:
	c = PixelCanvas.new(640,360)
	c.img.fill(DEEP)
	match id:
		"garden": garden()
		"gate_outside": gate()
		"window_ledge": ledge()
		"basement": basement()
		"inner_passage": hall("passage")
		"banquet": hall("banquet")
		"arena": hall("arena")
		"father_arena": chamber()
	return c.img

func poly(points: Array, col: Color, outline := false) -> void:
	var p := PackedVector2Array()
	for xy in points: p.append(Vector2(xy[0],xy[1]))
	c.poly(p,col)
	if outline: c.poly_outline(p,INK)

func masonry(r: Rect2i, tone: Color, brick_w := 36, brick_h := 16) -> void:
	c.rect(r.position.x,r.position.y,r.size.x,r.size.y,tone)
	for y in range(r.position.y,r.end.y,brick_h):
		c.hline(r.position.x,r.end.x-1,y,GROUT)
		var offset := brick_w/2 if (y/brick_h)%2 else 0
		for x in range(r.position.x+offset,r.end.x,brick_w):
			c.vline(x,y,mini(y+brick_h,r.end.y-1),GROUT)
			if tone == STONE: c.hline(x+2,mini(x+brick_w-3,r.end.x-1),y+2,LIGHT)

func arch(x: int,y: int,w: int,h: int,fill: Color,trim: Color, pointed := true) -> void:
	var shoulder := y+int(h*0.31)
	var pts: Array = [[x,y+h],[x,shoulder],[x+w*.12,y+h*.15],[x+w*.5,y],[x+w*.88,y+h*.15],[x+w,shoulder],[x+w,y+h]]
	if not pointed:
		pts = [[x,y+h],[x,y+h*.35],[x+w*.06,y+h*.2],[x+w*.2,y+h*.06],[x+w*.5,y],[x+w*.8,y+h*.06],[x+w*.94,y+h*.2],[x+w,y+h*.35],[x+w,y+h]]
	poly(pts,fill)
	var pp := PackedVector2Array()
	for a in pts: pp.append(Vector2(a[0],a[1]))
	c.poly_outline(pp,trim)

func rose(x: int,y: int,r: int) -> void:
	c.ellipse(x,y,r+3,r+3,INK)
	c.ellipse(x,y,r+2,r+2,GOLD)
	c.ellipse(x,y,r,r,VAULT)
	for i in 8:
		var a := TAU*i/8.0
		var xx := x+cos(a)*r*.60
		var yy := y+sin(a)*r*.60
		c.ellipse(xx,yy,r*.22,r*.22,BLUE if i%2 else RED)
		c.linev(Vector2(x,y),Vector2(x+cos(a)*r,y+sin(a)*r),GOLD)
	c.ellipse(x,y,3,3,GOLD)

func banner(x: int,y: int,w: int,h: int,tone: Color,emblem := 0) -> void:
	poly([[x,y],[x+w,y],[x+w,y+h],[x+w/2,y+h-w/3],[x,y+h]],tone,true)
	c.vline(x+2,y+2,y+h-4,GOLD)
	c.vline(x+w-2,y+2,y+h-4,GOLD)
	c.hline(x-3,x+w+3,y-2,INK)
	c.hline(x-2,x+w+2,y-1,GOLD)
	var mx := x+w/2
	var my := y+h/3
	var k := maxi(2,w/7)
	if emblem%3 == 0:
		poly([[mx-k*2,my-k],[mx-k,my],[mx,my-k*2],[mx+k,my],[mx+k*2,my-k],[mx+k*2,my+k],[mx-k*2,my+k]],GOLD)
	elif emblem%3 == 1:
		poly([[mx,my-k*2],[mx+k,my-k],[mx+k*2,my],[mx+k,my+k],[mx,my+k*2],[mx-k,my+k],[mx-k*2,my],[mx-k,my-k]],GOLD)
	else:
		c.ellipse(mx-k,my,k,k,GOLD)
		c.ellipse(mx+k,my,k,k,GOLD)
		poly([[mx-k*2,my],[mx+k*2,my],[mx,my+k*2]],GOLD)

func candle(x: int,y: int,h := 20, three := false) -> void:
	c.rect(x-3,y-2,7,3,INK)
	c.hline(x-2,x+2,y-1,GOLD)
	c.vline(x,y-h,y-2,GOLD)
	var arms := [-5,0,5] if three else [0]
	if three: c.hline(x-5,x+5,y-h+5,GOLD)
	for d in arms:
		c.rect(x+d-1,y-h-3,2,8,PAPER)
		c.rect(x+d-1,y-h-7,2,3,GOLD)
		c.px(x+d,y-h-8,PAPER)

func tiled_floor(top := 184, dim := false) -> void:
	c.rect(0,top,640,360-top,DARK if dim else FLOOR_A)
	var rows := [top,top+8,top+20,top+39,top+68,top+112,360]
	for row in range(rows.size()-1):
		var a: int = rows[row]
		var b: int = rows[row+1]
		var near_scale := float(b-top+30)/30.0
		var far_scale := float(a-top+30)/30.0
		for col in range(-12,13):
			var xa := 320+col*22*far_scale
			var xb := 320+(col+1)*22*far_scale
			var xc := 320+(col+1)*22*near_scale
			var xd := 320+col*22*near_scale
			var tone := FLOOR_A if (col+row)%2 else FLOOR_B
			if dim: tone = DARK if (col+row)%2 else DEEP
			poly([[xa,a],[xb,a],[xc,b],[xd,b]],tone)
			c.linev(Vector2(xa,a),Vector2(xd,b),GROUT)
		c.hline(0,639,b,GROUT)

func column(x: int,y: int,w: int,h: int) -> void:
	c.rect(x-3,y-5,w+6,7,INK)
	c.rect(x-2,y-4,w+4,4,HIGH)
	poly([[x,y],[x+w,y],[x+w-3,y+8],[x+3,y+8]],LIGHT,true)
	c.rect(x+3,y+8,w-6,h-15,STONE)
	c.vline(x+4,y+8,y+h-7,HIGH)
	c.vline(x+w-5,y+8,y+h-7,DARK)
	for line in range(x+7,x+w-6,5): c.vline(line,y+8,y+h-7,LIGHT)
	c.rect(x-2,y+h-8,w+4,8,INK)
	c.rect(x-1,y+h-7,w+2,5,LIGHT)
	c.hline(x,x+w,y+h-7,HIGH)

func hall(kind: String) -> void:
	var dim := kind == "arena"
	var passage := kind == "passage"
	masonry(Rect2i(0,0,640,230),DARK if dim else STONE,40,18)
	tiled_floor(206,dim)
	# Perspective walls and vaults are decorative architecture, not collision geometry.
	poly([[0,0],[185,51],[185,209],[0,322]],DARK,true)
	poly([[640,0],[455,51],[455,209],[640,322]],DARK,true)
	for side in [-1,1]:
		for n in 7:
			c.linev(Vector2(320+side*320,26+n*44),Vector2(320+side*135,66+n*21),GROUT)
	poly([[0,0],[640,0],[455,52],[185,52]],VAULT)
	for reach in [314,235,164]:
		var r: int = reach
		c.line(320-r,84,320-int(r*.65),18,LIGHT)
		c.line(320+r,84,320+int(r*.65),18,LIGHT)
		c.line(320-int(r*.65),18,320,0,GOLD)
		c.line(320+int(r*.65),18,320,0,GOLD)
	arch(240,30,160,185,DEEP,GOLD)
	if passage:
		arch(263,66,114,141,WOOD,INK)
		c.frame(268,102,104,103,GOLD)
		c.vline(320,76,207,INK)
		for x in [276,325]:
			c.frame(x,113,39,34,WOOD_HI)
			c.frame(x,159,39,36,WOOD_HI)
			c.ellipse(x+30,151,2,3,GOLD)
	else:
		rose(320,65,22)
		c.rect(273,101,94,102,RED)
		for x in range(277,367,12):
			c.vline(x,104,201,WOOD)
			for y in range(108,192,16): c.rect(x+3,y,2,2,GOLD)
		c.hline(269,370,101,GOLD)
	for i in range(3,-1,-1):
		var distance := [22,99,151,185][i]
		var yy := [81,101,116,128][i]
		var ww := [28,22,16,12][i]
		var hh := [246,168,115,79][i]
		for side in [-1,1]:
			var xx: int = distance if side < 0 else 640-distance-ww
			arch(xx-9,yy-39,ww+36,hh+24,DEEP,LIGHT)
			column(xx,yy,ww,hh)
			var bx: int = xx+ww+12 if side < 0 else xx-30
			banner(bx,yy-3,maxi(12,ww-3),maxi(40,hh/2),BLUE if i%2==0 else RED,i)
			if i%2 == 0: candle(xx+ww/2,yy+hh-12,15,false)
	if passage:
		# Full-width stair; it does not encode a safe route or hazard position.
		for i in 3:
			c.rect(0,326+i*11,640,11,STONE if i%2 else DARK)
			c.hline(0,639,326+i*11,LIGHT)
	else:
		if kind == "banquet":
			poly([[291,209],[349,209],[414,360],[226,360]],RED,true)
			c.line(291,209,226,359,GOLD)
			c.line(349,209,414,359,GOLD)
			for y in range(229,319,20): c.rect(318,y,3,3,GOLD)
			poly([[265,198],[375,198],[396,229],[244,229]],BLUE,true)
			c.rect(244,229,152,8,VAULT)
			c.hline(244,395,234,GOLD)
			feast(false)
		else:
			feast(true)
			for x in [12,38,576,602]: chair(x,304,14)

func feast(edges: bool) -> void:
	for side in [-1,1]:
		var inner := 191 if not edges else 252
		var outer := 285 if not edges else 310
		var a := 320+side*inner
		var b := 320+side*outer
		poly([[320+side*134,206],[320+side*171,206],[b,347],[a,347]],WOOD,true)
		poly([[320+side*134,204],[320+side*171,204],[b,325],[a,325]],PAPER if not edges else LIGHT,true)
		for i in 4:
			var u := float(i)/3.0
			var x := roundi(lerpf(320+side*152,(a+b)*.5,u))
			var y := roundi(lerpf(210,318,u))
			var r := 3+i
			c.ellipse(x,y,r*1.5,r*.5,HIGH if edges else GOLD)
			c.ellipse(x,y-1,r,r*.35,PAPER if not edges else STONE)
			if not edges or i == 0: candle(x+side*8,y-3,10+i*4,i>1)
			if i<3 and not edges:
				c.rect(x-side*8,y-8,3,4,GOLD)
				c.vline(x-side*8+1,y-4,y-1,GOLD)
	if not edges:
		# Empty side table and one punch bowl, no overturned chair in it.
		c.rect(83,259,44,5,WOOD_HI)
		c.rect(88,264,3,20,WOOD)
		c.rect(121,264,3,20,WOOD)
		c.ellipse(105,252,15,8,GOLD)
		c.ellipse(105,248,15,4,INK)
		c.ellipse(105,248,12,2,RED)

func chair(x: int,y: int,w: int) -> void:
	c.rect(x,y,w,4,WOOD_HI)
	c.rect(x,y-21,3,27,WOOD)
	c.rect(x+w-3,y-21,3,27,WOOD)
	c.rect(x,y-19,w,3,WOOD_HI)
	c.line(x+3,y+4,x+w+5,y+10,WOOD)

func garden() -> void:
	c.rect(0,0,640,34,VAULT)
	c.rect(0,34,640,31,BLUE)
	c.rect(0,65,640,32,STONE)
	masonry(Rect2i(144,79,352,103),STONE,30,13)
	for x in range(145,497,24): c.rect(x,72,14,8,LIGHT)
	arch(285,96,70,86,DEEP,GOLD)
	rose(320,95,10)
	banner(223,106,20,56,RED)
	banner(398,106,20,56,BLUE,1)
	tiled_floor(181)
	c.ellipse(320,216,68,22,LIGHT)
	c.ellipse(320,216,64,19,FLOOR_B)
	for i in range(4,-1,-1):
		var u := float(i)/4.0
		var x := roundi(lerpf(12,216,u))
		var y := roundi(lerpf(107,148,u))
		var h := roundi(lerpf(197,40,u))
		for side in [-1,1]:
			var xx := x if side < 0 else 640-x-24
			c.rect(xx,y,3,h,WOOD)
			c.rect(xx+25,y,3,h,WOOD)
			for step in range(0,h,15):
				c.hline(xx,xx+27,y+step,WOOD_HI)
				c.line(xx,y+step,xx+25,mini(y+h,y+step+15),WOOD)
				for k in 3:
					c.ellipse(xx+4+k*8,y+step+4,4,2,LIGHT)
				if step%30 == 0:
					for d in [[0,0],[4,0],[2,4]]: c.ellipse(xx+12+d[0],y+step+8+d[1],2,3,RED)
			c.rect(xx-7,y+h-8,39,13,DARK)
			c.hline(xx-7,xx+31,y+h-8,LIGHT)

func gate() -> void:
	c.rect(0,0,640,90,VAULT)
	c.rect(0,35,640,30,BLUE)
	masonry(Rect2i(0,83,640,186),STONE,42,20)
	tiled_floor(267)
	arch(206,70,228,197,DEEP,GOLD)
	for x in range(216,431,15):
		c.rect(x,128,3,140,INK)
		c.vline(x+1,129,267,HIGH)
	for y in [141,192,242]: c.rect(208,y,224,4,INK)
	c.rect(317,96,6,171,INK)
	c.ellipse(312,198,4,4,GOLD)
	c.ellipse(328,198,4,4,GOLD)
	for x in [174,438]:
		column(x,68,28,207)
		poly([[x-4,65],[x+14,48],[x+32,65]],GOLD,true)
	banner(116,92,28,90,BLUE)
	banner(496,92,28,90,RED,2)
	arch(32,220,49,37,DEEP,LIGHT)
	for x in [43,55,67]: c.vline(x,235,256,WOOD_HI)

func ledge() -> void:
	masonry(Rect2i(0,0,640,360),DARK,76,35)
	arch(176,20,296,253,LIGHT,INK)
	arch(187,30,274,231,WOOD_HI,HIGH)
	arch(201,42,245,208,GOLD,INK)
	# Warm interior is flat gold/wood, with a single empty table silhouette.
	c.rect(228,200,189,8,WOOD)
	c.rect(244,208,6,39,WOOD)
	c.rect(395,208,6,39,WOOD)
	poly([[207,84],[302,64],[302,248],[207,248]],VAULT,true)
	for y in range(95,235,26):
		c.line(209,y,301,y+19,LIGHT)
		c.line(209,y+20,301,y,HIGH)
	c.rect(303,61,5,189,INK)
	poly([[311,66],[377,95],[377,247],[311,249]],STONE,true)
	for y in range(95,231,25): c.line(315,y,374,y+19,INK)
	c.line(337,77,337,248,INK)
	c.line(359,87,359,248,INK)
	poly([[151,252],[488,252],[527,288],[118,288]],HIGH,true)
	c.rect(118,288,409,15,LIGHT)
	c.rect(137,303,368,12,STONE)
	c.hline(121,524,290,HIGH)
	# Ivy in subdued stone/wood families, obeying the exact restricted palette.
	for side in [0,1]:
		var x := 86 if side==0 else 538
		for i in 11:
			var xx := x+(i%3)*7
			c.line(xx,20+i*24,xx+7,44+i*24,WOOD)
			c.ellipse(xx-3,30+i*24,7,3,LIGHT)
			c.ellipse(xx+9,40+i*24,6,3,STONE)

func crate(x: int,y: int,w: int,h: int) -> void:
	c.rect(x,y,w,h,WOOD)
	c.frame(x,y,w,h,INK)
	c.frame(x+2,y+2,w-4,h-4,WOOD_HI)
	c.line(x+3,y+3,x+w-4,y+h-4,WOOD_HI)
	c.line(x+w-4,y+3,x+3,y+h-4,WOOD_HI)

func barrel(x: int,y: int,w: int,h: int) -> void:
	c.ellipse(x+w/2,y+h/2,w/2,h/2,WOOD)
	for xx in range(x+3,x+w-2,5): c.vline(xx,y+4,y+h-5,DARK)
	c.hline(x+2,x+w-3,y+h/4,LIGHT)
	c.hline(x+2,x+w-3,y+h*3/4,LIGHT)
	c.ellipse(x+w/2,y+3,w/2-2,3,WOOD_HI)

func basement() -> void:
	masonry(Rect2i(0,0,640,260),DEEP,40,18)
	c.rect(0,0,640,45,VAULT)
	# Broad vaults, no fine wall-edge tracing or collision-map geometry.
	for x in [0,213,426]:
		arch(x-20,39,248,190,DARK,STONE,false)
		arch(x-9,49,226,180,DEEP,DARK,false)
	tiled_floor(222,true)
	for x in [98,318,538]:
		c.vline(x,45,89,INK)
		c.frame(x-5,88,11,16,LIGHT)
		c.rect(x-1,94,2,5,GOLD)
	# Uniformly spaced visual clutter, including the centre; no marked corridor.
	for x in [26,154,282,410,538]:
		c.rect(x,135,71,5,DARK)
		c.rect(x,177,71,4,DARK)
		c.vline(x+2,130,221,STONE)
		c.vline(x+67,130,221,STONE)
		barrel(x+4,147,20,29)
		crate(x+32,149,28,26)
		crate(x+3,187,28,32)
		barrel(x+42,186,24,35)
	for i in 5:
		var x := 38+i*124
		crate(x,245,29,21)
		c.ellipse(x+46,264,12,9,DARK)
		c.hline(x+40,x+50,256,STONE)
	# Near field intentionally low contrast and free of readable route cues.
	for x in [72,228,384,540]:
		c.ellipse(x,316,12,4,DARK)
	for x in [0,584]:
		for k in 4: c.line(x,50,x+50-k*8,80+k*4,STONE)

func chamber() -> void:
	masonry(Rect2i(0,0,640,236),STONE,48,22)
	tiled_floor(236)
	arch(73,-32,494,269,DARK,HIGH,false)
	arch(93,-14,454,251,STONE,LIGHT,false)
	arch(275,69,112,167,DEEP,GOLD)
	arch(286,88,90,148,VAULT,LIGHT)
	c.rect(293,179,77,57,DARK)
	# Far benches keep the left foreground clear for Prospero.
	for x in [147,414]:
		c.rect(x,216,77,10,HIGH)
		c.rect(x+6,226,8,19,STONE)
		c.rect(x+63,226,8,19,STONE)
		banner(x+26,86,26,91,BLUE if x<300 else RED,2)
		candle(x+38,212,19)
