extends ScrollContainer

@onready var list: VBoxContainer = $VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/VIPData.gd").new()
	GameState.lifetime_money_changed.connect(_on_lifetime_changed)
	GameState.vip_recruited.connect(_on_vip_recruited)
	GameState.money_changed.connect(_on_money_changed)
	_refresh_list()

func _refresh_list() -> void:
	for child in list.get_children():
		child.queue_free()

	var vips: Array = _data_node.VIPS
	var shown_locked := false
	for vip in vips:
		if GameState.vips_recruited.get(vip.id, false):
			continue  # already recruited, skip
		if GameState.vip_is_available(vip.id):
			list.add_child(_make_row(vip))
		elif not shown_locked:
			list.add_child(_make_mystery_row())
			shown_locked = true

func _make_row(vip: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "vip_" + vip.id

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = vip.name
	name_lbl.add_theme_font_size_override("font_size", 14)
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

func _make_mystery_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "vip_mystery"
	var lbl := Label.new()
	lbl.text = "???  —  ???"
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
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
