## A small in-world TV widget that plays on the island map.
## Cycles through act-appropriate news headlines every ~20 seconds.
## No interaction — purely atmospheric.
extends Control

const CYCLE_INTERVAL: float = 20.0

const ACT1_HEADLINES: Array = [
	"WEATHER: Sunny, 84°F",
	"Island named Top Luxury Retreat",
	"Yacht traffic up 14% this season",
	"Exclusive resort: no vacancies",
	"Celebrity spotted on private island",
	"Annual charity gala raises $2.1M",
	"Real estate boom in private islands",
	"Resort dining earns Michelin star",
]

const ACT2_HEADLINES: Array = [
	"EXCLUSIVE RETREAT UNDER SCRUTINY",
	"FAA: unusual flight patterns noted",
	"Senator: 'No comment on the island'",
	"Anonymous source: 'I was there'",
	"Investigative report — tonight 11PM",
	"Flight logs sealed by court order",
	"Financier denies allegations",
	"Sources: guest list goes missing",
]

const ACT3_HEADLINES: Array = [
	"BREAKING: Federal indictment filed",
	"DOJ: Island investigation ongoing",
	"Assets frozen pending inquiry",
	"Witnesses reportedly recanting",
	"Island financier sought by FBI",
	"Congress demands answers",
	"Judge denies bail application",
	"LIVE: Press conference in 10 min",
]

var _headline_lbl: Label
var _live_dot: Label
var _cycle_timer: float = 0.0
var _headline_index: int = 0
var _blink_t: float = 0.0

func _ready() -> void:
	_build_widget()
	_pick_headline()
	_cycle_timer = CYCLE_INTERVAL

func _build_widget() -> void:
	# Anchor bottom-right of parent
	anchor_left   = 1.0
	anchor_top    = 1.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	offset_left   = -148.0
	offset_top    = -88.0
	offset_right  = -8.0
	offset_bottom = -36.0  # above the staff rate label
	mouse_filter  = MOUSE_FILTER_IGNORE

	# Outer frame — dark gunmetal with slight blue tint
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color                   = Color(0.04, 0.06, 0.10, 0.92)
	frame_style.border_width_left          = 1
	frame_style.border_width_top           = 1
	frame_style.border_width_right         = 1
	frame_style.border_width_bottom        = 1
	frame_style.border_color               = Color(0.15, 0.3, 0.5, 0.8)
	frame_style.corner_radius_top_left     = 4
	frame_style.corner_radius_top_right    = 4
	frame_style.corner_radius_bottom_left  = 4
	frame_style.corner_radius_bottom_right = 4
	frame_style.content_margin_left        = 6.0
	frame_style.content_margin_right       = 6.0
	frame_style.content_margin_top         = 5.0
	frame_style.content_margin_bottom      = 5.0
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = MOUSE_FILTER_IGNORE
	frame.add_child(vbox)

	# Top row: channel name + LIVE indicator
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)
	top_row.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)

	var channel_lbl := Label.new()
	channel_lbl.text = "📺 ISLAND NEWS"
	channel_lbl.add_theme_font_size_override("font_size", 9)
	channel_lbl.add_theme_color_override("font_color", Color(0.45, 0.65, 0.9, 1.0))
	channel_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	channel_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	top_row.add_child(channel_lbl)

	_live_dot = Label.new()
	_live_dot.text = "● LIVE"
	_live_dot.add_theme_font_size_override("font_size", 9)
	_live_dot.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	_live_dot.mouse_filter = MOUSE_FILTER_IGNORE
	top_row.add_child(_live_dot)

	# Thin divider
	var div := ColorRect.new()
	div.color = Color(0.15, 0.3, 0.5, 0.5)
	div.custom_minimum_size = Vector2(0, 1)
	div.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(div)

	# Headline label (wraps)
	_headline_lbl = Label.new()
	_headline_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_headline_lbl.add_theme_font_size_override("font_size", 10)
	_headline_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1.0))
	_headline_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_headline_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(_headline_lbl)

func _process(delta: float) -> void:
	# Blink the LIVE dot
	_blink_t += delta * 1.8
	_live_dot.modulate.a = 0.5 + 0.5 * sin(_blink_t * PI)

	# Cycle headline
	_cycle_timer -= delta
	if _cycle_timer <= 0.0:
		_cycle_timer = CYCLE_INTERVAL
		_next_headline()

func _current_pool() -> Array:
	var lm: float = GameState.lifetime_money
	if lm >= 50_000_000.0:
		return ACT3_HEADLINES
	elif lm >= 1_000_000.0:
		return ACT2_HEADLINES
	return ACT1_HEADLINES

func _pick_headline() -> void:
	var pool: Array = _current_pool()
	_headline_index = randi() % pool.size()
	_headline_lbl.text = pool[_headline_index]

func _next_headline() -> void:
	var pool: Array = _current_pool()
	_headline_index = (_headline_index + 1) % pool.size()
	var next_text: String = pool[_headline_index]

	# Crossfade
	var tween := create_tween()
	tween.tween_property(_headline_lbl, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _headline_lbl.text = next_text)
	tween.tween_property(_headline_lbl, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
