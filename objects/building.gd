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
    type="builing"
    update_chara_panel()

func set_anim(anim_data, info):
    .set_anim(anim_data, info)
    anim_sprite.animation="idle"
    status="idle"
