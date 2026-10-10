extends Node

const MODES := {
	"conveyor": ["01 / MATERIAL RECOVERY", "Conveyor Sort", "A steady hand. A clean stream.", "Drag each material into its destination, or press 1–4 to sort the lowest item. Three mistakes end the shift. Recover 2,400 points to complete the mission."],
	"defense": ["02 / NEIGHBORHOOD WATCH", "Garbage Defense", "Build a future worth protecting.", "Collect golden energy. Pick a station and click a free tile. Arrow keys select a tile; Enter builds; C collects energy; 1–9 selects a packet. Five stages, three waves each."],
	"tunnel": ["03 / ECO-VELOCITY", "Eco-Velocity", "Find the gap. Keep the future moving.", "A/D or arrows rotate the tunnel around your locked ship. Space fires at red targets. Green organics and blue bottles recharge energy. Survive the 90-second route."],
	"shooter": ["04 / THE GARBAGE COURT", "Garbage Court", "Five places. Five tools. One second chance.", "WASD move. Mouse look after clicking the view; arrow keys also move/turn. Click or F fires. 1–5 selects a tool, R reloads, Space jumps, E uses the unlocked elevator. Esc pauses and releases the mouse."]
}
var game: ArcadeMode
var current_mode := ""
var state := "menu"
var ui: Control
var overlay: Control
var hud: Control
var stats: Label
var objective: Label
var feedback: Label
var audio: Node
var options := {"difficulty":1.0,"reduced_motion":false,"quality":0,"sound":true,"volume":0.75}
var bests := {}
var frame_label: Label
var previous_focus: Control

func _ready() -> void:
	setup_inputs()
	audio = load("res://scripts/sound.gd").new()
	add_child(audio)
	options.audio = audio
	load_save()
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	ui.theme = make_theme()
	show_menu()
	if OS.has_feature("web"):
		var requested = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('mode') || ''")
		if requested is String and MODES.has(requested): show_briefing(requested)
		JavaScriptBridge.eval("window.parent.postMessage({type:'masthak-ready'}, window.location.origin)")
	if "--smoke" in OS.get_cmdline_user_args(): smoke_test()
	if "--input-test" in OS.get_cmdline_user_args(): input_test()

func setup_inputs() -> void:
	var bindings := {"left":[KEY_A],"right":[KEY_D],"forward":[KEY_W,KEY_UP],"back":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"fire":[KEY_F],"use":[KEY_E],"reload":[KEY_R]}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for code in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action,event)

func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font=ThemeDB.fallback_font
	theme.set_font("font","Button",load("res://kenney/ui/font.ttf"))
	theme.default_font_size = 18
	for type in ["Button", "OptionButton", "CheckButton"]:
		theme.set_color("font_color",type,Color("eef0dd"))
		theme.set_color("font_hover_color",type,Color("fff6d8"))
		for item in ["normal","hover","pressed","focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("202a34") if item == "normal" else Color("394553")
			style.border_color = Color("ffba58") if item == "focus" else Color("546573")
			style.set_border_width_all(2 if item == "focus" else 1)
			style.set_corner_radius_all(3)
			style.content_margin_left = 18
			style.content_margin_right = 18
			style.content_margin_top = 12
			style.content_margin_bottom = 12
			theme.set_stylebox(item,type,style)
	for item in ["normal","hover","pressed"]:
		var skin := StyleBoxTexture.new()
		skin.texture=load("res://kenney/ui/button_square_header_large_rectangle_screws.png")
		skin.set_texture_margin_all(10)
		skin.modulate_color=Color("384654") if item=="normal" else Color("637484") if item=="hover" else Color("ab813a")
		skin.content_margin_left=14;skin.content_margin_right=14
		theme.set_stylebox(item,"Button",skin)
	return theme

func panel(rect: Rect2, parent: Node, color := Color("f2eddc")) -> Panel:
	var node := Panel.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = rect.position
	node.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	style.border_color = Color("596673")
	style.set_border_width_all(1)
	node.add_theme_stylebox_override("panel",style)
	parent.add_child(node)
	return node

func label(text: String, rect: Rect2, parent: Node, font_size := 20, color := Color("e9eedb")) -> Label:
	var node := Label.new()
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.clip_text = true
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size",font_size)
	if font_size>=28: node.add_theme_font_override("font",load("res://kenney/ui/font.ttf"))
	node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func button(text: String, rect: Rect2, parent: Node, action: Callable) -> Button:
	var node := Button.new()
	node.text = text.to_upper()
	node.position = rect.position
	node.size = rect.size
	if action.is_valid(): node.pressed.connect(action)
	node.pressed.connect(func(): audio.effect("click"))
	node.mouse_entered.connect(func(): audio.effect("hover"))
	parent.add_child(node)
	return node

func clear_overlay() -> void:
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)

