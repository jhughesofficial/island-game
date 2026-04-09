extends Node

# ── Runtime State ───────────────────────────────────────────────
var money: float = 0.0
var lifetime_money: float = 0.0
var political_influence: int = 0
var heat: float = 0.0          # 0.0 – 5.0; 5.0 = CRITICAL
var last_save_unix: int = 0    # Unix timestamp of last save
var secrets_found: int = 0
var act3_revealed: bool = false

# { venue_id: int }
var venue_counts: Dictionary = {}
# { upgrade_id: bool }
var upgrades_purchased: Dictionary = {}
# { vip_id: bool }
var vips_recruited: Dictionary = {}
# { staff_id: int }
var staff_counts: Dictionary = {}

# ── Signals ─────────────────────────────────────────────────────
signal money_changed(amount: float)
signal lifetime_money_changed(amount: float)
signal pi_changed(pi: int)
signal heat_changed(heat: float)
signal venue_count_changed(venue_id: String, count: int)
signal upgrade_purchased(upgrade_id: String)
signal vip_recruited(vip_id: String)
signal staff_count_changed(staff_id: String, count: int)
signal game_over_triggered(ending: String)
signal arrest_countdown_changed(seconds: float)
signal offline_earnings_received(amount: float)
signal game_reset()
signal secret_found(secret_id: String)

# ── Cached Rates (rebuilt on state change) ──────────────────────
var _income_per_second: float = 0.0
var _click_value: float = 1.0
var _heat_per_second: float = 0.0
var _vip_multiplier: float = 1.0
var _auto_clicks_per_second: float = 0.0
var _auto_click_acc: float = 0.0

# ── Data refs (loaded once) ──────────────────────────────────────
var _venue_data: Node
var _vip_data: Node
var _upgrade_data: Node
var _staff_data: Node

const HEAT_CRITICAL: float = 5.0
const HEAT_CRITICAL_COUNTDOWN: float = 60.0
var _critical_timer: float = 0.0
var _is_critical: bool = false

# ── Lifecycle ────────────────────────────────────────────────────
func _ready() -> void:
	_venue_data = load("res://scripts/data/VenueData.gd").new()
	_vip_data = load("res://scripts/data/VIPData.gd").new()
	_upgrade_data = load("res://scripts/data/UpgradeData.gd").new()
	_staff_data = load("res://scripts/data/StaffData.gd").new()
	load_game()
	_rebuild_rates()

func _process(delta: float) -> void:
	_tick_income(delta)
	_tick_heat(delta)
	_check_critical(delta)
	_tick_auto_click(delta)

# ── Tick ─────────────────────────────────────────────────────────
func _tick_income(delta: float) -> void:
	if _income_per_second == 0.0:
		return
	var earned: float = _income_per_second * delta
	_add_money(earned)

func _tick_heat(delta: float) -> void:
	if _heat_per_second == 0.0:
		return
	heat = clampf(heat + _heat_per_second * delta, 0.0, HEAT_CRITICAL)
	heat_changed.emit(heat)

func _check_critical(delta: float) -> void:
	if heat >= HEAT_CRITICAL:
		if not _is_critical:
			_is_critical = true
			_critical_timer = HEAT_CRITICAL_COUNTDOWN
		else:
			_critical_timer -= delta
			arrest_countdown_changed.emit(_critical_timer)
			if _critical_timer <= 0.0:
				game_over_triggered.emit("arrested")
	else:
		if _is_critical:
			arrest_countdown_changed.emit(0.0)
		_is_critical = false
		_critical_timer = 0.0

func _tick_auto_click(delta: float) -> void:
	if _auto_clicks_per_second == 0.0:
		return
	_auto_click_acc += _auto_clicks_per_second * delta
	while _auto_click_acc >= 1.0:
		_add_money(_click_value)
		_auto_click_acc -= 1.0

# ── Player Actions ───────────────────────────────────────────────
func click_party() -> float:
	var earned: float = _click_value
	_add_money(earned)
	return earned

func buy_venue(venue_id: String) -> bool:
	var venue = _get_venue(venue_id)
	if venue == null:
		return false
	var count: int = venue_counts.get(venue_id, 0)
	var cost: float = _venue_data.get_cost(venue, count)
	if money < cost:
		return false
	money -= cost
	money_changed.emit(money)
	venue_counts[venue_id] = count + 1
	venue_count_changed.emit(venue_id, venue_counts[venue_id])
	_rebuild_rates()
	return true

func buy_venue_n(venue_id: String, n: int) -> int:
	var bought := 0
	for i in range(n):
		if not buy_venue(venue_id):
			break
		bought += 1
	return bought

