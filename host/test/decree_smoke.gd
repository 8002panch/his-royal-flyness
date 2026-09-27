extends SceneTree

## Run with: godot --headless --path host --script res://test/decree_smoke.gd
## The on-screen Royal Decree must be README.md's canonical text word for word, and fit its pages.

const MARK := "**The Royal Decree** (canonical text; shown on the main screen and on Devpost):"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var readme := ProjectSettings.globalize_path("res://").path_join("../README.md").simplify_path()
	var lines := FileAccess.get_file_as_string(readme).split("\n")
	var canonical := ""
	for i in lines.size() - 1:
		if lines[i].strip_edges().ends_with(MARK):
			canonical = lines[i + 1].strip_edges().replace("*", "")
	var fails: Array[String] = []
	if canonical == "":
		fails.append("no canonical Decree found in " + readme)
	elif canonical != DecreeOverlay.TEXT:
		fails.append("DecreeOverlay.TEXT differs from README.md's canonical Decree")
	var pages := DecreeOverlay.pages()
	if pages.is_empty() or pages.size() > 3:
		fails.append("the Decree should take 1 to 3 pages, not %d" % pages.size())
	var words := 0
	for page in pages:
		for line in page:
			words += str(line).split(" ").size()
	if words != DecreeOverlay.TEXT.split(" ").size():
		fails.append("pages lost or added words")
	if fails.is_empty():
		print("decree smoke: PASS (%d pages)" % pages.size())
		quit(0)
	else:
		for f in fails:
			push_error("decree smoke FAIL: " + f)
		quit(1)
