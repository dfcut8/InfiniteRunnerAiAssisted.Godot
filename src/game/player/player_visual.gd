class_name RunnerPlayerVisual
extends AnimatedSprite2D

func update_pose(player: RunnerPlayer) -> void:
	visible = not player.dead or player.death_time < 0.65
	var pose := int(player.elapsed * 12.0 * player.speed / player.settings.initial_speed) % 8
	if not player.grounded:
		pose = 8 if player.vy < 0.0 else 9
	if player.dash_left > 0.0:
		pose = 10
	if player.dead:
		pose = 11
	frame = pose
