extends ArcadeMode

var mode := "conveyor"
var items: Array[Dictionary] = []
var stations: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var sheets: Array[Texture2D] = []
var spawn_clock := 1.0
var selected := 0
var dragged := -1
var pointer := Vector2(576,350)
var serial := 0
var cooldowns: Array[float] = [0,0,0,0,0,0,0,0]
var mowers := [true,true,true,true,true]
var wave_spawned := 0
var wave_count := 5
var energy_clock := 3.0
var tile := Vector2i(0,2)
var font: Font
var styles := {}
var shot_sound_clock := 0.0
const PACKETS := ["ENERGY", "COMPOST", "RECYCLE", "SPECIAL", "SHIELD", "SLOW", "BURST", "RESIDUAL", "SHOVEL"]
const COSTS := [50,100,100,125,50,150,150,125,0]
const RECHARGE := [4.0,2.0,2.0,3.0,3.0,6.0,10.0,3.0,0.0]
const GRID := Vector2(282,181)
const CELL := Vector2(88,74)

func _ready() -> void:
	super._ready()
	font = ThemeDB.fallback_font
	for id in IDS: sheets.append(load("res://assets/"+id+"-walk.png"))
	message = "Four destinations. Three chances. Press 1–4 or drag an item." if mode == "conveyor" else "Build a generator, then compost and recycling stations in the middle lane."
	spawn_clock = 1.0 if mode == "conveyor" else 10.0
	emit_hud()

func objective() -> String:
	return "RECOVERY SHIFT  /  %d of 2400 points  /  %d chances" % [score,ceili(health/34.0)] if mode == "conveyor" else "NEIGHBORHOOD %d / 5   ·   WAVE %d / 3   ·   Collect seeds before they fade" % [stage,wave]

func _physics_process(delta: float) -> void:
	if stopped: return
	var dt := tick(delta)
	shot_sound_clock=maxf(0,shot_sound_clock-dt)
	spawn_clock -= dt
	if mode == "conveyor": update_belt(dt)
	else: update_defense(dt)
	for p in particles:
		p.life -= dt
		p.position.y -= dt*35
	particles = particles.filter(func(p): return p.life>0)
	queue_redraw()

func update_belt(dt: float) -> void:
	stage = 1 + mini(5,score/500)
	var speed := (64.0 + (stage-1)*8)*difficulty
	if spawn_clock<=0 and items.size()<12:
		items.append({"id":serial,"kind":serial%6,"position":Vector2(560+rng.randf_range(-45,45),112.0)})
		serial += 1
		spawn_clock = maxf(.85,1.9-(stage-1)*.13)/difficulty
	for i in range(items.size()-1,-1,-1):
		if items[i].id == dragged: continue
		items[i].position.y += speed*dt
		if items[i].position.y>500:
			damage(34,"MISSED: "+IDS[items[i].kind]+" needs "+STREAMS[CATEGORIES[items[i].kind]])
			items.remove_at(i)
			if stopped: break

func sort_item(id: int, destination: int) -> void:
	if stopped: return
	for i in range(items.size()):
		if items[i].id != id: continue
		var item: Dictionary = items[i]
		if CATEGORIES[item.kind] == destination:
			message = IDS[item.kind].capitalize()+" > "+STREAMS[destination]+". A better future."
			recover()
			pop(item.position,"+100",COLORS[destination])
		else:
			damage(34,"OBJECTION! "+IDS[item.kind]+" belongs in "+STREAMS[CATEGORIES[item.kind]])
			pop(item.position,"OBJECTION",Color("e99c79"))
		items.remove_at(i)
		dragged = -1
		if score>=2400: end(true)
		return

func allowed_lanes() -> Array:
	return [2] if stage==1 else [1,2,3] if stage==2 else [0,1,2,3,4]

