extends CanvasLayer

signal start_game

@onready var lives_counter = $MarginContainer/HBoxContainer/LivesCounter.get_children()
@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var message = $VBoxContainer/Message
@onready var start_button = $VBoxContainer/StartButton
@onready var shield_bar = $MarginContainer/HBoxContainer/ShieldBar
@onready var heart_shield = $MarginContainer/HBoxContainer/MarginContainer/TextureRect

func _ready() -> void:
	hide_game_hud_elements()

func show_message(text):
	message.text = text
	message.show()
	$Timer.start()

func update_score(value):
	score_label.text = str(value)

func update_lives(value):
	for item in 3:
		lives_counter[item].visible = value > item

func game_over():
	hide_game_hud_elements()
	
	show_message("Game Over")
	await $Timer.timeout
	start_button.show()


func update_shield(value):
	shield_bar.tint_progress = Color.WHITE
	
	if value > 0.7:
		shield_bar.tint_progress = Color.GREEN
	if value < 0.3:
		shield_bar.tint_progress = Color.RED

	shield_bar.value = value

func _on_start_button_pressed() -> void:
	shield_bar.show()
	heart_shield.show()
	
	start_button.hide()
	start_game.emit()

func hide_game_hud_elements():
	shield_bar.hide()
	heart_shield.hide()

func _on_timer_timeout() -> void:
	message.hide()
	message.text = ""
