class_name RunnerCourse
extends Node2D
## Streams reusable entity scenes, deterministically for a seed.
@export var settings: RunnerCourseSettings
@export var platform_scene: PackedScene
@export var relic_scene: PackedScene
@export var stone_scene: PackedScene
var rng := RandomNumberGenerator.new()
var platforms: Array[CourseEntity] = []
var relics: Array[CourseEntity] = []
var stones: Array[CourseEntity] = []
var last_stone := -1000.0

func reset(seed_value: int = -1) -> void:
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	clear_entities(platforms)
	clear_entities(relics)
	clear_entities(stones)
	last_stone = -1000.0
	add_platform(settings.opening_left, settings.opening_right, settings.ground)
	for i in range(settings.relic_arch.size()):
		add_relic(settings.opening_relic_start + i * settings.opening_relic_spacing, settings.ground - settings.relic_height)
	# Preserve all 24 units of safe runway; hazards begin on later platforms.
	ensure_ahead(0.0)

func arrival_time(x: float) -> float:
	# Use the same movement resource as the player when projecting difficulty.
	var movement := settings.movement
	var ramp := maxf(movement.ramp_seconds, 0.00001)
	var acceleration := (movement.maximum_speed - movement.initial_speed) / ramp
	var ramp_distance := (movement.initial_speed + movement.maximum_speed) * ramp * 0.5
	if x <= ramp_distance:
		if is_zero_approx(acceleration):
			return x / movement.initial_speed
		return (-movement.initial_speed + sqrt(movement.initial_speed ** 2 + 2.0 * acceleration * x)) / acceleration
	return ramp + (x - ramp_distance) / movement.maximum_speed

func ensure_ahead(x: float) -> void:
	while platforms.back().end < x + settings.look_ahead:
		var previous: CourseEntity = platforms.back()
		var t := arrival_time(float(previous.end))
		var difficulty := clampf((t - settings.easy_seconds) / maxf(settings.movement.ramp_seconds - settings.easy_seconds, 0.00001), 0.0, 1.0)
		var gap := settings.easy_gap if t < settings.easy_seconds else rng.randf_range(settings.minimum_gap, lerpf(settings.early_maximum_gap, settings.late_maximum_gap, difficulty))
		var y := float(previous.y)
		if t >= settings.height_change_seconds:
			y = clampf(y + float(rng.randi_range(-1, 1)) * settings.height_step, settings.ground - settings.height_range, settings.ground + settings.height_range)
		var start := float(previous.end) + gap
		var length := float(settings.platform_lengths[rng.randi_range(0, settings.platform_lengths.size() - 1)])
		add_platform(start, start + length, y)
		var arch := rng.randf() < settings.arch_probability
		for i in range(settings.relic_arch.size()):
			var height := settings.relic_height
			if arch:
				height = settings.relic_arch[i]
			add_relic(start + settings.relic_start_offset + i * settings.relic_spacing, y - height)
		var stone_x := start + settings.stone_offset
		if stone_x - last_stone >= settings.stone_spacing and rng.randf() < settings.stone_probability:
			add_stone(stone_x, y)
			last_stone = stone_x

	while platforms.size() > 1 and platforms[0].end < x - settings.retire_distance:
		retire(platforms, 0)
	for entities in [relics, stones]:
		for i in range(entities.size() - 1, -1, -1):
			if entities[i].x < x - settings.retire_distance:
				retire(entities, i)

func add_platform(left: float, right: float, top: float) -> CourseEntity:
	var entity := _spawn(platform_scene, $Platforms, Vector2(left, top))
	entity.set_width(right - left)
	platforms.append(entity)
	return entity

func add_relic(x: float, y: float) -> CourseEntity:
	var entity := _spawn(relic_scene, $Relics, Vector2(x, y))
	relics.append(entity)
	return entity

func add_stone(x: float, y: float) -> CourseEntity:
	var entity := _spawn(stone_scene, $Runestones, Vector2(x, y))
	stones.append(entity)
	return entity

func _spawn(scene: PackedScene, container: Node, at: Vector2) -> CourseEntity:
	var entity := scene.instantiate() as CourseEntity
	entity.position = at
	container.add_child(entity)
	return entity

func retire(entities: Array[CourseEntity], index: int) -> void:
	var entity := entities[index]
	entities.remove_at(index)
	entity.get_parent().remove_child(entity)
	entity.queue_free()

func clear_entities(entities: Array[CourseEntity]) -> void:
	while not entities.is_empty():
		retire(entities, entities.size() - 1)
