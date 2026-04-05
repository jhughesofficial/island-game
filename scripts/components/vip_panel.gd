extends ScrollContainer

@onready var list: VBoxContainer = $VBoxContainer
var _data_node: Node

func _ready() -> void:
	_data_node = load("res://scripts/data/VIPData.gd").new()
	GameState.lifetime_money_changed.connect(_on_lifetime_changed)
	GameState.vip_recruited.connect(_on_vip_recruited)
	_refresh_list()

func _refresh_list() -> void:
	for child in list.get_children():
		child.queue_free()
	for vip in _data_node.VIPS:
		if not GameState.vip_is_available(vip.id):
			continue
		var row := _make_row(vip)
		list.add_child(row)

func _make_row(vip: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "vip_" + vip.id

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = vip.name
	name_lbl.theme_override_font_sizes/font_size = 14
	info.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.text = "%s  |  x%.1f earnings  |  +%d PI" % [vip.flavor, vip.multiplier, vip.pi_award]
	sub_lbl.theme_override_font_sizes/font_size = 11
	sub_lbl.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(sub_lbl)
	row.add_child(info)

	var btn := Button.new()
	btn.text = NumberFormatter.format(vip.cost)
	btn.custom_minimum_size = Vector2(110, 0)
	btn.disabled = GameState.money < vip.cost
	btn.pressed.connect(_on_recruit.bind(vip.id))
	row.add_child(btn)
	return row

func _on_recruit(vip_id: String) -> void:
	GameState.recruit_vip(vip_id)

func _on_lifetime_changed(_amount: float) -> void:
	_refresh_list()

func _on_vip_recruited(_id: String) -> void:
	_refresh_list()
