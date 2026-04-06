extends PanelContainer

@onready var message_label: Label = $MarginContainer/MessageLabel

func _ready() -> void:
	modulate.a = 0.0

func show_message(text: String, duration: float = 3.5) -> void:
	message_label.text = text
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
