extends ArcadeMode

var mode := "shooter"
var world: Node3D
var player: CharacterBody3D
var enemies: Array[Dictionary] = []
var pickups: Array[Node3D] = []
var hazards: Array[Node3D] = []
var bullets: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var astar := AStarGrid2D.new()
var cells: Array[Array] = []
var spawn_clock := 5.0
var fire_clock := 0.0
var invulnerability := 0.0
var weapon := 0
var ammo := [18,8,6,6,30]
var reload_clock := 0.0
var kills := 0
var boss_down := false
var unlocked := false
var gate: Node3D
var stage_clock := 0.0
var hit_marker := 0.0
var damage_flash := 0.0
const TILE := 2.3
const LEVELS := ["MAYA’S STREET", "LANDFILL LABYRINTH", "THE TOXIC PLANT", "THE OVERGROWN PARK", "THE GARBAGE COURT"]
const TOOLS := ["BIO-DEGRADER", "RECYCLE-RAY", "HAZARD NEUTRALIZER", "COMPOST LAUNCHER", "RESIDUAL BLASTER"]
const CAPACITY := [18,8,6,6,30]
const RATES := [.16,.48,.75,.7,.1]
const POWER := [35.0,100.0,110.0,85.0,30.0]
const TARGETS := [0,3,1,1,2,4]

func _ready() -> void:
	super._ready()
	build_stage()

func objective() -> String:
	var boss := ""
	for enemy in enemies:
		if enemy.boss: boss="  /  JUDGE %d%%: %s" % [ceili(enemy.hp/12),TOOLS[boss_tool(enemy.hp)]]
	return "%s  ·  %d / %d RECOVERED  ·  %s %d/%d%s" % [LEVELS[stage-1],kills,6+stage*2,TOOLS[weapon],ammo[weapon],CAPACITY[weapon],boss] if not unlocked else "ELEVATOR OPEN  /  Find the golden door and press E"

func boss_tool(hp: float) -> int:
	return 1 if hp>800 else 2 if hp>400 else 3

func build_stage() -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	enemies.clear();pickups.clear();hazards.clear();bullets.clear();flashes.clear()
	kills=0;unlocked=false;boss_down=false;spawn_clock=1.8;stage_clock=0
	world=Node3D.new()
	add_child(world)
	ArcadeModels.environment(world,Color("141921"))
	var ground := ArcadeModels.box(world,Vector3(17.25,-.25,17.25),Vector3(34.5,.5,34.5),Color.WHITE,true)
	ArcadeModels.coat(ground,ArcadeModels.textured("concrete",Color("889097"),Vector3(18,18,1)))
	var ceiling := ArcadeModels.box(world,Vector3(17.25,7.0 if stage==5 else 3.5,17.25),Vector3(34.5,.25,34.5),Color.WHITE)
	ArcadeModels.coat(ceiling,ArcadeModels.textured("roof_plates",Color("555b62"),Vector3(16,16,1)))
	cells.clear()
	for z in range(15):
		var row: Array = []
		for x in range(15):
			var solid := x==0 or z==0 or x==14 or z==14
			if stage<5 and z in [4,8,12] and x>1 and x<14:
				var gap := 3 if z==4 else 9 if z==8 else 4
				solid=not (x>=gap and x<=gap+2)
			row.append(solid)
			if solid:
				var pos := Vector3((x+.5)*TILE,1.45,(z+.5)*TILE)
				if stage==5: pos.y=3.5
				var wall := ArcadeModels.box(world,pos,Vector3(TILE,7.0 if stage==5 else 3.4,TILE),Color.WHITE,true)
				ArcadeModels.coat(wall,ArcadeModels.textured("wall",Color("9198a1") if stage!=3 else Color("799887")))
				ArcadeModels.box(world,pos+Vector3(0,.85,0),Vector3(TILE+.03,.09,TILE+.03),Color("343d46"))
		cells.append(row)
	astar.region=Rect2i(0,0,15,15)
	astar.cell_size=Vector2(TILE,TILE)
	astar.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for z in range(15):
		for x in range(15): astar.set_point_solid(Vector2i(x,z),cells[z][x])
	for i in range(16):
		var pos := random_open()
		var prop := ArcadeModels.asset("tree" if stage==4 else "bin")
		prop.position=pos
		prop.scale=Vector3.ONE*.75
		world.add_child(prop)
	for z in [2,6,10]:
		for x in [3,9]:
			var light := OmniLight3D.new()
			light.position=Vector3((x+.5)*TILE,2.7,(z+.5)*TILE)
			light.light_color=Color("ffb66f") if (x+z)%2==1 else Color("8ed7e0")
			light.omni_range=7.0;light.light_energy=1.3;light.shadow_enabled=false
			world.add_child(light)
			ArcadeModels.box(world,light.position,Vector3(.7,.06,.3),light.light_color)
	for i in range(6):
		var prop: Node3D = load("res://kenney/props/detail-dumpster-open.glb").instantiate()
		prop.position=random_open();prop.scale=Vector3.ONE*1.0
		world.add_child(prop)
	player=load("res://scripts/player.gd").new()
	player.position=Vector3(4.5*TILE,.05,1.5*TILE)
	player.rotation.y=PI
	player.reduced_motion=reduced_motion
	world.add_child(player)
	gate=ArcadeModels.box(world,Vector3(13*TILE,1.2,13*TILE),Vector3(1.7,2.4,.3),Color("726951"))
	ArcadeModels.sign(world,"ELEVATOR",Vector3(13*TILE,3.1,13*TILE))
	ArcadeModels.sign(world,LEVELS[stage-1],Vector3(4.5*TILE,2.6,7.5*TILE))
	for i in range(7): spawn_pickup(random_open())
	if stage==3:
		for i in range(6): spawn_hazard(random_open())
	if stage==5: spawn_enemy(2,Vector3(8*TILE,0,10*TILE),true)
	else:
		spawn_enemy(0,Vector3(4.5*TILE,0,3.1*TILE))
		spawn_enemy(3,Vector3(6*TILE,0,3*TILE))
	message="Recover each material with its matching tool. Reload with R."
	emit_hud()

