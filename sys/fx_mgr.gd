extends Node2D

export (Resource) var coin_fx_res

var gc_countdown=5

func play_coin_fx(coin_num, posi):
    var fx = coin_fx_res.instance()
    fx.position=posi
    add_child(fx)
    fx.emitting=true

func _process(delta):
    gc_countdown=gc_countdown-delta
    if gc_countdown<0:
        for c in get_children():
            if c.emitting==false:
                c.queue_free()
                remove_child(c)
        gc_countdown=5

