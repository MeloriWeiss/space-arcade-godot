extends Area2D

@export var bullet_scene : PackedScene
@export var speed = 150
@export var rotation_speed = 120
@export var health = randi_range(2, 4)
@export var bullet_spread = 0.3

signal exploded

var follow = PathFollow2D.new()
var target = null


func _ready() -> void:
	$Sprite2D.frame = randi_range(0, 2)
	var path = $EnemyPaths.get_children()[randi_range(0, 3)]
	path.add_child(follow)
	follow.loop = false
	position = follow.position


func _process(delta: float) -> void:
	pass
	
func _physics_process(delta):
	rotation += deg_to_rad(rotation_speed) * delta
	follow.progress += speed * delta
	position = follow.position
	if follow.progress_ratio >= 1:
		queue_free()

func shoot():
	var dir = global_position.direction_to(target.global_position)
	dir = dir.rotated(randf_range(-bullet_spread, bullet_spread))
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(global_position, dir)
	$ShootSound.play()

func shoot_pulse(n, delay):
	for i in n:
		shoot()
		await get_tree().create_timer(delay).timeout

func _on_gun_cooldown_timeout() -> void:
	shoot_pulse(3, 0.15)

func take_damage(amount):
	health -= amount
	$AnimationPlayer.play("flash")
	if health <= 0:
		explode()

func explode():
	speed = 0
	$GunCooldown.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	$ExplosionSound.play()
	exploded.emit()
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Rocks"): return
	explode()
	body.shield -= 50
