extends Node2D

signal finish_play

var b_play=false
var remain_time=0
var total_time=0
var s_pos
var e_pos
var bullet_spd=900

func play(_s_pos, _e_pos):
    s_pos=_s_pos
    e_pos=_e_pos
    var bullet=get_node("Sprite")
    if s_pos.x>e_pos.x:
        bullet.flip_h=true
    var dist=(s_pos-e_pos).length()
    total_time=dist/bullet_spd
    remain_time=total_time
    b_play=true

func _physics_process(delta):
    if b_play:
        remain_time=remain_time-delta
        position=(e_pos - s_pos)*(1-remain_time/total_time)+s_pos
        if remain_time<0:
            emit_signal("finish_play")
            queue_free()

func _ready():
    pass # Replace with function body.

