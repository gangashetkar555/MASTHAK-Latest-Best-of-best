extends Node

var enabled := false
var volume := 0.6
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var mode := ""
var effects: Array[AudioStreamPlayer] = []
var sounds := {}

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.stream = load("res://audio/arcade-loop.wav")
	if music.stream is AudioStreamWAV: music.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	music.volume_db = -16
	add_child(music)
	ambience=AudioStreamPlayer.new()
	ambience.stream=load("res://kenney/audio/engine.ogg")
	ambience.stream.loop=true
	ambience.volume_db=-22
	add_child(ambience)
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -8
		add_child(player)
		effects.append(player)
	for id in ["click","hover","coin","build","reload","bad","hit","explode","shot","pulse"]:
		sounds[id]=load("res://kenney/audio/"+id+".ogg")
	sounds.good=sounds.coin

func apply(on: bool, level: float) -> void:
	enabled = on
	volume = level
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(level, 0.001)))
	if on:
		if not music.playing: music.play()
		if mode=="tunnel" and not ambience.playing: ambience.play()
	else:
		music.stop()
		ambience.stop()
		for player in effects: player.stop()

func effect(id: String) -> void:
	if not enabled or not sounds.has(id): return
	for player in effects:
		if not player.playing:
			player.stream = sounds[id]
			player.pitch_scale=randf_range(.95,1.05) if id in ["shot","pulse","coin"] else 1.0
			player.play()
			return

func quiet(pause: bool) -> void:
	music.stream_paused = pause
	ambience.stream_paused=pause
	for player in effects: player.stream_paused = pause

func enter_mode(value: String) -> void:
	mode=value
	if mode!="tunnel": ambience.stop()
	music.pitch_scale=1.08 if mode=="tunnel" else .85 if mode=="shooter" else 1.0

