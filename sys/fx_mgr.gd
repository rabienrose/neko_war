extends Node2D

export (Resource) var coin_fx_res
export (Resource) var frame_fx_res

var effect_root="res://anim_sprite/effect/"

var gc_countdown=5

func play_coin_fx(coin_num, posi):
    var fx = coin_fx_res.instance()
    fx.position=posi
    add_child(fx)
    fx.emitting=true

func play_frame_fx(res_name, anim_name,posi):
    var fx_file=effect_root+res_name+".tres"
    var frame_data = load(fx_file)
    var fx = frame_fx_res.instance()
    var r_x = rand_range(-10,10)
    var r_y = rand_range(-10,10)
    fx.frames=frame_data
    fx.position=posi+Vector2(r_x, r_y)
    fx.animation=anim_name
    add_child(fx)
    fx.play()

func _process(delta):
    gc_countdown=gc_countdown-delta
    if gc_countdown<0:
        for c in get_children():
            if c is Particles2D and c.emitting==false:
                c.queue_free()
                # remove_child(c)
        gc_countdown=5