func venue_max_affordable(venue_id: String) -> int:
	var venue = _get_venue(venue_id)
	if venue == null:
		return 0
	var count: int = venue_counts.get(venue_id, 0)
	var budget: float = money
	var n := 0
	while n < 10000:
		var cost: float = _venue_data.get_cost(venue, count + n)
		if budget < cost:
			break
		budget -= cost
		n += 1
	return n

func venue_cost_n(venue_id: String, n: int) -> float:
	var venue = _get_venue(venue_id)
	if venue == null:
		return 0.0
	var count: int = venue_counts.get(venue_id, 0)
	var total: float = 0.0
	for i in range(n):
		total += _venue_data.get_cost(venue, count + i)
	return total

func buy_upgrade(upgrade_id: String) -> bool:
	if upgrades_purchased.get(upgrade_id, false):
		return false
	var upgrade = _get_upgrade(upgrade_id)
	if upgrade == null:
		return false
	if money < upgrade.cost:
		return false
	money -= upgrade.cost
	money_changed.emit(money)
	upgrades_purchased[upgrade_id] = true
	upgrade_purchased.emit(upgrade_id)
	_rebuild_rates()
	return true

func recruit_vip(vip_id: String) -> bool:
	if vips_recruited.get(vip_id, false):
		return false
	var vip = _get_vip(vip_id)
	if vip == null:
		return false
	if money < vip.cost:
		return false
	money -= vip.cost
	money_changed.emit(money)
	vips_recruited[vip_id] = true
	political_influence += vip.pi_award
	pi_changed.emit(political_influence)
	if vip.effect == "heat_reduce_1":
		heat = maxf(0.0, heat - 1.0)
		heat_changed.emit(heat)
	elif vip.effect == "heat_reduce_2":
		heat = maxf(0.0, heat - 2.0)
		heat_changed.emit(heat)
	elif vip.effect == "heat_reduce_3":
		heat = maxf(0.0, heat - 3.0)
		heat_changed.emit(heat)
	vip_recruited.emit(vip_id)
	_rebuild_rates()
	return true

func buy_staff(staff_id: String) -> bool:
	var staff = _get_staff(staff_id)
	if staff == null:
		return false
	var count: int = staff_counts.get(staff_id, 0)
	var cost: float = _staff_data.get_cost(staff, count)
	if money < cost:
		return false
	money -= cost
	money_changed.emit(money)
	staff_counts[staff_id] = count + 1
	staff_count_changed.emit(staff_id, staff_counts[staff_id])
	_rebuild_rates()
	return true

func buy_staff_n(staff_id: String, n: int) -> int:
	var bought := 0
	for i in range(n):
		if not buy_staff(staff_id):
			break
		bought += 1
	return bought

func staff_max_affordable(staff_id: String) -> int:
	var staff = _get_staff(staff_id)
	if staff == null:
		return 0
	var count: int = staff_counts.get(staff_id, 0)
	var budget: float = money
	var n := 0
	while n < 10000:
		var cost: float = _staff_data.get_cost(staff, count + n)
		if budget < cost:
			break
		budget -= cost
		n += 1
	return n

func staff_cost(staff_id: String) -> float:
	var staff = _get_staff(staff_id)
	if staff == null:
		return 0.0
	var count: int = staff_counts.get(staff_id, 0)
	return _staff_data.get_cost(staff, count)

func staff_cost_n(staff_id: String, n: int) -> float:
	var staff = _get_staff(staff_id)
	if staff == null:
		return 0.0
	var count: int = staff_counts.get(staff_id, 0)
	var total: float = 0.0
	for i in range(n):
		total += _staff_data.get_cost(staff, count + i)
	return total

# ── Rate Calculation ─────────────────────────────────────────────
func _rebuild_rates() -> void:
	# VIP multiplier
	_vip_multiplier = 1.0
	for vip in _vip_data.VIPS:
		if vips_recruited.get(vip.id, false):
			_vip_multiplier *= vip.multiplier

	# Income per second + heat per second
	_income_per_second = 0.0
	_heat_per_second = 0.0
	for venue in _venue_data.VENUES:
		var count: int = venue_counts.get(venue.id, 0)
		if count == 0:
			continue
		var qty_mult: float = _venue_data.get_quantity_multiplier(count)
		var upg_mult: float = 1.0
		for upg in _upgrade_data.UPGRADES:
			if upg.type == venue.id and upgrades_purchased.get(upg.id, false):
				upg_mult *= upg.multiplier
		_income_per_second += venue.base_income * count * qty_mult * upg_mult
		_heat_per_second += venue.heat_rate * count
	_income_per_second *= _vip_multiplier
	if vips_recruited.get("president", false):
		_heat_per_second = maxf(0.0, _heat_per_second - 0.02)

	# Click value: 10% of passive income (min $1), boosted by click upgrades + VIPs
	var click_base: float = maxf(1.0, _income_per_second * 0.1)
	var click_upg_mult: float = 1.0
	for upg in _upgrade_data.UPGRADES:
		if upg.type == "click" and upgrades_purchased.get(upg.id, false):
			click_upg_mult *= upg.multiplier
	_click_value = click_base * click_upg_mult * _vip_multiplier

	# Auto-clicks from staff
	_auto_clicks_per_second = 0.0
	for staff in _staff_data.STAFF:
		var count: int = staff_counts.get(staff.id, 0)
		if count > 0:
			_auto_clicks_per_second += staff.clicks_per_second * count

