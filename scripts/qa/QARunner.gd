## Automated QA runner for The Island.
## Run via: mcp__godot__editor_run(scene: "scenes/QATest.tscn")
## Reads GameState directly, prints PASS/FAIL, then quits.
## Backs up and restores user://save.json so no progress is lost.
extends Node

const LOG_PATH: String = "user://qa_results.txt"

var _pass: int = 0
var _fail: int = 0
var _failures: Array = []
var _log_lines: Array = []

var _venue_data
var _upgrade_data
var _vip_data
var _staff_data
var _narrative_data
var _achievement_data

# ── Entry point ───────────────────────────────────────────────────
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	await get_tree().process_frame
	_log("[QA] ── The Island QA Runner ─────────────────────────")
	_load_data()
	_backup_save()
	_run_data_integrity()
	_run_economy()
	_run_heat_system()
	_run_click_value()
	_run_narrative_events()
	_run_save_load()
	_run_identity_system()
	_restore_save()
	_print_summary()
	get_tree().quit()

# ── Data loading ──────────────────────────────────────────────────
func _load_data() -> void:
	_venue_data      = load("res://scripts/data/VenueData.gd").new()
	_upgrade_data    = load("res://scripts/data/UpgradeData.gd").new()
	_vip_data        = load("res://scripts/data/VIPData.gd").new()
	_staff_data      = load("res://scripts/data/StaffData.gd").new()
	_narrative_data  = load("res://scripts/data/NarrativeEventData.gd").new()
	_achievement_data = load("res://scripts/data/AchievementData.gd").new()

# ── Save backup/restore ───────────────────────────────────────────
func _backup_save() -> void:
	if not FileAccess.file_exists("user://save.json"):
		return
	var f := FileAccess.open("user://save.json", FileAccess.READ)
	var content: String = f.get_as_text()
	f.close()
	var out := FileAccess.open("user://save.qa_backup.json", FileAccess.WRITE)
	out.store_string(content)
	out.close()

func _restore_save() -> void:
	if not FileAccess.file_exists("user://save.qa_backup.json"):
		return
	var f := FileAccess.open("user://save.qa_backup.json", FileAccess.READ)
	var content: String = f.get_as_text()
	f.close()
	var out := FileAccess.open("user://save.json", FileAccess.WRITE)
	out.store_string(content)
	out.close()
	DirAccess.remove_absolute(OS.get_user_data_dir() + "/save.qa_backup.json")

# ── State helpers ─────────────────────────────────────────────────
func _fresh() -> void:
	## Reset GameState to a clean, money-rich state for testing.
	GameState.money               = 1_000_000_000.0
	GameState.lifetime_money      = 1_000_000_000.0
	GameState.political_influence = 0
	GameState.heat                = 0.0
	GameState.venue_counts        = {}
	GameState.upgrades_purchased  = {}
	GameState.vips_recruited      = {}
	GameState.staff_counts        = {}
	# Reset identity so tests don't inherit multipliers from a loaded save
	GameState.player_identity         = ""
	GameState._identity_click_mult    = 1.0
	GameState._identity_vip_discount  = 1.0
	GameState._rebuild_rates()

# ── Assertion helpers ─────────────────────────────────────────────
func _log(line: String) -> void:
	print(line)
	_log_lines.append(line)

