extends ArcadeMode

var mode := "tunnel"
var world: Node3D
var track: Node3D
var camera: Camera3D
var ship: Node3D
var rings: Array[Node3D] = []
var debris: Array[Dictionary] = []
var pulses: Array[Dictionary] = []
var angle := -PI/2
var spawn_clock := 2.0
var shot_clock := 0.0
var invulnerability := 0.0
var route_time := 0.0
var safe_streak := 0
var virtual_turn := 0.0
var virtual_fire := false

func _ready() -> void:
	super._ready()
	energy=100
	world=Node3D.new()
	add_child(world)
	track=Node3D.new()
	world.add_child(track)
	ArcadeModels.environment(world,Color("101b20"))
	camera=Camera3D.new()
	camera.position.z=5
	camera.fov=76
	camera.near=.1
	camera.far=240
	world.add_child(camera)
	camera.make_current()
	ship=ArcadeModels.asset("ship")
	ship.rotation.y=PI
	ship.scale=Vector3.ONE*1.8
	ship.position=Vector3(0,-5,-6)
	world.add_child(ship)
	var meshes := tunnel_meshes()
	for i in range(24):
		var section := Node3D.new()
		section.position.z=-i*9
		for mesh in meshes:
			var visual := MeshInstance3D.new()
			visual.mesh=mesh
			section.add_child(visual)
		track.add_child(section)
		rings.append(section)
	message="A/D turns the tunnel. Space blasts red targets. Collect green and blue."
	spawn_debris(5,-PI/2,-35)
	spawn_debris(0,-PI/2,-65)
	spawn_debris(4,-PI/2+.65,-85)
	emit_hud()

func tunnel_meshes() -> Array[ArrayMesh]:
	var faces := SurfaceTool.new()
	faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges := SurfaceTool.new()
	edges.begin(Mesh.PRIMITIVE_LINES)
	for i in range(12):
		var a := i*TAU/12
		var b := (i+1)*TAU/12
		var vertices := [Vector3(cos(a)*7,sin(a)*7,0),Vector3(cos(b)*7,sin(b)*7,0),Vector3(cos(b)*7,sin(b)*7,-9),Vector3(cos(a)*7,sin(a)*7,-9)]
		for index in [0,1,2,0,2,3]:
			faces.set_color(Color("203640") if i%3==0 else Color("172b2c") if i%3==1 else Color("252c3d"))
			faces.add_vertex(vertices[index])
		for index in [0,1,1,2,2,3,3,0]:
			edges.set_color(Color("69cbd7"));edges.add_vertex(vertices[index])
	var mat := StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo=true
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	faces.set_material(mat);edges.set_material(mat)
	return [faces.commit(),edges.commit()]

func objective() -> String:
	return "ROUTE %02d / 90s   ·   %s   ·   ENERGY %d%%" % [floori(route_time),["RECOVERY RUN","THE BLOCKADE","FULL VELOCITY"][stage-1],energy]

