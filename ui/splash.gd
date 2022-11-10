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
			var succ = yield(Global.login_remote(ret[0],"",ret[1],false), "completed") 
			if succ:
				Global.fetch_user_and_go_home()
		else:
			get_tree().change_scene(Global.login_scene)
