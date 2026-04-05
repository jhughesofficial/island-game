extends ScrollContainer

@onready var list: VBoxContainer = $VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/UpgradeData.gd").new()
	GameState.lifetime_money_changed.connect(_on_lifetime_changed)
	GameState.upgrade_purchased.connect(_on_upgrade_purchased)
	GameState.money_changed.connect(_on_money_changed)
	_refresh_list()

func _refresh_list() -> void:
	for child in list.get_children():
		child.queue_free()

	var upgrades: Array = _data_node.UPGRADES
	var shown_locked := false
	for upg in upgrades:
		if upgrades_purchased.get(upg.id, false):
			continue  # already bought, skip
		if GameState.upgrade_is_available(upg.id):
			list.add_child(_make_row(upg))
		elif not shown_locked:
			list.add_child(_make_mystery_row())
			shown_locked = true

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
	btn.name = "BuyBtn"
	btn.text = NumberFormatter.format(upg.cost)
	btn.custom_minimum_size = Vector2(100, 0)
	btn.disabled = GameState.money < upg.cost
	btn.pressed.connect(_on_buy.bind(upg.id))
	row.add_child(btn)
	return row

func _make_mystery_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "upg_mystery"
	var lbl := Label.new()
	lbl.text = "???  —  ???"
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	return row

func _on_buy(upgrade_id: String) -> void:
	GameState.buy_upgrade(upgrade_id)

func _on_lifetime_changed(_amount: float) -> void:
	_refresh_list()

func _on_upgrade_purchased(_id: String) -> void:
	_refresh_list()

func _on_money_changed(money: float) -> void:
	for upg in _data_node.UPGRADES:
		var row = list.get_node_or_null("upg_" + upg.id)
		if row == null:
			continue
		row.get_node("BuyBtn").disabled = money < upg.cost

# Helper to check already purchased (mirrors GameState)
var upgrades_purchased: Dictionary:
	get: return GameState.upgrades_purchased
