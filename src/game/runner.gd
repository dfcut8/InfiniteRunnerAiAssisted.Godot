extends Node2D
const Course = preload("res://game/course.gd")
const Art = preload("res://game/pixel_art.gd")
var course := Course.new()
var art := Art.new()
var x := 0.0
var y := 132.0
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
var relic_count := 0
var broken := 0
var score := 0
var effects: Array[Dictionary] = []
var ghosts: Array[Dictionary] = []
var ghost_timer := 0.0
var jump_held := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reset()

func reset(seed_value: int = -1) -> void:
	course.reset(seed_value)
	x = 0.0
	y = Course.GROUND
	vy = 0.0
	elapsed = 0.0
	speed = 80.0
	grounded = true
	jumps = 2
	grace = 0.1
	buffer = 0.0
	dash_left = 0.0
	cooldown = 0.0
	saved_vy = 0.0
	dead = false
	death_time = 0.0
	relic_count = 0
	broken = 0
	score = 0
	effects.clear()
	ghosts.clear()
	ghost_timer = 0.0
	jump_held = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:
		return
	var key := event as InputEventKey
	if key.keycode == KEY_R and key.pressed and dead:
		reset()
	elif key.keycode in [KEY_SPACE, KEY_Z]:
		if key.pressed:
			jump_held = true
			buffer = 0.12
		else:
			jump_held = false
			cut_jump()
	elif key.keycode in [KEY_SHIFT, KEY_X] and key.pressed:
		start_dash()

func cut_jump() -> void:
	if dash_left > 0.0:
		if saved_vy < 0.0:
			saved_vy *= 0.45
	elif vy < 0.0:
		vy *= 0.45

func start_dash() -> void:
	if dead or dash_left > 0.0 or cooldown > 0.00001:
		return
	dash_left = 0.20
	saved_vy = vy
	ghost_timer = 0.0

func _physics_process(delta: float) -> void:
	step(delta)
	queue_redraw()

func step(dt: float) -> void:
	for effect in effects:
		effect.life -= dt
		effect.p += effect.v * dt
		effect.v.y += 100.0 * dt
	effects = effects.filter(func(e: Dictionary) -> bool: return e.life > 0.0)
	for ghost in ghosts:
		ghost.life -= dt
	ghosts = ghosts.filter(func(g: Dictionary) -> bool: return g.life > 0.0)
	if dead:
		death_time += dt
		return
	elapsed += dt
	speed = lerpf(80.0, 144.0, minf(elapsed / 120.0, 1.0))
	if grounded:
		grace = 0.10
	else:
		grace = maxf(0.0, grace - dt)
		if grace <= 0.0 and jumps == 2:
			jumps = 1
	if buffer > 0.0 and jumps > 0 and dash_left <= 0.0:
		vy = -144.0
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
		x += speed * 2.0 * dt
		dash_left = maxf(0.0, dash_left - dt)
		ghost_timer -= dt
		if ghost_timer <= 0.0:
			ghosts.append({"x": x, "y": y, "life": 0.13})
			ghost_timer += 0.045
	else:
		cooldown = maxf(0.0, cooldown - dt)
		x += speed * dt
		vy += 448.0 * dt
		y += vy * dt
	grounded = false
	for platform in course.platforms:
		var left := float(platform.x)
		var right := float(platform.end)
		var top := float(platform.y)
		# Swept front face: dashing is never invulnerability to masonry.
		if old_x + 9.0 <= left and x + 9.0 > left and y > top + 0.01 and y - 20.0 < 220.0:
			x = left - 9.0
			die()
			return
		if x + 8.0 > left and x - 8.0 < right and old_y <= top + 0.01 and y >= top and (vy >= 0.0 or dashing):
			y = top
			vy = 0.0
			if dashing:
				saved_vy = 0.0
			grounded = true
			jumps = 2
	if y > Course.GROUND + 96.0:
		die()
		return
	var body := Rect2(x - 9.0, y - 20.0, 18.0, 20.0)
	for i in range(course.stones.size() - 1, -1, -1):
		var stone: Dictionary = course.stones[i]
		if body.intersects(Rect2(stone.x - 5.0, stone.y - 27.0, 10.0, 27.0)):
			if dashing:
				burst(Vector2(stone.x, stone.y - 15.0), 16, false)
				course.stones.remove_at(i)
				broken += 1
			else:
				die()
				return
	for i in range(course.relics.size() - 1, -1, -1):
		var relic: Dictionary = course.relics[i]
		if body.intersects(Rect2(relic.x - 3.0, relic.y - 3.0, 6.0, 6.0)):
			burst(Vector2(relic.x, relic.y), 7, false)
			course.relics.remove_at(i)
			relic_count += 1
	if dashing and dash_left <= 0.00001:
		dash_left = 0.0
		cooldown = 0.70
		vy = saved_vy
	score = int(floor(x / 16.0 * 10.0)) + relic_count * 25 + broken * 100
	course.ensure_ahead(x)

func die() -> void:
	dead = true
	vy = 0.0
	score = int(floor(x / 16.0 * 10.0)) + relic_count * 25 + broken * 100
	burst(Vector2(x, y - 12.0), 28, true)

func burst(at: Vector2, count: int, ivory: bool) -> void:
	for i in range(count):
		var angle := float(i) * TAU / float(count)
		var velocity := Vector2(cos(angle), sin(angle)) * randf_range(16.0, 48.0)
		effects.append({"p": at, "v": velocity, "life": 0.75 if ivory else 0.35, "ivory": ivory})

func _draw() -> void:
	art.paint(self)
