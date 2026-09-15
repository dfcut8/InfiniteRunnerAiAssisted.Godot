class_name RunnerEffect
extends Sprite2D
@export var lifetime: float = 0.35
@export var gravity: float = 100.0
var velocity: Vector2 = Vector2.ZERO
var age: float = 0.0

func step(delta: float) -> void:
	age += delta
	position += velocity * delta
	velocity.y += gravity * delta
	if age >= lifetime:
		get_parent().remove_child(self)
		queue_free()
