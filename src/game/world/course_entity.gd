class_name CourseEntity
extends Area2D
## World-space bounds come from the shape authored in each reusable scene.
@onready var hitbox: CollisionShape2D = $Hitbox
var x: float:
	get: return position.x
	set(value): position.x = value
var y: float:
	get: return position.y
	set(value): position.y = value
var end: float:
	get: return x + bounds().size.x
	set(value): set_width(value - x)

func bounds() -> Rect2:
	var shape := hitbox.shape as RectangleShape2D
	return Rect2(position + hitbox.position - shape.size * 0.5, shape.size)

func set_width(width: float) -> void:
	var shape := hitbox.shape as RectangleShape2D
	shape.size.x = width
	hitbox.position.x = width * 0.5
