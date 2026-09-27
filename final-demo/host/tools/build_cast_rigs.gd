extends SceneTree
## Offline compiler: original PNG pixels -> small colored cutout meshes.
## Saves meshes, not replacement images. Runtime loads no source PNGs.
const ROOT := "res://assets/pixelart/animation_v1/"
const SOURCE := "res://assets/pixelart/v3/"
const RIG := preload("res://scripts/animation/cast_rig.gd")
const PARTS := ["WingL", "WingR", "LegL", "LegR", "Body", "ArmL", "ArmR"]

func _init() -> void:
	call_deferred("build")

func profile(file: String, wings: Array, arms: Array, legs: float = 0.75) -> Dictionary:
	return {"file": file, "wings": wings, "arms": arms, "legs": legs}

func profiles() -> Dictionary:
	# All mask coordinates use normalized SOURCE canvas, not cropped bounds.
	return {
		"hamlet": profile("characters/hamlet.png", [[0.28,0.54,0.40,0.68],[0.61,0.555,0.77,0.70]], [[0.35,0.55,0.435,0.66],[0.55,0.56,0.63,0.68]], 0.72),
		"miranda": profile("characters/miranda.png", [[0.30,0.56,0.40,0.69],[0.59,0.53,0.75,0.70]], [[0.39,0.595,0.49,0.68],[0.46,0.60,0.56,0.695]], 0.75),
		"prospero_nice": profile("characters/prospero_nice.png", [[0.11,0.35,0.325,0.50],[0.67,0.35,0.87,0.52]], [[0.19,0.46,0.345,0.725],[0.71,0.54,0.91,0.65]], 0.79),
		"prospero_mad": profile("characters/prospero_mad.png", [[0.11,0.35,0.325,0.50],[0.67,0.35,0.87,0.52]], [[0.19,0.46,0.345,0.725],[0.71,0.54,0.91,0.65]], 0.79),
		"helmsman": profile("council/helmsman.png", [[0.33,0.51,0.405,0.565],[0.60,0.51,0.765,0.68]], [[0.275,0.56,0.40,0.64],[0.54,0.58,0.64,0.67]], 0.75),
		"liftmaster": profile("council/liftmaster.png", [[0.35,0.52,0.405,0.565],[0.635,0.53,0.80,0.70]], [[0.20,0.34,0.35,0.77],[0.565,0.60,0.67,0.685]], 0.745),
		"wingmaster": profile("council/wingmaster.png", [[0.365,0.57,0.435,0.625],[0.63,0.56,0.79,0.745]], [[0.15,0.37,0.375,0.68],[0.555,0.59,0.66,0.675]], 0.76),
		"royal_seer": profile("council/royal_seer.png", [[0.385,0.545,0.43,0.60],[0.62,0.535,0.745,0.705]], [[0.285,0.52,0.395,0.64],[0.545,0.59,0.615,0.665]], 0.745),
		"lord_tinman": profile("npcs/lord_tinman.png", [[0.26,0.54,0.38,0.69],[0.65,0.58,0.78,0.73]], [[0.365,0.575,0.51,0.645],[0.50,0.55,0.645,0.645]], 0.765),
		"sir_cheapdate": profile("npcs/sir_cheapdate.png", [[0.365,0.50,0.42,0.56],[0.60,0.495,0.735,0.67]], [[0.26,0.555,0.415,0.67],[0.55,0.54,0.63,0.665]], 0.71),
		"count_rutabaga": profile("npcs/count_rutabaga.png", [[0.235,0.50,0.44,0.74],[0.70,0.53,0.78,0.62]], [[0.38,0.61,0.525,0.70],[0.64,0.46,0.815,0.60]], 0.755),
		"clown_jester": profile("npcs/clown_jester.png", [[0.20,0.47,0.355,0.60],[0.58,0.54,0.68,0.62]], [[0.32,0.605,0.42,0.68],[0.60,0.51,0.765,0.665]], 0.745),
		"giant": profile("hazards/giant_hand.png", [], [], 1.0),
	}

func inside(p: Vector2, box: Array) -> bool:
	return p.x >= box[0] and p.y >= box[1] and p.x <= box[2] and p.y <= box[3]

