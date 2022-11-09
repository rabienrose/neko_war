extends TextureRect

func _ready():
	var cmds=OS.get_cmdline_args()
	if len(cmds)>=1:
		if cmds[0]=="server":
			Global.rng.randomize()
			get_tree().change_scene(Global.game_scene)
	else:
		var ret= Global.check_token()
		if ret!=null:
			Global.login_remote(ret[0],"",ret[1],false)
		else:
			get_tree().change_scene(Global.login_scene)
