extends Node2D
var mgr
func _input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            var res_info={"type":"frame","res":"0215","anim":"lightning"}
            mgr.play_frame_link(res_info, Vector2(0,0), Vector2(300,0))

func _ready():
    mgr=get_node("FxMgr")
    
