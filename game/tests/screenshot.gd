extends SceneTree
## Capture d'écran de la scène principale (nécessite un affichage). Lancement : tools/screenshot.sh
##
## Arguments après `--` : chemin_png [secondes=6] [distance=16] [inclinaison=-16] [rotation=0] [--debug] [--beam-port|--beam-starboard]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() > 0 else "screenshot.png"
	var seconds: float = float(args[1]) if args.size() > 1 else 6.0
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	var camera: Node = main.get_node("Camera")
	if args.size() > 2:
		camera.distance = float(args[2])
	if args.size() > 3:
		camera.pitch_deg = float(args[3])
	if args.size() > 4:
		camera.set("_yaw_offset", deg_to_rad(float(args[4])))
	main.get_node("ForceOverlay").visible = "--debug" in args
	if "--beam-port" in args:
		camera.beam_side = -1
	elif "--beam-starboard" in args:
		camera.beam_side = 1
	await create_timer(seconds).timeout
	await process_frame
	root.get_texture().get_image().save_png(path)
	print("Capture enregistrée : ", path)
	quit()
