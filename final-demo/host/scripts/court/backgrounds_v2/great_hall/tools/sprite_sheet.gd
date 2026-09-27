extends SceneTree

## Dev tool: dumps the Great Hall v2 sprites at 4x to a PNG so they can be judged
## up close.  godot --headless --path host --script res://scripts/court/backgrounds_v2/great_hall/tools/sprite_sheet.gd -- --out=C:/tmp/sheet.png

const S := preload("../gh2_sprites.gd")


func _init() -> void:
	var out := "user://sheet.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var sheet := PixelCanvas.new(360, 200)
	sheet.rect(0, 0, 360, 200, Color("#3A2E24"))
	var x := 4
	for h in [24, 48, 72, 100]:
		var cd: Dictionary = S.candelabra(h)
		var cv: PixelCanvas = cd["canvas"]
		sheet.blit(cv, x, 196 - cv.h)
		x += cv.w + 6
	for v in [0, 1]:
		for w in [28, 48, 80]:
			var cv: PixelCanvas = S.chair_pile(w, v)
			if x + cv.w > 356:
				break
			sheet.blit(cv, x, 196 - cv.h)
			x += cv.w + 4
	var y2 := 4
	var x2 := 4
	for px in [8, 16, 28]:
		var g: PixelCanvas = S.goblet_fallen(px)
		sheet.blit(g, x2, y2)
		x2 += g.w + 4
		var p: PixelCanvas = S.plate(px * 2)
		sheet.blit(p, x2, y2)
		x2 += p.w + 4
	var img := sheet.img
	img.resize(1440, 800, Image.INTERPOLATE_NEAREST)
	img.save_png(out)
	print("sheet -> ", out)
	quit()
