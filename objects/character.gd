extends Node2D
class_name Character

class Buf:
    var countdown
    var time_remain
    var is_time_limit

#path
export (NodePath) var sprite_anim_path
export (NodePath) var hp_bar_path
export (NodePath) var fct_mgr_path

#node
var anim_sprite
var hp_bar
var fct_mgr
var fx_pos_node
var anim_player

#resource
export (Resource) var bar_red
export (Resource) var bar_green
export (Resource) var bar_yellow

#attr
var hp=30
var max_hp=30
var atk=10
var def=0
var atk_spd=1
var mov_spd=1
var atk_range=200
var atk_frame=0
var atk_num=1
var team_id=0
var dead=false
var gold=20

#constant
var ground_y=771
var mov_spd_coef=100

#temp_status
var init_atk=true
var atk_targets=[]
var check_atk_countdown=0

var bufs=[]

var mov_dir=1
var cur_anim

var game

func _ready():
    anim_player=get_node("AnimationPlayer")
    fx_pos_node=get_node("FxPos")
    anim_sprite=get_node(sprite_anim_path)
    hp_bar=get_node(hp_bar_path)
    fct_mgr=get_node(fct_mgr_path)
    hp_bar.rect_position.y=hp_bar.rect_position.y+rand_range(0,190)

func on_create(_game):
    game=_game

func set_attr_data(data):
    max_hp=data["hp"]
    hp=max_hp
    atk = data["atk"]
    mov_spd = data["mov_spd"]
    atk_spd = data["atk_spd"]
    gold = data["drop_gold"]
    atk_num = data["atk_num"]
    hp_bar.max_value=max_hp
    hp_bar.value=atk
    update_chara_panel()

func attack():
    init_atk=false
    for chara in atk_targets:
        if is_instance_valid(chara)==false:
            continue
        if chara.dead==false:
            var temp_atk=atk
            for buf in bufs:
                if buf["type"]=="attr": 
                    temp_atk=temp_atk+buf["val"]
            chara.change_hp(-temp_atk,self)

func get_enemy_team_id():
    if team_id==0:
        return 1
    else:
        return 0

func get_min_max_atk_range():
    if team_id==0:
        return [position.x, position.x+atk_range]
    else:
        return [position.x-atk_range, position.x]

func update_atk_targets():
    var range_atk=get_min_max_atk_range()
    var chars_in_range=game.get_charas_in_range(get_enemy_team_id(), range_atk[0], range_atk[1])
    atk_targets=[]
    if len(chars_in_range)>0:
        init_atk=true
        for i in range(atk_num):
            if i<len(chars_in_range):
                atk_targets.append(chars_in_range[len(chars_in_range)-i-1])

func _on_AnimatedSprite_animation_finished():
    if anim_sprite.animation=="atk":
        update_atk_targets()
        init_atk=true
        if len(atk_targets)==0:
            play_move()

func _on_AnimatedSprite_frame_changed():
    if anim_sprite.animation=="atk":
        if init_atk and atk_frame<=anim_sprite.frame:
            attack()

func set_anim(anim_data, info):
    atk_frame=info["atk_frame"]
    anim_sprite.frames=anim_data
    anim_sprite.animation="idle"
    anim_sprite.play()
    anim_sprite.offset.y=info["y_offset"]
    position.y=ground_y
    anim_sprite.material = anim_sprite.material.duplicate()

func play_anim(anim_name):
    anim_sprite.animation=anim_name

func set_team(_team_id):
    team_id=_team_id
    if team_id==1:
        mov_dir=-1
        anim_sprite.flip_h=true

func set_x_pos(x_pos):
    position.x=x_pos

func play_move():
    anim_sprite.animation="mov"
    anim_sprite.speed_scale=mov_spd

func play_atk():
    anim_sprite.animation="atk"
    anim_sprite.frame=0
    var frame_num = anim_sprite.frames.get_frame_count("atk")
    var atk_period=1/atk_spd
    anim_sprite.speed_scale=1
    var fps=frame_num/atk_period
    anim_sprite.frames.set_animation_speed("atk", fps)

func reduce_buf_count(buf):
    buf["countdown"]=buf["countdown"]-1
    if buf["countdown"]<=0:
        bufs.erase(buf)

func _physics_process(delta):
    for buf in bufs:
        if buf["is_time_limit"]==true:
            buf["time_remain"]=buf["time_remain"]-delta
            if buf["time_remain"]<=0:
                bufs.erase(buf)
    if anim_sprite.animation=="mov":
        position.x = position.x + mov_dir*delta*mov_spd*mov_spd_coef
        if team_id==1 and position.x<game.scene_min or team_id==0 and position.x>game.scene_max:
            game.remove_chara(self)
            return
        if check_atk_countdown<0:
            check_atk_countdown=rand_range(0.1,0.5)
            update_atk_targets()
            if len(atk_targets)>0:
                play_atk()
        check_atk_countdown=check_atk_countdown-delta

func on_die(_chara):
    if team_id==1 and gold>0:
        game.change_gold(gold)
        var coin_ef_num=int(gold/10)+1
        if coin_ef_num>10:
            coin_ef_num=10
        game.fx_mgr.play_coin_fx(coin_ef_num, fx_pos_node.position+position)
    game.remove_chara(self)

func change_hp(val, chara):
    var new_hp=hp+val
    if new_hp>max_hp:
        new_hp=max_hp
    elif new_hp<=0:
        on_die(chara)
        new_hp=0
    var actual_val=new_hp-hp
    hp=new_hp
    if actual_val==0:
        return
    if val<0:
        if team_id==1:
            fct_mgr.show_value(str(actual_val), Color.white)
        else:
            fct_mgr.show_value(str(actual_val), Color.red)
        if team_id==1:
            anim_player.play("white")
        else:
            anim_player.play("red")
    else:
        fct_mgr.show_value(str(actual_val), Color.green)
    update_chara_panel()

func update_chara_panel():
    hp_bar.texture_progress = bar_green
    if hp < max_hp * 0.7:
        hp_bar.texture_progress = bar_yellow
    if hp < max_hp * 0.35:
        hp_bar.texture_progress = bar_red
    hp_bar.value = hp
    if hp<max_hp:
        hp_bar.visible=true
    else:
        hp_bar.visible=false

