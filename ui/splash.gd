extends TextureRect

func start_with_account(email, pw):
	var succ = yield(Global.login_remote(email,"",pw,false), "completed") 
	if succ:
		Global.fetch_user_and_go_home()

func _ready():
	var cmds=OS.get_cmdline_args()
	if len(cmds)>=1:
		var email = cmds[0]
		var password = cmds[1]
		start_with_account(email, password)
	else:
		var ret= Global.check_token()
		if ret!=null:
			start_with_account(ret[0], ret[1])
		else:
			get_tree().change_scene(Global.login_scene)
