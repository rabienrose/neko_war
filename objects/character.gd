extends Node2D
class_name Character

class Buf:
    var countdown=-1
    var time_remain=1
    var is_time_limit=true
    var name=""
    var data={}
    var max_layer=100
    var type=""

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
var deff=0.1
var flee=0.1
var luk=0.1
var cri=0.1
var team_id=0
var dead=false
var gold=20
var target_scheme=null

#static status
var type=""
var atk_anim_name=""
var mov_dir=1
var chara_index=-1
var atk_frame=0 

#constant
var ground_y=771
var mov_spd_coef=100

#temp_status
var check_atk_countdown=0
var status="mov"

#list status
var bufs={}
var skills={}
var atk_buf={}

var game
var atk_timer
var shoot_fx
var atk_fx
var bullet_fx
var hit_fx

func _ready():
    anim_player=get_node("AnimationPlayer")
    fx_pos_node=get_node("FxPos")
    anim_sprite=get_node(sprite_anim_path)
    hp_bar=get_node(hp_bar_path)
    fct_mgr=get_node(fct_mgr_path)
    hp_bar.rect_position.y=hp_bar.rect_position.y+rand_range(0,190)
    atk_timer=get_node("AtkTimer")

func on_create(_game):
    game=_game

func set_attr_data(data):
    max_hp=data["hp"]
    hp=max_hp
    atk = data["atk"]
    mov_spd = data["mov_spd"]
    atk_spd = data["atk_spd"]
    gold = data["drop_gold"]
    atk_range=data["range"]
    target_scheme=data["target_scheme"]
    hp_bar.max_value=max_hp
    hp_bar.value=max_hp
    type="chara"
    update_chara_panel()
    chara_index=data["index"]
    skills=data["skills"]
    atk_buf=data["atk_buf"]
    deff=data["deff"]
    flee=data["flee"]
    luk=data["luk"]
    cri=data["cri"]

func add_buf(buf):
    if buf.name in bufs:
        if len(bufs[buf.name])<buf.max_layer:
            bufs[buf.name].append(buf)
    else:
        bufs[buf.name]=[buf]

func apply_attr_buf(attr):
    var temp_val=get(attr)
    for buf_name in bufs:
        for buf in bufs[buf_name]:
            if buf.type=="attr" and buf.data["attr"]==attr:
                temp_val = game.apply_op(buf.data["op"], buf.data["val"], temp_val)
    return temp_val

func attack(atk_targets):
    for chara in atk_targets:
        if is_instance_valid(chara)==false:
            continue
        if chara.dead==false:
            for b in atk_buf:
                if Global.check_prob_pass(b["chance"]*luk):
                    var buf_data=Global.atk_buf_tb[b["name"]]
                    if buf_data["name"]=="":
                        pass
                    else:
                        game.apply_skill(buf_data, [chara], chara.team_id)
            
            var cri_ok = Global.check_prob_pass(cri)
            var temp_atk=apply_attr_buf("atk")
            if cri_ok==false:
                var flee_ok = Global.check_prob_pass(chara.flee)
                if flee_ok==true:
                    show_miss()
                    continue
                else:
                    temp_atk=temp_atk*(1-chara.def)
            chara.change_hp(-temp_atk,self)
            chara.play_hit()

func play_hit():
    var fx=Global.rand_in_list(hit_fx)
    var g_pos=fx_pos_node.global_position
    game.fx_mgr.play_frame_fx(fx["res"], fx["anim"], g_pos)
    anim_sprite.animation="hit"
    status="hit"
    atk_timer.stop()

func show_miss():
    if team_id==0:
        fct_mgr.show_value("Miss!", Color.red)
    else:
        fct_mgr.show_value("Miss!", Color.white)

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
    var targets=game.get_charas_by_group(target_scheme["group"],target_scheme["type"], team_id)
    var range_atk=get_min_max_atk_range()
    var chars_in_range=game.get_charas_in_range(range_atk[0], range_atk[1],targets)
    return game.filter_targets(target_scheme, chars_in_range)

