extends Character

class_name Building

func on_die(_chara):
    if team_id==0:
        game.stop_game(false)
    else:
        game.stop_game(true)
    .on_die(_chara)

func set_attr_data(data):
    max_hp=data["hp"]
    hp=max_hp
    hp_bar.max_value=max_hp
    hp_bar.value=max_hp
    type="building"

func set_anim(anim_data, info):
    hit_fx=info["hit_fx"]
    anim_sprite.frames=anim_data
    anim_sprite.offset.y=info["y_offset"]
    hit_y_offset=info["hit_y_offset"]
    position.y=ground_y
    anim_sprite.material = anim_sprite.material.duplicate()
    anim_sprite.animation="idle"
    status="idle"

func play_atk():
    pass
    
func play_continue():
    pass

func add_buf(buf):
    pass
