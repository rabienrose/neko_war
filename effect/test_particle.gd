extends Node2D
var mgr
func _input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            var fx_file="res://anim_sprite/effect/impact.tres"
            var frame_data = load(fx_file)
            mgr.play_frame_fx(frame_data, "fx_1", Vector2(200,200))


func _ready():
    mgr=get_node("FxMgr")
    
