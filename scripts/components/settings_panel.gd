extends PanelContainer

@onready var close_btn: Button = $VBoxContainer/HBoxContainer/CloseBtn
@onready var reset_btn: Button = $VBoxContainer/ResetBtn
@onready var confirm_reset: ConfirmationDialog = $ConfirmReset

func _ready() -> void:
	close_btn.pressed.connect(func(): hide())
	reset_btn.pressed.connect(func(): confirm_reset.popup_centered())
	confirm_reset.confirmed.connect(func():
		GameState.reset_game()
		hide()
	)
