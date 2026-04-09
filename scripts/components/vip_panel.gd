extends ScrollContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer
var _data_node: Node
var _last_sig: String = ""

func _ready() -> void:
	_data_node = load("res://scripts/data/VIPData.gd").new()
	GameState.lifetime_money_changed.connect(_on_lifetime_changed)
	GameState.vip_recruited.connect(_on_vip_recruited)
	GameState.money_changed.connect(_on_money_changed)
	GameState.heat_changed.connect(_on_heat_changed)
	GameState.game_reset.connect(_refresh_list)
	_refresh_list()

func _clear_list() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

func _get_sig() -> String:
	var parts: Array = []
	for vip in _data_node.VIPS:
		if not GameState.vips_recruited.get(vip.id, false) and GameState.vip_is_available(vip.id):
			parts.append(vip.id)
	return ",".join(parts)

func _refresh_list() -> void:
	_last_sig = _get_sig()
	_clear_list()
	var next_locked: Dictionary = {}
	var last_shown_name: String = ""
	var has_recruited: bool = false
	var has_available: bool = false

	# First pass: count sections so we know whether to insert a separator
	for vip in _data_node.VIPS:
		if GameState.vips_recruited.get(vip.id, false):
			has_recruited = true
		elif GameState.vip_is_available(vip.id):
			has_available = true

	var separator_added: bool = false
	for vip in _data_node.VIPS:
		if GameState.vips_recruited.get(vip.id, false):
			list.add_child(_make_recruited_row(vip))
			last_shown_name = vip.name
			continue
		if not separator_added and has_recruited and has_available:
			var sep := HSeparator.new()
			sep.add_theme_constant_override("separation", 6)
			list.add_child(sep)
			separator_added = true
		if GameState.vip_is_available(vip.id):
			list.add_child(_make_row(vip))
			last_shown_name = vip.name
		elif next_locked.is_empty():
			next_locked = vip
	if not next_locked.is_empty():
		list.add_child(_make_mystery_row(last_shown_name))

func _parse_heat_reduce(effect: String) -> int:
	if not effect.begins_with("heat_reduce_"):
		return 0
	var parts := effect.split("_")
	if parts.size() < 3:
		return 0
	return parts[2].to_int()

func _make_row(vip: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "vip_" + vip.id
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 56)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_lbl := Label.new()
	name_lbl.text = vip.name
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	var sub_text := "%s  |  x%.1f earnings  |  +%d PI" % [vip.flavor, vip.multiplier, vip.pi_award]
	var heat_val := _parse_heat_reduce(vip.get("effect", ""))
	if heat_val > 0:
		sub_text += "  |  -%d heat" % heat_val
	sub_lbl.text = sub_text
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)
	row.add_child(info)

	var actual_cost: float = GameState.vip_cost(vip.id)
	var btn := Button.new()
	btn.name = "BuyBtn"
	btn.text = NumberFormatter.format(actual_cost)
	if actual_cost < vip.cost:
		btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 1))
	btn.custom_minimum_size = Vector2(110, 0)
	btn.disabled = GameState.money < actual_cost
	btn.pressed.connect(_on_recruit.bind(vip.id))
	row.add_child(btn)
	return row

func _make_recruited_row(vip: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "vip_recruited_" + vip.id
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 48)
	row.modulate = Color(0.55, 0.55, 0.55, 1)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_lbl := Label.new()
	name_lbl.text = vip.name
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.text = "✓ Active  |  x%.1f  |  +%d PI earned" % [vip.multiplier, vip.pi_award]
	sub_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(sub_lbl)
	row.add_child(info)

	var badge := Label.new()
	badge.text = "✓ On Island"
	badge.custom_minimum_size = Vector2(110, 0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4, 1))
	row.add_child(badge)
	return row

func _make_mystery_row(prereq_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "vip_mystery"
	row.add_theme_constant_override("separation", 8)
	row.modulate = Color(0.5, 0.5, 0.5)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = "Unlock %s to reveal" % prereq_name if prereq_name != "" else "Keep earning to reveal"
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.text = "???"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(sub_lbl)
	row.add_child(info)

	var btn := Button.new()
	btn.text = "???"
	btn.custom_minimum_size = Vector2(110, 0)
	btn.disabled = true
	row.add_child(btn)
	return row

func _on_recruit(vip_id: String) -> void:
	if GameState.recruit_vip(vip_id):
		AudioManager.play_sfx("purchase")

func _on_lifetime_changed(_amount: float) -> void:
	var sig := _get_sig()
	if sig != _last_sig:
		_refresh_list()

func _on_vip_recruited(_id: String) -> void:
	_refresh_list()

var _last_heat_tier: int = 0

func _on_heat_changed(heat: float) -> void:
	var tier: int = 1 if heat >= 4.0 else 0
	if tier != _last_heat_tier:
		_last_heat_tier = tier
		_refresh_list()  # prices changed, rebuild

func _on_money_changed(money: float) -> void:
	for vip in _data_node.VIPS:
		var row = list.get_node_or_null("vip_" + vip.id)
		if row == null:
			continue
		row.get_node("BuyBtn").disabled = money < GameState.vip_cost(vip.id)
