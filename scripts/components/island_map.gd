extends Control

const VENUE_POSITIONS: Dictionary = {
	"bonfire":   Vector2(0.15, 0.75),
	"yacht":     Vector2(0.05, 0.55),
	"villa":     Vector2(0.55, 0.30),
	"jet":       Vector2(0.70, 0.65),
	"offshore":  Vector2(0.80, 0.20),
	"shell":     Vector2(0.30, 0.20),
	"political": Vector2(0.45, 0.50),
	"blackout":  Vector2(0.20, 0.40),
}

const VENUE_COLORS: Dictionary = {
	"bonfire":   Color(1.0, 0.4, 0.0),
	"yacht":     Color(0.2, 0.4, 0.9),
	"villa":     Color(0.9, 0.85, 0.6),
	"jet":       Color(0.7, 0.7, 0.7),
	"offshore":  Color(0.2, 0.8, 0.4),
	"shell":     Color(0.6, 0.3, 0.8),
	"political": Color(0.9, 0.1, 0.1),
	"blackout":  Color(0.1, 0.1, 0.1),
}

# Secret spawn timing
const SECRET_FADE_DURATION: float  = 0.3
const SECRET_LIFETIME:      float  = 15.0
const SECRET_SPAWN_MIN:     float  = 30.0
const SECRET_SPAWN_MAX:     float  = 90.0

# Margin so buttons don't clip the island edge (normalised units)
const SECRET_MARGIN: float = 0.10

@onready var island_rect:   ColorRect      = $IslandRect
@onready var venues_layer:  Control        = $VenuesLayer
@onready var throw_btn:     Button         = $ThrowPartyBtn
@onready var particles:     CPUParticles2D = $CPUParticles2D

var _venue_nodes:    Dictionary = {}
var _secret_timer:   float      = 0.0
var _active_secret:  Control    = null
var _secret_data:    Node       = null

func _ready() -> void:
	GameState.venue_count_changed.connect(_on_venue_count_changed)
	GameState.game_reset.connect(_on_game_reset)
	throw_btn.pressed.connect(_on_throw_party)
	_secret_data = load("res://scripts/data/SecretData.gd").new()
	_sync_from_state()
	_schedule_next_secret()

func _process(delta: float) -> void:
	if _active_secret != null:
		return
	_secret_timer -= delta
	if _secret_timer <= 0.0:
		_spawn_secret()

# ── Venue helpers ─────────────────────────────────────────────────────────────

func _sync_from_state() -> void:
	for node in _venue_nodes.values():
		node.queue_free()
	_venue_nodes.clear()
	for venue_id in GameState.venue_counts:
		if GameState.venue_counts[venue_id] > 0:
			_show_venue(venue_id)

func _on_game_reset() -> void:
	# Clear any active secret first, then sync venues
	if _active_secret != null:
		_active_secret.queue_free()
		_active_secret = null
	_sync_from_state()
	_schedule_next_secret()

func _on_venue_count_changed(venue_id: String, count: int) -> void:
	if count == 1:
		_show_venue(venue_id)

func _show_venue(venue_id: String) -> void:
	if _venue_nodes.has(venue_id):
		return
	if not VENUE_POSITIONS.has(venue_id):
		return
	var rect := ColorRect.new()
	rect.color = VENUE_COLORS.get(venue_id, Color.WHITE)
	rect.size = Vector2(40, 40)
	venues_layer.add_child(rect)
	_reposition_venue(venue_id, rect)
	_venue_nodes[venue_id] = rect

func _reposition_venue(venue_id: String, node: ColorRect) -> void:
	var pos_norm: Vector2 = VENUE_POSITIONS[venue_id]
	node.position = pos_norm * venues_layer.size - node.size * 0.5

# ── Click helpers ─────────────────────────────────────────────────────────────

func _on_throw_party() -> void:
	var earned: float = GameState.click_party()
	AudioManager.play_sfx("click")
	_play_click_particles()
	_spawn_click_label(earned)

func _play_click_particles() -> void:
	particles.restart()
	particles.emitting = true

