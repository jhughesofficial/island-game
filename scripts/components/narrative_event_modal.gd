extends Control

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Overlay/CenterContainer/Panel
@onready var title_label: Label = $Overlay/CenterContainer/Panel/VBox/TitleLabel
@onready var body_label: Label = $Overlay/CenterContainer/Panel/VBox/BodyLabel
@onready var noted_button: Button = $Overlay/CenterContainer/Panel/VBox/NotedButton

func _ready() -> void:
	hide()

func show_event(event: Dictionary) -> void:
	AudioManager.play_sfx("narrative")
	title_label.text = event.get("title", "")
	body_label.text = event.get("body", "")
	show()
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_noted_pressed() -> void:
	hide()
