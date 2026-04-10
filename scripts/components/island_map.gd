extends Control

const VENUE_POSITIONS: Dictionary = {
	"bonfire":   Vector2(0.22, 0.55),  # west area, above SW coast
	"yacht":     Vector2(0.15, 0.47),  # west shore interior
	"villa":     Vector2(0.55, 0.35),  # upper-center
	"jet":       Vector2(0.72, 0.48),  # east-center
	"offshore":  Vector2(0.76, 0.38),  # east interior, below NE coast
	"shell":     Vector2(0.38, 0.45),  # center
	"political": Vector2(0.50, 0.55),  # center-south
	"blackout":  Vector2(0.28, 0.38),  # left-center upper
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

# Margin applied to the island polygon so it doesn't fill edge-to-edge.
# Venue positions use the same factor so icons stay on the island.
const POLY_MARGIN: float = 0.08

# Secret spawn timing
const SECRET_FADE_DURATION: float  = 0.3
const SECRET_LIFETIME:      float  = 15.0
const SECRET_SPAWN_MIN:     float  = 30.0
const SECRET_SPAWN_MAX:     float  = 90.0

# Seagull timing
const SEAGULL_INTERVAL_MIN: float = 45.0
const SEAGULL_INTERVAL_MAX: float = 90.0
const SEAGULL_FLY_MIN:      float = 8.0
const SEAGULL_FLY_MAX:      float = 12.0

# Ocean shimmer colours
const OCEAN_COLOR_DARK:  Color = Color(0.04, 0.12, 0.22, 1.0)
const OCEAN_COLOR_LIGHT: Color = Color(0.05, 0.15, 0.27, 1.0)

# Margin so buttons don't clip the island edge (normalised units)
const SECRET_MARGIN: float = 0.10

var ISLAND_POINTS_NORM: PackedVector2Array = PackedVector2Array([
	Vector2(0.08, 0.42),  # NW peninsula tip
	Vector2(0.15, 0.32),  # NW coast
	Vector2(0.28, 0.25),  # N coast west
	Vector2(0.45, 0.22),  # N coast center
	Vector2(0.62, 0.26),  # N coast east
	Vector2(0.78, 0.32),  # NE corner
	Vector2(0.88, 0.42),  # E tip
	Vector2(0.85, 0.55),  # SE coast
	Vector2(0.72, 0.65),  # S coast east
	Vector2(0.55, 0.70),  # S coast center-east
	Vector2(0.48, 0.72),  # S coast dock indent
	Vector2(0.38, 0.70),  # S coast center-west
	Vector2(0.22, 0.63),  # SW coast
	Vector2(0.10, 0.54),  # W coast
	Vector2(0.06, 0.48),  # NW coast lower
])

const SHADOW_OFFSET: Vector2 = Vector2(4.0, 6.0)

@onready var island_polygon: Polygon2D      = $IslandPolygon
@onready var island_shadow:  Polygon2D      = $IslandShadow
@onready var venues_layer:   Control        = $VenuesLayer
@onready var throw_btn:      Button         = $ThrowPartyBtn
@onready var particles:      CPUParticles2D = $CPUParticles2D
@onready var ocean_bg:       ColorRect      = $OceanBg

const VENUE_GUEST_BASES: Dictionary = {
	"bonfire":   8,
	"yacht":     12,
	"villa":     20,
	"jet":       6,
	"offshore":  0,
	"shell":     0,
	"political": 4,
	"blackout":  2,
}

var _venue_nodes:       Dictionary = {}
var _secret_timer:      float      = 0.0
var _active_secret:     Control    = null
var _secret_data:       Node       = null
var _staff_rate_label:  Label      = null
var _guest_count_label: Label      = null
var _seagull_timer:     float      = 0.0
var _seagull_label:     Label      = null
var _tooltip:           PanelContainer = null
var _tooltip_name_lbl:  Label      = null
var _tooltip_count_lbl: Label      = null
var _tooltip_income_lbl: Label     = null
var _tooltip_upg_lbl:   Label      = null
var _venue_data_node:   Node       = null
var _upgrade_data_node: Node       = null

func _ready() -> void:
	add_to_group("island_map")
	GameState.venue_count_changed.connect(_on_venue_count_changed)
	GameState.game_reset.connect(_on_game_reset)
	throw_btn.pressed.connect(_on_throw_party)
	throw_btn.text = "🎉 Throw Party"
	_secret_data = load("res://scripts/data/SecretData.gd").new()
	_venue_data_node = load("res://scripts/data/VenueData.gd").new()
	_upgrade_data_node = load("res://scripts/data/UpgradeData.gd").new()
	_rebuild_polygon()
	_sync_from_state()
	_schedule_next_secret()
	_setup_staff_rate_label()
	_setup_tooltip()
	if GameState.has_signal("staff_count_changed"):
		GameState.staff_count_changed.connect(_on_staff_count_changed)
	_start_ocean_shimmer()
	_setup_seagull()
	_schedule_next_seagull()
	_setup_guest_count_label()
	_setup_tv_overlay()
	_start_throw_btn_pulse()

func _start_throw_btn_pulse() -> void:
	# Only pulse until the player first clicks — stops on first party throw
	if GameState.lifetime_money > 0.0:
		return  # already played before, no need to prompt
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(throw_btn, "modulate", Color(1.25, 1.15, 0.5, 1.0), 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(throw_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	throw_btn.pressed.connect(func():
		tween.kill()
		throw_btn.modulate = Color(1, 1, 1, 1)
	, CONNECT_ONE_SHOT)

func _setup_tv_overlay() -> void:
	var tv = load("res://scripts/components/tv_overlay.gd").new()
	add_child(tv)

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
	var margin_px := s * POLY_MARGIN
	var draw_size := s * (1.0 - 2.0 * POLY_MARGIN)
	var pts: PackedVector2Array = PackedVector2Array()
	var count: int = ISLAND_POINTS_NORM.size()
	pts.resize(count)
	for i in count:
		pts[i] = margin_px + ISLAND_POINTS_NORM[i] * draw_size
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
	_staff_rate_label.mouse_filter  = Control.MOUSE_FILTER_IGNORE
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

func _on_staff_count_changed(_id: String, _count: int) -> void:
	_update_staff_rate_label()

func _setup_guest_count_label() -> void:
	_guest_count_label = Label.new()
	_guest_count_label.name = "GuestCountLabel"
	_guest_count_label.add_theme_font_size_override("font_size", 12)
	_guest_count_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.7))
	_guest_count_label.anchor_left   = 0.0
	_guest_count_label.anchor_top    = 1.0
	_guest_count_label.anchor_right  = 0.0
	_guest_count_label.anchor_bottom = 1.0
	_guest_count_label.offset_left   = 8.0
	_guest_count_label.offset_top    = -26.0
	_guest_count_label.offset_right  = 120.0
	_guest_count_label.offset_bottom = -6.0
	_guest_count_label.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_guest_count_label)
	_update_guest_count()

