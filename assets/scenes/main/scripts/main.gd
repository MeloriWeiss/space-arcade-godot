extends Node2D

@export var rock_scene : PackedScene
var screensize = Vector2.ZERO

var level = 0
var score = 0
var playing = false


func _ready() -> void:
	screensize = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	if not playing: return
	
	if get_tree().get_nodes_in_group("Rocks").size() == 0:
		new_level()

func new_game():
	get_tree().call_group("Rocks", "queue_free")
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Player.reset()
	await $HUD/Timer.timeout
	playing = true

func new_level():
	level += 1
	$Player.fire_rate -= 0.03
	
	var lives = $Player.lives
	if lives < 3:
		$Player.set_lives(lives + 1, false)
	
	$HUD.show_message("Level %s" % level)
	for i in level:
		spawn_rock(3)

func spawn_rock(size, pos=null, vel=null):
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	
	var r = rock_scene.instantiate()
	
	r.screensize = screensize
	r.exploded.connect(self._on_rock_exploded)
	r.start(pos, vel, size)
	
	call_deferred("add_child", r)

func _on_rock_exploded(size, radius, pos, vel):
	score += 10 * size
	$HUD.update_score(score)
	
	if size <= 1: return
	
	for offset in [-1, 1]:
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newvel)

func game_over():
	playing = false
	$HUD.game_over()
