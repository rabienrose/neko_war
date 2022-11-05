extends TextureRect

func _ready():
	var cmds=OS.get_cmdline_args()
	if len(cmds)>=1:
		if cmds[0]=="server":
			Global.rng.randomize()
			get_tree().change_scene(Global.game_scene)
	else:
		if Global.check_token():
			Global.fetch_user_remote()
		else:
			get_tree().change_scene(Global.login_scene)
