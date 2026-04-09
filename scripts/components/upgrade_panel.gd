extends ScrollContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer
var _data_node: Node
var _last_sig: String = ""

func _ready() -> void:
	_data_node = load("res://scripts/data/UpgradeData.gd").new()
	GameState.lifetime_money_changed.connect(_on_lifetime_changed)
	GameState.upgrade_purchased.connect(_on_upgrade_purchased)
	GameState.money_changed.connect(_on_money_changed)
	GameState.game_reset.connect(_refresh_list)
	_refresh_list()

func _clear_list() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

func _get_sig() -> String:
	var parts: Array = []
	for upg in _data_node.UPGRADES:
		if not GameState.upgrades_purchased.get(upg.id, false) and GameState.upgrade_is_available(upg.id):
			parts.append(upg.id)
	return ",".join(parts)

func _refresh_list() -> void:
	_last_sig = _get_sig()
	_clear_list()
	var next_locked: Dictionary = {}
	var last_shown_name: String = ""
	for upg in _data_node.UPGRADES:
		if GameState.upgrades_purchased.get(upg.id, false):
			last_shown_name = upg.name
			continue
		if GameState.upgrade_is_available(upg.id):
			list.add_child(_make_row(upg))
			last_shown_name = upg.name
		elif next_locked.is_empty():
			next_locked = upg
	if not next_locked.is_empty():
		list.add_child(_make_mystery_row(last_shown_name))

func _make_row(upg: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "upg_" + upg.id
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 56)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_lbl := Label.new()
	name_lbl.text = upg.name
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.text = upg.flavor
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)
	row.add_child(info)

	var btn := Button.new()
	btn.name = "BuyBtn"
	btn.text = NumberFormatter.format(upg.cost)
	btn.custom_minimum_size = Vector2(100, 0)
	btn.disabled = GameState.money < upg.cost
	btn.pressed.connect(_on_buy.bind(upg.id))
	row.add_child(btn)
	return row

func _make_mystery_row(prereq_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "upg_mystery"
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
	btn.custom_minimum_size = Vector2(100, 0)
	btn.disabled = true
	row.add_child(btn)
	return row

func _on_buy(upgrade_id: String) -> void:
	if GameState.buy_upgrade(upgrade_id):
		AudioManager.play_sfx("purchase")

func _on_lifetime_changed(_amount: float) -> void:
	var sig := _get_sig()
	if sig != _last_sig:
		_refresh_list()

func _on_upgrade_purchased(_id: String) -> void:
	_refresh_list()

func _on_money_changed(money: float) -> void:
	for upg in _data_node.UPGRADES:
		var row = list.get_node_or_null("upg_" + upg.id)
		if row == null:
			continue
		row.get_node("BuyBtn").disabled = money < upg.cost
