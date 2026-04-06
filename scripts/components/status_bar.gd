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
	pi_label.text = "🏛 %s" % NumberFormatter.format_pi(pi)
	retire_btn.visible = pi >= RETIRE_PI_THRESHOLD

func _on_heat_changed(heat: float) -> void:
	var stars: int = ceili(heat)
	var star_str: String = "🔥".repeat(stars) + "·".repeat(5 - stars)
	heat_label.text = star_str
	if heat >= 4.0:
		heat_label.add_theme_color_override("font_color", Color(1, 0.1, 0.1))
	elif heat >= 2.5:
		heat_label.add_theme_color_override("font_color", Color(1, 0.5, 0.0))
	else:
		heat_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.2))

func _on_arrest_countdown(seconds: float) -> void:
	if seconds <= 0.0:
		arrest_label.hide()
	else:
		arrest_label.text = "⚠ ARREST IN %ds" % ceili(seconds)
		arrest_label.show()

func _on_retire_pressed() -> void:
	GameState.game_over_triggered.emit("retired")

func _on_settings_btn_pressed() -> void:
	get_parent()._on_settings_button_pressed()
