extends Node

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

func format(value: float) -> String:
	if value < 0.0:
		return "-" + format(-value)
	if value < 1000.0:
		if value == floorf(value):
			return "$%d" % int(value)
		return "$%.1f" % value
	var tier: int = 0
	var v: float = value
	while v >= 1000.0 and tier < SUFFIXES.size() - 1:
		v /= 1000.0
		tier += 1
	if v >= 100.0:
		return "$%.0f%s" % [v, SUFFIXES[tier]]
	elif v >= 10.0:
		return "$%.1f%s" % [v, SUFFIXES[tier]]
	else:
		return "$%.2f%s" % [v, SUFFIXES[tier]]

func format_rate(per_second: float) -> String:
	return "%s/sec" % format(per_second).replace("$", "")

func format_pi(pi: int) -> String:
	if pi < 1000:
		return "%d PI" % pi
	return "%.1fK PI" % (pi / 1000.0)