func random_open() -> Vector3:
	var cell := Vector2i(2,2)
	for attempt in range(150):
		cell=Vector2i(rng.randi_range(1,13),rng.randi_range(1,13))
		if not cells[cell.y][cell.x]: break
	return Vector3((cell.x+.5)*TILE,0,(cell.y+.5)*TILE)

func spawn_pickup(pos: Vector3) -> void:
	var kit := ArcadeModels.box(world,pos+Vector3(0,.35,0),Vector3(.48,.6,.48),Color("f0d792"))
	ArcadeModels.sign(kit,"+",Vector3(0,.55,0),Color("284b30"))
	pickups.append(kit)

func spawn_hazard(pos: Vector3) -> void:
	var puddle := ArcadeModels.box(world,pos+Vector3(0,.03,0),Vector3(1.1,.035,1.1),Color("abb643"))
	hazards.append(puddle)

func spawn_enemy(kind: int, pos: Vector3, boss := false) -> void:
	var body := CharacterBody3D.new()
	body.position=pos
	body.collision_layer=2
	body.collision_mask=5
	body.add_to_group("waste")
	var hitbox := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height=1.7 if not boss else 4.5
	shape.radius=.4 if not boss else 1.1
	hitbox.shape=shape
	hitbox.position.y=.85 if not boss else 2.25
	body.add_child(hitbox)
	var model := ArcadeModels.asset(IDS[kind])
	model.scale=Vector3.ONE*(2.9 if boss else 1.0)
	body.add_child(model)
	world.add_child(body)
	ArcadeModels.animate(model,1.2 if kind==0 else .8)
	enemies.append({"body":body,"model":model,"kind":kind,"hp":1200.0 if boss else 240.0 if kind==4 else 140.0 if kind==5 else 90.0,"boss":boss,"attack":3.0,"path":PackedVector2Array(),"path_clock":0.0})

func select_tool(index: int) -> void:
	if index<0 or index>4: return
	weapon=index
	reload_clock=0
	message=TOOLS[index]+" ready. R reloads."
	player.reset_input()
	sfx("reload")
	emit_hud()

func _unhandled_input(event: InputEvent) -> void:
	if stopped: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode>=KEY_1 and event.keycode<=KEY_5: select_tool(event.keycode-KEY_1)
		if event.keycode==KEY_R: reload_tool()

func reload_tool() -> void:
	if reload_clock>0 or ammo[weapon]==CAPACITY[weapon]: return
	reload_clock=1.25
	sfx("reload")
	message="Reloading "+TOOLS[weapon]+"…"

