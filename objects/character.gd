extends Node2D
class_name Character

class Buf:
    var countdown=-1
    var time_remain=1
    var is_time_limit=true
    var name=""
    var data={}
    var max_layer=10
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
var shoot_offset=Vector2(0,0)

#constant
var ground_y=771
var dash_spd=600
var mov_skill_delay=5
var back_spd=1000

#temp_status
var check_atk_countdown=0
var status="mov"
var pending_atk_tar=[]
var cur_skill=""
var skill_mov_delay_count=mov_skill_delay

#list status
var bufs={}
var skills={}
var atk_buf={}

var game
var atk_timer
var shoot_timer
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
    shoot_timer=get_node("ShootTimer")

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

func add_back_buf(dist):
    var buf=Buf.new()
    buf.name="back"
    buf.time_remain=dist/back_spd
    add_buf(buf)

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
    pending_atk_tar = []
    var max_dist=-1
    var max_dist_char=null
    for chara in atk_targets:
        if is_instance_valid(chara)==false:
            continue
        if chara.dead==false:
            pending_atk_tar.append(chara)
            var dist=abs(chara.global_position.x-global_position.x)
            if max_dist<dist:
                max_dist=dist
                max_dist_char=chara
    if len(pending_atk_tar)>0:
        if len(atk_fx)>0:
            var dura = game.fx_mgr.play_frame_link(atk_fx[0],global_position+shoot_offset,max_dist_char.fx_pos_node.global_position)
            shoot_timer.start(dura)
        elif len(bullet_fx)>0:
            var bullet = game.fx_mgr.play_bullet(bullet_fx[0],global_position+shoot_offset,max_dist_char.fx_pos_node.global_position)
            bullet.connect("finish_play", self, "on_shoot_timeout")
        else:
            apply_attck()
    if len(shoot_fx)>0:
        game.fx_mgr.play_frame_fx(shoot_fx[0],global_position+shoot_offset)
            

func play_hit(source_fx_info):
    if len(source_fx_info)==0:
        return
    var fx=Global.rand_in_list(source_fx_info)
    var g_pos=fx_pos_node.global_position
    game.fx_mgr.play_frame_fx(fx, g_pos)
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

func apply_attck():
    for chara in pending_atk_tar:
        if is_instance_valid(chara) and chara.dead==false:
            for b in atk_buf:
                if Global.check_prob_pass(b["chance"]*luk):
                    var buf_data=Global.atk_buf_tb[b["name"]]
                    if buf_data["name"]=="":
                        pass
                    else:
                        game.apply_skill(buf_data, [chara], chara.team_id, self)
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
            chara.play_hit(hit_fx)
    pending_atk_tar=[]

func on_teleport():
    var tele_dist = Global.skills_tb[cur_skill]["distance"]
    var new_posi=position.x+tele_dist*mov_dir
    if check_if_outside(new_posi)==false:
        position.x=new_posi
    visible=true
    anim_sprite.animation="teleport_reverse"

func on_shoot_timeout():
    apply_attck()

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
    elif anim_sprite.animation=="teleport":
        visible=false
        get_node("TeleportTimer").start(Global.skills_tb[cur_skill]["delay"])
    elif anim_sprite.animation=="teleport_reverse":
        cur_skill=""
        play_continue()
    elif anim_sprite.animation=="dash":
        cur_skill=""
        play_continue()

func set_anim(anim_data, info):
    shoot_fx=info["shoot_fx"]
    atk_fx=info["atk_fx"]
    bullet_fx=info["bullet_fx"]
    hit_fx=info["hit_fx"]
    anim_sprite.frames=anim_data
    play_move()
    anim_sprite.offset.y=info["y_offset"]
    shoot_offset=Vector2(info["shoot_offset"][0],info["shoot_offset"][1]) 
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
        shoot_offset.x=-shoot_offset.x

func set_x_pos(x_pos):
    position.x=x_pos

func play_move():
    anim_sprite.animation="mov"
    status="mov"
    var frame_num=anim_sprite.frames.get_frame_count("mov")
    var frame_p_pixel=0.002
    var loop_time = mov_spd*frame_p_pixel
    var fps=frame_num/loop_time
    anim_sprite.speed_scale=fps/10
    anim_sprite.play()

func play_dash(targets, dash_info):
    if anim_sprite.frames.has_animation("dash")==false:
        return false
    anim_sprite.animation="dash"
    status="skill"
    cur_skill=dash_info["name"]
    var frame_data=anim_sprite.frames
    var frame_num=frame_data.get_frame_count("dash")
    var dist = dash_info["distance"]
    var time_need=dist/dash_spd
    var fps=frame_num/time_need
    var speed_rate=fps/10
    anim_sprite.speed_scale=speed_rate
    anim_sprite.play()
    for c in targets:
        c.add_back_buf(dist)
    return true


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
    var skill_candi=[]
    for s in skills:
        if Global.check_prob_pass(s["chance"]*luk):
            skill_candi.append(s["name"])
    if len(skill_candi)>0:
        var s = Global.rand_in_list(skill_candi)
        var skill_data=Global.skills_tb[s]
        if skill_data["type"]=="teleport":
            anim_sprite.animation="teleport"
            anim_player.play()
            status="skill"
            cur_skill=s
        else:
            return game.apply_skill(skill_data,[],team_id, self)
        return true
    else:
        return false

func reduce_buf_count(buf):
    buf["countdown"]=buf["countdown"]-1
    if buf["countdown"]<=0:
        bufs[buf.name].erase(buf)
        if len(bufs[buf.name])==0:
            bufs.erase(buf.name)

func check_if_outside(x):
    if team_id==1 and x<game.scene_min or team_id==0 and x>game.scene_max:
        return true
    else:
        return false

func _physics_process(delta):
    for buf_name in bufs:
        if bufs[buf_name][0]["is_time_limit"]==true:
            for buf in bufs[buf_name]:
                buf.time_remain=buf.time_remain-delta
                if buf.time_remain<=0:
                    bufs[buf_name].erase(buf)
                    if len(bufs[buf_name])==0:
                        bufs.erase(buf_name)
    if "back" in bufs:
        position.x=position.x - mov_dir*delta*back_spd
    if anim_sprite.animation=="dash":
        position.x=position.x + mov_dir*delta*dash_spd
    if status=="mov":
        position.x = position.x + mov_dir*delta*mov_spd
        if check_if_outside(global_position.x):
            game.remove_chara(self)
            return
        if check_atk_countdown<0:
            check_atk_countdown=rand_range(0.03,0.2)
            var do_skill=false
            skill_mov_delay_count=skill_mov_delay_count-1
            if skill_mov_delay_count<0:
                skill_mov_delay_count=mov_skill_delay
                do_skill = process_skills()
            if do_skill==false:
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