func update_defense(dt: float) -> void:
	for i in range(8): cooldowns[i] = maxf(0,cooldowns[i]-dt)
	energy_clock -= dt
	if energy_clock<=0:
		drops.append({"position":Vector2(rng.randf_range(315,1000),160),"target":rng.randf_range(230,480),"life":11.0})
		energy_clock = 7.0
	for drop in drops:
		drop.position.y = minf(drop.target,drop.position.y+60*dt)
		drop.life -= dt
	drops = drops.filter(func(d): return d.life>0)
	if spawn_clock<=0 and wave_spawned<wave_count and items.size()<20:
		var lanes := allowed_lanes()
		var lane: int = lanes[wave_spawned%lanes.size()]
		var types := [0,3] if stage<3 else [0,3,1,5,4,2]
		var kind: int = types[wave_spawned%types.size()]
		items.append({"id":serial,"kind":kind,"lane":lane,"position":Vector2(1120,GRID.y+lane*CELL.y+37),"hp":160.0 if kind==4 else 80.0+stage*8,"max_hp":160.0 if kind==4 else 80.0+stage*8,"attack":0.0,"slow":0.0})
		serial+=1; wave_spawned+=1
		spawn_clock = maxf(1.6,5.6-stage*.45)/difficulty
	for station in stations:
		station.cool -= dt
		if station.type == 0 and station.cool<=0:
			drops.append({"position":station.position+Vector2(18,-25),"target":station.position.y+8,"life":11.0})
			station.cool=8.0
		elif station.type not in [0,4] and station.cool<=0:
			var ahead := items.any(func(it): return it.lane==station.lane and it.position.x>station.position.x)
			if ahead and shots.size()<72:
				shots.append({"position":station.position+Vector2(25,0),"lane":station.lane,"type":station.type})
				if shot_sound_clock<=0: sfx("pulse");shot_sound_clock=.15
				station.cool=1.15 if station.type!=5 else 2.0
	for i in range(shots.size()-1,-1,-1):
		var shot: Dictionary = shots[i]
		shot.position.x+=340*dt
		var hit := false
		for enemy in items:
			if enemy.lane==shot.lane and absf(enemy.position.x-shot.position.x)<26:
				var category: int = CATEGORIES[enemy.kind]
				var valid: bool = shot.type==5 or (shot.type==1 and category==0) or (shot.type==2 and category==1) or (shot.type==3 and category==3) or (shot.type==7 and category==2)
				if valid:
					enemy.hp-=35 if shot.type!=3 else 55
					if shot.type==5: enemy.slow=4.0
				else: message="Match the station: "+IDS[enemy.kind]+" needs "+STREAMS[category]
				hit=true
				break
		if hit or shot.position.x>1128: shots.remove_at(i)
	for i in range(items.size()-1,-1,-1):
		var enemy: Dictionary = items[i]
		if enemy.hp<=0:
			recover();pop(enemy.position,"RECOVERED",COLORS[CATEGORIES[enemy.kind]])
			items.remove_at(i)
			continue
		enemy.slow=maxf(0,enemy.slow-dt)
		var target: Dictionary = {}
		for station in stations:
			if station.lane==enemy.lane and absf(station.position.x-enemy.position.x)<38: target=station;break
		if target:
			enemy.attack-=dt
			if enemy.attack<=0:
				target.hp-=20
				enemy.attack=.8
				if target.hp<=0: stations.erase(target)
		else:
			enemy.position.x-=dt*(13+stage*2.0)*difficulty*(.5 if enemy.slow>0 else 1.0)
		if enemy.position.x<245:
			if mowers[enemy.lane]:
				mowers[enemy.lane]=false
				for other in items:
					if other.lane==enemy.lane: other.hp=0
				message="Emergency lane rescue used. This lane has no second rescue."
			else:
				damage(20,"Waste breached the neighborhood.")
				items.remove_at(i)
				if stopped: break
	if wave_spawned>=wave_count and items.is_empty() and not stopped:
		if wave<3: wave+=1;energy+=75
		elif stage<5: stage+=1;wave=1;energy+=200
		else: end(true);return
		wave_spawned=0;wave_count=4+stage+wave;spawn_clock=9.0
		message="NEXT WAVE: prepare your active lanes." if wave<3 else "FINAL WAVE OF THIS STAGE!"
		emit_hud()

func place_station(cell: Vector2i) -> void:
	if stopped or cell.x<0 or cell.x>8 or not allowed_lanes().has(cell.y): return
	for station in stations:
		if station.cell==cell:
			if selected==8: stations.erase(station);message="Station cleared.";sfx("build")
			else: message="Occupied tile. Select Shovel to remove a station."
			return
	if selected==8: return
	if selected>2 and stage<3: message="This packet unlocks in stage 3.";return
	if energy<COSTS[selected] or cooldowns[selected]>0: message="Collect energy or wait for the packet to recharge.";return
	energy-=COSTS[selected]
	cooldowns[selected]=RECHARGE[selected]
	var pos := GRID+Vector2(cell)*CELL+CELL*.5
	if selected==6:
		for enemy in items:
			if enemy.position.distance_to(pos)<160: enemy.hp=0
		pop(pos,"CLEANUP",Color("efcf86"))
	else: stations.append({"cell":cell,"lane":cell.y,"position":pos,"type":selected,"hp":550.0 if selected==4 else 180.0,"max_hp":550.0 if selected==4 else 180.0,"cool":2.0})
	message=PACKETS[selected]+" station planted."
	sfx("build")
	emit_hud()

