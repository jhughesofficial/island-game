extends PanelContainer

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

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
