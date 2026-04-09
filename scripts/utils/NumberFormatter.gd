extends Node

# Suffixes cover up to Decillion (10^33). Ghost Mode multipliers can push values
# into the quadrillions, so anything below Dc should be reachable in late game.
const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

func format(value: float) -> String:
	if value < 0.0:
		return "-" + format(-value)
	if value < 1000.0:
		# Integer: no decimal places
		if value == floorf(value):
			return "$%d" % int(value)
		# Sub-$10: two decimal places ($1.50)
		if value < 10.0:
			return "$%.2f" % value
		# $10–$999 non-integer: one decimal place ($12.5)
		return "$%.1f" % value
	var tier: int = 0
	var v: float = value
	while v >= 1000.0 and tier < SUFFIXES.size() - 1:
		v /= 1000.0
		tier += 1
	# Choose decimal places to keep 3–4 significant figures
	if v >= 100.0:
		return "$%.0f%s" % [v, SUFFIXES[tier]]
	elif v >= 10.0:
		return "$%.1f%s" % [v, SUFFIXES[tier]]
	else:
		return "$%.2f%s" % [v, SUFFIXES[tier]]

func format_rate(per_second: float) -> String:
	return "%s/s" % format(per_second).replace("$", "")

# Returns a comma-separated integer string with "PI" suffix.
# Handles values from 0 up through billions (PI grows slowly but Ghost Mode
# can accelerate it).
func format_pi(pi: int) -> String:
	if pi < 1000:
		return "%d PI" % pi
	if pi < 1_000_000:
		return "%s PI" % _comma_int(pi)
	# For very large PI values fall back to the same tier system as money,
	# but without a dollar sign.
	var v: float = float(pi)
	var tier: int = 0
	while v >= 1000.0 and tier < SUFFIXES.size() - 1:
		v /= 1000.0
		tier += 1
	if v >= 100.0:
		return "%.0f%s PI" % [v, SUFFIXES[tier]]
	elif v >= 10.0:
		return "%.1f%s PI" % [v, SUFFIXES[tier]]
	else:
		return "%.2f%s PI" % [v, SUFFIXES[tier]]

# Formats an integer with comma thousands separators, e.g. 1234567 → "1,234,567".
func _comma_int(n: int) -> String:
	var s: String = str(abs(n))
	var result: String = ""
	var count: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	if n < 0:
		result = "-" + result
	return result
