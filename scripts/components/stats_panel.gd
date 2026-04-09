extends Control

@onready var close_btn: Button = $Panel/VBoxContainer/HeaderRow/CloseBtn
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

func _ready() -> void:
	close_btn.pressed.connect(func(): hide())

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

func _refresh() -> void:
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
