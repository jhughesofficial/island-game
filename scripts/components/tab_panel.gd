extends TabContainer

func _ready() -> void:
	set_tab_title(0, "Venues")
	set_tab_title(1, "Staff")
	set_tab_title(2, "Upgrades")
	set_tab_title(3, "VIPs")
	tab_changed.connect(_on_tab_changed)

func _on_tab_changed(tab_index: int) -> void:
	var child := get_child(tab_index)
	if child == null:
		return
	child.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(child, "modulate:a", 1.0, 0.2)
