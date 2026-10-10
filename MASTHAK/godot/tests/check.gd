extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var belt = load("res://scripts/flat.gd").new()
	root.add_child(belt)
	belt.set_physics_process(false)
	belt.items.append({"id":7,"kind":4,"position":Vector2(550,230)})
	belt.sort_item(7,3)
	assert(belt.score==100 and belt.health==100 and belt.items.is_empty(),"Batteries must use special collection")
	for i in range(3):
		belt.items.append({"id":i,"kind":0,"position":Vector2(550,230)})
		belt.sort_item(i,1)
	assert(belt.stopped and belt.health==0,"Three wrong sorts end the shift")
	belt.queue_free()
	var defense = load("res://scripts/flat.gd").new()
	defense.mode="defense"
	root.add_child(defense)
	defense.set_physics_process(false)
	defense.energy=500
	defense.selected=1
	defense.place_station(Vector2i(1,0))
	assert(defense.stations.is_empty(),"Closed lanes reject placement")
	defense.place_station(Vector2i(1,2))
	assert(defense.stations.size()==1 and defense.energy==400)
	defense.place_station(Vector2i(1,2))
	assert(defense.stations.size()==1 and defense.energy==400,"Occupied tiles cannot charge twice")
	defense.place_station(Vector2i(2,2))
	assert(defense.stations.size()==1,"Cooldown prevents duplicate placement")
	defense.selected=8
	defense.place_station(Vector2i(1,2))
	assert(defense.stations.is_empty(),"Shovel removes a station")
	defense.queue_free()
	var fps = load("res://scripts/shooter.gd").new()
	assert(fps.boss_tool(1200)==1 and fps.boss_tool(700)==2 and fps.boss_tool(300)==3,"Judge phases need distinct tools")
	fps.free()
	var tunnel = load("res://scripts/tunnel.gd").new()
	assert(tunnel.circular_distance(PI-.1,-PI+.1)<.21,"Circular collision wraps at the angle seam")
	tunnel.free()
	for id in ["banana","leaf","bottle","judge","battery","wrapper"]:
		var actor := ArcadeModels.asset(id)
		var players := actor.find_children("*","AnimationPlayer",true,false)
		assert(not players.is_empty(),"Custom cast must contain imported animations")
		ArcadeModels.animate(actor)
		assert(players[0].is_playing(),"Custom cast animation must play")
		actor.free()
	await process_frame
	print("MASTHAK_RULES_OK: sorting, defeat, lane locks, occupied cells, cooldown, shovel, boss phases, circular collision")
	quit()