func pop(pos: Vector2, text: String, color: Color) -> void:
	if particles.size()<24: particles.append({"position":pos,"text":text,"color":color,"life":1.0})

func _unhandled_input(event: InputEvent) -> void:
	if stopped: return
	if event is InputEventKey and event.pressed and not event.echo:
		if mode=="conveyor" and event.keycode>=KEY_1 and event.keycode<=KEY_4:
			if not items.is_empty():
				var oldest: Dictionary = items[0]
				for item in items:
					if item.position.y>oldest.position.y: oldest=item
				sort_item(oldest.id,event.keycode-KEY_1)
		elif mode=="defense":
			if event.keycode>=KEY_1 and event.keycode<=KEY_9: selected=event.keycode-KEY_1
			elif event.keycode==KEY_C:
				energy+=drops.size()*25;drops.clear();sfx("good")
			elif event.keycode==KEY_ENTER: place_station(tile)
			elif event.keycode==KEY_LEFT: tile.x=maxi(0,tile.x-1)
			elif event.keycode==KEY_RIGHT: tile.x=mini(8,tile.x+1)
			elif event.keycode==KEY_UP: tile.y=maxi(0,tile.y-1)
			elif event.keycode==KEY_DOWN: tile.y=mini(4,tile.y+1)
	if event is InputEventMouseMotion:
		pointer=event.position
		if dragged>=0:
			for item in items:
				if item.id==dragged: item.position=pointer
	if event is InputEventScreenDrag:
		pointer=event.position
		for item in items:
			if item.id==dragged: item.position=pointer
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT: interact(event.position,event.pressed)
	if event is InputEventScreenTouch: interact(event.position,event.pressed)

func interact(pos: Vector2, down: bool) -> void:
	pointer=pos
	if mode=="conveyor":
		if down:
			for item in items:
				if item.position.distance_to(pos)<43: dragged=item.id;return
			for b in range(4):
				if bin_rect(b).has_point(pos) and not items.is_empty(): sort_item(items[0].id,b);return
		elif dragged>=0:
			for b in range(4):
				if bin_rect(b).has_point(pos): sort_item(dragged,b);return
			for item in items:
				if item.id==dragged: item.position=Vector2(560,clampf(pos.y,120,460))
			dragged=-1
	elif down:
		for i in range(9):
			if Rect2(25+i*124,110,116,58).has_point(pos): selected=i;return
		for drop in drops:
			if drop.position.distance_to(pos)<31:
				energy+=25;drops.erase(drop);sfx("coin");pop(pos,"+25",Color("ffe083"));emit_hud();return
		if not Rect2(GRID,CELL*Vector2(9,5)).has_point(pos): return
		tile=Vector2i((pos-GRID)/CELL)
		place_station(tile)

func reset_input() -> void:
	for item in items:
		if item.id==dragged: item.position=Vector2(560,clampf(item.position.y,120,460))
	dragged=-1

func bin_rect(index: int) -> Rect2:
	return Rect2(192+index*204,513,186,74)

func sprite(kind: int, pos: Vector2, height: float, pose := 0) -> void:
	var texture: Texture2D = sheets[kind]
	var cell := Vector2(160,192)
	var frame := int(elapsed*10+kind*2)%8 if not reduced_motion else 0
	var src := Rect2(Vector2(frame*160,0),cell)
	var width := height*cell.x/cell.y
	draw_texture_rect_region(texture,Rect2(pos-Vector2(width/2,height/2),Vector2(width,height)),src)

func text(value: String, pos: Vector2, color := Color("eff0da"), size := 16) -> void:
	draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func box_style(color: Color, radius := 10) -> StyleBoxFlat:
	var key := color.to_html()+str(radius)
	if styles.has(key): return styles[key]
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(mini(radius,4))
	styles[key]=style
	return style

func _draw() -> void:
	if font==null: return
	draw_rect(Rect2(0,0,1152,648),Color("e7e4cf") if mode=="defense" else Color("20382e"))
	if mode=="conveyor": draw_belt()
	else: draw_lawn()
	for p in particles: text(p.text,p.position,p.color*Color(1,1,1,p.life),20)

