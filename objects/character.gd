extends Node2D
class_name Character

#path
export (NodePath) var fct_mgr_path

#node
var fct_mgr
var fx_pos_node
var anim_player

#attr
var hp=30
var lv
var hit_delay

#static status
var team_id=0
var is_local=true
var chara_name=""
var atk_anim_name=""
var mov_dir=1
var chara_index=-1
var atk_frame=0 
var hit_y_offset

#temp_status
var status="mov"
var pending_atk_tar=[]
var dead=false
var atk_pre_countdown=0
var atk_after_countdown=0
var in_atk_pre=false
var in_atk_after=false

var hit_delay_countdown=0
var in_hit_delay=false

var game
var shoot_timer
var attr
var info

func _ready():
	anim_player=get_node("AnimationPlayer")
	fx_pos_node=get_node("FxPos")
	fct_mgr=get_node(fct_mgr_path)
	shoot_timer=get_node("ShootTimer")
	hit_delay=Global.global_data["hit_delay"]

func on_create(_game):
	game=_game

func set_attr_data(data, _lv):
	attr=data["attrs"][_lv]
	hp=attr["hp"]
	lv=_lv
	info=data

func attack(atk_targets):
	pending_atk_tar = []
	for chara in atk_targets:
		if is_instance_valid(chara)==false:
			continue
		if chara.dead==false:
			pending_atk_tar.append(chara)
	if len(pending_atk_tar)>0:
		apply_attck()

func play_hit(source_fx_info):
	if len(source_fx_info)==0:
		return
	if hit_delay>0.02:
		var fx=Global.rand_in_list(source_fx_info)
		game.fx_mgr.play_frame_fx(fx, get_hit_pos(fx))
		change_animation("hit", "hit")
		hit_delay_countdown=hit_delay
		in_hit_delay=true

func show_miss():
	if is_local:
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
		return [position.x, position.x+attr["atk_range"]]
	else:
		return [position.x-attr["atk_range"], position.x]

func update_atk_targets():
	return null

func play_continue():
	var atk_targets = update_atk_targets()
	if len(atk_targets)==0:
		play_move()
	else:
		play_atk()

func apply_attck():
	if dead==true:
		return
	for chara in pending_atk_tar:
		if is_instance_valid(chara) and chara.dead==false:
			var temp_atk=10
			temp_atk=floor(temp_atk)
			if temp_atk<=1:
				continue
			chara.change_hp(-temp_atk,self,false)
			if chara.dead==false:
				chara.play_hit(info["appearance"]["hit_fx"])
	pending_atk_tar=[]

func on_shoot_timeout():
	apply_attck()

func change_animation(anim_name, _status):
	pass

func set_team(_team_id, _is_local):
	team_id=_team_id
	is_local=_is_local
	name=chara_name+"_"+str(team_id)+"_"+str(chara_index)
	if team_id==1:
		mov_dir=-1
		# anim_sprite.flip_h=true
		# shoot_offset.x=-shoot_offset.x

func set_x_pos(x_pos):
	position.x=x_pos

func play_move():
	change_animation("mov", "mov")
	# var frame_num=anim_sprite.frames.get_frame_count("mov")
	# var frame_p_pixel=100
	# var loop_time = frame_p_pixel/mov_spd
	# var fps=frame_num/loop_time
	# anim_sprite.speed_scale=fps/10

func play_atk():
	if atk_anim_name=="":
		return
	change_animation(atk_anim_name, "atk")
	# var frame_num = anim_sprite.frames.get_frame_count(atk_anim_name)
	# var temp_atk_spd=apply_attr_buf("atk_spd")
	# if temp_atk_spd<0.1:
	# 	temp_atk_spd=0.1
	# var atk_period=stepify(1/temp_atk_spd, 0.01) 
	# var atk_time= stepify(atk_period*float(atk_frame)/frame_num, 0.01) 
	# anim_sprite.speed_scale=1
	# var fps=int(frame_num/atk_period)
	# anim_sprite.speed_scale=fps/10.0
	# atk_pre_countdown=atk_time
	# atk_after_countdown=atk_period
	# in_atk_pre=true
	# in_atk_after=true

func check_if_outside(x):
	if team_id==1 and x<game.scene_min or team_id==0 and x>game.scene_max:
		return true
	else:
		return false

func _physics_process(delta):
	if Global.paused:
		return
	if status=="mov":
		if attr["mov_spd"]>0:
			position.x = position.x + mov_dir*delta*attr["mov_spd"] 
			if check_if_outside(global_position.x):
				game.remove_chara(self)
				return
			var atk_targets = update_atk_targets()
			if len(atk_targets)>0:
				play_atk()
	if status=="atk":
		atk_pre_countdown=atk_pre_countdown-delta
		if in_atk_pre and atk_pre_countdown<=0:
			in_atk_pre=false
			if dead==false:
				var atk_targets = update_atk_targets()
				attack(atk_targets)
		atk_after_countdown=atk_after_countdown-delta
		if in_atk_after and atk_after_countdown<=0:
			in_atk_after=false
	if status=="hit":
		hit_delay_countdown=hit_delay_countdown-delta
		if in_hit_delay and hit_delay_countdown<=0:
			in_hit_delay=false
			if dead==false:
				play_continue()

func get_hit_pos(fx):
	return null

func on_die(_chara):
	# var discount_gold=gold*0.9*reward_discount
	# game.change_coin(int(discount_gold), get_enemy_team_id())
	# if is_local==false:
	# 	var coin_ef_num=int(gold/10)+1
	# 	if coin_ef_num>10:
	# 		coin_ef_num=10
	# 	game.fx_mgr.play_coin_fx(coin_ef_num, fx_pos_node.position+position)
	# anim_sprite.speed_scale=1
	change_animation("die", "die")
	var die_fx=info["appearance"]["die_fx"]
	if len(die_fx)>0:
		game.fx_mgr.play_frame_fx(die_fx[0], get_hit_pos(die_fx[0]))
	dead=true
	game.update_chara_list_ui()

func change_hp(val, chara, b_critical=false):
	var new_hp=hp+val
	if new_hp>attr["max_hp"] :
		new_hp=attr["max_hp"]
	elif new_hp<=0:
		on_die(chara)
		new_hp=0
	var actual_val=new_hp-hp
	# print("damage: ",actual_val,"  ",chara.name,"  ",game.frame_id)
	hp=new_hp
	if actual_val==0:
		return
	if val<0:
		if is_local==false:
			fct_mgr.show_value(str(actual_val), Color.white,b_critical)
		else:
			fct_mgr.show_value(str(actual_val), Color.red,b_critical)
		if is_local==false:
			anim_player.play("white")
		else:
			anim_player.play("red")
	else:
		fct_mgr.show_value(str(actual_val), Color.green)


