extends Node2D
## Authored strips repeat outside the viewport; integer offsets keep pixels crisp.
@export var far_speed: float = 0.15
@export var near_speed: float = 0.4

func update_scroll(camera_x: float) -> void:
	$Far.position.x = -posmod(int(floor(camera_x * far_speed)), 336)
	$Near.position.x = -posmod(int(floor(camera_x * near_speed)), 432)