func build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "rigs"))
	var manifest := {"version": "1.0.0", "native_height": 72, "characters": [], "source": "../v3", "method": "baked colored cutout meshes; source PNGs unchanged"}
	var configs := profiles()
	for id in configs:
		var cfg: Dictionary = configs[id]
		var source := Image.load_from_file(SOURCE + cfg.file)
		assert(source != null and not source.is_empty(), "Missing " + cfg.file)
		var original := Vector2(source.get_size())
		var used := visible_bounds(source)
		var img := source.get_region(used)
		var h := 80 if id == "giant" else 72
		var ratio := float(h) / used.size.y
		img.resize(maxi(1, roundi(used.size.x * ratio)), h, Image.INTERPOLATE_NEAREST)
		var root := Node2D.new()
		root.name = id
		root.set_script(RIG)
		root.set("character_id", id)
		root.set("native_height", float(h))
		root.set("giant", id == "giant")
		var pivot := Node2D.new()
		pivot.name = "Pivot"
		root.add_child(pivot)
		pivot.owner = root
		var buckets: Dictionary = {}
		var joints: Dictionary = {}
		for part in PARTS:
			buckets[part] = {"v": PackedVector2Array(), "c": PackedColorArray(), "i": PackedInt32Array()}
			joints[part] = Vector2(img.get_width() * 0.5, img.get_height())
		for side in 2:
			var suffix := "L" if side == 0 else "R"
			if cfg.wings.size() > side:
				var box: Array = cfg.wings[side]
				joints["Wing" + suffix] = (Vector2(box[2] if side == 0 else box[0], box[1]) * original - Vector2(used.position)) * ratio
			if cfg.arms.size() > side:
				var box: Array = cfg.arms[side]
				joints["Arm" + suffix] = (Vector2(box[2] if side == 0 else box[0], (box[1] + box[3]) * 0.5) * original - Vector2(used.position)) * ratio
			joints["Leg" + suffix] = Vector2(img.get_width() * (0.4 if side == 0 else 0.6), (cfg.legs * original.y - used.position.y) * ratio)
		for y in img.get_height():
			for x in img.get_width():
				var col := img.get_pixel(x,y)
				if col.a < 0.5: continue
				col.a = 1.0
				var uv := (Vector2(x + 0.5,y + 0.5) / ratio + Vector2(used.position)) / original
				var part := "Body"
				if id != "giant":
					if uv.y >= cfg.legs: part = "LegL" if x < img.get_width() / 2 else "LegR"
					for side in 2:
						if inside(uv, cfg.arms[side]): part = "ArmL" if side == 0 else "ArmR"
					# Restrict wings to pale membrane/veins plus immediately neighboring outline.
					for side in 2:
						if inside(uv, cfg.wings[side]) and wing_pixel(img,x,y): part = "WingL" if side == 0 else "WingR"
				var b: Dictionary = buckets[part]
				var start: int = b.v.size()
				var origin: Vector2 = Vector2(x,y) - joints[part]
				for v in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
					b.v.append(origin + v)
					b.c.append(col)
				for i in [0,1,2,0,2,3]: b.i.append(start+i)
		var total := 0
		for part in PARTS:
			var b: Dictionary = buckets[part]
			if b.v.is_empty(): continue
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = b.v
			arrays[Mesh.ARRAY_COLOR] = b.c
			arrays[Mesh.ARRAY_INDEX] = b.i
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var node := MeshInstance2D.new()
			node.name = part
			node.mesh = mesh
			node.position = joints[part] - Vector2(img.get_width()*0.5,h)
			pivot.add_child(node)
			node.owner = root
			total += b.v.size()
		var packed := PackedScene.new()
		assert(packed.pack(root) == OK)
		assert(ResourceSaver.save(packed, ROOT + "rigs/" + id + ".scn", ResourceSaver.FLAG_COMPRESS) == OK)
		manifest.characters.append({"id":id, "scene":"rigs/"+id+".scn", "source":cfg.file, "vertices":total, "parts":pivot.get_child_count()})
		print("BAKED ",id," ",img.get_size()," ",total," vertices")
		root.free()
	var f := FileAccess.open(ROOT + "manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest,"\t") + "\n")
	f.close()
	quit()

func wing_pixel(img: Image, x: int, y: int) -> bool:
	for dy in range(-1,2):
		for dx in range(-1,2):
			var c := img.get_pixel(clampi(x+dx,0,img.get_width()-1),clampi(y+dy,0,img.get_height()-1))
			if c.a > 0.5 and c.r > 0.57 and c.g > 0.52 and c.b > 0.48 and absf(c.r-c.b) < 0.28:
				return true
	return false

func visible_bounds(source: Image) -> Rect2i:
	# Generated PNGs can contain nearly invisible alpha far outside the figure.
	# Ignore those specks so every character really is 72 visible pixels high.
	var left := source.get_width()
	var top := source.get_height()
	var right := 0
	var bottom := 0
	for y in range(0,source.get_height(),3):
		for x in range(0,source.get_width(),3):
			if source.get_pixel(x,y).a >= 0.5:
				left = mini(left,x)
				top = mini(top,y)
				right = maxi(right,x)
				bottom = maxi(bottom,y)
	return Rect2i(left-3,top-3,right-left+7,bottom-top+7).intersection(Rect2i(Vector2i.ZERO,source.get_size()))
