extends ScrollContainer

@onready var list: VBoxContainer = $VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/VenueData.gd").new()
	_build_list()
	GameState.money_changed.connect(_on_money_changed)
	GameState.venue_count_changed.connect(_on_venue_changed)

func _build_list() -> void:
	for venue in _data_node.VENUES:
		var row := _make_row(venue)
		list.add_child(row)

func _make_row(venue: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "row_" + venue.id
	row.theme_override_constants/separation = 8

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = venue.name
	name_lbl.theme_override_font_sizes/font_size = 15
	info.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.name = "SubLabel"
	sub_lbl.text = venue.flavor
	sub_lbl.theme_override_font_sizes/font_size = 11
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)

	row.add_child(info)

	var count_lbl := Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = "0"
	count_lbl.custom_minimum_size = Vector2(30, 0)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(count_lbl)

	var buy_btn := Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.text = NumberFormatter.format(venue.base_cost)
	buy_btn.custom_minimum_size = Vector2(100, 0)
	buy_btn.pressed.connect(_on_buy_pressed.bind(venue.id))
	row.add_child(buy_btn)

	return row

func _on_buy_pressed(venue_id: String) -> void:
	GameState.buy_venue(venue_id)

func _on_money_changed(amount: float) -> void:
	_refresh_buttons(amount)

func _on_venue_changed(venue_id: String, count: int) -> void:
	var row = list.get_node_or_null("row_" + venue_id)
	if row == null:
		return
	row.get_node("CountLabel").text = str(count)
	row.get_node("BuyBtn").text = NumberFormatter.format(GameState.venue_cost(venue_id))
	for venue in _data_node.VENUES:
		if venue.id == venue_id:
			var income: float = venue.base_income * count
			row.get_node("VBoxContainer/SubLabel").text = "%s  |  %s" % [venue.flavor, NumberFormatter.format_rate(income)]
			break

func _refresh_buttons(money: float) -> void:
	for venue in _data_node.VENUES:
		var row = list.get_node_or_null("row_" + venue.id)
		if row == null:
			continue
		var cost: float = GameState.venue_cost(venue.id)
		row.get_node("BuyBtn").disabled = money < cost
		row.get_node("BuyBtn").text = NumberFormatter.format(cost)
