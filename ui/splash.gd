extends TextureRect

func _ready():
    if Global.check_token():
        Global.update_user_remote()
    else:
        get_tree().change_scene(Global.login_scene)
