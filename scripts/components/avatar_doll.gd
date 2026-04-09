extends Control
# Paper doll drawn purely with _draw(). No sprites needed.
# Parent character_creation.gd calls queue_redraw() when identity changes.

const SKIN   := Color(0.87, 0.78, 0.68, 1)
const SUIT   := Color(0.12, 0.12, 0.14, 1)
const PANTS  := Color(0.08, 0.08, 0.10, 1)
const SHOE   := Color(0.05, 0.05, 0.05, 1)
const SHIRT  := Color(0.82, 0.82, 0.82, 1)

# Accent color updated by parent before each redraw
var accent_color: Color = Color(0.788, 0.659, 0.298, 1)

func _draw() -> void:
	# Figure centered horizontally in the 100×170 canvas
	var cx := size.x / 2.0

	# Head
	draw_circle(Vector2(cx, 22), 16, SKIN)
	# Hair (thin cap)
	draw_arc(Vector2(cx, 22), 16, PI, 2.0 * PI, 16, SUIT, 4.0)

	# Neck
	draw_rect(Rect2(cx - 5, 38, 10, 10), SKIN)

	# Shoulders
	draw_rect(Rect2(cx - 26, 46, 52, 10), SUIT)

	# Left arm
	draw_rect(Rect2(cx - 28, 46, 10, 44), SUIT)
	# Right arm
	draw_rect(Rect2(cx + 18, 46, 10, 44), SUIT)

	# Body / jacket
	draw_rect(Rect2(cx - 18, 48, 36, 52), SUIT)

	# Shirt front (center strip)
	draw_rect(Rect2(cx - 5, 50, 10, 44), SHIRT)

	# Tie (identity accent color)
	draw_rect(Rect2(cx - 3, 52, 6, 30), accent_color)
	# Tie tip — slight point effect
	var tip_pts: PackedVector2Array = PackedVector2Array([
		Vector2(cx - 3, 82),
		Vector2(cx + 3, 82),
		Vector2(cx, 88)
	])
	draw_colored_polygon(tip_pts, accent_color)

	# Hands
	draw_circle(Vector2(cx - 23, 92), 6, SKIN)
	draw_circle(Vector2(cx + 23, 92), 6, SKIN)

	# Belt
	draw_rect(Rect2(cx - 18, 100, 36, 5), Color(0.15, 0.15, 0.15, 1))
	# Belt buckle
	draw_rect(Rect2(cx - 4, 99, 8, 7), Color(0.6, 0.5, 0.25, 1))

	# Left leg
	draw_rect(Rect2(cx - 18, 105, 14, 48), PANTS)
	# Right leg
	draw_rect(Rect2(cx + 4, 105, 14, 48), PANTS)

	# Left shoe
	draw_rect(Rect2(cx - 21, 151, 20, 8), SHOE)
	# Right shoe
	draw_rect(Rect2(cx + 1, 151, 20, 8), SHOE)
