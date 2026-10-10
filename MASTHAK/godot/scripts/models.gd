class_name ArcadeModels
extends RefCounted

static var resources := {}
static var materials := {}

static func animate(root: Node, speed := 1.0) -> void:
	for child in root.find_children("*","AnimationPlayer",true,false):
		var names = child.get_animation_list()
		for clip in names:
			if clip == "RESET": continue
			var animation = child.get_animation(clip)
			animation.loop_mode=Animation.LOOP_LINEAR
			child.play(clip,-1,speed)
			break

static func textured(name: String, tint := Color.WHITE, uv := Vector3.ONE) -> StandardMaterial3D:
	var key := name+tint.to_html()+str(uv)
	if not materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture=load("res://kenney/textures/"+name+".png")
		mat.albedo_color=tint
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		mat.uv1_scale=uv
		mat.roughness=1.0
		materials[key]=mat
	return materials[key]

static func coat(root: Node, mat: Material) -> void:
	for child in root.get_children():
		if child is MeshInstance3D: child.material_override=mat

static func asset(id: String) -> Node3D:
	if not resources.has(id): resources[id]=load("res://assets/"+id+".glb")
	return resources[id].instantiate()

static func material(color: Color, unlit := false) -> StandardMaterial3D:
	var key := color.to_html()+str(unlit)
	if not materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color=color
		mat.roughness=1.0
		if unlit: mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		materials[key]=mat
	return materials[key]

static func box(parent: Node, pos: Vector3, size: Vector3, color: Color, collision := false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.position=pos
	parent.add_child(root)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size=size
	mesh.mesh=shape
	mesh.material_override=material(color)
	root.add_child(mesh)
	if collision:
		var collider := CollisionShape3D.new()
		var form := BoxShape3D.new()
		form.size=size
		collider.shape=form
		root.add_child(collider)
	return root

static func environment(parent: Node3D, background: Color) -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=background
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("f4e8c9")
	env.ambient_light_energy=.5
	world.environment=env
	parent.add_child(world)
	var light := DirectionalLight3D.new()
	light.light_color=Color("fff0d6")
	light.light_energy=1.1
	light.rotation_degrees=Vector3(-48,-35,0)
	light.shadow_enabled=false
	parent.add_child(light)

static func sign(parent: Node3D, value: String, pos: Vector3, color := Color("f5e9c7")) -> Label3D:
	var node := Label3D.new()
	node.text=value
	node.position=pos
	node.font_size=48
	node.pixel_size=.008
	node.modulate=color
	node.outline_size=6
	node.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(node)
	return node


