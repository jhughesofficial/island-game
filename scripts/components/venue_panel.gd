extends ScrollContainer

@onready var list: VBoxContainer = $VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/VenueData.gd").new()
	_build_list()
	GameState.money_changed.connect(_on_money_changed)
	GameState.venue_count_changed.connect(_on_venue_changed)
	GameState.game_reset.connect(_build_list)

func _build_list() -> void:
	for child in list.get_children():
		child.queue_free()

	var venues: Array = _data_node.VENUES
	var last_owned_index: int = -1
	for i in range(venues.size()):
		if GameState.venue_counts.get(venues[i].id, 0) > 0:
			last_owned_index = i

	# Show owned + one next + one ??? placeholder
	var show_up_to: int = last_owned_index + 1  # index of first unowned to show fully
	var has_hidden: bool = show_up_to + 1 < venues.size()

	for i in range(venues.size()):
		var venue = venues[i]
		if i <= show_up_to:
			list.add_child(_make_row(venue))
		elif i == show_up_to + 1 and has_hidden:
			list.add_child(_make_mystery_row())
			break  # only one ??? row

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
	sub_lbl.text = venue.flavor
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)
	row.add_child(info)

	var count_lbl := Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = str(GameState.venue_counts.get(venue.id, 0))
	count_lbl.custom_minimum_size = Vector2(30, 0)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(count_lbl)

	var buy_btn := Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.text = NumberFormatter.format(GameState.venue_cost(venue.id))
	buy_btn.custom_minimum_size = Vector2(100, 0)
	buy_btn.disabled = GameState.money < GameState.venue_cost(venue.id)
	buy_btn.pressed.connect(_on_buy_pressed.bind(venue.id))
	row.add_child(buy_btn)

	return row

func _make_mystery_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "row_mystery"
	var lbl := Label.new()
	lbl.text = "???  —  ???"
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	return row

func _on_buy_pressed(venue_id: String) -> void:
	GameState.buy_venue(venue_id)

func _on_money_changed(money: float) -> void:
	# Update buy button disabled states without full rebuild
	for venue in _data_node.VENUES:
		var row = list.get_node_or_null("row_" + venue.id)
		if row == null:
			continue
		var cost: float = GameState.venue_cost(venue.id)
		row.get_node("BuyBtn").disabled = money < cost
		row.get_node("BuyBtn").text = NumberFormatter.format(cost)

func _on_venue_changed(venue_id: String, count: int) -> void:
	# Rebuild to potentially reveal next venue
	_build_list()
	# Update rate label on the changed row
	var row = list.get_node_or_null("row_" + venue_id)
	if row == null:
		return
	row.get_node("CountLabel").text = str(count)
	for venue in _data_node.VENUES:
		if venue.id == venue_id:
			var income: float = venue.base_income * count
			row.get_node("Info/SubLabel").text = "%s  |  %s" % [venue.flavor, NumberFormatter.format_rate(income)]
			break
