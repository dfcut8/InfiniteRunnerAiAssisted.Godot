extends SceneTree
const Runner = preload("res://game/runner.tscn")
const Course = preload("res://game/world/course.tscn")
const DT := 1.0 / 120.0
var failures := 0
var checks := 0
var game: RunnerPlayer
var session: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func ticks(count: int) -> void:
	for i in range(count):
		session.step(DT)

func jump() -> void:
	game.jump_held = true
	game.buffer = 0.12
	session.step(DT)

func runway() -> void:
	session.reset(42)
	replace_entities(session.course, "platforms", [{"x": -100.0, "end": 10000.0, "y": 132.0}])
	session.course.clear_entities(session.course.stones)
	session.course.clear_entities(session.course.relics)

func run() -> void:
	session = Runner.instantiate()
	root.add_child(session)
	session.set_physics_process(false)
	game = session.player
	verify_composition()
	runway()
	jump()
	var held_peak: float = game.y
	for i in range(45):
		session.step(DT)
		held_peak = minf(held_peak, game.y)
	runway()
	jump()
	game.cut_jump()
	var tap_peak: float = game.y
	for i in range(45):
		session.step(DT)
		tap_peak = minf(tap_peak, game.y)
	check(tap_peak - held_peak > 14.0, "Held jumps must be substantially higher than taps")
	runway()
	jump()
	ticks(8)
	jump()
	check(game.jumps == 0 and game.vy < -130.0, "Second press resets ascent and consumes recovery")
	ticks(2)
	var before: float = game.vy
	jump()
	check(game.vy > before and game.jumps == 0, "Third airborne press cannot jump")
	ticks(100)
	check(game.grounded and game.jumps == 2, "Landing restores both jumps")
	runway()
	session.course.platforms[0].end = 0.0
	session.course.add_platform(1000.0, 10000.0, 132.0)
	game.x = 10.0
	ticks(5)
	jump()
	check(game.jumps == 1 and game.vy < 0.0, "Coyote jump preserves recovery")
	runway()
	session.course.platforms[0].end = 0.0
	session.course.add_platform(1000.0, 10000.0, 132.0)
	game.x = 10.0
	ticks(15)
	check(game.jumps == 1, "Walking off consumes ground jump after grace")
	jump()
	check(game.jumps == 0, "Walk-off permits only one recovery")
	runway()
	game.y = 125.0
	game.vy = 50.0
	game.grounded = false
	game.jumps = 0
	game.buffer = 0.12
	game.jump_held = true
	ticks(13)
	check(game.vy < 0.0 and game.jumps == 1, "Buffered input jumps on landing")
	runway()
	jump()
	var suspended_y: float = game.y
	var suspended_vy: float = game.vy
	game.start_dash()
	ticks(24)
	check(is_equal_approx(game.y, suspended_y), "Dash suspends vertical travel for 0.20 seconds")
	check(game.dash_left == 0.0 and is_equal_approx(game.cooldown, 0.7), "Cooldown starts after dash ends")
	check(is_equal_approx(game.vy, suspended_vy) and game.jumps == 1, "Dash resumes velocity without granting jumps")
	game.start_dash()
	check(game.dash_left == 0.0, "Dash cannot restart during cooldown")
	ticks(83)
	check(game.cooldown > 0.0, "Landing does not bypass dash cooldown")
	ticks(1)
	game.start_dash()
	check(game.dash_left > 0.0, "Dash recharges after exactly 0.70 seconds")
	runway()
	replace_entities(session.course, "stones", [{"x": 12.0, "y": 132.0}])
	ticks(1)
	check(game.dead, "Undashed runestone contact is fatal")
	var frozen_score: int = session.score
	var frozen_x: float = game.x
	ticks(100)
	check(session.score == frozen_score and game.x == frozen_x, "Death freezes movement and scoring")
	runway()
	replace_entities(session.course, "stones", [{"x": 12.0, "y": 132.0}])
	game.start_dash()
	ticks(1)
	check(not game.dead and session.broken == 1, "Active dash breaks runestones")
	ticks(20)
	check(session.broken == 1 and session.course.stones.is_empty(), "Runestones award only once")
	runway()
	replace_entities(session.course, "relics", [{"x": 2.0, "y": 118.0}])
	ticks(2)
	check(session.relic_count == 1 and session.score == int(floor(game.x / 16.0 * 10.0)) + 25, "Relic scores 25 once plus distance")
	for dash in [false, true]:
		runway()
		replace_entities(session.course, "platforms", [{"x": 12.0, "end": 900.0, "y": 124.0}])
		if dash:
			game.start_dash()
		ticks(8)
		check(game.dead, "Platform front is fatal, including during dash")
	runway()
	game.y = 229.0
	ticks(1)
	check(game.dead, "Falling six units ends the run")
	session.reset(43)
	check(game.x == 0.0 and session.score == 0 and session.relic_count == 0 and session.broken == 0 and game.speed == 80.0 and game.jumps == 2 and game.dash_left == 0.0 and game.cooldown == 0.0 and not game.dead and session.effects.get_child_count() == 0, "Retry resets all state")
	var arrangement: String = platform_layout(session.course)
	session.reset(44)
	check(platform_layout(session.course) != arrangement, "Different seeds produce fresh courses")
	await verify_course()
	await verify_long_runs()
	# Same fixed physics simulation with 30/60/144 Hz presentation schedules.
	var distances: Array[float] = []
	for fps in [30, 60, 144]:
		runway()
		var accumulator := 0.0
		for frame in range(fps * 3):
			accumulator += 1.0 / float(fps)
			while accumulator + 0.0000001 >= DT:
				session.step(DT)
				accumulator -= DT
		distances.append(game.x)
	check(is_equal_approx(distances[0], distances[1]) and is_equal_approx(distances[1], distances[2]), "Display frame rates do not change movement")
	print("VERIFIED: %d checks, %d failures" % [checks, failures])
	session.free()
	quit(1 if failures else 0)

