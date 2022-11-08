extends Node2D

export (Resource) var coin_fx_res
export (Resource) var frame_fx_res

var frame_root="res://anim_sprite/effect/"
var prefab_root="res://effect/"

var link_frame_spd=900

var gc_countdown=5

func play_coin_fx(coin_num, posi):
    var fx = coin_fx_res.instance()
    fx.position=posi
    add_child(fx)
    fx.emitting=true

func play_bullet(res_info, s_pos, e_pos):
    var fx_file=prefab_root+res_info["res"]+".tscn"
    var fx_prefab = load(fx_file).instance()
    add_child(fx_prefab)
    fx_prefab.play(s_pos, e_pos)
    return fx_prefab

func play_frame_link(res_info, s_pos, e_pos):
    var res_name=res_info["res"]
    var anim_name=res_info["anim"]
    var fx_file=frame_root+res_name+".tres"
    var frame_data = load(fx_file)
    var fx = frame_fx_res.instance()
    var img_size = frame_data.get_frame(anim_name,0).get_size()
    var frame_num=frame_data.get_frame_count(anim_name)
    var fx_long=e_pos.x - s_pos.x
    var dura=fx_long/link_frame_spd
    var fps=frame_num/dura
    var speed_scale=fps/10
    var scale_rate=fx_long/img_size.x
    fx.speed_scale=speed_scale
    fx.scale.x=scale_rate
    fx.centered=false
    fx.frames=frame_data
    fx.position=Vector2(s_pos.x,s_pos.y-img_size.y/2)
    fx.animation=anim_name
    add_child(fx)
    fx.play()
    return dura


func play_frame_fx(res_info, posi):
    var res_name=res_info["res"]
    var res_type=res_info["type"]
    if res_type=="frame":
        var anim_name=res_info["anim"]
        var fx_file=frame_root+res_name+".tres"
        var frame_data = load(fx_file)
        var fx = frame_fx_res.instance()
        var r_x = rand_range(-10,10)
        var r_y = rand_range(-10,10)
        fx.frames=frame_data
        fx.position=posi+Vector2(r_x, r_y)
        fx.animation=anim_name
        add_child(fx)
        fx.play()
        fx.z_index=2000
    elif res_type=="prefab":
        var fx_file=prefab_root+res_name+".tscn"
        var fx_prefab = load(fx_file).instance()
        add_child(fx_prefab)
        fx_prefab.position=posi
        fx_prefab.play()

func _process(delta):
    gc_countdown=gc_countdown-delta
    if gc_countdown<0:
        for c in get_children():
            if c is Particles2D and c.emitting==false:
                c.queue_free()
                # remove_child(c)
        gc_countdown=5