func draw_belt() -> void:
	draw_style_box(box_style(Color("10261c"),18),Rect2(376,98,368,407))
	draw_rect(Rect2(400,98,320,407),Color("405844"))
	for i in range(12):
		var y := 103+fmod(i*38+elapsed*(64+(stage-1)*8)*difficulty,400)
		draw_rect(Rect2(411,y,298,5),Color("789070"))
	for x in [384,732]:
		for y in range(117,501,42): draw_circle(Vector2(x,y),5,Color("9aab80"))
	text("MATERIAL RECOVERY",Vector2(44,179),Color("c6d6b0"),22)
	text("SHIFT  %02d"%stage,Vector2(44,220),Color("efdcac"),34)
	text("1  COMPOST",Vector2(44,281),COLORS[0],18)
	text("2  RECYCLING",Vector2(44,319),COLORS[1],18)
	text("3  RESIDUAL",Vector2(44,357),COLORS[2],18)
	text("4  SPECIAL",Vector2(44,395),COLORS[3],18)
	sprite(2,Vector2(926,300),235,7 if health<70 else 0)
	text("THREE CHANCES",Vector2(820,467),Color("d9c89b"),18)
	for i in range(3): draw_circle(Vector2(838+i*55,434),12,Color("bad48b") if i<ceili(health/34.0) else Color("53634b"))
	for b in range(4):
		var rect := bin_rect(b)
		draw_style_box(box_style(COLORS[b],12),rect)
		draw_rect(Rect2(rect.position+Vector2(12,8),Vector2(rect.size.x-24,9)),Color("364b37"))
		text(str(b+1)+"  "+STREAMS[b],rect.position+Vector2(13,53),Color("26392b"),18)
	for item in items:
		draw_circle(item.position+Vector2(0,27),28,Color(0.02,.08,.03,.24))
		sprite(item.kind,item.position,86,0)
		if item.id==dragged: draw_arc(item.position,44,0,TAU,30,Color("ffe4a1"),3)

func draw_lawn() -> void:
	for i in range(9):
		var rect := Rect2(25+i*124,110,116,58)
		var enabled: bool = i==8 or (energy>=COSTS[i] and cooldowns[i]<=0 and (i<3 or stage>=3))
		draw_style_box(box_style(Color("456342") if selected==i else Color("d1d5b9"),8),rect)
		var col := Color("fff0c4") if selected==i else Color("2a422e")
		text(str(i+1)+" "+PACKETS[i],rect.position+Vector2(9,22),col,13)
		text("STAGE 3" if i>2 and i<8 and stage<3 else str(ceili(cooldowns[i]))+"s" if i<8 and cooldowns[i]>0 else str(COSTS[i])+" ENERGY" if i<8 else "REMOVE",rect.position+Vector2(9,44),col,12)
		if not enabled: draw_rect(rect,Color(0.85,.88,.77,.24))
	for lane in range(5):
		var active := allowed_lanes().has(lane)
		for col in range(9):
			var rect := Rect2(GRID+Vector2(col,lane)*CELL,CELL-Vector2(2,2))
			draw_rect(rect,Color("88a56b") if active and (col+lane)%2==0 else Color("94ad73") if active else Color("bbc5a3"))
			if active:
				for p in range(3):
					var pos := rect.position+Vector2(10+p*26,56-(col*7+lane*13+p*19)%37)
					draw_line(pos,pos+Vector2(-2,-5),Color("779659"),1)
		if mowers[lane]:
			draw_style_box(box_style(Color("506b48"),8),Rect2(236,GRID.y+lane*CELL.y+19,34,35))
	text("MAYA’S",Vector2(36,301),Color("4b6541"),27)
	text("HOME",Vector2(36,339),Color("4b6541"),27)
	sprite(1,Vector2(127,425),159,11)
	for station in stations:
		var kind := 1 if station.type==0 else 3 if station.type==2 else 2 if station.type==4 else 0
		draw_circle(station.position+Vector2(0,23),24,Color("557c42"))
		sprite(kind,station.position,65,1)
		draw_rect(Rect2(station.position+Vector2(-24,-35),Vector2(48,4)),Color("253d28"))
		draw_rect(Rect2(station.position+Vector2(-24,-35),Vector2(48*station.hp/station.max_hp,4)),Color("eff0b6"))
		text(PACKETS[station.type],station.position+Vector2(-26,32),Color("213722"),9)
	for enemy in items:
		sprite(enemy.kind,enemy.position,70,3+int(elapsed*4)%2 if not reduced_motion else 0)
		draw_rect(Rect2(enemy.position+Vector2(-21,-38),Vector2(42*enemy.hp/enemy.max_hp,4)),Color("b26342"))
	for shot in shots: draw_circle(shot.position,6,COLORS[mini(shot.type-1,3)])
	for drop in drops:
		draw_circle(drop.position,21,Color("f2d583"));draw_circle(drop.position,15,Color("ffe9a6"));text("25",drop.position+Vector2(-10,6),Color("63542a"),16)
	if tile.y>=0 and tile.y<5 and tile.x>=0 and tile.x<9: draw_rect(Rect2(GRID+Vector2(tile)*CELL,CELL-Vector2(2,2)),Color("fff2b8"),false,3)

