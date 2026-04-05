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

@onready var island_rect: ColorRect = $IslandRect
@onready var venues_layer: Control = $VenuesLayer
@onready var throw_btn: Button = $ThrowPartyBtn
@onready var particles: CPUParticles2D = $CPUParticles2D

var _venue_nodes: Dictionary = {}

func _ready() -> void:
	GameState.venue_count_changed.connect(_on_venue_count_changed)
	GameState.game_reset.connect(_sync_from_state)
	throw_btn.pressed.connect(_on_throw_party)
	_sync_from_state()

func _sync_from_state() -> void:
	# Clear existing sprites
	for node in _venue_nodes.values():
		node.queue_free()
	_venue_nodes.clear()
	# Re-add from current state
	for venue_id in GameState.venue_counts:
		if GameState.venue_counts[venue_id] > 0:
			_show_venue(venue_id)


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

func _on_throw_party() -> void:
	GameState.click_party()
	_play_click_particles()

func _play_click_particles() -> void:
	particles.restart()
	particles.emitting = true

func _on_resized() -> void:
	for venue_id in _venue_nodes:
		_reposition_venue(venue_id, _venue_nodes[venue_id])