func menu_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color("101720")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	label("MASTHAK  /  SECOND CHANCE",Rect2(48,28,850,35),overlay,16,Color("ffbb5b"))
	label("ESC / P: PAUSE       WASD / ARROWS: MOVE       KENNEY + ORIGINAL ASSETS",Rect2(48,610,1040,24),overlay,11,Color("8695a4"))

func show_menu() -> void:
	state = "menu"
	audio.enter_mode("")
	audio.quiet(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
		game = null
	if is_instance_valid(hud): hud.queue_free()
	clear_overlay()
	menu_backdrop()
	label("CHOOSE YOUR MISSION",Rect2(48,79,1040,65),overlay,36)
	var i := 0
	for id in MODES:
		var card := panel(Rect2(48+i*269,159,248,369),overlay,Color("202934"))
		label("0"+str(i+1)+" / "+["SORT","PROTECT","FLY","FIGHT"][i],Rect2(18,18,210,24),card,13,Color("ffbb5b"))
		var art := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas=load("res://assets/"+["bottle","leaf","banana","judge"][i]+"-walk.png")
		atlas.region=Rect2(0,0,160,192)
		art.texture=atlas;art.position=Vector2(46,49);art.size=Vector2(156,177)
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(art)
		label(MODES[id][1].to_upper(),Rect2(18,231,213,31),card,18)
		label(MODES[id][2],Rect2(18,270,213,42),card,12,Color("a6b5c5"))
		button("PLAY  >",Rect2(16,315,216,40),card,show_briefing.bind(id))
		i += 1
	button("SETTINGS",Rect2(48,547,248,43),overlay,show_settings)
	button("CREDITS",Rect2(316,547,248,43),overlay,show_credits)

func show_briefing(id: String) -> void:
	current_mode = id
	state = "briefing"
	clear_overlay()
	menu_backdrop()
	var card := panel(Rect2(110,91,932,490),overlay,Color("202934"))
	label(MODES[id][0],Rect2(35,27,830,28),card,14,Color("bad399"))
	label(MODES[id][1],Rect2(35,73,850,70),card,48)
	label(MODES[id][3],Rect2(35,162,850,140),card,22)
	label("ESC / P: PAUSE       BEST: "+str(bests.get(id,0)),Rect2(35,311,850,63),card,17,Color("a6b5c5"))
	button("< All missions",Rect2(35,400,230,56),card,show_menu)
	var launch := button("Launch mission  >",Rect2(586,400,307,56),card,start_game)
	launch.grab_focus()

func start_game() -> void:
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
	state = "playing"
	clear_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var script := "flat" if current_mode in ["conveyor","defense"] else current_mode
	game = load("res://scripts/"+script+".gd").new()
	game.set("mode",current_mode)
	game.configure(options)
	game.hud_changed.connect(update_hud)
	game.finished.connect(show_result)
	add_child(game)
	build_hud()
	audio.enter_mode(current_mode)
	audio.apply(options.sound,options.volume)
	audio.quiet(false)
	game.emit_hud()
	if current_mode == "shooter" and not OS.has_feature("web"): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func build_hud() -> void:
	if is_instance_valid(hud): hud.queue_free()
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	panel(Rect2(0,0,1152,66),hud,Color("17212b"))
	stats = label("",Rect2(25,12,800,45),hud,18)
	panel(Rect2(15,68,1100,36),hud,Color("17212b"))
	objective = label("",Rect2(28,70,900,32),hud,16,Color("efdfac"))
	feedback = label("",Rect2(24,600,1060,42),hud,16)
	var foot := ColorRect.new()
	foot.position = Vector2(0,595)
	foot.size = Vector2(1152,53)
	foot.color = Color("17212b")
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(foot)
	hud.move_child(foot,0)
	button("PAUSE",Rect2(1015,10,122,43),hud,pause_game)
	var sound_button := button("SOUND ON" if options.sound else "SOUND OFF",Rect2(851,10,152,43),hud,Callable())
	sound_button.pressed.connect(func(): options.sound=not options.sound;audio.apply(options.sound,options.volume);sound_button.text="SOUND ON" if options.sound else "SOUND OFF";save_data())
	if current_mode == "shooter":
		var crosshair := TextureRect.new()
		crosshair.texture=load("res://kenney/ui/crosshair_color_b.png")
		crosshair.position=Vector2(564,312);crosshair.size=Vector2(24,24)
		crosshair.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;crosshair.mouse_filter=Control.MOUSE_FILTER_IGNORE
		hud.add_child(crosshair)
		button("1 Bio",Rect2(30,546,135,43),hud,select_tool.bind(0))
		button("2 Recycle",Rect2(177,546,150,43),hud,select_tool.bind(1))
		button("3 Hazard",Rect2(340,546,150,43),hud,select_tool.bind(2))
		button("4 Compost",Rect2(503,546,150,43),hud,select_tool.bind(3))
		button("5 Residual",Rect2(666,546,150,43),hud,select_tool.bind(4))

func select_tool(index: int) -> void:
	if is_instance_valid(game) and game.has_method("select_tool"): game.select_tool(index)

func update_hud(data: Dictionary) -> void:
	if not is_instance_valid(stats): return
	stats.text = "ECO-SCORE  %05d     HEALTH  %d%%     STAGE  %d     ENERGY  %d" % [data.score,data.health,data.stage,data.energy]
	if current_mode in ["shooter","conveyor"]: stats.text="ECO-SCORE  %05d     HEALTH  %d%%     STAGE  %d" % [data.score,data.health,data.stage]
	objective.text = data.progress
	feedback.text = data.message

func pause_game() -> void:
	if state != "playing": return
	state = "paused"
	if game.has_method("reset_input"): game.reset_input()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio.quiet(true)
	clear_overlay()
	panel(Rect2(0,0,1152,648),overlay,Color(0.05,0.13,0.09,0.87))
	label("PAUSED",Rect2(300,132,650,78),overlay,50)
	label("ESC / P TO RESUME",Rect2(302,222,650,48),overlay,22,Color("a6b5c5"))
	button("Resume mission  >",Rect2(325,305,500,56),overlay,resume_game).grab_focus()
	button("Restart mission",Rect2(325,380,500,56),overlay,start_game)
	button("Return to missions",Rect2(325,455,500,56),overlay,show_menu)

func resume_game() -> void:
	if state != "paused": return
	clear_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.process_mode = Node.PROCESS_MODE_INHERIT
	state = "playing"
	audio.quiet(false)
	if current_mode == "shooter" and not OS.has_feature("web"): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_result(won: bool, points: int) -> void:
	state = "result"
	game.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio.quiet(true)
	bests[current_mode] = maxi(points,bests.get(current_mode,0))
	save_data()
	clear_overlay()
	menu_backdrop()
	label("MISSION CLEARED" if won else "MISSION FAILED",Rect2(150,143,900,90),overlay,50)
	label("All objectives complete." if won else "Restart to try again, or choose a different mission.",Rect2(150,250,900,60),overlay,23,Color("a6b5c5"))
	label("ECO-SCORE  %05d   /   BEST  %05d" % [points,bests[current_mode]],Rect2(150,336,880,60),overlay,28)
	button("Play again",Rect2(150,452,365,60),overlay,start_game)
	button("Choose another mission",Rect2(563,452,440,60),overlay,show_menu)

func show_settings() -> void:
	clear_overlay()
	menu_backdrop()
	label("SETTINGS",Rect2(140,95,880,75),overlay,44)
	var sound := CheckButton.new()
	sound.text = "Soundtrack and effects"
	sound.button_pressed = options.sound
	sound.position = Vector2(140,210)
	sound.toggled.connect(func(value): options.sound=value; audio.apply(value,options.volume))
	overlay.add_child(sound)
	label("Volume",Rect2(140,282,200,35),overlay,20)
	var volume := HSlider.new()
	volume.position = Vector2(350,284)
	volume.size = Vector2(580,35)
	volume.min_value=0; volume.max_value=1; volume.step=.05; volume.value=options.volume
	volume.value_changed.connect(func(value): options.volume=value; audio.apply(options.sound,value))
	overlay.add_child(volume)
	var easy := CheckButton.new()
	easy.text = "Gentle mode (slower threats, same sorting rules)"
	easy.position = Vector2(140,347)
	easy.button_pressed = options.difficulty < 1.0
	easy.toggled.connect(func(value): options.difficulty=.75 if value else 1.0)
	overlay.add_child(easy)
	var motion := CheckButton.new()
	motion.text = "Reduce camera motion"
	motion.position = Vector2(140,409)
	motion.button_pressed = options.reduced_motion
	motion.toggled.connect(func(value): options.reduced_motion=value)
	overlay.add_child(motion)
	button("Save & return",Rect2(140,512,400,55),overlay,func(): save_data(); show_menu())
	button("Fullscreen",Rect2(596,512,400,55),overlay,func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED))
	button("Delete saved game data",Rect2(756,122,311,43),overlay,func():
		bests.clear()
		for key in ["sound","volume","difficulty","reduced_motion"]: options[key]=false if key in ["sound","reduced_motion"] else .6 if key=="volume" else 1.0
		audio.apply(false,.6)
		DirAccess.remove_absolute("user://arcade.cfg")
		show_settings())