func _update_guest_count() -> void:
	if _guest_count_label == null:
		return
	var total: int = 0
	for venue_id in VENUE_GUEST_BASES:
		var base: int = VENUE_GUEST_BASES[venue_id]
		if base == 0:
			continue
		var count: int = GameState.venue_counts.get(venue_id, 0)
		total += count * base
	if total == 0:
		_guest_count_label.visible = false
	else:
		_guest_count_label.text = "👥 %d guests" % total
		_guest_count_label.visible = true

func _process(delta: float) -> void:
	# Secret spawning
	if _active_secret == null:
		_secret_timer -= delta
		if _secret_timer <= 0.0:
			_spawn_secret()

	# Seagull spawning
	if _seagull_label == null:
		_seagull_timer -= delta
		if _seagull_timer <= 0.0:
			_fly_seagull()

# ── Ocean shimmer ─────────────────────────────────────────────────────────────

func _start_ocean_shimmer() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(ocean_bg, "color", OCEAN_COLOR_LIGHT, 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ocean_bg, "color", OCEAN_COLOR_DARK, 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ── Seagull ───────────────────────────────────────────────────────────────────

func _setup_seagull() -> void:
	_seagull_label = Label.new()
	_seagull_label.name = "Seagull"
	_seagull_label.text = "🦅"
	_seagull_label.add_theme_font_size_override("font_size", 18)
	_seagull_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_seagull_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seagull_label.modulate.a = 0.0
	add_child(_seagull_label)
	# Mark as inactive (null means "no active flight"; we'll toggle via modulate)
	_seagull_label = null

func _schedule_next_seagull() -> void:
	_seagull_timer = randf_range(SEAGULL_INTERVAL_MIN, SEAGULL_INTERVAL_MAX)

func _fly_seagull() -> void:
	# Build the label on first flight or reuse by finding it
	var gull: Label = get_node_or_null("Seagull") as Label
	if gull == null:
		gull = Label.new()
		gull.name = "Seagull"
		gull.text = "🦅"
		gull.add_theme_font_size_override("font_size", 18)
		gull.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		gull.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gull.modulate.a = 0.0
		add_child(gull)

	_seagull_label = gull

	var map_h: float = size.y * 0.8
	var start_y: float = randf_range(size.y * 0.1, map_h)
	var fly_dur: float = randf_range(SEAGULL_FLY_MIN, SEAGULL_FLY_MAX)

	gull.position = Vector2(-32.0, start_y)
	gull.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	# Fade in quickly
	tween.tween_property(gull, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	# Drift across
	tween.tween_property(gull, "position:x", size.x + 32.0, fly_dur).set_ease(Tween.EASE_IN_OUT)
	# Fade out in the last 0.8 s
	tween.chain()
	tween.tween_property(gull, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_seagull_done)

func _on_seagull_done() -> void:
	_seagull_label = null
	_schedule_next_seagull()

# ── Tooltip ───────────────────────────────────────────────────────────────────

func _setup_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.name = "Tooltip"

	var style := StyleBoxFlat.new()
	style.bg_color                   = Color(0.0, 0.0, 0.0, 0.85)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left        = 10.0
	style.content_margin_right       = 10.0
	style.content_margin_top         = 8.0
	style.content_margin_bottom      = 8.0
	_tooltip.add_theme_stylebox_override("panel", style)
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_tooltip.add_child(vbox)

	_tooltip_name_lbl = Label.new()
	_tooltip_name_lbl.add_theme_font_size_override("font_size", 14)
	_tooltip_name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	vbox.add_child(_tooltip_name_lbl)

	_tooltip_count_lbl = Label.new()
	_tooltip_count_lbl.add_theme_font_size_override("font_size", 12)
	_tooltip_count_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 1.0))
	vbox.add_child(_tooltip_count_lbl)

	_tooltip_income_lbl = Label.new()
	_tooltip_income_lbl.add_theme_font_size_override("font_size", 12)
	_tooltip_income_lbl.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6, 1.0))
	vbox.add_child(_tooltip_income_lbl)

	_tooltip_upg_lbl = Label.new()
	_tooltip_upg_lbl.add_theme_font_size_override("font_size", 11)
	_tooltip_upg_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	vbox.add_child(_tooltip_upg_lbl)

	_tooltip.visible = false
	add_child(_tooltip)

