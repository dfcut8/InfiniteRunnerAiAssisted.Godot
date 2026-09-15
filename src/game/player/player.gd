class_name RunnerPlayer
extends Area2D
signal burst_requested(at: Vector2, count: int, ivory: bool)
signal ghost_requested(at: Vector2)
signal relic_collected
signal stone_broken
signal died
@export var settings: RunnerMovementSettings
@onready var collision_resolver: Node = $CollisionResolver
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var visual: RunnerPlayerVisual = $Visual
var x: float:
	get: return position.x
	set(value): position.x = value
var y: float:
	get: return position.y
	set(value): position.y = value
var vy := 0.0
var elapsed := 0.0
var speed := 80.0
var grounded := true
var jumps := 2
var grace := 0.1
var buffer := 0.0
var dash_left := 0.0
var cooldown := 0.0
var saved_vy := 0.0
var dead := false
var death_time := 0.0
var ghost_timer := 0.0
var jump_held := false

func reset(ground: float = 132.0) -> void:
	x = 0.0
	y = ground
	vy = 0.0
	elapsed = 0.0
	speed = settings.initial_speed
	grounded = true
	jumps = 2
	grace = settings.coyote_seconds
	buffer = 0.0
	dash_left = 0.0
	cooldown = 0.0
	saved_vy = 0.0
	dead = false
	death_time = 0.0
	ghost_timer = 0.0
	jump_held = false

func cut_jump() -> void:
	if dash_left > 0.0:
		if saved_vy < 0.0:
			saved_vy *= settings.jump_cut
	elif vy < 0.0:
		vy *= settings.jump_cut

func start_dash() -> void:
	if dead or dash_left > 0.0 or cooldown > 0.00001:
		return
	dash_left = settings.dash_seconds
	saved_vy = vy
	ghost_timer = 0.0

func step(dt: float, course: RunnerCourse) -> void:
	if dead:
		death_time += dt
		return
	elapsed += dt
	speed = lerpf(settings.initial_speed, settings.maximum_speed, minf(elapsed / maxf(settings.ramp_seconds, 0.00001), 1.0))
	if grounded:
		grace = settings.coyote_seconds
	else:
		grace = maxf(0.0, grace - dt)
		if grace <= 0.0 and jumps == 2:
			jumps = 1
	if buffer > 0.0 and jumps > 0 and dash_left <= 0.0:
		vy = settings.jump_velocity
		jumps -= 1
		grounded = false
		grace = 0.0
		buffer = 0.0
		if not jump_held:
			cut_jump()
	buffer = maxf(0.0, buffer - dt)
	var old_x := x
	var old_y := y
	var dashing := dash_left > 0.00001
	if dashing:
		x += speed * settings.dash_multiplier * dt
		dash_left = maxf(0.0, dash_left - dt)
		ghost_timer -= dt
		if ghost_timer <= 0.0:
			ghost_requested.emit(position)
			ghost_timer += 0.045
	else:
		cooldown = maxf(0.0, cooldown - dt)
		x += speed * dt
		vy += settings.gravity * dt
		y += vy * dt
	collision_resolver.resolve(self, course, old_x, old_y, dashing)
	if dead:
		return
	if dashing and dash_left <= 0.00001:
		dash_left = 0.0
		cooldown = settings.cooldown_seconds
		vy = saved_vy

func die() -> void:
	if dead:
		return
	dead = true
	vy = 0.0
	burst(Vector2(x, y - 12.0), 28, true)
	died.emit()

func burst(at: Vector2, count: int, ivory: bool) -> void:
	burst_requested.emit(at, count, ivory)

func request_jump() -> void:
	jump_held = true
	buffer = settings.buffer_seconds

func release_jump() -> void:
	jump_held = false
	cut_jump()

func bounds() -> Rect2:
	var shape := hitbox.shape as RectangleShape2D
	return Rect2(position + hitbox.position - shape.size * 0.5, shape.size)
