extends ScrollContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer
var _data_node: Node
# -1 = max, otherwise 1/10/100
var _mult: int = 1

func _ready() -> void:
	_data_node = load("res://scripts/data/VenueData.gd").new()
	_add_mult_row()
	_build_list()
	GameState.money_changed.connect(_on_money_changed)
	GameState.venue_count_changed.connect(_on_venue_changed)
	GameState.game_reset.connect(_on_reset)

func _add_mult_row() -> void:
	var row := HBoxContainer.new()
	row.name = "MultRow"
	row.add_theme_constant_override("separation", 4)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	for opt in [["×1", 1], ["×10", 10], ["×100", 100], ["MAX", -1]]:
		var btn := Button.new()
		btn.name = "Mult_%s" % opt[0].replace("×", "x")
		btn.text = opt[0]
		btn.custom_minimum_size = Vector2(50, 28)
		var val: int = opt[1]
		btn.pressed.connect(func(): _set_mult(val))
		row.add_child(btn)

	list.add_child(row)
	_update_mult_buttons()

func _set_mult(val: int) -> void:
	_mult = val
	_update_mult_buttons()
	_refresh_buy_buttons()

func _update_mult_buttons() -> void:
	var row = list.get_node_or_null("MultRow")
	if row == null:
		return
	var labels := {1: "Mult_x1", 10: "Mult_x10", 100: "Mult_x100", -1: "Mult_MAX"}
	for val in labels:
		var btn = row.get_node_or_null(labels[val])
		if btn:
			btn.modulate = Color(0.788, 0.659, 0.298, 1) if val == _mult else Color(1, 1, 1, 1)

func _clear_list() -> void:
	for child in list.get_children():
		if child.name == "MultRow":
			continue
		list.remove_child(child)
		child.queue_free()

func _build_list() -> void:
	_clear_list()
	var venues: Array = _data_node.VENUES
	var last_owned_index: int = -1
	for i in range(venues.size()):
		if GameState.venue_counts.get(venues[i].id, 0) > 0:
			last_owned_index = i
	var show_up_to: int = last_owned_index + 1
	var shown_mystery := false
	for i in range(venues.size()):
		if i <= show_up_to:
			list.add_child(_make_row(venues[i]))
		elif not shown_mystery:
			var prereq_name: String = venues[show_up_to].name if show_up_to >= 0 else ""
			list.add_child(_make_mystery_row(prereq_name))
			shown_mystery = true
			break

func _get_effective_n(venue_id: String) -> int:
	if _mult == -1:
		return maxi(1, GameState.venue_max_affordable(venue_id))
	return _mult

func _make_row(venue: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "row_" + venue.id
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 56)

	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = venue.name
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.name = "SubLabel"
	var count: int = GameState.venue_counts.get(venue.id, 0)
	if count > 0:
		sub_lbl.text = "%s  |  %s" % [venue.flavor, NumberFormatter.format_rate(venue.base_income * count)]
	else:
		sub_lbl.text = venue.flavor
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)
	row.add_child(info)

	var count_lbl := Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = str(count)
	count_lbl.custom_minimum_size = Vector2(30, 0)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(count_lbl)

	var n := _get_effective_n(venue.id)
	var cost := GameState.venue_cost_n(venue.id, n)
	var buy_btn := Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.text = _btn_label(venue.id, n, cost)
	buy_btn.custom_minimum_size = Vector2(110, 0)
	buy_btn.disabled = GameState.money < cost or n == 0
	buy_btn.pressed.connect(_on_buy_pressed.bind(venue.id))
	row.add_child(buy_btn)
	return row

func _btn_label(venue_id: String, n: int, cost: float) -> String:
	if _mult == -1:
		return "MAX %d\n%s" % [n, NumberFormatter.format(cost)]
	return NumberFormatter.format(cost)

func _make_mystery_row(prereq_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "row_mystery"
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

	var count_lbl := Label.new()
	count_lbl.text = "-"
	count_lbl.custom_minimum_size = Vector2(30, 0)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(count_lbl)

	var btn := Button.new()
	btn.text = "???"
	btn.custom_minimum_size = Vector2(110, 0)
	btn.disabled = true
	row.add_child(btn)
	return row

func _on_buy_pressed(venue_id: String) -> void:
	var n := _get_effective_n(venue_id)
	if n <= 0:
		return
	if GameState.buy_venue_n(venue_id, n) > 0:
		AudioManager.play_sfx("purchase")

func _on_venue_changed(_venue_id: String, _count: int) -> void:
	_build_list()

func _on_reset() -> void:
	_mult = 1
	_update_mult_buttons()
	_build_list()

func _refresh_buy_buttons() -> void:
	for venue in _data_node.VENUES:
		var row = list.get_node_or_null("row_" + venue.id)
		if row == null:
			continue
		var n := _get_effective_n(venue.id)
		var cost := GameState.venue_cost_n(venue.id, n)
		var btn = row.get_node("BuyBtn")
		btn.text = _btn_label(venue.id, n, cost)
		btn.disabled = GameState.money < cost or n == 0

func _on_money_changed(money: float) -> void:
	for venue in _data_node.VENUES:
		var row = list.get_node_or_null("row_" + venue.id)
		if row == null:
			continue
		var n := _get_effective_n(venue.id)
		var cost := GameState.venue_cost_n(venue.id, n)
		var btn = row.get_node("BuyBtn")
		btn.text = _btn_label(venue.id, n, cost)
		btn.disabled = money < cost or n == 0
		var count: int = GameState.venue_counts.get(venue.id, 0)
		if count > 0:
			row.get_node("Info/SubLabel").text = "%s  |  %s" % [venue.flavor, NumberFormatter.format_rate(venue.base_income * count)]
		row.get_node("CountLabel").text = str(count)
