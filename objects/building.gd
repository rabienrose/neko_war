extends Character

class_name Building

func on_die(_chara):
	.on_die(_chara)
	if is_master:
		game.stop_game(false)
	else:
		game.stop_game(true)
