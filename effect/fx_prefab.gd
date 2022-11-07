extends Node2D

func play():
	get_node("AnimatedSprite").frame=0
	get_node("AnimatedSprite").play()

func _ready():
	pass # Replace with function body.

func _on_AnimatedSprite_animation_finished():
	queue_free()
