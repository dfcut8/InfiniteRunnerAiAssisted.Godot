extends Node
signal jump_pressed
signal jump_released
signal dash_pressed
signal retry_pressed

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		jump_released.emit()
	elif event.is_action_pressed("dash"):
		dash_pressed.emit()
	elif event.is_action_pressed("retry"):
		retry_pressed.emit()