func show_credits() -> void:
	clear_overlay()
	menu_backdrop()
	label("CREDITS",Rect2(70,108,1020,84),overlay,42)
	label("MASTHAK story: Ganga, Swanandi and Abhilasha.\nCustom animated cast: Blender, inspired by supplied character sheets.\nGame engine: Godot. Original procedural soundtrack.\nKenney: Interface Sounds, Sci-Fi Sounds, UI Pack - Sci-Fi, Retro Urban Kit.\nKenney assets and font: CC0. License files included.\n\nScores and settings stay on this device.\nSorting tools are fictional. Batteries require special collection.",Rect2(73,223,980,295),overlay,20,Color("a6b5c5"))
	button("< Back to missions",Rect2(73,540,480,55),overlay,show_menu)

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("arcade","bests",bests)
	config.set_value("settings","audio_version",2)
	for key in ["sound","volume","difficulty","reduced_motion"]: config.set_value("settings",key,options[key])
	config.save("user://arcade.cfg")

func load_save() -> void:
	var config := ConfigFile.new()
	if config.load("user://arcade.cfg") != OK: return
	bests = config.get_value("arcade","bests",{})
	for key in ["sound","volume","difficulty","reduced_motion"]:
		if key=="sound" and config.get_value("settings","audio_version",0)<2: continue
		options[key] = config.get_value("settings",key,options[key])

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_P]:
		if state == "playing": pause_game()
		elif state == "paused": resume_game()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing": pause_game()

