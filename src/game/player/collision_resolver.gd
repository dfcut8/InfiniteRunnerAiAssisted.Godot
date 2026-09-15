extends Node
## Explicit swept tests preserve fixed-tick dash/front-face behavior.
@export var landing_inset: float = 1.0
@export var fall_distance: float = 96.0

func resolve(player: RunnerPlayer, course: RunnerCourse, old_x: float, old_y: float, dashing: bool) -> void:
	player.grounded = false
	var body := player.bounds()
	var front_offset := body.end.x - player.x
	for platform in course.platforms:
		var left := platform.bounds().position.x
		var right := platform.bounds().end.x
		var top := platform.bounds().position.y
		# Swept front face: dashing is never invulnerability to masonry.
		if old_x + front_offset <= left and body.end.x > left and player.y > top + 0.01 and body.position.y < platform.bounds().end.y:
			player.x = left - front_offset
			player.die()
			return
		if body.end.x - landing_inset > left and body.position.x + landing_inset < right and old_y <= top + 0.01 and player.y >= top and (player.vy >= 0.0 or dashing):
			player.y = top
			player.vy = 0.0
			if dashing:
				player.saved_vy = 0.0
			player.grounded = true
			player.jumps = 2
	if player.y > course.settings.ground + fall_distance:
		player.die()
		return
	body = player.bounds()
	for i in range(course.stones.size() - 1, -1, -1):
		var stone: CourseEntity = course.stones[i]
		if body.intersects(stone.bounds()):
			if dashing:
				player.burst(Vector2(stone.x, stone.y - 15.0), 16, false)
				course.retire(course.stones, i)
				player.stone_broken.emit()
			else:
				player.die()
				return
	for i in range(course.relics.size() - 1, -1, -1):
		var relic: CourseEntity = course.relics[i]
		if body.intersects(relic.bounds()):
			player.burst(Vector2(relic.x, relic.y), 7, false)
			course.retire(course.relics, i)
			player.relic_collected.emit()
