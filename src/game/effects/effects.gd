class_name RunnerEffects
extends Node2D
@export var gold_particle: PackedScene
@export var ivory_particle: PackedScene
@export var ghost_scene: PackedScene

func burst(at: Vector2, count: int, ivory: bool) -> void:
	var scene := ivory_particle if ivory else gold_particle
	for i in range(count):
		var particle := scene.instantiate() as RunnerEffect
		particle.position = at
		particle.velocity = Vector2.from_angle(float(i) * TAU / float(count)) * randf_range(16.0, 48.0)
		add_child(particle)

func ghost(at: Vector2) -> void:
	var instance := ghost_scene.instantiate() as RunnerEffect
	instance.position = at
	add_child(instance)

func step(delta: float) -> void:
	for effect in get_children():
		effect.step(delta)

func clear() -> void:
	for effect in get_children():
		remove_child(effect)
		effect.queue_free()
