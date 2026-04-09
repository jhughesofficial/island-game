extends Control

@onready var card_row: HBoxContainer = $Center/Root/CardRow
@onready var doll_node: Control    = $Center/Root/AvatarRow/AvatarPanel/Doll
@onready var identity_label: Label = $Center/Root/AvatarRow/AvatarPanel/IdentityLabel
@onready var begin_btn: Button       = $Center/Root/BeginBtn

var _identity_data = load("res://scripts/data/IdentityData.gd").new()
var _selected_id: String = ""
var _cards: Array = []

const GOLD := Color(0.788, 0.659, 0.298, 1)
const DARK := Color(0.051, 0.051, 0.051, 1)
const PANEL_NORMAL := Color(0.09, 0.09, 0.11, 1)
const PANEL_SELECTED := Color(0.13, 0.11, 0.05, 1)

func _ready() -> void:
	begin_btn.pressed.connect(_on_begin)
	begin_btn.disabled = true
	_build_cards()

func _build_cards() -> void:
	for identity in _identity_data.IDENTITIES:
		var card := _make_card(identity)
		card_row.add_child(card)
		_cards.append(card)

func _make_card(identity: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 230)
	panel.set_meta("identity_id", identity.id)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = PANEL_NORMAL
	style_normal.border_color = Color(0.2, 0.2, 0.2, 1)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style_normal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Accent bar
	var accent_bar := ColorRect.new()
	accent_bar.custom_minimum_size = Vector2(0, 4)
	accent_bar.color = identity.accent_color
	vbox.add_child(accent_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 5)
	margin.add_child(inner)

	var name_lbl := Label.new()
	name_lbl.text = identity.name
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", GOLD)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(name_lbl)

	var cover_lbl := Label.new()
	cover_lbl.text = identity.cover
	cover_lbl.add_theme_font_size_override("font_size", 11)
	cover_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
	cover_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(cover_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separation_color", Color(0.2, 0.2, 0.2, 0.6))
	inner.add_child(sep)

	var flavor_lbl := Label.new()
	flavor_lbl.text = identity.flavor
	flavor_lbl.add_theme_font_size_override("font_size", 11)
	flavor_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1))
	flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(flavor_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(spacer)

	var bonus_lbl := Label.new()
	bonus_lbl.text = identity.bonus_label
	bonus_lbl.add_theme_font_size_override("font_size", 13)
	bonus_lbl.add_theme_color_override("font_color", identity.accent_color)
	bonus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(bonus_lbl)

	panel.gui_input.connect(func(event: InputEvent): _on_card_input(event, identity.id, panel))
	panel.mouse_entered.connect(func(): _on_card_hover(panel, true))
	panel.mouse_exited.connect(func(): _on_card_hover(panel, false))

	return panel

func _on_card_hover(panel: PanelContainer, hovered: bool) -> void:
	if panel.get_meta("identity_id") == _selected_id:
		return
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	style.border_color = Color(0.35, 0.35, 0.35, 1) if hovered else Color(0.2, 0.2, 0.2, 1)
	panel.add_theme_stylebox_override("panel", style)

func _on_card_input(event: InputEvent, identity_id: String, panel: PanelContainer) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_identity(identity_id)

func _select_identity(id: String) -> void:
	_selected_id = id
	begin_btn.disabled = false

	# Update card visuals
	for card in _cards:
		var card_id: String = card.get_meta("identity_id")
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		if card_id == id:
			style.bg_color = PANEL_SELECTED
			style.border_color = GOLD
			style.set_border_width_all(2)
		else:
			style.bg_color = PANEL_NORMAL
			style.border_color = Color(0.2, 0.2, 0.2, 1)
			style.set_border_width_all(1)
		card.add_theme_stylebox_override("panel", style)

	# Update paper doll
	_update_doll()

	# Update identity label
	for identity in _identity_data.IDENTITIES:
		if identity.id == id:
			identity_label.text = identity.name
			identity_label.add_theme_color_override("font_color", identity.accent_color)
			break

func _update_doll() -> void:
	for identity in _identity_data.IDENTITIES:
		if identity.id == _selected_id:
			doll_node.accent_color = identity.accent_color
			break
	doll_node.queue_redraw()

func _on_begin() -> void:
	if _selected_id.is_empty():
		return
	GameState.reset_game()
	GameState.set_player_identity(_selected_id)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
