extends Area2D

@export var speed = 1000

var velocity = Vector2.ZERO


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	position += velocity * delta


func start(_transform):
	transform = _transform
	velocity = transform.x * speed


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Rocks"):
		body.explode()
		queue_free()