func smoke_test() -> void:
	for id in MODES:
		current_mode=id
		start_game()
		await get_tree().process_frame
		await get_tree().physics_frame
		assert(is_instance_valid(game))
		for frame in range(120): await get_tree().physics_frame
		if id == "shooter": assert(game.player.position.y > -1.0,"Player must stay on the floor")
		pause_game()
		assert(game.process_mode == Node.PROCESS_MODE_DISABLED)
		resume_game()
		show_menu()
		await get_tree().process_frame
	print("MASTHAK_SMOKE_OK: four modes, menus, pause, resume, scene cleanup")
	get_tree().quit()

func pointer_event(pos: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.position=pos;event.global_position=pos;event.pressed=down
	get_viewport().push_input(event,true)

func input_test() -> void:
	current_mode="conveyor";start_game()
	await get_tree().process_frame
	game.set_physics_process(false)
	game.items.clear()
	game.items.append({"id":998,"kind":0,"position":Vector2(560,280)})
	pointer_event(Vector2(560,280),true)
	assert(game.dragged==998,"HUD must not swallow a belt press")
	var drag := InputEventMouseMotion.new()
	drag.position=Vector2(285,550);drag.global_position=drag.position;drag.button_mask=MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(drag,true)
	assert(game.items[0].position==drag.position,"Pointer movement must drag the material")
	pointer_event(Vector2(285,550),false)
	assert(game.score==100 and game.items.is_empty(),"Releasing over compost must sort")
	current_mode="defense";start_game()
	await get_tree().process_frame
	game.set_physics_process(false)
	game.drops.append({"position":Vector2(500,300),"target":300,"life":10})
	var before: int = game.energy
	pointer_event(Vector2(500,300),true);pointer_event(Vector2(500,300),false)
	assert(game.energy==before+25 and game.drops.is_empty(),"Coin click must reach the board")
	pointer_event(Vector2(187,135),true);pointer_event(Vector2(187,135),false)
	assert(game.selected==1,"Packet mouse selection must work")
	pointer_event(Vector2(326,366),true);pointer_event(Vector2(326,366),false)
	assert(game.stations.size()==1,"Selected packet must build by click")
	current_mode="shooter";start_game()
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.set_physics_process(false)
	var yaw: float = game.player.rotation.y
	pointer_event(Vector2(576,324),true)
	var target_hp: float = game.enemies[0].hp
	game._physics_process(.02)
	assert(game.ammo[0]==17 and game.enemies[0].hp<target_hp,"Mouse fire must spend ammo and hit the visible target")
	var motion := InputEventMouseMotion.new()
	motion.position=Vector2(576,324);motion.relative=Vector2(60,10);motion.screen_relative=motion.relative
	get_viewport().push_input(InputEventMouseMotion.new(),true)
	get_viewport().push_input(motion,true)
	assert(absf(game.player.rotation.y-yaw)>.1,"FPS mouse motion must turn the camera")
	pointer_event(Vector2(576,324),true)
	assert(game.player.fire_pressed,"FPS click must fire")
	pointer_event(Vector2(576,324),false)
	assert(not game.player.fire_pressed,"FPS button release must stop firing")
	current_mode="tunnel";start_game()
	await get_tree().process_frame
	game.set_physics_process(false)
	var fixed_ship: Vector3 = game.ship.position
	game.virtual_turn=1
	game._physics_process(.05)
	assert(game.ship.position==fixed_ship and absf(game.track.rotation.z)>.05,"Tunnel must turn while ship stays locked")
	game.virtual_turn=0
	game.angle=-PI/2
	game.fire()
	var count: int=game.debris.size()
	for i in range(6): game._physics_process(.05)
	assert(game.debris.size()<count and game.score>=60,"Pulse must destroy a red target")
	show_menu()
	audio.apply(false,options.volume)
	await get_tree().process_frame
	for frame in range(6): await get_tree().physics_frame
	await get_tree().process_frame
	print("MASTHAK_INPUT_OK: viewport drag/drop, coin click, packet selection, placement, mouse look/fire/release, locked ship and pulse impact")
	get_tree().quit()


