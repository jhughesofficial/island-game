extends Control

@onready var headline:      Label  = $CenterContainer/VBoxContainer/Headline
@onready var tagline:       Label  = $CenterContainer/VBoxContainer/Tagline
@onready var body_label:    Label  = $CenterContainer/VBoxContainer/Body
@onready var stats_label:   Label  = $CenterContainer/VBoxContainer/StatsLabel
@onready var pi_label:      Label  = $CenterContainer/VBoxContainer/PILabel
@onready var ghost_label:   Label  = $CenterContainer/VBoxContainer/GhostLabel
@onready var restart_btn:   Button = $CenterContainer/VBoxContainer/ButtonRow/RestartBtn
@onready var main_menu_btn: Button = $CenterContainer/VBoxContainer/ButtonRow/MainMenuBtn
@onready var center:        CenterContainer = $CenterContainer

var _current_ending: String = ""

func _ready() -> void:
	restart_btn.pressed.connect(_on_restart)
	main_menu_btn.pressed.connect(_on_main_menu)

func show_ending(ending: String) -> void:
	_current_ending = ending
	match ending:
		"arrested":
			headline.text = "ARRESTED"
			headline.add_theme_color_override("font_color", Color(0.85, 0.1, 0.1))
			tagline.text = "ISLAND FINANCIER TAKEN INTO FEDERAL CUSTODY"
			tagline.add_theme_color_override("font_color", Color(0.85, 0.1, 0.1, 0.8))
			body_label.text = (
				"Prosecutors are confident.\n\n" +
				"The paper trail led back to you — it always does.\n" +
				"Three witnesses. Fourteen charges. No deal.\n\n" +
				"You left too many loose ends."
			)
			restart_btn.text = "Start Over"
		"suicide":
			headline.text = "BREAKING NEWS"
			headline.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
			tagline.text = "ISLAND FINANCIER FOUND DEAD IN FEDERAL HOLDING CELL"
			tagline.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0, 0.8))
			body_label.text = (
				"The networks are calling it suicide.\n\n" +
				"You set down your drink and watch the coverage from the terrace.\n" +
				"The new island has a better dock anyway.\n\n" +
				"Some problems solve themselves."
			)
			restart_btn.text = "Play Again"
		"retired":
			headline.text = "RETIRED"
			headline.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))
			tagline.text = "ON YOUR OWN TERMS"
			tagline.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 0.8))
			body_label.text = (
				"You saw it coming long before they did.\n\n" +
				"The accounts are offshore. The jet is fueled.\n" +
				"Certain obligations have been quietly resolved.\n\n" +
				"The island was just the beginning."
			)
			restart_btn.text = "Play Again"
			GameState.unlock_ghost_mode()
			GameState.record_identity_retire()
			ghost_label.visible = true
		_:
			headline.text = "GAME OVER"
			headline.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			tagline.text = ""
			body_label.text = ""
			restart_btn.text = "Start Over"

	pi_label.text = "Political Influence: %s" % NumberFormatter.format_pi(GameState.political_influence)
	stats_label.text = _build_stats()
	_play_entrance()

func _build_stats() -> String:
	var venues_total: int = 0
	for c in GameState.venue_counts.values():
		venues_total += int(c)

	var upgrades_total: int = 0
	for v in GameState.upgrades_purchased.values():
		if bool(v):
			upgrades_total += 1

	var vips_total: int = 0
	for v in GameState.vips_recruited.values():
		if bool(v):
			vips_total += 1

	var secs: int = int(GameState.time_played)
	var hours: int = secs / 3600
	var mins: int = (secs % 3600) / 60

	var time_str: String
	if hours > 0:
		time_str = "%dh %dm" % [hours, mins]
	else:
		time_str = "%dm" % mins

	var identity_line: String = ""
	if not GameState.player_identity.is_empty():
		var idata = load("res://scripts/data/IdentityData.gd").new()
		for identity in idata.IDENTITIES:
			if identity.id == GameState.player_identity:
				identity_line = "\n• Cover:           %s" % identity.cover
				break
		idata.free()

	var lines: Array = [
		"• Total earned:    %s" % NumberFormatter.format(GameState.lifetime_money),
		"• Venues built:    %d" % venues_total,
		"• Upgrades:        %d / 21" % upgrades_total,
		"• VIPs recruited:  %d / 8" % vips_total,
		"• Secrets found:   %d" % GameState.secrets_found,
		"• Time played:     %s%s" % [time_str, identity_line],
	]
	return "\n".join(lines)

func _play_entrance() -> void:
	center.modulate.a = 0.0
	center.scale = Vector2(0.92, 0.92)
	center.pivot_offset = center.size / 2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(center, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(center, "scale", Vector2(1.0, 1.0), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_restart() -> void:
	GameState.reset_game()
	# After a retire win with ghost_mode unlocked, offer Custom Run directly
	if _current_ending == "retired" and GameState.ghost_mode:
		get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_main_menu() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