func _spawn_click_label(amount: float) -> void:
	var lbl := Label.new()
	lbl.text = "+" + NumberFormatter.format(amount)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1))
	lbl.position = throw_btn.position + Vector2(randf_range(60, throw_btn.size.x - 60), -20)
	add_child(lbl)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 60, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)

# ── Secrets ───────────────────────────────────────────────────────────────────

func _schedule_next_secret() -> void:
	_secret_timer = randf_range(SECRET_SPAWN_MIN, SECRET_SPAWN_MAX)

func _spawn_secret() -> void:
	if _active_secret != null:
		return

	AudioManager.play_sfx("secret")
	var secret_dict: Dictionary = _secret_data.pick_weighted()

	# Build the button
	var btn := Button.new()
	btn.text = secret_dict.label_text
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1))

	# Dark semi-transparent background via StyleBoxFlat
	var style := StyleBoxFlat.new()
	style.bg_color         = Color(0.05, 0.05, 0.05, 0.82)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left   = 8.0
	style.content_margin_right  = 8.0
	style.content_margin_top    = 4.0
	style.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover",  style)
	btn.add_theme_stylebox_override("pressed", style)

	# Auto-size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	# Random position within island_rect, respecting margin
	var isize: Vector2 = island_rect.size
	var margin_px: Vector2 = isize * SECRET_MARGIN
	var rx: float = randf_range(margin_px.x, isize.x - margin_px.x)
	var ry: float = randf_range(margin_px.y, isize.y - margin_px.y)
	# Position is relative to island_rect's parent (this Control)
	var base_pos: Vector2 = island_rect.position + Vector2(rx, ry)
	btn.position = base_pos

	# Start invisible, then fade in
	btn.modulate.a = 0.0
	add_child(btn)
	_active_secret = btn

	# Connect click
	btn.pressed.connect(_on_secret_clicked.bind(secret_dict))

	# Fade in
	var tween_in := create_tween()
	tween_in.tween_property(btn, "modulate:a", 1.0, SECRET_FADE_DURATION)

	# Auto-despawn after lifetime
	var despawn_timer := get_tree().create_timer(SECRET_LIFETIME)
	despawn_timer.timeout.connect(_despawn_secret)

func _despawn_secret() -> void:
	if _active_secret == null:
		return
	var dying: Control = _active_secret
	_active_secret = null
	var tween_out := create_tween()
	tween_out.tween_property(dying, "modulate:a", 0.0, SECRET_FADE_DURATION)
	tween_out.tween_callback(dying.queue_free)
	_schedule_next_secret()

func _on_secret_clicked(secret_dict: Dictionary) -> void:
	if _active_secret == null:
		return
	var dying: Control = _active_secret
	_active_secret = null

	AudioManager.play_sfx("secret_collect")
	# Disconnect despawn timer implicitly — node gone, timer callback guards with null check
	dying.queue_free()

	# Apply reward
	var reward_label: String = ""
	match secret_dict.reward_type:
		"money":
			var amount: float = maxf(500.0, GameState.lifetime_money * secret_dict.reward_value)
			GameState._add_money(amount)
			reward_label = "+" + NumberFormatter.format(amount)
		"pi":
			var pi_gain: int = int(secret_dict.reward_value)
			GameState.political_influence += pi_gain
			GameState.pi_changed.emit(GameState.political_influence)
			reward_label = "+" + str(pi_gain) + " PI"
		"heat_reduce":
			GameState.heat = clampf(GameState.heat - secret_dict.reward_value, 0.0, GameState.HEAT_CRITICAL)
			GameState.heat_changed.emit(GameState.heat)
			reward_label = "Heat ▼"

	# Increment counter and fire signal
	GameState.secrets_found += 1
	GameState.secret_found.emit(secret_dict.id)

	# Floating reward label at the button's position
	_spawn_secret_label(dying.position, reward_label)

	_schedule_next_secret()

func _spawn_secret_label(pos: Vector2, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1))
	lbl.position = pos
	add_child(lbl)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 70, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)

# ── Layout ────────────────────────────────────────────────────────────────────

func _on_resized() -> void:
	for venue_id in _venue_nodes:
		_reposition_venue(venue_id, _venue_nodes[venue_id])
