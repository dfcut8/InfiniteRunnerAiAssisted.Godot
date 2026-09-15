extends SceneTree
## Render the actual game viewport for visual regression review.
const Runner = preload("res://game/runner.tscn")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var session := Runner.instantiate()
	var game: RunnerPlayer = session.get_node("World/Player")
	root.add_child(session)
	session.set_physics_process(false)
	session.reset(21)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../preview.png")
	game.x = 475.0
	game.elapsed = 6.0
	game.y = 111.0
	game.grounded = false
	game.vy = -70.0
	session.refresh_view()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../preview-jump.png")
	game.start_dash()
	session.step(1.0 / 120.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../preview-dash.png")
	game.die()
	session.refresh_view()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../preview-death.png")
	for size in [Vector2i(640, 360), Vector2i(1000, 700), Vector2i(1280, 720), Vector2i(1536, 864)]:
		root.size = size
		await process_frame
		await process_frame
		var transform := root.get_final_transform()
		print("WINDOW %s logical=%s transform=%s" % [size, root.get_visible_rect().size, transform])
	quit()
