extends SceneTree

const VIEWS = [
	{"id": "trois-vannes", "anchor": "tv-place-cloche", "offset": Vector3(24, 19, 29), "elevation": 3.4},
	{"id": "port", "anchor": "tv-port", "offset": Vector3(-26, 17, 34), "elevation": 2.8},
	{"id": "phare", "anchor": "phare-keravel", "offset": Vector3(18, 19, 35), "elevation": 8.0},
	{"id": "kastell-glas", "anchor": "ea-citadelle-remparts", "offset": Vector3(-26, 25, 29), "elevation": 5.5},
]

func _initialize():
	call_deferred("run")

func argument(name: String, fallback: String = "") -> String:
	var args = OS.get_cmdline_user_args()
	var index = args.find(name)
	return args[index + 1] if index >= 0 and index + 1 < args.size() else fallback

func compare_pixels(current: Image, previous_file: String, threshold: float) -> Dictionary:
	if previous_file.is_empty():
		return {"status": "baseline_skipped"}
	var previous = Image.load_from_file(previous_file)
	if previous == null or previous.is_empty():
		return {"status": "baseline_missing"}
	if current.get_size() != previous.get_size():
		return {"status": "baseline_incompatible", "expected": [previous.get_width(), previous.get_height()]}
	# Full-resolution files stay available for inspection; compare every fourth pixel.
	var error := 0.0
	var changed := 0
	var measured := 0
	for y in range(0, current.get_height(), 4):
		for x in range(0, current.get_width(), 4):
			var a = current.get_pixel(x, y)
			var b = previous.get_pixel(x, y)
			var distance = (absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b)) / 3.0
			error += distance
			if distance > 0.05:
				changed += 1
			measured += 1
	var average = error / measured
	return {"status": "pass" if average <= threshold else "drift", "mean_rgb_error": average,
		"changed_fraction": float(changed) / measured, "threshold": threshold, "samples": measured}

func frame_metrics() -> Dictionary:
	var current_fps = Performance.get_monitor(Performance.TIME_FPS)
	var process_seconds = Performance.get_monitor(Performance.TIME_PROCESS)
	var primitives = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var visible = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	var video_memory = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var tagged_npcs = get_nodes_in_group("studio_npc")
	return {"fps": current_fps if current_fps > 0 else null,
		"frame_process_ms": process_seconds * 1000.0 if process_seconds > 0 else null,
		"render_setup_cpu_ms": RenderingServer.get_frame_setup_time_cpu(),
		"rendered_primitives": int(primitives) if primitives > 0 else null,
		"draw_calls": int(draw_calls) if draw_calls > 0 else null,
		"visible_render_objects": int(visible) if visible > 0 else null,
		"engine_memory_bytes": int(memory) if memory > 0 else null,
		"gpu_memory_bytes": int(video_memory) if video_memory > 0 else null,
		"scene_nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"active_tagged_npcs": tagged_npcs.filter(func(n): return n.can_process()).size() if not tagged_npcs.is_empty() else null}

func has_visual_content(screenshot: Image) -> bool:
	var first = screenshot.get_pixel(0, 0)
	for y in range(0, screenshot.get_height(), 16):
		for x in range(0, screenshot.get_width(), 16):
			var p = screenshot.get_pixel(x, y)
			if p.a>0.05 and maxf(absf(first.r-p.r),maxf(absf(first.g-p.g),absf(first.b-p.b)))>0.035:
				return true
	return false

func run():
	var folder = argument("--visual-out")
	if folder.is_empty():
		push_error("Le dossier --visual-out est requis.")
		quit(2)
		return
	if DisplayServer.get_name().to_lower() == "headless":
		push_error("Le serveur d’affichage headless ne permet pas de capturer le rendu.")
		quit(2)
		return
	var baseline = argument("--visual-baseline")
	var threshold = argument("--visual-threshold", "0.045").to_float()
	var begin = Time.get_ticks_msec()
	var packed = load("res://main.tscn") as PackedScene
	if packed == null:
		quit(2)
		return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var load_ms = Time.get_ticks_msec() - begin
	# Keep the authored lighting and game geometry while holding time and camera steady.
	game.set_process(false)
	game.set_physics_process(false)
	game.actor.visible = false
	game.hud.hide()
	game.world.atmosphere(46.0, 0.15, 0.04, 0.0, true)
	var adapter = RenderingServer.get_video_adapter_name()
	var report = {"godot": Engine.get_version_info().get("string"), "scene_load_ms": load_ms,
		"adapter": adapter if not adapter.is_empty() else null, "captures": []}
	var failed = false
	for view in VIEWS:
		var id: String = view.id
		var anchor: String = view.anchor
		if not game.world.campaign.points.has(anchor):
			report.captures.append({"id": id, "status": "missing_anchor"})
			failed = true
			continue
		var xy: Vector2 = game.world.campaign.points[anchor]
		var target: Vector3 = game.world.pos(xy) + Vector3.UP * view.elevation
		game.camera.position = target + view.offset
		game.camera.look_at(target)
		game.camera.fov = 57.
		for frame in 3:
			await RenderingServer.frame_post_draw
		var screenshot = root.get_texture().get_image()
		if screenshot == null or screenshot.is_empty() or screenshot.save_png(folder.path_join(id + ".png")) != OK:
			report.captures.append({"id": id, "status": "capture_failed"})
			failed = true
			continue
		if not has_visual_content(screenshot):
			report.captures.append({"id": id, "status": "flat_frame", "file": id + ".png"})
			failed = true
			continue
		var details = compare_pixels(screenshot, baseline.path_join(id + ".png") if not baseline.is_empty() else "", threshold)
		report.captures.append({"id": id, "status": "captured", "file": id + ".png",
			"dimensions": [screenshot.get_width(), screenshot.get_height()],
			"metrics": frame_metrics(), "comparison": details})
		failed = failed or details.status in ["baseline_missing", "baseline_incompatible", "drift"]
	var output = FileAccess.open(folder.path_join("engine.json"), FileAccess.WRITE)
	if output == null:
		quit(2)
		return
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	quit(1 if failed else 0)
