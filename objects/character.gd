extends Node2D
class_name Character

#path
export (NodePath) var fct_mgr_path
export (NodePath) var appearance_path

#node
var appearance
var appear_player
var fct_mgr
var fx_pos_node
var anim_player
var chara_name
var hit_pos_node

var min_y=600
var max_y=1000

#attr
var hp=30
var lv

#static status
var team_id=0
var is_master=true
var mov_dir=1
var chara_index=-1

#temp_status
var status="mov"
var pending_atk_tar=[]
var dead=false

var game
var shoot_timer
var attr
var info

func _ready():
	appearance=get_node(appearance_path)
	anim_player=get_node("AnimationPlayer")
	appear_player=get_node("AppearAnima")
	fx_pos_node=get_node("FxPos")
	fct_mgr=get_node(fct_mgr_path)
	shoot_timer=get_node("ShootTimer")
	hit_pos_node=get_node("hit_pos")
	if anim_player:
		anim_player.connect("animation_finished", self, "on_anim_done")

func on_anim_done(anim_name):
	if anim_name=="hit":
		# print("e_hit ",chara_index,"  ",game.frame_id)
		if dead==false:
			play_continue()
	if anim_name=="die":
		game.remove_chara(self)

func on_atk_cb_from_anim():
	# print("e_atk ",chara_index,"  ",game.frame_id)
	if dead==false:
		var atk_targets = update_atk_targets()
		attack(atk_targets)

func on_create(_game):
	game=_game

func set_attr_data(data, _lv, char_ind):
	attr=data["attrs"][_lv]
	hp=attr["hp"]
	lv=_lv
	info=data
	chara_name=info["name"]
	chara_index = char_ind
	if attr["mov_spd"]>0:
		play_move()

func attack(atk_targets):
	pending_atk_tar = []
	for chara in atk_targets:
		if is_instance_valid(chara)==false:
			continue
		if chara.dead==false:
			pending_atk_tar.append(chara)
	if len(pending_atk_tar)>0:
		apply_attck()
	else:
		play_continue()


func play_hit(source_fx_info):
	if len(source_fx_info)==0:
		return
	var fx=Global.rand_in_list(source_fx_info)
	game.fx_mgr.play_frame_fx(fx, get_hit_pos(fx))
	change_animation("hit","hit")

func show_miss():
	if is_master:
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
	var enemy_id = get_enemy_team_id()
	var min_char=null
	var min_dist=-1
	for c in game.char_root.get_children():
		if is_instance_valid(c)==false or c.dead==true:
			continue
		if c.info["type"]=="building" and info["tar_building"]==false:
			continue
		if c.info["type"]=="chara" and info["tar_chara"]==false:
			continue
		if c.team_id!=enemy_id:
			continue
		var dist = abs(c.position.x-position.x)
		if dist>attr["range"]:
			continue
		if min_dist==-1 or min_dist>dist:
			min_dist=dist
			min_char=c
	if min_dist>0:
		return [min_char]
	else:
		return []

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
			var temp_atk=attr["atk"]
			temp_atk=floor(temp_atk)
			if temp_atk<=1:
				continue
			chara.change_hp(-temp_atk,self,false)
			if chara.dead==false:
				chara.play_hit(info["appearance"]["hit_fx"])
			else:
				play_continue()
		else:
			play_continue()
	pending_atk_tar=[]

func on_shoot_timeout():
	apply_attck()

func change_animation(anim_name, _status):
	# if anim_name=="hit":
	# 	print("s_hit ",chara_index,"  ",game.frame_id)
	# if anim_name=="atk":
	# 	print("s_atk ",chara_index,"  ",game.frame_id)
	if anim_player:
		anim_player.play(anim_name)
		anim_player.seek(0)
	status=_status

func set_team(_team_id, _is_local):
	team_id=_team_id
	is_master=_is_local
	name=chara_name+"_"+str(team_id)+"_"+str(chara_index)
	if team_id==1:
		mov_dir=-1
		appearance.scale.x=-1

func set_x_pos(pos, b_rand_y):
	position.x=pos.x
	if b_rand_y:
		position.y=Global.rng.randf_range(min_y,max_y)
	else:
		position.y=pos.y
	z_index=position.y

func play_move():
	change_animation("walk","mov")
	var coef=50
	anim_player.playback_speed=stepify(attr["mov_spd"]/coef,0.01)

func play_atk():
	change_animation("atk", "atk")
	var anim_length = anim_player.get_animation("atk").length
	var atk_period=1/attr["atk_spd"]
	if atk_period<0.2:
		atk_period=0.2
	anim_player.playback_speed=stepify(anim_length/atk_period,0.01)

func check_if_outside(x):
	if team_id==1 and x<game.scene_min or team_id==0 and x>game.scene_max:
		return true
	else:
		return false

func _physics_process(delta):
	if status=="mov":
		if attr["mov_spd"]>0:
			position.x = position.x + mov_dir*delta*attr["mov_spd"] 
			if check_if_outside(global_position.x):
				game.remove_chara(self)
				return
			var atk_targets = update_atk_targets()
			if len(atk_targets)>0:
				play_atk()				

func get_hit_pos(fx):
	return hit_pos_node.global_position

func on_die(_chara):
	# print("die ",chara_index," ",game.frame_id)
	if is_master==false:
		var coin = info["build_cost"]
		var coin_ef_num=int(coin/10)+1
		if coin_ef_num>10:
			coin_ef_num=10
		game.fx_mgr.play_coin_fx(coin_ef_num, fx_pos_node.global_position)
	change_animation("die", "die")
	anim_player.playback_speed=1
	var die_fx=info["appearance"]["die_fx"]
	if len(die_fx)>0:
		game.fx_mgr.play_frame_fx(die_fx[0], get_hit_pos(die_fx[0]))
	dead=true
	game.update_chara_list_ui()

func change_hp(val, chara, b_critical=false):
	var new_hp=hp+val
	if new_hp>attr["hp"] :
		new_hp=attr["hp"]
	elif new_hp<=0:
		on_die(chara)
		new_hp=0
	var actual_val=new_hp-hp
	# print("damage: ",actual_val,"  ",chara.name,"  ",game.frame_id)
	hp=new_hp
	if actual_val==0:
		return
	if val<0:
		if is_master==false:
			fct_mgr.show_value(str(actual_val), Color.white,b_critical)
		else:
			fct_mgr.show_value(str(actual_val), Color.red,b_critical)
	else:
		fct_mgr.show_value(str(actual_val), Color.green)


