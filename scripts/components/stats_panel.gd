extends Control

@onready var close_btn: Button = $Panel/VBoxContainer/HeaderRow/CloseBtn
@onready var stats_grid: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/StatsGrid
@onready var total_earned_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/TotalEarnedVal
@onready var current_balance_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/CurrentBalanceVal
@onready var passive_income_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/PassiveIncomeVal
@onready var click_value_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/ClickValueVal
@onready var political_influence_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/PoliticalInfluenceVal
@onready var heat_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/HeatVal
@onready var venues_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/VenuesVal
@onready var upgrades_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/UpgradesVal
@onready var vips_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/VIPsVal
@onready var staff_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/StaffVal
@onready var secrets_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/SecretsVal
@onready var auto_clicks_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/AutoClicksVal
@onready var peak_income_val: Label = $Panel/VBoxContainer/ScrollContainer/StatsGrid/PeakIncomeVal

var _peak_income_per_second: float = 0.0
var _identity_row: HBoxContainer = null
var _identity_val: Label = null

func _ready() -> void:
	close_btn.pressed.connect(func(): hide())
	_build_identity_row()

func _process(_delta: float) -> void:
	if not visible:
		return
	var current_ips: float = GameState.get_income_per_second()
	if current_ips > _peak_income_per_second:
		_peak_income_per_second = current_ips
		peak_income_val.text = NumberFormatter.format_rate(_peak_income_per_second)

func show_panel() -> void:
	_refresh()
	show()
	$Panel.scale = Vector2(0.92, 0.92)
	$Panel.pivot_offset = $Panel.size / 2
	var tween := create_tween()
	tween.tween_property($Panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _build_identity_row() -> void:
	_identity_row = HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Operator Identity"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	_identity_row.add_child(lbl)
	_identity_val = Label.new()
	_identity_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_identity_row.add_child(_identity_val)
	stats_grid.add_child(_identity_row)
	# Move to top of grid
	stats_grid.move_child(_identity_row, 0)
	_identity_row.visible = false

func _refresh() -> void:
	# Identity row — visible only in Custom Run
	if not GameState.player_identity.is_empty():
		var id_data = load("res://scripts/data/IdentityData.gd").new()
		for identity in id_data.IDENTITIES:
			if identity.id == GameState.player_identity:
				_identity_val.text = identity.cover
				_identity_val.add_theme_color_override("font_color", identity.accent_color)
				break
		_identity_row.visible = true
	else:
		_identity_row.visible = false

	total_earned_val.text = NumberFormatter.format(GameState.lifetime_money)
	current_balance_val.text = NumberFormatter.format(GameState.money)
	passive_income_val.text = NumberFormatter.format_rate(GameState.get_income_per_second())
	click_value_val.text = NumberFormatter.format(GameState.get_click_value())
	political_influence_val.text = str(GameState.political_influence)
	heat_val.text = "%.1f / 5.0" % GameState.heat

	var total_venues: int = 0
	for v in GameState.venue_counts.values():
		total_venues += v
	venues_val.text = str(total_venues)

	upgrades_val.text = str(GameState.upgrades_purchased.size())
	vips_val.text = str(GameState.vips_recruited.size())

	var total_staff: int = 0
	for s in GameState.staff_counts.values():
		total_staff += s
	staff_val.text = str(total_staff)

	secrets_val.text = str(GameState.secrets_found)
	auto_clicks_val.text = "%.1f/sec" % GameState.get_auto_clicks_per_second()
	peak_income_val.text = NumberFormatter.format_rate(_peak_income_per_second)