func shoot() -> void:
	if stopped or fire_clock>0 or reload_clock>0: return
	if ammo[weapon]<=0: reload_tool();return
	ammo[weapon]-=1
	fire_clock=RATES[weapon]
	player.kick()
	sfx("shot")
	var origin: Vector3 = player.camera.global_position
	var direction: Vector3 = -player.camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*50,3)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	var impact: Vector3 = hit.position if hit else origin+direction*30
	beam(origin+player.camera.global_basis*Vector3(.28,-.2,-.4),impact,COLORS[0] if weapon in [0,3] else COLORS[1] if weapon==1 else COLORS[3] if weapon==2 else COLORS[2])
	if hit and hit.collider.is_in_group("waste"):
		for enemy in enemies:
			if enemy.body!=hit.collider: continue
			var valid: bool = weapon==boss_tool(enemy.hp) if enemy.boss else weapon==TARGETS[enemy.kind] or (enemy.kind in [0,1] and weapon in [0,3])
			if valid:
				enemy.hp-=POWER[weapon]
				hit_marker=.15
				sfx("hit")
				var tween := create_tween()
				tween.tween_property(enemy.model,"scale",Vector3.ONE*(3.12 if enemy.boss else 1.10),.04)
				tween.tween_property(enemy.model,"scale",Vector3.ONE*(2.9 if enemy.boss else 1.0),.07)
				message="Correct stream. Keep moving!"
				if weapon==3:
					for other in enemies:
						if other!=enemy and other.kind in [0,1] and other.body.position.distance_to(enemy.body.position)<3.5: other.hp-=65
			else:
				score=maxi(0,score-25)
				message="OBJECTION! Use "+TOOLS[boss_tool(enemy.hp) if enemy.boss else TARGETS[enemy.kind]]+"."
				sfx("bad")
			break

func beam(start: Vector3, target: Vector3, color: Color) -> void:
	if flashes.size()>24: return
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius=.025;cylinder.bottom_radius=.025;cylinder.height=start.distance_to(target)
	cylinder.radial_segments=5
	mesh.mesh=cylinder
	mesh.material_override=ArcadeModels.material(color,true)
	world.add_child(mesh)
	mesh.global_position=(start+target)*.5
	if start.distance_to(target)>.01:
		mesh.look_at(target,Vector3.UP)
		mesh.rotate_object_local(Vector3.RIGHT,PI/2)
	flashes.append({"object":mesh,"life":.08})

