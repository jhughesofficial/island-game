extends Node

# ── Constants ────────────────────────────────────────────────────
const MUSIC_PATHS: Array[String] = [
	"",                                        # index 0 unused
	"res://audio/music/act1_ambient.ogg",
	"res://audio/music/act2_tension.ogg",
	"res://audio/music/act3_danger.ogg",
]

const SFX_PATHS: Dictionary = {
	"click":          "res://audio/sfx/click.wav",
	"purchase":       "res://audio/sfx/purchase.wav",
	"secret":         "res://audio/sfx/secret.wav",
	"secret_collect": "res://audio/sfx/secret_collect.wav",
	"achievement":    "res://audio/sfx/achievement.wav",
	"narrative":      "res://audio/sfx/narrative.wav",
	"breaking_news":  "res://audio/sfx/breaking_news.wav",
}

const DEFAULT_MUSIC_DB: float = -6.0
const DEFAULT_SFX_DB:   float = 0.0
const CROSSFADE_DURATION: float = 1.5

# ── Act thresholds ───────────────────────────────────────────────
const ACT2_THRESHOLD: float = 1_000_000.0
const ACT3_THRESHOLD: float = 50_000_000.0

# ── Nodes ────────────────────────────────────────────────────────
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer    # whichever player is currently audible
var _sfx_players: Dictionary = {}       # name -> AudioStreamPlayer

# ── State ────────────────────────────────────────────────────────
var _current_act: int = 0
var _music_volume_db: float = DEFAULT_MUSIC_DB
var _sfx_volume_db:   float = DEFAULT_SFX_DB
var _crossfade_tween: Tween = null

# ── Lifecycle ────────────────────────────────────────────────────
func _ready() -> void:
	_build_music_players()
	_build_sfx_players()
	GameState.lifetime_money_changed.connect(_on_lifetime_money_changed)
	# Determine starting act from saved state
	_on_lifetime_money_changed(GameState.lifetime_money)

func _build_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.name = "MusicA"
	_music_a.bus = "Master"
	_music_a.volume_db = _music_volume_db
	add_child(_music_a)

	_music_b = AudioStreamPlayer.new()
	_music_b.name = "MusicB"
	_music_b.bus = "Master"
	_music_b.volume_db = -80.0   # start silent
	add_child(_music_b)

	_active_music = _music_a

func _build_sfx_players() -> void:
	for sfx_name in SFX_PATHS:
		var player := AudioStreamPlayer.new()
		player.name = "SFX_" + sfx_name
		player.bus = "Master"
		player.volume_db = _sfx_volume_db
		add_child(player)
		_sfx_players[sfx_name] = player

# ── Public API ───────────────────────────────────────────────────
func play_music(act: int) -> void:
	if act == _current_act:
		return
	_current_act = act
	if act < 1 or act > 3:
		return

	var stream = _load_stream(MUSIC_PATHS[act])
	if stream == null:
		return

	# Pick the inactive player as the incoming track
	var incoming: AudioStreamPlayer = _music_b if _active_music == _music_a else _music_a
	var outgoing: AudioStreamPlayer = _active_music

	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	# Cancel any in-progress crossfade
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(incoming, "volume_db", _music_volume_db, CROSSFADE_DURATION)
	_crossfade_tween.tween_property(outgoing, "volume_db", -80.0, CROSSFADE_DURATION)
	_crossfade_tween.chain().tween_callback(outgoing.stop)

	_active_music = incoming

func play_sfx(sfx_name: String) -> void:
	if not _sfx_players.has(sfx_name):
		return
	var player: AudioStreamPlayer = _sfx_players[sfx_name]
	if player.stream == null:
		# Try loading on first use — file may have been dropped in since startup
		var stream = _load_stream(SFX_PATHS.get(sfx_name, ""))
		if stream == null:
			return
		player.stream = stream
	player.play()

func set_music_volume(db: float) -> void:
	_music_volume_db = db
	# Only adjust the currently playing player; inactive stays silent
	_active_music.volume_db = db

func set_sfx_volume(db: float) -> void:
	_sfx_volume_db = db
	for player in _sfx_players.values():
		player.volume_db = db

# ── Internal helpers ─────────────────────────────────────────────
func _load_stream(path: String) -> AudioStream:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _on_lifetime_money_changed(amount: float) -> void:
	var target_act: int = 1
	if amount >= ACT3_THRESHOLD:
		target_act = 3
	elif amount >= ACT2_THRESHOLD:
		target_act = 2
	play_music(target_act)
