extends Control

@onready var new_game_btn: Button = $CenterContainer/VBoxContainer/NewGameBtn
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueBtn
@onready var how_to_play_btn: Button = $CenterContainer/VBoxContainer/HowToPlayBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitBtn
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/Subtitle
@onready var help_panel = $HelpPanel

var _confirm_dialog: ConfirmationDialog

func _ready() -> void:
	continue_btn.disabled = not FileAccess.file_exists("user://save.json")
	if GameState.ghost_mode:
		subtitle_label.text = "Ghost Mode — A Private Resort Management Sim"
		subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 1))
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "New Game"
	_confirm_dialog.dialog_text = "Start a new game? Your current progress will be lost."
	_confirm_dialog.ok_button_text = "Start Fresh"
	_confirm_dialog.cancel_button_text = "Cancel"
	_confirm_dialog.confirmed.connect(_start_new_game)
	add_child(_confirm_dialog)
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	how_to_play_btn.pressed.connect(func(): help_panel.show_panel())
	quit_btn.pressed.connect(_on_quit)
	_setup_button_hover(new_game_btn)
	_setup_button_hover(continue_btn)
	_setup_button_hover(how_to_play_btn)
	_setup_button_hover(quit_btn)

func _setup_button_hover(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2
	btn.mouse_entered.connect(func(): _animate_btn(btn, Vector2(1.03, 1.03)))
	btn.mouse_exited.connect(func(): _animate_btn(btn, Vector2(1.0, 1.0)))

func _animate_btn(btn: Button, target_scale: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", target_scale, 0.1)

func _on_new_game() -> void:
	if FileAccess.file_exists("user://save.json"):
		_confirm_dialog.popup_centered()
	else:
		_start_new_game()

func _start_new_game() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit() -> void:
	get_tree().quit()
