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

const VENUE_EMOJIS: Dictionary = {
	"bonfire":   "🔥",
	"yacht":     "🛥",
	"villa":     "🏛",
	"jet":       "✈",
	"offshore":  "🏦",
	"shell":     "🏢",
	"political": "🤝",
	"blackout":  "📺",
}

const VENUE_SIZE: Vector2 = Vector2(52, 52)

# Secret spawn timing
const SECRET_FADE_DURATION: float  = 0.3
const SECRET_LIFETIME:      float  = 15.0
const SECRET_SPAWN_MIN:     float  = 30.0
const SECRET_SPAWN_MAX:     float  = 90.0

# Margin so buttons don't clip the island edge (normalised units)
const SECRET_MARGIN: float = 0.10

const ISLAND_POINTS_NORM: PackedVector2Array = PackedVector2Array(
	0.08, 0.42,  # NW peninsula tip
	0.15, 0.32,  # NW coast
	0.28, 0.25,  # N coast west
	0.45, 0.22,  # N coast center
	0.62, 0.26,  # N coast east
	0.78, 0.32,  # NE corner
	0.88, 0.42,  # E tip
	0.85, 0.55,  # SE coast
	0.72, 0.65,  # S coast east
	0.55, 0.70,  # S coast center-east
	0.48, 0.72,  # S coast dock indent
	0.38, 0.70,  # S coast center-west
	0.22, 0.63,  # SW coast
	0.10, 0.54,  # W coast
	0.06, 0.48   # NW coast lower
)

const SHADOW_OFFSET: Vector2 = Vector2(4.0, 6.0)

@onready var island_polygon: Polygon2D      = $IslandPolygon
@onready var island_shadow:  Polygon2D      = $IslandShadow
@onready var venues_layer:   Control        = $VenuesLayer
@onready var throw_btn:      Button         = $ThrowPartyBtn
@onready var particles:      CPUParticles2D = $CPUParticles2D

var _venue_nodes:      Dictionary = {}
var _secret_timer:     float      = 0.0
var _active_secret:    Control    = null
var _secret_data:      Node       = null
var _staff_rate_label: Label      = null

func _ready() -> void:
	add_to_group("island_map")
	GameState.venue_count_changed.connect(_on_venue_count_changed)
	GameState.game_reset.connect(_on_game_reset)
	throw_btn.pressed.connect(_on_throw_party)
	throw_btn.text = "🎉 Throw Party"
	_secret_data = load("res://scripts/data/SecretData.gd").new()
	_rebuild_polygon()
	_sync_from_state()
	_schedule_next_secret()
	_setup_staff_rate_label()
	if GameState.has_signal("staff_count_changed"):
		GameState.staff_count_changed.connect(_on_staff_count_changed)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	# Skip if a UI element has keyboard focus (e.g. a modal/input is open)
	if get_viewport().gui_get_focus_owner() != null:
		return
	if event.keycode == KEY_SPACE:
		_on_throw_party()

func _rebuild_polygon() -> void:
	var s: Vector2 = size
	var pts: PackedVector2Array = PackedVector2Array()
	var count: int = ISLAND_POINTS_NORM.size()
	pts.resize(count)
	for i in count:
		pts[i] = ISLAND_POINTS_NORM[i] * s
	island_polygon.polygon = pts
	var shadow_pts: PackedVector2Array = PackedVector2Array()
	shadow_pts.resize(count)
	for i in count:
		shadow_pts[i] = pts[i] + SHADOW_OFFSET
	island_shadow.polygon = shadow_pts

func _setup_staff_rate_label() -> void:
	_staff_rate_label = Label.new()
	_staff_rate_label.name = "StaffRateLabel"
	_staff_rate_label.add_theme_font_size_override("font_size", 13)
	_staff_rate_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.85))
	_staff_rate_label.anchor_left   = 1.0
	_staff_rate_label.anchor_top    = 1.0
	_staff_rate_label.anchor_right  = 1.0
	_staff_rate_label.anchor_bottom = 1.0
	_staff_rate_label.offset_left   = -90.0
	_staff_rate_label.offset_top    = -28.0
	_staff_rate_label.offset_right  = -8.0
	_staff_rate_label.offset_bottom = -6.0
	add_child(_staff_rate_label)
	_update_staff_rate_label()

func _update_staff_rate_label() -> void:
	if _staff_rate_label == null:
		return
	var rate: float = 0.0
	if GameState.has_method("get_auto_clicks_per_second"):
		rate = GameState.get_auto_clicks_per_second()
	if rate > 0.0:
		_staff_rate_label.text = "👥 %.1f/s" % rate
		_staff_rate_label.visible = true
	else:
		_staff_rate_label.visible = false

func _on_staff_count_changed(_count: int) -> void:
	_update_staff_rate_label()

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
	elif count > 1:
		if not _venue_nodes.has(venue_id):
			_show_venue(venue_id)
			return
		var panel: Control = _venue_nodes[venue_id]
		var vbox: VBoxContainer = panel.get_child(0) as VBoxContainer
		if vbox == null:
			return
		var count_lbl: Label = vbox.get_child(1) as Label
		if count_lbl == null:
			return
		count_lbl.text = "x%d" % count
		count_lbl.visible = count > 1

func _show_venue(venue_id: String) -> void:
	if _venue_nodes.has(venue_id):
		return
	if not VENUE_POSITIONS.has(venue_id):
		return

	# Build PanelContainer with dark semi-transparent background
	var panel := PanelContainer.new()
	panel.name = venue_id
	panel.custom_minimum_size = VENUE_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color                   = Color(0.0, 0.0, 0.0, 0.6)
	style.border_width_left          = 0
	style.border_width_top           = 0
	style.border_width_right         = 0
	style.border_width_bottom        = 0
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	# VBoxContainer holds the two labels
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Emoji label
	var emoji_lbl := Label.new()
	emoji_lbl.text = VENUE_EMOJIS.get(venue_id, "?")
	emoji_lbl.add_theme_font_size_override("font_size", 20)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(emoji_lbl)

	# Count label (hidden by default, shown when count > 1)
	var count_lbl := Label.new()
	count_lbl.text    = "x1"
	count_lbl.visible = false
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(count_lbl)

	venues_layer.add_child(panel)
	_reposition_venue(venue_id, panel)
	_venue_nodes[venue_id] = panel

	# Scale-in entrance animation
	panel.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _reposition_venue(venue_id: String, node: Control) -> void:
	var pos_norm: Vector2 = VENUE_POSITIONS[venue_id]
	var node_size: Vector2 = node.size if node.size != Vector2.ZERO else node.custom_minimum_size
	node.position = pos_norm * venues_layer.size - node_size * 0.5

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
	style.bg_color                   = Color(0.05, 0.05, 0.05, 0.82)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left        = 8.0
	style.content_margin_right       = 8.0
	style.content_margin_top         = 4.0
	style.content_margin_bottom      = 4.0
	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("hover",   style)
	btn.add_theme_stylebox_override("pressed", style)

	# Auto-size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	# Random position within the island polygon area, respecting margin
	var isize: Vector2 = size
	var margin_px: Vector2 = isize * SECRET_MARGIN
	var rx: float = randf_range(margin_px.x, isize.x - margin_px.x)
	var ry: float = randf_range(margin_px.y, isize.y - margin_px.y)
	btn.position = Vector2(rx, ry)

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
	_rebuild_polygon()
	for venue_id in _venue_nodes:
		_reposition_venue(venue_id, _venue_nodes[venue_id])