func _physics_process(delta: float) -> void:
	if stopped or not is_instance_valid(player): return
	var dt := tick(delta)
	stage_clock+=dt
	hit_marker=maxf(0,hit_marker-dt)
	damage_flash=maxf(0,damage_flash-dt)
	queue_redraw()
	fire_clock=maxf(0,fire_clock-dt)
	invulnerability=maxf(0,invulnerability-dt)
	if reload_clock>0:
		reload_clock-=dt
		if reload_clock<=0: ammo[weapon]=CAPACITY[weapon];message=TOOLS[weapon]+" reloaded."
	player.reloading=reload_clock>0
	if player.fire_pressed or Input.is_action_pressed("fire"): shoot()
	spawn_clock-=dt
	if spawn_clock<=0 and enemies.size()<8 and not unlocked:
		var available := [0,3] if stage==1 else [0,3,5] if stage==2 else [0,3,4,5] if stage==3 else [0,1,3,4,5]
		var pos := random_open()
		for attempt in range(20):
			if pos.distance_to(player.position)>9: break
			pos=random_open()
		spawn_enemy(available[rng.randi_range(0,available.size()-1)],pos)
		spawn_clock=maxf(2.0,4.0-stage*.3)/difficulty
	for i in range(enemies.size()-1,-1,-1):
		var enemy: Dictionary = enemies[i]
		var body: CharacterBody3D = enemy.body
		if enemy.hp<=0:
			sfx("explode")
			if enemy.boss: boss_down=true;recover(1000)
			else: kills+=1;recover()
			if rng.randf()<.28 and pickups.size()<12: spawn_pickup(body.position)
			body.queue_free();enemies.remove_at(i)
			if kills>=6+stage*2 and (stage<5 or boss_down): open_exit()
			continue
		enemy.attack-=dt
		var distance: float = body.position.distance_to(player.position)
		if Vector2(body.position.x-player.position.x,body.position.z-player.position.z).length_squared()>.01: body.look_at(Vector3(player.position.x,body.position.y,player.position.z),Vector3.UP,true)
		if enemy.boss:
			enemy.model.position.y=sin(elapsed*2)*.06 if not reduced_motion else 0.0
			if enemy.attack<=0:
				fire_hostile(body.position+Vector3(0,2.2,0),player.position+Vector3(0,1.1,0))
				enemy.attack=1.1/difficulty
			continue
		enemy.path_clock-=dt
		if enemy.path_clock<=0:
			var from := Vector2i(int(body.position.x/TILE),int(body.position.z/TILE))
			var to := Vector2i(int(player.position.x/TILE),int(player.position.z/TILE))
			if astar.is_in_boundsv(from) and astar.is_in_boundsv(to): enemy.path=astar.get_point_path(from,to)
			enemy.path_clock=.65
		var target: Vector3 = player.position
		if enemy.path.size()>1: target=Vector3(enemy.path[1].x+TILE*.5,0,enemy.path[1].y+TILE*.5)
		var dir: Vector3 = (target-body.position).normalized()
		var speed := (2.0 if enemy.kind==0 else .8 if enemy.kind==4 else 1.25)*difficulty
		body.velocity=Vector3(dir.x*speed,body.velocity.y-18*dt,dir.z*speed) if distance>1.1 else Vector3(0,body.velocity.y-18*dt,0)
		body.move_and_slide()
		if not reduced_motion: enemy.model.position.y=sin(elapsed*7+body.get_instance_id()%10)*.035
		if enemy.kind==3 and distance<12 and enemy.attack<=0:
			fire_hostile(body.position+Vector3(0,1.15,0),player.position+Vector3(0,1.15,0));enemy.attack=2.8
		elif distance<1.35 and enemy.attack<=0: hurt(9,"Waste attack! Back away and match your tool.");enemy.attack=1.8
	for i in range(bullets.size()-1,-1,-1):
		var bullet: Dictionary = bullets[i]
		var old: Vector3 = bullet.object.position
		var pos: Vector3 = old+bullet.velocity*dt
		bullet.life-=dt
		var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(old,pos,1))
		if pos.distance_to(player.position+Vector3(0,1,0))<.55:
			hurt(12,"Microplastic projectile! Strafe away from the glowing shot.")
			bullet.life=0
		if hit or bullet.life<=0: bullet.object.queue_free();bullets.remove_at(i)
		else: bullet.object.position=pos
	for i in range(pickups.size()-1,-1,-1):
		var kit: Node3D = pickups[i]
		kit.rotation.y+=dt
		if Vector2(kit.position.x-player.position.x,kit.position.z-player.position.z).length()<.9:
			health=mini(100,health+25);ammo[weapon]=CAPACITY[weapon];message="Eco-kit: +25 health and a fresh tool charge.";sfx("good");kit.queue_free();pickups.remove_at(i)
	for puddle in hazards:
		if Vector2(puddle.position.x-player.position.x,puddle.position.z-player.position.z).length()<.8 and player.position.y<.4: hurt(5,"Acid spill! Move away or jump over it.")
	for i in range(flashes.size()-1,-1,-1):
		flashes[i].life-=dt
		if flashes[i].life<=0: flashes[i].object.queue_free();flashes.remove_at(i)
	if unlocked and player.position.distance_to(gate.position)<3 and Input.is_action_just_pressed("use"):
		if stage==5: end(true)
		else: stage+=1;health=mini(100,health+35);ammo=CAPACITY.duplicate();build_stage()

func hurt(amount: int, text: String) -> void:
	if invulnerability>0: return
	invulnerability=.7
	damage_flash=.25
	damage(amount,text)

func _draw() -> void:
	if damage_flash>0: draw_rect(Rect2(0,0,1152,648),Color(.8,.12,.05,damage_flash*.65))
	if hit_marker>0:
		for side in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			draw_line(Vector2(576,324)+side*8,Vector2(576,324)+side*16,Color("ffbb59"),3)

func fire_hostile(start: Vector3, target: Vector3) -> void:
	if bullets.size()>=24: return
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius=.12;sphere.height=.24;sphere.radial_segments=8;sphere.rings=4
	orb.mesh=sphere;orb.material_override=ArcadeModels.material(Color("efb16d"),true)
	orb.position=start
	world.add_child(orb)
	bullets.append({"object":orb,"velocity":(target-start).normalized()*6*difficulty,"life":6.0})

func open_exit() -> void:
	if unlocked: return
	unlocked=true
	message="The elevator is open. Follow the golden doorway and press E."
	for child in gate.get_children():
		if child is MeshInstance3D: child.material_override=ArcadeModels.material(Color("d2d391"),true)

func reset_input() -> void:
	if is_instance_valid(player): player.reset_input()


