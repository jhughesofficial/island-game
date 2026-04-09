extends PanelContainer

# Only active in debug builds — hidden automatically in exported releases

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	hide()
	$VBoxContainer/Add100.pressed.connect(_on_add_100)
	$VBoxContainer/Add10K.pressed.connect(_on_add_10k)
	$VBoxContainer/Add1M.pressed.connect(_on_add_1m)
	$VBoxContainer/Add1B.pressed.connect(_on_add_1b)
	$VBoxContainer/Add1T.pressed.connect(_on_add_1t)
	$VBoxContainer/MaxHeat.pressed.connect(_on_max_heat)
	$VBoxContainer/ResetHeat.pressed.connect(_on_reset_heat)
	$VBoxContainer/AddPI.pressed.connect(_on_add_pi)
	$VBoxContainer/TestRetire.pressed.connect(_on_test_retire)
	$VBoxContainer/TestSuicide.pressed.connect(_on_test_suicide)
	$VBoxContainer/TriggerSecret.pressed.connect(_on_trigger_secret)
	$VBoxContainer/TriggerNarrative.pressed.connect(_on_trigger_narrative)
	$VBoxContainer/UnlockAllVenues.pressed.connect(_on_unlock_all_venues)
	$VBoxContainer/UnlockGhost.pressed.connect(_on_unlock_ghost)
	$VBoxContainer/CycleIdentity.pressed.connect(_on_cycle_identity)
	$VBoxContainer/ClearIdentity.pressed.connect(_on_clear_identity)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:  # backtick `
			visible = not visible

func _on_add_100() -> void:
	GameState._add_money(100.0)

func _on_add_10k() -> void:
	GameState._add_money(10_000.0)

func _on_add_1m() -> void:
	GameState._add_money(1_000_000.0)

func _on_add_1b() -> void:
	GameState._add_money(1_000_000_000.0)

func _on_add_1t() -> void:
	GameState._add_money(1_000_000_000_000.0)

func _on_max_heat() -> void:
	GameState.heat = 4.9
	GameState.heat_changed.emit(GameState.heat)

func _on_reset_heat() -> void:
	GameState.heat = 0.0
	GameState.heat_changed.emit(GameState.heat)

func _on_add_pi() -> void:
	GameState.political_influence += 500
	GameState.pi_changed.emit(GameState.political_influence)

func _on_test_retire() -> void:
	GameState.trigger_game_over("retired")

func _on_test_suicide() -> void:
	GameState.trigger_game_over("suicide")

func _on_trigger_secret() -> void:
	var island_map = get_tree().get_first_node_in_group("island_map")
	if island_map and island_map.has_method("_spawn_secret"):
		island_map._spawn_secret()

func _on_trigger_narrative() -> void:
	var narrative_data = load("res://scripts/data/NarrativeEventData.gd").new()
	var narrative_modal = get_tree().get_first_node_in_group("narrative_modal")
	for event in narrative_data.EVENTS:
		if event.id not in GameState.narrative_events_seen:
			GameState.narrative_events_seen.append(event.id)
			if narrative_modal:
				narrative_modal.show_event(event)
			break

func _on_unlock_all_venues() -> void:
	var venue_data = load("res://scripts/data/VenueData.gd").new()
	for venue in venue_data.VENUES:
		GameState.buy_venue_n(venue.id, 10)

func _on_unlock_ghost() -> void:
	GameState.unlock_ghost_mode()

func _on_cycle_identity() -> void:
	var id_data = load("res://scripts/data/IdentityData.gd").new()
	var ids: Array = id_data.IDENTITIES.map(func(i): return i.id)
	var current_idx: int = ids.find(GameState.player_identity)
	var next_idx: int = (current_idx + 1) % ids.size()
	GameState.set_player_identity(ids[next_idx])
	$VBoxContainer/CycleIdentity.text = "Identity: %s →" % ids[next_idx]

func _on_clear_identity() -> void:
	GameState.player_identity       = ""
	GameState._identity_click_mult  = 1.0
	GameState._identity_vip_discount = 1.0
	GameState._rebuild_rates()
	$VBoxContainer/CycleIdentity.text = "Cycle Identity →"