func _on_venue_hover_enter(venue_id: String) -> void:
	# Find venue dict
	var venue: Dictionary = {}
	for v in _venue_data_node.VENUES:
		if v.id == venue_id:
			venue = v
			break
	if venue.is_empty():
		return

	var count: int = GameState.venue_counts.get(venue_id, 0)

	# Base income (without VIP multiplier — honest approximation)
	var qty_mult: float = _venue_data_node.get_quantity_multiplier(count)
	var upg_mult: float = 1.0
	var upg_purchased: bool = false
	for upg in _upgrade_data_node.UPGRADES:
		if upg.type == venue_id and GameState.upgrades_purchased.get(upg.id, false):
			upg_mult *= upg.multiplier
			upg_purchased = true

	var base_income: float = venue.base_income * count * qty_mult * upg_mult

	# Populate labels
	_tooltip_name_lbl.text = venue.name
	_tooltip_count_lbl.text = "x%d owned" % count
	_tooltip_income_lbl.text = "~$%s base" % NumberFormatter.format_rate(base_income)
	_tooltip_upg_lbl.text = "Upgraded ✓" if upg_purchased else ""
	_tooltip_upg_lbl.visible = upg_purchased

	# Position: venue panel position (in venues_layer space) + venues_layer offset + icon width
	var venue_node: Control = _venue_nodes.get(venue_id)
	if venue_node == null:
		return
	var raw_pos: Vector2 = venues_layer.position + venue_node.position + Vector2(VENUE_SIZE.x + 4.0, 0.0)

	# Wait one frame for tooltip to size itself, then clamp
	await get_tree().process_frame
	if not is_instance_valid(_tooltip):
		return
	var tooltip_size: Vector2 = _tooltip.size
	var map_size: Vector2 = size
	raw_pos.x = clampf(raw_pos.x, 0.0, map_size.x - tooltip_size.x)
	raw_pos.y = clampf(raw_pos.y, 0.0, map_size.y - tooltip_size.y)
	_tooltip.position = raw_pos
	_tooltip.visible = true

