extends Control

@onready var status_bar: Control = $StatusBar
@onready var island_map: Control = $HSplitContainer/IslandMap
@onready var tab_panel: Control = $HSplitContainer/TabPanel
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var settings_panel: Control = $SettingsPanel
@onready var save_timer: Timer = $SaveTimer
@onready var toast: Control = $Toast
@onready var breaking_news_modal: Control = $BreakingNewsModal
@onready var narrative_modal: Control = $NarrativeEventModal

const ACT3_THRESHOLD: float = 50_000_000.0

var _narrative_data = load("res://scripts/data/NarrativeEventData.gd").new()

func _ready() -> void:
	game_over_overlay.hide()
	settings_panel.hide()
	GameState.game_over_triggered.connect(_on_game_over)
	GameState.offline_earnings_received.connect(_on_offline_earnings)
	GameState.lifetime_money_changed.connect(_on_lifetime_money_changed)
	save_timer.timeout.connect(_on_save_timer)
	save_timer.start(60.0)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_game_over(ending: String) -> void:
	if ending not in GameState.endings_reached:
		GameState.endings_reached.append(ending)
	game_over_overlay.show_ending(ending)
	game_over_overlay.show()
	save_timer.stop()

func _on_offline_earnings(amount: float) -> void:
	toast.show_message("Welcome back! Earned %s while away." % NumberFormatter.format(amount))

func _on_save_timer() -> void:
	GameState.save_game()

func _on_lifetime_money_changed(amount: float) -> void:
	if amount >= ACT3_THRESHOLD and not GameState.act3_revealed:
		GameState.act3_revealed = true
		GameState.save_game()
		breaking_news_modal.show_modal()
	_check_narrative_events(amount)

func _check_narrative_events(amount: float) -> void:
	var best_event: Dictionary = {}
	var best_threshold: float = -1.0
	for event in _narrative_data.EVENTS:
		if event.trigger_at <= amount and event.id not in GameState.narrative_events_seen:
			if event.trigger_at > best_threshold:
				best_threshold = event.trigger_at
				best_event = event
	if not best_event.is_empty():
		GameState.narrative_events_seen.append(best_event.id)
		GameState.save_game()
		narrative_modal.show_event(best_event)

func _on_achievement_unlocked(_id: String, achievement_name: String) -> void:
	toast.show_message("🏆 " + achievement_name, 4.0)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if settings_panel.visible:
			settings_panel.hide()
		elif narrative_modal.visible:
			narrative_modal.hide()
		elif breaking_news_modal.visible:
			breaking_news_modal.hide()
		elif game_over_overlay.visible:
			pass  # do not dismiss game over with Escape

func _on_settings_button_pressed() -> void:
	settings_panel.visible = not settings_panel.visible