func get_income_per_second() -> float:
	return _income_per_second

func get_click_value() -> float:
	return _click_value

func get_auto_clicks_per_second() -> float:
	return _auto_clicks_per_second

func get_heat_stars() -> int:
	return ceili(heat)

# ── Helpers ──────────────────────────────────────────────────────
func _add_money(amount: float) -> void:
	money += amount
	lifetime_money += amount
	money_changed.emit(money)
	lifetime_money_changed.emit(lifetime_money)

func _get_venue(venue_id: String) -> Variant:
	for v in _venue_data.VENUES:
		if v.id == venue_id:
			return v
	return null

func _get_vip(vip_id: String) -> Variant:
	for v in _vip_data.VIPS:
		if v.id == vip_id:
			return v
	return null

func _get_upgrade(upgrade_id: String) -> Variant:
	for u in _upgrade_data.UPGRADES:
		if u.id == upgrade_id:
			return u
	return null

func _get_staff(staff_id: String) -> Variant:
	for s in _staff_data.STAFF:
		if s.id == staff_id:
			return s
	return null

func venue_cost(venue_id: String) -> float:
	var venue = _get_venue(venue_id)
	if venue == null:
		return 0.0
	var count: int = venue_counts.get(venue_id, 0)
	return _venue_data.get_cost(venue, count)

func vip_is_available(vip_id: String) -> bool:
	var vip = _get_vip(vip_id)
	if vip == null:
		return false
	return lifetime_money >= vip.appears_at and not vips_recruited.get(vip_id, false)

func upgrade_is_available(upgrade_id: String) -> bool:
	var upg = _get_upgrade(upgrade_id)
	if upg == null:
		return false
	return lifetime_money >= upg.unlock_at and not upgrades_purchased.get(upgrade_id, false)

# ── Save / Load ──────────────────────────────────────────────────
const SAVE_PATH: String = "user://save.json"
const OFFLINE_CAP_SECONDS: int = 28800  # 8 hours

func save_game() -> void:
	var data: Dictionary = {
		"money": money,
		"lifetime_money": lifetime_money,
		"political_influence": political_influence,
		"heat": heat,
		"venue_counts": venue_counts,
		"upgrades_purchased": upgrades_purchased,
		"vips_recruited": vips_recruited,
		"staff_counts": staff_counts,
		"secrets_found": secrets_found,
		"act3_revealed": act3_revealed,
		"saved_at": Time.get_unix_time_from_system()
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var raw: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if parsed == null or not parsed is Dictionary:
		return
	money = float(parsed.get("money", 0.0))
	lifetime_money = float(parsed.get("lifetime_money", 0.0))
	political_influence = int(parsed.get("political_influence", 0))
	heat = float(parsed.get("heat", 0.0))
	venue_counts = parsed.get("venue_counts", {})
	upgrades_purchased = parsed.get("upgrades_purchased", {})
	vips_recruited = parsed.get("vips_recruited", {})
	staff_counts = parsed.get("staff_counts", {})
	secrets_found = int(parsed.get("secrets_found", 0))
	act3_revealed = bool(parsed.get("act3_revealed", false))
	# Offline earnings
	var saved_at: int = int(parsed.get("saved_at", 0))
	if saved_at > 0:
		var elapsed: int = mini(
			int(Time.get_unix_time_from_system()) - saved_at,
			OFFLINE_CAP_SECONDS
		)
		if elapsed > 0:
			_rebuild_rates()
			var offline_earned: float = _income_per_second * elapsed
			if offline_earned > 0.0:
				_add_money(offline_earned)
				call_deferred("_emit_offline_earnings", offline_earned)

func _emit_offline_earnings(amount: float) -> void:
	offline_earnings_received.emit(amount)

func reset_game() -> void:
	money = 0.0
	lifetime_money = 0.0
	political_influence = 0
	heat = 0.0
	venue_counts = {}
	upgrades_purchased = {}
	vips_recruited = {}
	staff_counts = {}
	secrets_found = 0
	act3_revealed = false
	_auto_click_acc = 0.0
	_rebuild_rates()
	game_reset.emit()
	money_changed.emit(money)
	lifetime_money_changed.emit(lifetime_money)
	heat_changed.emit(heat)
	pi_changed.emit(political_influence)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
