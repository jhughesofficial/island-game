extends Node

# Persistent state stored in user://tutorial.json
# {"completed": bool, "hints_shown": [String]}

const SAVE_PATH: String = "user://tutorial.json"

var _completed: bool = false
var _hints_shown: Array = []

signal show_hint(hint_id: String, text: String, target_position: Vector2)

# Hint definitions: id -> {text, position}
const HINTS: Dictionary = {
	"click":   {text = "→ Click to earn money", position = Vector2(200, 500)},
	"venue":   {text = "→ Buy venues for passive income", position = Vector2(600, 120)},
	"heat":    {text = "→ Watch your Heat ★ meter", position = Vector2(400, 30)},
	"upgrade": {text = "→ Upgrades multiply your earnings", position = Vector2(600, 120)},
	"vip":     {text = "→ VIPs boost everything. Recruit them.", position = Vector2(600, 120)},
}

func _ready() -> void:
	_load()

func advance_to(hint_id: String) -> void:
	if _completed:
		return
	if not HINTS.has(hint_id):
		return
	if hint_id in _hints_shown:
		return
	_hints_shown.append(hint_id)
	_save()
	var hint: Dictionary = HINTS[hint_id]
	show_hint.emit(hint_id, hint.text, hint.position)

func mark_complete() -> void:
	_completed = true
	_save()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		return
	_completed = parsed.get("completed", false)
	var shown = parsed.get("hints_shown", [])
	if shown is Array:
		_hints_shown = shown

func _save() -> void:
	var data: Dictionary = {
		"completed": _completed,
		"hints_shown": _hints_shown,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
