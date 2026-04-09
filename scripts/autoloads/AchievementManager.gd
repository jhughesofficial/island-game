extends Node

signal achievement_unlocked(id: String, name: String)

const SAVE_PATH: String = "user://achievements.json"

var unlocked: Dictionary = {}

var _achievement_data: Node
var _venue_data: Node

func _ready() -> void:
	_achievement_data = load("res://scripts/data/AchievementData.gd").new()
	_venue_data = load("res://scripts/data/VenueData.gd").new()
	_load_achievements()

	GameState.money_changed.connect(_on_check)
	GameState.venue_count_changed.connect(_on_venue_or_staff_changed)
	GameState.vip_recruited.connect(_on_vip_recruited)
	GameState.staff_count_changed.connect(_on_venue_or_staff_changed)
	GameState.secret_found.connect(_on_secret_found)
	GameState.pi_changed.connect(_on_pi_changed)
	GameState.heat_changed.connect(_on_heat_changed)
	GameState.game_over_triggered.connect(_on_game_over)
	GameState.game_reset.connect(_on_game_reset)

func _on_check(_val) -> void:
	check_all()

func _on_venue_or_staff_changed(_id, _count) -> void:
	check_all()

func _on_vip_recruited(_id) -> void:
	check_all()

func _on_secret_found(_id) -> void:
	check_all()

func _on_pi_changed(_pi) -> void:
	check_all()

func _on_heat_changed(_heat) -> void:
	check_all()

func _on_game_over(_ending) -> void:
	check_all()

func _on_game_reset() -> void:
	# Achievements persist across resets (like Ghost Mode prestige).
	# Re-check conditions in case any new ones unlock immediately after reset.
	check_all()

func check_all() -> void:
	for achievement in _achievement_data.ACHIEVEMENTS:
		var id: String = achievement.id
		if unlocked.get(id, false):
			continue
		if _is_condition_met(id):
			unlocked[id] = true
			_save_achievements()
			achievement_unlocked.emit(id, achievement.name)

func _is_condition_met(id: String) -> bool:
	match id:
		"first_dollar":
			return GameState.lifetime_money >= 1.0
		"ten_thousand":
			return GameState.lifetime_money >= 10_000.0
		"million_club":
			return GameState.lifetime_money >= 1_000_000.0
		"ten_million":
			return GameState.lifetime_money >= 10_000_000.0
		"first_venue":
			for v in GameState.venue_counts.values():
				if v > 0:
					return true
			return false
		"five_venues":
			var owned_types: int = 0
			for v in GameState.venue_counts.values():
				if v > 0:
					owned_types += 1
			return owned_types >= 5
		"all_venues":
			for venue in _venue_data.VENUES:
				if GameState.venue_counts.get(venue.id, 0) == 0:
					return false
			return true
		"first_vip":
			return GameState.vips_recruited.size() >= 1
		"all_vips":
			return GameState.vips_recruited.size() >= 8
		"heat_scare":
			return GameState.heat_scare_survived
		"first_secret":
			return GameState.secrets_found >= 1
		"ten_secrets":
			return GameState.secrets_found >= 10
		"first_staff":
			for s in GameState.staff_counts.values():
				if s > 0:
					return true
			return false
		"retire_ending":
			return "retired" in GameState.endings_reached
		"hundred_pi":
			return GameState.political_influence >= 100
		"retire_philanthropist":
			return "retired" in GameState.endings_reached and GameState.player_identity == "philanthropist"
		"retire_financier":
			return "retired" in GameState.endings_reached and GameState.player_identity == "financier"
		"retire_tech_mogul":
			return "retired" in GameState.endings_reached and GameState.player_identity == "tech_mogul"
		"retire_diplomat":
			return "retired" in GameState.endings_reached and GameState.player_identity == "diplomat"
		"all_identities":
			return GameState.retired_identities.size() >= 4
		"deep_state_upgrade":
			return GameState.upgrades_purchased.get("deep_state", false)
	return false

func _save_achievements() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(unlocked))
		file.close()

func _load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var raw: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		unlocked = parsed
