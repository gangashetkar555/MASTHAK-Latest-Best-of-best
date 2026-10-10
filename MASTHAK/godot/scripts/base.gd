class_name ArcadeMode
extends Node2D

signal hud_changed(data: Dictionary)
signal finished(won: bool, score: int)
var score := 0
var health := 100
var energy := 175
var stage := 1
var wave := 1
var elapsed := 0.0
var stopped := false
var difficulty := 1.0
var reduced_motion := false
var message := "Give every material a better future."
var rng := RandomNumberGenerator.new()
var audio: Node
const IDS := ["banana", "leaf", "judge", "bottle", "battery", "wrapper"]
const CATEGORIES := [0, 0, 1, 1, 3, 2]
const STREAMS := ["COMPOST", "RECYCLING", "RESIDUAL", "SPECIAL"]
const COLORS := [Color("a3cf7b"), Color("7abed2"), Color("d1ac75"), Color("e29b7d")]
var report_clock := 0.0

func _ready() -> void:
	rng.randomize()

func configure(options: Dictionary) -> void:
	difficulty = options.get("difficulty", 1.0)
	reduced_motion = options.get("reduced_motion", false)
	audio = options.get("audio")

func tick(delta: float) -> float:
	var dt := minf(delta, 0.05)
	elapsed += dt
	report_clock += dt
	if report_clock > 0.1:
		report_clock = 0.0
		emit_hud()
	return dt

func emit_hud() -> void:
	hud_changed.emit({"score":score, "health":health, "energy":energy, "stage":stage, "wave":wave, "message":message, "progress":objective()})

func objective() -> String:
	return ""

func damage(amount: int, text: String) -> void:
	if stopped: return
	health = maxi(0, health - amount)
	message = text
	sfx("bad")
	if health == 0: end(false)
	emit_hud()

func recover(points: int = 100) -> void:
	if stopped: return
	score += points
	sfx("good")
	emit_hud()

func sfx(kind: String) -> void:
	if is_instance_valid(audio): audio.effect(kind)

func end(won: bool) -> void:
	if stopped: return
	stopped = true
	finished.emit(won, score)

func circular_distance(a: float, b: float) -> float:
	return absf(wrapf(a-b, -PI, PI))

