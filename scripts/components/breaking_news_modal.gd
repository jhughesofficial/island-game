extends Control

const ACT3_THRESHOLD: float = 50_000_000.0

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Overlay/CenterContainer/Panel
@onready var continue_button: Button = $Overlay/CenterContainer/Panel/VBox/ContinueButton

func _ready() -> void:
	hide()

func show_modal() -> void:
	show()
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = panel.size / 2.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_continue_pressed() -> void:
	hide()
