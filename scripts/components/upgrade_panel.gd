extends ScrollContainer

@onready var list: VBoxContainer = $VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/UpgradeData.gd").new()
	GameState.lifetime_money_changed.connect(_on_lifetime_changed)
	GameState.upgrade_purchased.connect(_on_upgrade_purchased)
	_refresh_list()

func _refresh_list() -> void:
	for child in list.get_children():
		child.queue_free()
	for upg in _data_node.UPGRADES:
		if not GameState.upgrade_is_available(upg.id):
			continue
		var row := _make_row(upg)
		list.add_child(row)

func _make_row(upg: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "upg_" + upg.id

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = upg.name
	name_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.text = upg.flavor
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)
	row.add_child(info)

	var btn := Button.new()
	btn.text = NumberFormatter.format(upg.cost)
	btn.custom_minimum_size = Vector2(100, 0)
	btn.disabled = GameState.money < upg.cost
	btn.pressed.connect(_on_buy.bind(upg.id))
	row.add_child(btn)
	return row

func _on_buy(upgrade_id: String) -> void:
	GameState.buy_upgrade(upgrade_id)

func _on_lifetime_changed(_amount: float) -> void:
	_refresh_list()

func _on_upgrade_purchased(_id: String) -> void:
	_refresh_list()
