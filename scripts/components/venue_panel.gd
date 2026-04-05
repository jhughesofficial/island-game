extends ScrollContainer

@onready var list: VBoxContainer = $VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/VenueData.gd").new()
	_build_list()
	GameState.money_changed.connect(_on_money_changed)
	GameState.venue_count_changed.connect(_on_venue_changed)
	GameState.game_reset.connect(_build_list)

func _clear_list() -> void:
	# Immediate removal to avoid same-name node conflicts with queue_free
	for child in list.get_children():
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
			list.add_child(_make_mystery_row(venues[i]))
			shown_mystery = true
			break

func _make_row(venue: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "row_" + venue.id
	row.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

	var cost := GameState.venue_cost(venue.id)
	var buy_btn := Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.text = NumberFormatter.format(cost)
	buy_btn.custom_minimum_size = Vector2(100, 0)
	buy_btn.disabled = GameState.money < cost
	buy_btn.pressed.connect(_on_buy_pressed.bind(venue.id))
	row.add_child(buy_btn)
	return row

func _make_mystery_row(next_venue: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "row_mystery"
	row.add_theme_constant_override("separation", 8)
	row.modulate = Color(0.5, 0.5, 0.5)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = "Unlock %s to reveal" % next_venue.name
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
	btn.custom_minimum_size = Vector2(100, 0)
	btn.disabled = true
	row.add_child(btn)
	return row

func _on_buy_pressed(venue_id: String) -> void:
	GameState.buy_venue(venue_id)

func _on_venue_changed(_venue_id: String, _count: int) -> void:
	# Full rebuild keeps counts, costs, and mystery row all correct
	_build_list()

func _on_money_changed(money: float) -> void:
	for venue in _data_node.VENUES:
		var row = list.get_node_or_null("row_" + venue.id)
		if row == null:
			continue
		var cost := GameState.venue_cost(venue.id)
		row.get_node("BuyBtn").disabled = money < cost
		row.get_node("BuyBtn").text = NumberFormatter.format(cost)
