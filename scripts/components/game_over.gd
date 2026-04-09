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
			headline.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
			body_label.text = "Prosecutors Confident.\n\nYou left too many loose ends."
			restart_btn.text = "Start Over"
		"suicide":
			headline.text = "BREAKING NEWS"
			headline.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
			body_label.text = "Financier Dead in Cell.\n\nYou set down your drink and watch the sunset.\nThe new island has a better dock anyway."
			restart_btn.text = "Play Again"
		"retired":
			headline.text = "RETIRED"
			headline.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))
			body_label.text = "You saw it coming.\n\nThe accounts are offshore. The jet is fueled.\nThe island was just the beginning."
			restart_btn.text = "Play Again"
			GameState.unlock_ghost_mode()
		_:
			headline.text = "GAME OVER"
			headline.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			body_label.text = ""
			restart_btn.text = "Start Over"
	pi_label.text = "Final Score: %s" % NumberFormatter.format_pi(GameState.political_influence)

func _on_restart() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_main_menu() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
