extends AnimatedSprite

func _ready():
	pass # Replace with function body.


func _on_SelfDestroyFx_animation_finished():
	queue_free()