func _ok(label: String, cond: bool) -> void:
	_pass += 1 if cond else 0
	_fail += 1 if not cond else 0
	_log("[QA] %s  %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		_failures.append(label)

func _approx(label: String, actual: float, expected: float, tol: float = 0.0001) -> void:
	var pass_approx: bool = absf(actual - expected) <= tol
	_ok("%s  [got %.5f, want %.5f]" % [label, actual, expected], pass_approx)

# ── Test suites ───────────────────────────────────────────────────

func _run_data_integrity() -> void:
	_log("[QA] ── data integrity ───────────────────────────────")

	# Venue IDs are unique
	var venue_ids: Array = []
	for v in _venue_data.VENUES:
		_ok("venue id '%s' unique" % v.id, v.id not in venue_ids)
		venue_ids.append(v.id)
	_ok("venue count == 8", _venue_data.VENUES.size() == 8)

	# Upgrade IDs unique, unlock_at < cost
	var upg_ids: Array = []
	for u in _upgrade_data.UPGRADES:
		_ok("upgrade id '%s' unique" % u.id, u.id not in upg_ids)
		upg_ids.append(u.id)
		_ok("upgrade '%s' unlock_at <= cost" % u.id, u.unlock_at <= u.cost)
	_ok("upgrade count == 21", _upgrade_data.UPGRADES.size() == 21)

	# VIP IDs unique, appears_at > 0
	var vip_ids: Array = []
	for v in _vip_data.VIPS:
		_ok("vip id '%s' unique" % v.id, v.id not in vip_ids)
		vip_ids.append(v.id)
		_ok("vip '%s' appears_at > 0" % v.id, v.appears_at > 0.0)
	_ok("vip count == 8", _vip_data.VIPS.size() == 8)

	# Staff IDs unique, cps > 0
	var staff_ids: Array = []
	for s in _staff_data.STAFF:
		_ok("staff id '%s' unique" % s.id, s.id not in staff_ids)
		staff_ids.append(s.id)
		_ok("staff '%s' clicks_per_second > 0" % s.id, s.clicks_per_second > 0.0)

	# Achievement IDs unique
	var ach_ids: Array = []
	for a in _achievement_data.ACHIEVEMENTS:
		_ok("achievement id '%s' unique" % a.id, a.id not in ach_ids)
		ach_ids.append(a.id)


func _run_economy() -> void:
	_log("[QA] ── economy ──────────────────────────────────────")
	_fresh()

	# Single bonfire: income = base_income
	var bonfire = _get_venue("bonfire")
	GameState.buy_venue("bonfire")
	GameState._rebuild_rates()
	_approx("1 bonfire income = 0.1/s", GameState.get_income_per_second(), 0.1, 0.001)

	# 10 bonfires: quantity multiplier kicks in (×2)
	for i in range(9):
		GameState.buy_venue("bonfire")
	GameState._rebuild_rates()
	_approx("10 bonfires income = 0.1*10*2 = 2.0/s",
		GameState.get_income_per_second(), 2.0, 0.01)

	# Add bonfire upgrade (×2): 10 bonfires × qty 2 × upg 2 = 4.0/s
	_fresh()
	for i in range(10):
		GameState.buy_venue("bonfire")
	GameState.upgrades_purchased["bonfire_upgrade"] = true
	GameState._rebuild_rates()
	_approx("10 bonfires + upgrade = 4.0/s",
		GameState.get_income_per_second(), 4.0, 0.01)

	# VIP guest (×1.5) on top
	_fresh()
	for i in range(10):
		GameState.buy_venue("bonfire")
	GameState.upgrades_purchased["bonfire_upgrade"] = true
	GameState.vips_recruited["guest"] = true
	GameState._rebuild_rates()
	_approx("10 bonfires + upgrade + guest VIP = 6.0/s",
		GameState.get_income_per_second(), 6.0, 0.01)

	# Ghost mode adds ×1.5 on top of everything
	_fresh()
	GameState.buy_venue("bonfire")
	GameState.ghost_mode = true
	GameState._rebuild_rates()
	_approx("1 bonfire ghost mode = 0.15/s",
		GameState.get_income_per_second(), 0.15, 0.001)
	GameState.ghost_mode = false

	# Blackout venue has negative heat_rate in data (heat_per_second is clamped to >=0)
	var blackout_venue = _get_venue("blackout")
	_ok("blackout venue heat_rate is negative in data",
		blackout_venue.heat_rate < 0.0)


func _run_heat_system() -> void:
	_log("[QA] ── heat system ──────────────────────────────────")
	_fresh()

	# All 8 venues once: heat rises
	for v in _venue_data.VENUES:
		GameState.venue_counts[v.id] = 1
	GameState._rebuild_rates()
	var base_heat: float = GameState.get_heat_per_second()
	_ok("venues generate positive net heat (8 venues)", base_heat > 0.0)

	# Legal Retainer reduces it by 0.015
	GameState.upgrades_purchased["legal_retainer"] = true
	GameState._rebuild_rates()
	_approx("legal_retainer reduces heat by 0.015",
		GameState.get_heat_per_second(), base_heat - 0.015, 0.0001)

	# Hush Money adds another -0.030
	GameState.upgrades_purchased["hush_money"] = true
	GameState._rebuild_rates()
	_approx("hush_money reduces heat by further 0.030",
		GameState.get_heat_per_second(), base_heat - 0.045, 0.0001)

	# President VIP adds another -0.02
	GameState.vips_recruited["president"] = true
	GameState._rebuild_rates()
	_approx("president VIP reduces heat by further 0.02",
		GameState.get_heat_per_second(), base_heat - 0.065, 0.0001)

	# heat_per_second never goes negative (clamped to 0)
	_fresh()
	GameState.upgrades_purchased["legal_retainer"] = true
	GameState.upgrades_purchased["hush_money"] = true
	GameState.vips_recruited["president"] = true
	GameState._rebuild_rates()
	_ok("heat_per_second >= 0 with all suppressors and no venues",
		GameState.get_heat_per_second() >= 0.0)


func _run_click_value() -> void:
	_log("[QA] ── click value ──────────────────────────────────")
	_fresh()

	# No venues: click = max(1.0, 0 * 0.1) = 1.0
	_approx("click value with no venues = 1.0", GameState.get_click_value(), 1.0, 0.001)

	# With champagne upgrade (×2): still 1.0 (can't go below 1 then multiply — actually: base=1.0 * 2 = 2.0)
	GameState.upgrades_purchased["champagne"] = true
	GameState._rebuild_rates()
	_approx("click value with champagne ×2 = 2.0", GameState.get_click_value(), 2.0, 0.001)

	# With venue income: 1 bonfire = 0.1 IPS → click_base = max(1.0, 0.01) = 1.0 → still 2.0
	GameState.buy_venue("bonfire")
	GameState._rebuild_rates()
	_approx("click still 2.0 with bonfire (IPS too low)", GameState.get_click_value(), 2.0, 0.001)

	# With 100 bonfires: 0.1*100*2(qty10)*2(qty25)*2(qty50)*2(qty100) = 0.1*100*16 = 160 IPS
	# click_base = max(1.0, 160*0.1) = 16.0; ×2 champagne = 32.0
	_fresh()
	GameState.venue_counts["bonfire"] = 100
	GameState.upgrades_purchased["champagne"] = true
	GameState._rebuild_rates()
	var expected_ips: float = 0.1 * 100 * 16.0  # 160
	var expected_click: float = maxf(1.0, expected_ips * 0.1) * 2.0  # 32.0
	_approx("click scales with 100 bonfires + champagne",
		GameState.get_click_value(), expected_click, 0.1)


func _run_narrative_events() -> void:
	_log("[QA] ── narrative events ─────────────────────────────")

	var events: Array = _narrative_data.EVENTS
	_ok("narrative events count >= 8", events.size() >= 8)

	# IDs unique
	var ids: Array = []
	for e in events:
		_ok("event id '%s' unique" % e.id, e.id not in ids)
		ids.append(e.id)

	# trigger_at in strictly ascending order
	var last_threshold: float = -1.0
	for e in events:
		_ok("event '%s' trigger_at ascending (%.0f > %.0f)" % [e.id, e.trigger_at, last_threshold],
			e.trigger_at > last_threshold)
		last_threshold = e.trigger_at

	# All events have title and body
	for e in events:
		_ok("event '%s' has non-empty title" % e.id, e.title.length() > 0)
		_ok("event '%s' has non-empty body" % e.id, e.body.length() > 0)


func _run_save_load() -> void:
	_log("[QA] ── save / load roundtrip ────────────────────────")
	_fresh()

	# Set known state
	GameState.money               = 12345.67
	GameState.lifetime_money      = 99999.99
	GameState.political_influence = 42
	GameState.heat                = 2.5
	GameState.venue_counts        = {"bonfire": 3, "yacht": 1}
	GameState.upgrades_purchased  = {"champagne": true}
	GameState.secrets_found       = 7
	GameState.time_played         = 600.0
	GameState.endings_reached     = ["arrested"]

	GameState.save_game()

	# Wipe state
	GameState.money               = 0.0
	GameState.lifetime_money      = 0.0
	GameState.political_influence = 0
	GameState.heat                = 0.0
	GameState.venue_counts        = {}
	GameState.upgrades_purchased  = {}
	GameState.secrets_found       = 0
	GameState.time_played         = 0.0
	GameState.endings_reached     = []

	# Reload
	GameState.load_game()

	_approx("save/load: money",               GameState.money,               12345.67, 0.01)
	_approx("save/load: lifetime_money",       GameState.lifetime_money,      99999.99, 0.01)
	_ok("save/load: political_influence",      GameState.political_influence  == 42)
	_approx("save/load: heat",                 GameState.heat,                2.5,      0.001)
	_ok("save/load: venue bonfire count",      GameState.venue_counts.get("bonfire", 0) == 3)
	_ok("save/load: venue yacht count",        GameState.venue_counts.get("yacht", 0)   == 1)
	_ok("save/load: upgrade champagne",        GameState.upgrades_purchased.get("champagne", false) == true)
	_ok("save/load: secrets_found",            GameState.secrets_found  == 7)
	_approx("save/load: time_played",          GameState.time_played,         600.0,    0.001)
	_ok("save/load: endings_reached",          "arrested" in GameState.endings_reached)


func _run_identity_system() -> void:
	_log("[QA] ── identity system ──────────────────────────────")

	var identity_data = load("res://scripts/data/IdentityData.gd").new()
	_ok("identity count == 4", identity_data.IDENTITIES.size() == 4)

	var ids: Array = []
	for identity in identity_data.IDENTITIES:
		_ok("identity id '%s' unique" % identity.id, identity.id not in ids)
		ids.append(identity.id)
		_ok("identity '%s' has name" % identity.id, identity.name.length() > 0)
		_ok("identity '%s' has bonus_type" % identity.id, identity.bonus_type.length() > 0)

	# Philanthropist: +15 PI
	_fresh()
	var pi_before: int = GameState.political_influence
	GameState.set_player_identity("philanthropist")
	_ok("philanthropist grants +15 PI", GameState.political_influence == pi_before + 15)
	_ok("philanthropist identity stored", GameState.player_identity == "philanthropist")

	# Financier: +$500
	_fresh()
	var money_before: float = GameState.money
	GameState.set_player_identity("financier")
	_approx("financier grants +$500", GameState.money, money_before + 500.0, 0.01)

	# Tech Mogul: click ×2
	_fresh()
	GameState.set_player_identity("tech_mogul")
	GameState._rebuild_rates()
	var base_click: float = maxf(1.0, GameState.get_income_per_second() * 0.1)
	_approx("tech_mogul click_mult == 2.0", GameState.get_click_value(), base_click * 2.0, 0.001)

	# Diplomat: VIP costs 25% cheaper
	_fresh()
	GameState.set_player_identity("diplomat")
	var vip_data_node = load("res://scripts/data/VIPData.gd").new()
	var first_vip: Dictionary = vip_data_node.VIPS[0]
	var discounted: float = GameState.vip_cost(first_vip.id)
	_approx("diplomat vip_cost = 75%% of base", discounted, first_vip.cost * 0.75, 0.01)

	# Reset clears identity
	GameState.reset_game()
	_ok("reset_game clears player_identity", GameState.player_identity == "")
	_approx("reset_game clears identity click mult", GameState.get_click_value(), 1.0, 0.001)

	identity_data.free()
	vip_data_node.free()

# ── Summary ───────────────────────────────────────────────────────
func _print_summary() -> void:
	var total: int = _pass + _fail
	_log("[QA] ─────────────────────────────────────────────────")
	_log("[QA] %d / %d passed" % [_pass, total])
	if _fail > 0:
		_log("[QA] FAILURES:")
		for f in _failures:
			_log("[QA]   ✗ %s" % f)
	else:
		_log("[QA] All tests passed ✓")
	# Write to file so it can be read after process exits
	var file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(_log_lines))
		file.close()

# ── Helpers ───────────────────────────────────────────────────────
func _get_venue(id: String) -> Dictionary:
	for v in _venue_data.VENUES:
		if v.id == id:
			return v
	return {}
