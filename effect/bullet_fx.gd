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
    position=s_pos
    var bullet=get_node("Sprite")
    if bullet.visible==false:
        bullet=get_node("AnimatedSprite")
    if s_pos.x>e_pos.x:
        bullet.flip_h=true
    var dist=(s_pos-e_pos).length()
    var dist_y=e_pos.y-s_pos.y
    bullet.rotation_degrees=asin(dist_y/dist)*180/3.1415926
    if bullet.flip_h:
        bullet.rotation_degrees=-bullet.rotation_degrees
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