func play_continue():
    var atk_targets = update_atk_targets()
    if len(atk_targets)==0:
        play_move()
    else:
        play_atk()

func on_atk_timeout():
    var atk_targets = update_atk_targets()
    attack(atk_targets)

func _on_AnimatedSprite_animation_finished():
    if status=="atk":
        if process_skills()==false:
            play_continue()
    elif status=="dead":
        game.remove_chara(self)
    elif status=="hit":
        play_continue()

func set_anim(anim_data, info):
    shoot_fx=info["shoot_fx"]
    atk_fx=info["atk_fx"]
    bullet_fx=info["bullet_fx"]
    hit_fx=info["hit_fx"]
    anim_sprite.frames=anim_data
    anim_sprite.animation="mov"
    status="mov"
    anim_sprite.play()
    anim_sprite.offset.y=info["y_offset"]
    position.y=ground_y
    anim_sprite.material = anim_sprite.material.duplicate()
    var names = anim_data.get_animation_names()
    var temp_counter=0
    for n in names:
        if "atk" in n:
            temp_counter=temp_counter+1
    if temp_counter>0:
        var temp_ind=ceil(rand_range(0,1)*temp_counter)
        atk_anim_name="atk_"+str(temp_ind)
        atk_frame=info["atk_frame"][temp_ind-1]
    else:
        atk_anim_name=""

func set_team(_team_id):
    team_id=_team_id
    name=type+"_"+str(team_id)+"_"+str(chara_index)
    if team_id==1:
        mov_dir=-1
        anim_sprite.flip_h=true

func set_x_pos(x_pos):
    position.x=x_pos

func play_move():
    anim_sprite.animation="mov"
    status="mov"
    anim_sprite.speed_scale=mov_spd
    anim_sprite.play()

func play_atk():
    if atk_anim_name=="":
        return
    anim_sprite.animation=atk_anim_name
    status="atk"
    anim_sprite.frame=0
    var frame_num = anim_sprite.frames.get_frame_count(atk_anim_name)
    var temp_atk_spd=apply_attr_buf("atk_spd")
    if temp_atk_spd<0.1:
        temp_atk_spd=0.1
    var atk_period=1/temp_atk_spd
    var atk_time=atk_period*float(atk_frame)/frame_num
    atk_timer.start(atk_time)
    anim_sprite.speed_scale=1
    var fps=frame_num/atk_period
    anim_sprite.frames.set_animation_speed(atk_anim_name, fps)
    anim_sprite.play()

func process_skills():
    if status=="skill" and status=="dead":
        return false
    for s in skills:
        if Global.check_prob_pass(s["chance"]):
            var skill_data=Global.skills_tb[s["name"]]
            if skill_data["name"]=="teleport":
                pass
            else:
                game.apply_skill(skill_data,[],team_id)
    return false

func reduce_buf_count(buf):
    buf["countdown"]=buf["countdown"]-1
    if buf["countdown"]<=0:
        bufs[buf.name].erase(buf)
        if len(bufs[buf.name])==0:
            bufs.erase(buf.name)

func _physics_process(delta):
    for buf_name in bufs:
        if bufs[buf_name][0]["is_time_limit"]==true:
            for buf in bufs[buf_name]:
                buf.time_remain=buf.time_remain-delta
                if buf.time_remain<=0:
                    bufs[buf_name].erase(buf)
                    if len(bufs[buf_name])==0:
                        bufs.erase(buf_name)
    if status=="mov":
        position.x = position.x + mov_dir*delta*mov_spd*mov_spd_coef
        if team_id==1 and position.x<game.scene_min or team_id==0 and position.x>game.scene_max:
            game.remove_chara(self)
            return
        if check_atk_countdown<0:
            check_atk_countdown=rand_range(0.1,0.3)
            if process_skills()==false:
                var atk_targets = update_atk_targets()
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
    anim_sprite.animation="dead"
    status="dead"

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