func verify_course() -> void:
	var course := Course.instantiate() as RunnerCourse
	root.add_child(course)
	var transitions := 0
	var last_end := -1.0
	var fair := true
	var bounded := true
	var spacing := true
	for seed_value in range(20):
		course.reset(seed_value)
		last_end = -1.0
		# Over an hour of travel per seed, including the full speed ramp.
		for position in range(0, 600000, 240):
			if position % 24000 == 0:
				await process_frame
			course.ensure_ahead(float(position))
			bounded = bounded and course.platforms.size() < 8 and course.relics.size() < 40 and course.stones.size() < 8
			for i in range(1, course.platforms.size()):
				var a: CourseEntity = course.platforms[i - 1]
				var b: CourseEntity = course.platforms[i]
				if float(b.end) <= last_end:
					continue
				last_end = b.end
				var speed := lerpf(80.0, 144.0, minf(course.arrival_time(a.end) / 120.0, 1.0))
				var height := float(a.y) - float(b.y)
				# Conservative descending crossing; reserve 8 px on either side.
				var flight := (144.0 + sqrt(144.0 * 144.0 - 896.0 * height)) / 448.0 - DT
				fair = fair and speed * flight > float(b.x) - float(a.end) + 16.0
				transitions += 1
			for i in range(1, course.stones.size()):
				spacing = spacing and float(course.stones[i].x) - float(course.stones[i - 1].x) >= 206.4
	check(fair, "Every generated transition is single-jump clearable with takeoff/landing margins")
	check(bounded, "Extended generation keeps entity counts bounded")
	check(spacing, "All runestones respect dash recovery spacing")
	print("COURSE: %d transitions checked across 20 seeds and 12 million pixels" % transitions)

	course.free()

func verify_long_runs() -> void:
	var completed := true
	for seed_value in range(5):
		session.reset(seed_value)
		for tick in range(120 * 240):
			if tick % 1000 == 0:
				await process_frame
			# Bot uses the same public control state as keyboard input, with no immunity.
			for stone in session.course.stones:
				if float(stone.x) > game.x and float(stone.x) - game.x < 25.0:
					game.start_dash()
			if game.grounded:
				for platform in session.course.platforms:
					if game.x >= float(platform.x) and game.x < float(platform.end) and float(platform.end) - game.x < 16.0:
						game.jump_held = true
						game.buffer = 0.12
			session.step(DT)
			if game.dead:
				print("BOT failed seed %d at %.2fs, x %.2f" % [seed_value, game.elapsed, game.x])
				completed = false
				break
		check(game.speed == 144.0, "Normal speed caps at nine units per second")
	check(completed, "Five four-minute runs survive using single jumps and dashes")


func replace_entities(course: RunnerCourse, kind: String, entries: Array) -> void:
	course.clear_entities(course.get(kind))
	for entry in entries:
		match kind:
			"platforms": course.add_platform(entry.x, entry.end, entry.y)
			"stones": course.add_stone(entry.x, entry.y)
			"relics": course.add_relic(entry.x, entry.y)

func platform_layout(course: RunnerCourse) -> String:
	var layout: Array[Vector3] = []
	for platform in course.platforms:
		layout.append(Vector3(platform.x, platform.end, platform.y))
	return str(layout)

func verify_composition() -> void:
	check(session.course.settings.movement == game.settings, "Player and course share one movement resource")
	session.reset(42)
	var arrangement := platform_layout(session.course)
	session.reset(42)
	check(platform_layout(session.course) == arrangement, "Scene generation is reproducible for the same seed")
	for kind in ["platforms", "relics", "stones"]:
		var entities: Array = session.course.get(kind)
		var parent: Node = entities[0].get_parent()
		check(parent.get_child_count() == entities.size(), "Reset retires old %s nodes" % kind)
	var first: CourseEntity = session.course.platforms[0]
	var second: CourseEntity = session.course.platforms[1]
	var second_width: float = second.bounds().size.x
	first.set_width(256.0)
	check(second.bounds().size.x == second_width, "Resizing terrain does not mutate another instance's shape")
	check(first.get_node("Sprite2D").texture.get_width() == 256, "Platform width selects its external texture")
	for key in [KEY_SPACE, KEY_Z]:
		runway()
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = true
		session.get_node("Input")._unhandled_input(event)
		session.step(DT)
		check(game.vy < 0.0 and game.jumps == 1, "Jump action reaches the composed player")
		var held_velocity := game.vy
		event.pressed = false
		session.get_node("Input")._unhandled_input(event)
		check(game.vy > held_velocity and not game.jump_held, "Jump release signal cuts ascent")
	for key in [KEY_SHIFT, KEY_X]:
		runway()
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = true
		session.get_node("Input")._unhandled_input(event)
		check(game.dash_left > 0.0, "Dash action reaches the composed player")
	game.die()
	session.refresh_view()
	check(session.hud.get_node("DeathPanel").visible and session.effects.get_child_count() > 0, "Death updates the HUD and spawns effect scenes")
	var retry := InputEventKey.new()
	retry.keycode = KEY_R
	retry.pressed = true
	session.get_node("Input")._unhandled_input(retry)
	check(not game.dead and not session.hud.get_node("DeathPanel").visible and session.effects.get_child_count() == 0, "Retry signal resets UI and removes transient nodes")
