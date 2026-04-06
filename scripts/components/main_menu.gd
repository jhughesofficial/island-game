extends Control

@onready var new_game_btn: Button = $CenterContainer/VBoxContainer/NewGameBtn
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitBtn

func _ready() -> void:
	continue_btn.disabled = not FileAccess.file_exists("user://save.json")
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)

func _on_new_game() -> void:
	var save_path := OS.get_user_data_dir() + "/save.json"
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute(save_path)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit() -> void:
	get_tree().quit()
