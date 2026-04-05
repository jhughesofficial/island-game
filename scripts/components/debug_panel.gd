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
