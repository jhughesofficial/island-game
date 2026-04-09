extends Control

@onready var close_btn: Button = $Panel/VBoxContainer/HeaderRow/CloseBtn
@onready var list_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ListContainer

var _achievement_data: Node

func _ready() -> void:
	_achievement_data = load("res://scripts/data/AchievementData.gd").new()
	close_btn.pressed.connect(func(): hide())

func show_panel() -> void:
	_rebuild_list()
	show()

func _rebuild_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for achievement in _achievement_data.ACHIEVEMENTS:
		var id: String = achievement.id
		var is_unlocked: bool = AchievementManager.unlocked.get(id, false)
		var is_secret: bool = achievement.secret

		var row := HBoxContainer.new()
		row.theme_override_constants_separation = 8

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		if is_secret and not is_unlocked:
			name_label.text = "???"
			name_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 1.0))
		else:
			name_label.text = achievement.name
			if is_unlocked:
				name_label.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1.0))
			else:
				name_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))

		var desc_label := Label.new()
		if is_secret and not is_unlocked:
			desc_label.text = "???"
		else:
			desc_label.text = achievement.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		info_col.add_child(name_label)
		info_col.add_child(desc_label)

		var check_label := Label.new()
		check_label.text = "✓" if is_unlocked else ""
		check_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3, 1.0))
		check_label.add_theme_font_size_override("font_size", 18)
		check_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		check_label.custom_minimum_size = Vector2(24, 0)
		check_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		row.add_child(info_col)
		row.add_child(check_label)
		list_container.add_child(row)

		# Separator between entries
		var sep := HSeparator.new()
		sep.add_theme_color_override("color", Color(0.25, 0.25, 0.25, 1.0))
		list_container.add_child(sep)
