extends Control

@onready var status_bar: Control = $StatusBar
@onready var island_map: Control = $HSplitContainer/IslandMap
@onready var tab_panel: Control = $HSplitContainer/TabPanel
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var settings_panel: Control = $SettingsPanel
@onready var save_timer: Timer = $SaveTimer
@onready var toast: Control = $Toast

func _ready() -> void:
	game_over_overlay.hide()
	settings_panel.hide()
	GameState.game_over_triggered.connect(_on_game_over)
	GameState.offline_earnings_received.connect(_on_offline_earnings)
	save_timer.timeout.connect(_on_save_timer)
	save_timer.start(60.0)

func _on_game_over(ending: String) -> void:
	game_over_overlay.show_ending(ending)
	game_over_overlay.show()
	save_timer.stop()

func _on_offline_earnings(amount: float) -> void:
	toast.show_message("Welcome back! Earned %s while away." % NumberFormatter.format(amount))

func _on_save_timer() -> void:
	GameState.save_game()

func _on_settings_button_pressed() -> void:
	settings_panel.visible = not settings_panel.visible
