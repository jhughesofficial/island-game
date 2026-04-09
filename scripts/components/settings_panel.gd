extends PanelContainer

@onready var close_btn: Button = $VBoxContainer/HBoxContainer/CloseBtn
@onready var statistics_btn: Button = $VBoxContainer/StatisticsBtn
@onready var main_menu_btn: Button = $VBoxContainer/MainMenuBtn
@onready var reset_btn: Button = $VBoxContainer/ResetBtn
@onready var confirm_reset: ConfirmationDialog = $ConfirmReset
@onready var stats_panel: Control = $StatsPanel

func _ready() -> void:
	close_btn.pressed.connect(func(): hide())
	statistics_btn.pressed.connect(func(): stats_panel.show_panel())
	main_menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	reset_btn.pressed.connect(func(): confirm_reset.popup_centered())
	confirm_reset.confirmed.connect(func():
		GameState.reset_game()
		hide()
	)
