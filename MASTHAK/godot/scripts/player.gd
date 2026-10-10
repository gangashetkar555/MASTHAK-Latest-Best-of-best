extends CharacterBody3D

var camera: Camera3D
var tool: Node3D
var pitch := 0.0
var fire_pressed := false
var walk_time := 0.0
var reduced_motion := false
var sensitivity := .0024
var muzzle: MeshInstance3D
var recoil := 0.0
var reloading := false
var ignore_first_motion := true
var capture_attempted := false

func _ready() -> void:
	collision_layer=4
	collision_mask=3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=.3;capsule.height=1.7
	shape.shape=capsule
	shape.position.y=.85
	add_child(shape)
	camera=Camera3D.new()
	camera.position.y=1.5
	camera.fov=82
	camera.near=.06
	camera.far=75
	add_child(camera)
	camera.make_current()
	tool=ArcadeModels.asset("tool")
	tool.position=Vector3(.35,-.3,-.65)
	tool.scale=Vector3.ONE*.55
	tool.rotation.y=PI
	camera.add_child(tool)
	muzzle=MeshInstance3D.new()
	var flash := SphereMesh.new()
	flash.radius=.09;flash.height=.18;flash.radial_segments=8;flash.rings=4
	muzzle.mesh=flash
	muzzle.material_override=ArcadeModels.material(Color("ffb24a"),true)
	muzzle.position=Vector3(.35,-.28,-1.0)
	camera.add_child(muzzle)
	muzzle.visible=false

func _physics_process(delta: float) -> void:
	var dt := minf(delta,.05)
	var axis := Input.get_vector("left","right","forward","back")
	var direction := (transform.basis*Vector3(axis.x,0,axis.y)).normalized()
	velocity.x=move_toward(velocity.x,direction.x*5.2,28*dt)
	velocity.z=move_toward(velocity.z,direction.z*5.2,28*dt)
	if not is_on_floor(): velocity.y-=18*dt
	elif Input.is_action_just_pressed("jump"): velocity.y=6
	if Input.is_physical_key_pressed(KEY_LEFT): rotation.y+=dt*1.8
	if Input.is_physical_key_pressed(KEY_RIGHT): rotation.y-=dt*1.8
	move_and_slide()
	walk_time+=dt
	if not reduced_motion:
		camera.position.y=1.5+sin(walk_time*11)*.015*axis.length()
	tool.position.y=lerpf(tool.position.y,-.3,dt*9)
	recoil=maxf(0,recoil-dt)
	muzzle.visible=recoil>0
	tool.position.z=lerpf(tool.position.z,-.65,dt*14)
	tool.rotation.x=lerpf(tool.rotation.x,.7 if reloading else 0.0,dt*8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if ignore_first_motion:
			ignore_first_motion=false
			return
		rotation.y-=event.screen_relative.x*sensitivity
		pitch=clampf(pitch-event.screen_relative.y*sensitivity,-1.1,1.1)
		camera.rotation.x=pitch
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		fire_pressed=event.pressed
		if event.pressed and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and not capture_attempted:
			capture_attempted=true
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func reset_input() -> void:
	fire_pressed=false
	ignore_first_motion=true
	capture_attempted=false

func kick() -> void:
	recoil=.07
	tool.position.z=-.5
	tool.position.y=-.25


