extends Control

@onready var headline: Label = $CenterContainer/VBoxContainer/Headline
@onready var body_label: Label = $CenterContainer/VBoxContainer/Body
@onready var pi_label: Label = $CenterContainer/VBoxContainer/PILabel
@onready var restart_btn: Button = $CenterContainer/VBoxContainer/RestartBtn
@onready var main_menu_btn: Button = $CenterContainer/VBoxContainer/MainMenuBtn

func _ready() -> void:
	restart_btn.pressed.connect(_on_restart)
	main_menu_btn.pressed.connect(_on_main_menu)

func show_ending(ending: String) -> void:
	match ending:
		"arrested":
			headline.text = "ARRESTED"
			body_label.text = "Prosecutors Confident.\n\nYou left too many loose ends."
		_:
			headline.text = "GAME OVER"
			body_label.text = ""
	pi_label.text = "Final Score: %s" % NumberFormatter.format_pi(GameState.political_influence)

func _on_restart() -> void:
	GameState.reset_game()
	hide()

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
