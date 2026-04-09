extends PanelContainer

const DISPLAY_SAVE_PATH: String = "user://display.json"

const WINDOW_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

@onready var close_btn: Button = $VBoxContainer/HBoxContainer/CloseBtn
@onready var statistics_btn: Button = $VBoxContainer/StatisticsBtn
@onready var achievements_btn: Button = $VBoxContainer/AchievementsBtn
@onready var main_menu_btn: Button = $VBoxContainer/MainMenuBtn
@onready var reset_btn: Button = $VBoxContainer/ResetBtn
@onready var confirm_reset: ConfirmationDialog = $ConfirmReset
@onready var stats_panel: Control = $StatsPanel
@onready var achievements_panel: Control = $AchievementsPanel
@onready var music_slider: HSlider = $VBoxContainer/AudioSection/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/AudioSection/SFXRow/SFXSlider
@onready var fullscreen_check: CheckButton = $VBoxContainer/DisplaySection/FullscreenRow/FullscreenCheck
@onready var scale_option: OptionButton = $VBoxContainer/DisplaySection/ScaleRow/ScaleOption

func _ready() -> void:
	close_btn.pressed.connect(func(): hide())
	statistics_btn.pressed.connect(func(): stats_panel.show_panel())
	achievements_btn.pressed.connect(func(): achievements_panel.show_panel())
	main_menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	reset_btn.pressed.connect(func(): confirm_reset.popup_centered())
	confirm_reset.confirmed.connect(func():
		GameState.reset_game()
		hide()
	)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	scale_option.item_selected.connect(_on_scale_selected)

	_load_display_settings()

# ── Audio ────────────────────────────────────────────────────────
func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

# ── Display ──────────────────────────────────────────────────────
func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	scale_option.disabled = pressed
	_save_display_settings()

func _on_scale_selected(index: int) -> void:
	if index < 0 or index >= WINDOW_SIZES.size():
		return
	var size: Vector2i = WINDOW_SIZES[index]
	DisplayServer.window_set_size(size)
	# Center the window on screen
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var pos: Vector2i = (screen_size - size) / 2
	DisplayServer.window_set_position(pos)
	_save_display_settings()

func _save_display_settings() -> void:
	var data: Dictionary = {
		"fullscreen": fullscreen_check.button_pressed,
		"window_scale": scale_option.selected,
	}
	var file = FileAccess.open(DISPLAY_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_display_settings() -> void:
	if not FileAccess.file_exists(DISPLAY_SAVE_PATH):
		# Apply sane defaults: windowed, medium (index 1 = 1600x900)
		scale_option.selected = 1
		_on_scale_selected(1)
		return

	var file = FileAccess.open(DISPLAY_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var raw: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw)
	if parsed == null or not parsed is Dictionary:
		return

	var is_fullscreen: bool = bool(parsed.get("fullscreen", false))
	var scale_index: int = int(parsed.get("window_scale", 1))
	scale_index = clampi(scale_index, 0, WINDOW_SIZES.size() - 1)

	# Apply scale first (matters when switching out of fullscreen)
	scale_option.selected = scale_index

	# Block signals while we set the toggle state so we don't double-apply
	fullscreen_check.set_block_signals(true)
	fullscreen_check.button_pressed = is_fullscreen
	fullscreen_check.set_block_signals(false)

	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		scale_option.disabled = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_on_scale_selected(scale_index)
		scale_option.disabled = false