func _physics_process(delta: float) -> void:
	if stopped: return
	var dt := tick(delta)
	route_time+=dt
	stage=mini(3,1+floori(route_time/30))
	var speed := (26+route_time*.32)*difficulty
	var turn := Input.get_axis("left","right")+virtual_turn
	if Input.is_physical_key_pressed(KEY_LEFT): turn-=1
	if Input.is_physical_key_pressed(KEY_RIGHT): turn+=1
	angle=wrapf(angle+clampf(turn,-1,1)*2.7*dt,-PI,PI)
	track.rotation.z=-PI/2-angle
	ship.position=Vector3(0,-5,-6)
	ship.rotation.z=0
	ship.rotation.x=0
	if not reduced_motion:
		camera.fov=lerpf(camera.fov,76+stage*3,dt)
	for ring in rings:
		ring.position.z+=speed*dt
		if ring.position.z>14: ring.position.z-=216
		if not reduced_motion:
			ring.position.x=sin(elapsed*.23+ring.position.z*.01)*.5
			ring.position.y=cos(elapsed*.18+ring.position.z*.015)*.3
			ring.rotation.z=sin(elapsed*.15+ring.position.z*.008)*.11
	spawn_clock-=dt;shot_clock=maxf(0,shot_clock-dt);invulnerability=maxf(0,invulnerability-dt)
	energy=maxi(0,100+safe_streak*12-floori(route_time*1.1))
	energy=mini(100,energy)
	if energy<=0: hurt(6,"Fuel exhausted! Recover the next green or blue supply.")
	if spawn_clock<=0 and debris.size()<30:
		var kind := rng.randi_range(0,5)
		var theta := rng.randf_range(-PI,PI)
		spawn_debris(kind,theta,-105)
		if stage>=2 and rng.randf()<.35:
			spawn_debris(2,theta+.45,-185)
			spawn_debris(2,theta-.45,-185)
		spawn_clock=maxf(.65,1.45-stage*.18)/difficulty
	for i in range(debris.size()-1,-1,-1):
		var item: Dictionary = debris[i]
		var previous: float = item.object.position.z
		item.object.position.z+=speed*dt
		if item.kind==2 and stage>1:
			item.angle=wrapf(item.angle+dt*.3,-PI,PI)
			item.object.position.x=cos(item.angle)*5
			item.object.position.y=sin(item.angle)*5
		if previous<-6 and item.object.position.z>=-6:
			if circular_distance(angle,item.angle)<.32:
				if item.kind in [0,1,3]:
					safe_streak+=1
					recover(100+mini(50,safe_streak*5))
					message="Recovered! Organics and bottles recharge the route."
				else: hurt(25 if item.kind==4 else 18,"OBJECTION! Avoid batteries and red blockades.")
		if item.object.position.z>6:
			item.object.queue_free();debris.remove_at(i)
	if Input.is_action_pressed("jump") or Input.is_action_pressed("fire") or virtual_fire: fire()
	for i in range(pulses.size()-1,-1,-1):
		var pulse: Dictionary = pulses[i]
		var old: float = pulse.object.position.z
		pulse.object.position.z-=130*dt
		pulse.life-=dt
		for j in range(debris.size()-1,-1,-1):
			var item: Dictionary = debris[j]
			if circular_distance(pulse.angle,item.angle)<.38 and item.object.position.z<=old+2.5 and item.object.position.z>=pulse.object.position.z-2.5:
				if item.kind in [0,1,3]:
					safe_streak+=1;recover(50);message="Supply captured: +energy!"
				else: recover(60);message="Target cleared!";sfx("explode")
				explode(item.object.position)
				item.object.queue_free();debris.remove_at(j);pulse.life=0;break
		if pulse.life<=0: pulse.object.queue_free();pulses.remove_at(i)
	if route_time>=90: end(true)

func spawn_debris(kind: int, theta: float, z: float) -> void:
	var root := Node3D.new()
	root.position=Vector3(cos(theta)*5,sin(theta)*5,z)
	var model := ArcadeModels.asset(IDS[kind])
	model.position.y=-.8
	model.scale=Vector3.ONE*.85
	root.add_child(model)
	var halo := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius=.78;torus.outer_radius=.92;torus.rings=16;torus.ring_segments=6
	halo.mesh=torus
	halo.rotation.x=PI/2
	halo.material_override=ArcadeModels.material(Color("a8d788") if kind in [0,1,3] else Color("e99a75"),true)
	root.add_child(halo)
	track.add_child(root)
	ArcadeModels.animate(model)
	debris.append({"object":root,"kind":kind,"angle":theta})

func fire() -> void:
	if shot_clock>0 or pulses.size()>=16: return
	shot_clock=.24
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius=.18;shape.height=.9;shape.radial_segments=8;shape.rings=4
	mesh.mesh=shape;mesh.material_override=ArcadeModels.material(Color("c8e9a2"),true)
	mesh.rotation.x=PI/2
	mesh.position=Vector3(cos(angle)*5,sin(angle)*5,-7)
	track.add_child(mesh)
	pulses.append({"object":mesh,"angle":angle,"life":1.8})
	sfx("pulse")

func explode(pos: Vector3) -> void:
	var blast := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius=.4;shape.height=.8;shape.radial_segments=8;shape.rings=4
	blast.mesh=shape;blast.position=pos
	blast.material_override=ArcadeModels.material(Color("ffc064"),true)
	track.add_child(blast)
	var tween := create_tween()
	tween.tween_property(blast,"scale",Vector3.ONE*4,.18)
	tween.tween_callback(blast.queue_free)

func hurt(amount: int, text: String) -> void:
	if invulnerability>0: return
	invulnerability=.65
	damage(amount,text)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT):
		if not event.pressed: reset_input();return
		if event.position.y>525 and event.position.y<592:
			if event.position.x<430: virtual_turn=-1.0 if event.pressed else 0.0
			elif event.position.x>722: virtual_turn=1.0 if event.pressed else 0.0
			else: virtual_fire=event.pressed

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for data in [[Vector2(160,539),"< ROTATE"],[Vector2(490,539),"FIRE / SPACE"],[Vector2(819,539),"ROTATE >"]]:
		var rect := Rect2(data[0],Vector2(173,42))
		draw_rect(rect,Color(0.12,.24,.17,.8))
		draw_rect(rect,Color("81986a"),false,1)
		draw_string(font,rect.position+Vector2(20,27),data[1],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("edf0d2"))

func reset_input() -> void:
	virtual_turn=0;virtual_fire=false