func _on_venue_hover_exit() -> void:
	_tooltip.visible = false

# ── Venue helpers ─────────────────────────────────────────────────────────────

func _sync_from_state() -> void:
	for node in _venue_nodes.values():
		node.queue_free()
	_venue_nodes.clear()
	for venue_id in GameState.venue_counts:
		if GameState.venue_counts[venue_id] > 0:
			_show_venue(venue_id)
	_update_guest_count()

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
	_update_guest_count()

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

	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(_on_venue_hover_enter.bind(venue_id))
	panel.mouse_exited.connect(_on_venue_hover_exit)

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
	# Apply same margin as the polygon so venue icons stay on the island
	var adjusted := Vector2(POLY_MARGIN, POLY_MARGIN) + pos_norm * (1.0 - 2.0 * POLY_MARGIN)
	node.position = adjusted * venues_layer.size - node_size * 0.5

# ── Click helpers ─────────────────────────────────────────────────────────────

func _on_throw_party() -> void:
	var earned: float = GameState.click_party()
	AudioManager.play_sfx("click")
	_spawn_island_burst()
	_spawn_click_label(earned)
	TutorialManager.advance_to("venue")


const _BURST_COLORS: Array[Color] = [
	Color(0.788, 0.659, 0.298, 1.0),  # gold
	Color(1.0,   0.92,  0.35,  1.0),  # yellow
	Color(1.0,   0.45,  0.45,  1.0),  # red
	Color(0.45,  0.85,  1.0,   1.0),  # blue
	Color(0.5,   1.0,   0.55,  1.0),  # green
	Color(1.0,   0.55,  1.0,   1.0),  # pink
	Color(1.0,   0.65,  0.2,   1.0),  # orange
]

func _spawn_island_burst() -> void:
	# Pick a random point within the island's drawn bounds
	var s := size
	var margin_px := s * POLY_MARGIN
	var draw_size := s * (1.0 - 2.0 * POLY_MARGIN)
	# Island polygon spans roughly x 0.08–0.88, y 0.22–0.72 — stay inside that
	var norm := Vector2(randf_range(0.12, 0.82), randf_range(0.27, 0.67))
	var pos := margin_px + norm * draw_size

	var burst := CPUParticles2D.new()
	burst.position = pos
	burst.z_index = 1
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.amount = 28
	burst.lifetime = 1.1
	burst.direction = Vector2(0.0, -1.0)
	burst.spread = 85.0
	burst.gravity = Vector2(0.0, 160.0)
	burst.initial_velocity_min = 70.0
	burst.initial_velocity_max = 210.0
	burst.scale_amount_min = 4.0
	burst.scale_amount_max = 10.0
	burst.color = _BURST_COLORS[randi() % _BURST_COLORS.size()]
	burst.emitting = true
	add_child(burst)
	get_tree().create_timer(burst.lifetime + 0.2).timeout.connect(burst.queue_free)

func _spawn_click_label(amount: float) -> void:
	var lbl := Label.new()
	lbl.text = "+" + NumberFormatter.format(amount)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var reward_color: Color
	match secret_dict.reward_type:
		"money":       reward_color = Color(0.788, 0.659, 0.298, 1)  # gold
		"pi":          reward_color = Color(0.4, 0.7, 1.0, 1)         # blue
		"heat_reduce": reward_color = Color(0.3, 0.9, 0.4, 1)         # green
		_:             reward_color = Color(1, 1, 1, 1)
	_spawn_secret_label(dying.position, reward_label, reward_color)

	_schedule_next_secret()

func _spawn_secret_label(pos: Vector2, text: String, color: Color = Color(0.788, 0.659, 0.298, 1)) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
