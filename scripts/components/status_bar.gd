extends PanelContainer

const RETIRE_PI_THRESHOLD: int = 100

@onready var money_label: Label = $MarginContainer/HBoxContainer/MoneyLabel
@onready var rate_label: Label = $MarginContainer/HBoxContainer/RateLabel
@onready var pi_label: Label = $MarginContainer/HBoxContainer/PILabel
@onready var heat_label: Label = $MarginContainer/HBoxContainer/HeatLabel
@onready var arrest_label: Label = $MarginContainer/HBoxContainer/ArrestLabel
@onready var retire_btn: Button = $MarginContainer/HBoxContainer/RetireBtn
@onready var settings_btn: Button = $MarginContainer/HBoxContainer/SettingsBtn

var _flash_t: float = 0.0

func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.pi_changed.connect(_on_pi_changed)
	GameState.heat_changed.connect(_on_heat_changed)
	GameState.arrest_countdown_changed.connect(_on_arrest_countdown)
	GameState.game_reset.connect(_refresh_all)
	settings_btn.pressed.connect(_on_settings_btn_pressed)
	retire_btn.pressed.connect(_on_retire_pressed)
	arrest_label.hide()
	if GameState.ghost_mode:
		var ghost_badge := Label.new()
		ghost_badge.text = "👻 GHOST"
		ghost_badge.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 1))
		ghost_badge.add_theme_font_size_override("font_size", 12)
		$MarginContainer/HBoxContainer.add_child(ghost_badge)
		$MarginContainer/HBoxContainer.move_child(ghost_badge, 1)
	_refresh_all()

func _process(delta: float) -> void:
	if arrest_label.visible:
		_flash_t += delta * 4.0
		arrest_label.modulate.a = 0.5 + 0.5 * sin(_flash_t)

func _refresh_all() -> void:
	_on_money_changed(GameState.money)
	_on_pi_changed(GameState.political_influence)
	_on_heat_changed(GameState.heat)

func _on_money_changed(amount: float) -> void:
	money_label.text = NumberFormatter.format(amount)
	rate_label.text = NumberFormatter.format_rate(GameState.get_income_per_second())

func _on_pi_changed(pi: int) -> void:
	if pi >= RETIRE_PI_THRESHOLD:
		pi_label.text = "🏛 %s PI" % NumberFormatter.format_pi(pi)
		pi_label.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1.0))
	elif pi >= 50:
		# Tease the retire threshold so the player knows to keep building PI
		pi_label.text = "🏛 %d / 100 PI" % pi
		pi_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	else:
		pi_label.text = "🏛 %s" % NumberFormatter.format_pi(pi)
		pi_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	retire_btn.visible = pi >= RETIRE_PI_THRESHOLD

func _on_heat_changed(heat: float) -> void:
	var stars: int = ceili(heat)
	heat_label.text = "★".repeat(stars) + "☆".repeat(5 - stars)
	match stars:
		0:
			heat_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		1:
			heat_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		2:
			heat_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.1))
		3:
			heat_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		4:
			heat_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
		5:
			heat_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))

func _on_arrest_countdown(seconds: float) -> void:
	if seconds <= 0.0:
		arrest_label.hide()
		heat_label.show()
	else:
		arrest_label.text = "⚠ ARREST IN %ds" % ceili(seconds)
		arrest_label.show()
		heat_label.hide()

func _on_retire_pressed() -> void:
	GameState.game_over_triggered.emit("retired")

func _on_settings_btn_pressed() -> void:
	get_parent()._on_settings_button_pressed()
