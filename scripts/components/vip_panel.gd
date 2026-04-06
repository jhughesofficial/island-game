extends ScrollContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/VIPData.gd").new()
	GameState.lifetime_money_changed.connect(_on_lifetime_changed)
	GameState.vip_recruited.connect(_on_vip_recruited)
	GameState.money_changed.connect(_on_money_changed)
	GameState.game_reset.connect(_refresh_list)
	_refresh_list()

func _clear_list() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

func _refresh_list() -> void:
	_clear_list()
	var next_locked: Dictionary = {}
	var last_shown_name: String = ""
	for vip in _data_node.VIPS:
		if GameState.vips_recruited.get(vip.id, false):
			last_shown_name = vip.name
			continue
		if GameState.vip_is_available(vip.id):
			list.add_child(_make_row(vip))
			last_shown_name = vip.name
		elif next_locked.is_empty():
			next_locked = vip
	if not next_locked.is_empty():
		list.add_child(_make_mystery_row(last_shown_name))

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
	sub_lbl.text = "%s  |  x%.1f earnings  |  +%d PI" % [vip.flavor, vip.multiplier, vip.pi_award]
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)
	row.add_child(info)

	var btn := Button.new()
	btn.name = "BuyBtn"
	btn.text = NumberFormatter.format(vip.cost)
	btn.custom_minimum_size = Vector2(110, 0)
	btn.disabled = GameState.money < vip.cost
	btn.pressed.connect(_on_recruit.bind(vip.id))
	row.add_child(btn)
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
	GameState.recruit_vip(vip_id)

func _on_lifetime_changed(_amount: float) -> void:
	_refresh_list()

func _on_vip_recruited(_id: String) -> void:
	_refresh_list()

func _on_money_changed(money: float) -> void:
	for vip in _data_node.VIPS:
		var row = list.get_node_or_null("vip_" + vip.id)
		if row == null:
			continue
		row.get_node("BuyBtn").disabled = money < vip.cost
