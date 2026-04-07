extends ScrollContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer
var _data_node: Node
# -1 = max, otherwise 1/10/100
var _mult: int = 1

func _ready() -> void:
	_data_node = load("res://scripts/data/StaffData.gd").new()
	_add_mult_row()
	_build_list()
	GameState.money_changed.connect(_on_money_changed)
	GameState.staff_count_changed.connect(_on_staff_changed)
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
	for staff in _data_node.STAFF:
		list.add_child(_make_row(staff))

func _get_effective_n(staff_id: String) -> int:
	if _mult == -1:
		return maxi(1, GameState.staff_max_affordable(staff_id))
	return _mult

func _make_row(staff: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "row_" + staff.id
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 56)

	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = staff.name
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.name = "SubLabel"
	var count: int = GameState.staff_counts.get(staff.id, 0)
	sub_lbl.text = _sub_text(staff, count)
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

	var n := _get_effective_n(staff.id)
	var cost := GameState.staff_cost_n(staff.id, n)
	var buy_btn := Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.text = _btn_label(staff.id, n, cost)
	buy_btn.custom_minimum_size = Vector2(110, 0)
	buy_btn.disabled = GameState.money < cost or n == 0
	buy_btn.pressed.connect(_on_hire_pressed.bind(staff.id))
	row.add_child(buy_btn)
	return row

func _sub_text(staff: Dictionary, count: int) -> String:
	var cps: float = staff.clicks_per_second * count
	if count > 0:
		return "%s  |  %.1f clicks/s" % [staff.flavor, cps]
	return staff.flavor

func _btn_label(staff_id: String, n: int, cost: float) -> String:
	if _mult == -1:
		return "HIRE %d\n%s" % [n, NumberFormatter.format(cost)]
	return NumberFormatter.format(cost)

func _on_hire_pressed(staff_id: String) -> void:
	var n := _get_effective_n(staff_id)
	if n <= 0:
		return
	GameState.buy_staff_n(staff_id, n)

func _on_staff_changed(staff_id: String, count: int) -> void:
	var row = list.get_node_or_null("row_" + staff_id)
	if row == null:
		return
	row.get_node("CountLabel").text = str(count)
	var staff_arr = _data_node.STAFF.filter(func(s): return s.id == staff_id)
	if staff_arr.size() > 0:
		row.get_node("Info/SubLabel").text = _sub_text(staff_arr[0], count)

func _on_reset() -> void:
	_mult = 1
	_update_mult_buttons()
	_build_list()

func _refresh_buy_buttons() -> void:
	for staff in _data_node.STAFF:
		var row = list.get_node_or_null("row_" + staff.id)
		if row == null:
			continue
		var n := _get_effective_n(staff.id)
		var cost := GameState.staff_cost_n(staff.id, n)
		var btn = row.get_node("BuyBtn")
		btn.text = _btn_label(staff.id, n, cost)
		btn.disabled = GameState.money < cost or n == 0

func _on_money_changed(money: float) -> void:
	for staff in _data_node.STAFF:
		var row = list.get_node_or_null("row_" + staff.id)
		if row == null:
			continue
		var n := _get_effective_n(staff.id)
		var cost := GameState.staff_cost_n(staff.id, n)
		var btn = row.get_node("BuyBtn")
		btn.text = _btn_label(staff.id, n, cost)
		btn.disabled = money < cost or n == 0
