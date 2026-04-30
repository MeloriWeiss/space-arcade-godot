extends RigidBody2D

@export var engine_power = 500
@export var spin_power = 16000

@export var bullet_scene : PackedScene
@export var fire_rate = 0.53: set = set_fire_rate
var can_shoot = true
var can_play = false

@export var max_shield = 100.0
@export var shield_regen = 5.0
signal shield_changed
var shield = 0: set = set_shield

signal lives_changed
signal dead

var reset_pos = false

var _lives = 0
var lives:
	get:
		return _lives
	set(value):
		set_lives(value)

var thrust = Vector2.ZERO
var rotation_dir = 0

enum { INIT, ALIVE, INVULNERABLE, DEAD }
var state = INIT

var screensize = Vector2.ZERO

func _ready() -> void:
	$Sprite2D.hide()
	
	screensize = get_viewport_rect().size
	change_state(ALIVE)
	$GunCooldown.wait_time = fire_rate


func _process(delta):
	if not can_play: return
	
	shield += shield_regen * delta
	get_input()


func get_input():
	$Exhaust.emitting = false
	thrust = Vector2.ZERO
	
	if state in [DEAD, INIT]: return
	
	if Input.is_action_pressed("thrust"):
		$Exhaust.emitting = true
		thrust = transform.x * engine_power
		if not $EngineSound.playing:
			$EngineSound.play()
	else:
		$EngineSound.stop()
	
	if Input.is_action_pressed("shoot"):
		shoot()
	
	rotation_dir = Input.get_axis("rotate_left", "rotate_right")

func _physics_process(delta):
	constant_force = thrust
	constant_torque = rotation_dir * spin_power

func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false

func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			collision_layer = 1
			collision_mask = 1
			$Sprite2D.modulate.a = 1.0
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", false)
			collision_layer = 0
			collision_mask = 0
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			$EngineSound.stop()
			linear_velocity = Vector2.ZERO
			dead.emit()
	state = new_state

func shoot():
	if state == INVULNERABLE or can_shoot == false: return
	
	can_shoot = false
	$GunCooldown.start()
	$LaserSound.play()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)


func _on_gun_cooldown_timeout() -> void:
	can_shoot = true

func set_lives(value, has_invulnerable = true):
	_lives = value
	lives_changed.emit(_lives)
	shield = max_shield
	
	if _lives <= 0:
		change_state(DEAD)
	else:
		if not has_invulnerable: return
		change_state(INVULNERABLE)

func reset():
	reset_pos = true
	$Sprite2D.show()
	can_play = true
	lives = 3
	change_state(ALIVE)


func _on_invulnerability_timer_timeout() -> void:
	change_state(ALIVE)


func _on_body_entered(body):
	if state == INVULNERABLE: return
	
	if body.is_in_group("Rocks"):
		shield -= body.size * 25
		body.explode()

func explode():
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()

func set_fire_rate(value):
	if value < 0.001:
		fire_rate = 0.001
		$GunCooldown.wait_time = fire_rate
	else:
		fire_rate = value
		$GunCooldown.wait_time = fire_rate


func set_shield(value):
	value = min(value, max_shield)
	shield = value
	shield_changed.emit(shield / max_shield)
	
	if shield <= 0:
		lives -= 1
		explode()
