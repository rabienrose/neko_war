extends Node2D

export (Resource) var build_res
export (NodePath) var char_root_path
export (NodePath) var spawn1_path
export (NodePath) var spawn2_path
export (NodePath) var chara_gen_ui_path
export (NodePath) var item_use_ui_path
export (NodePath) var summary_path
export (NodePath) var comfirm_path
export (NodePath) var lobby_path
export (NodePath) var lobby_msg_path
export (NodePath) var chara1_list_path
export (NodePath) var chara2_list_path
export (NodePath) var coin1_label_path
export (NodePath) var coin2_label_path
export (NodePath) var server_path

var fx_mgr
var char_root
var chara_gen_ui
var item_use_ui
var frame_time_countdown=0
var frame_delay=0.02
var fps=int(1/frame_delay)
var keyframe_step=10
var keyframe_p_s=int(fps/keyframe_step)
var scene_min=0
var scene_max=2364

var stop=false

var next_replay_time=0
var next_replay_index=0

var player_setting=["local","ai"] #local, remote, ai

#input args
var level_data={}

var server
var recording_data=[[],[]]
var replay_data=[[],[]]
var live_chara_count=[0,0]
var chara_count=[0,0]
var chara_hotkey=[[null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null]]

var coin_num=[0,0]
var init_coin_num=[0,0]
var team_charas=[[],[]]
var last_items_num=[]
var init_items_num=[]

var chara_inputs=[[],[]]

var ai_nodes=[]
var spawn_nodes=[]

var net_id_2_team_id={}
var team_id_2_net_id=[]

var game_start=false

var frame_id=-1

var wait_4_ack=false

func _ready():
	server=get_node(server_path)
	var cmds=OS.get_cmdline_args()
	if len(cmds)>=1:
		if cmds[0]=="server":
			Global.server_mode=true
	if len(cmds)>=2:
		if cmds[1]=="pvp_mode":
			Global.pvp_mode=true
	if Global.server_mode:
		server.start_server()
	else:
		if Global.level_mode:
			level_data=Global.levels_tb[Global.sel_level]
			get_node(coin1_label_path).get_parent().visible=true
			get_node(coin2_label_path).get_parent().visible=false
			init_coin_num[0]=Global.user_data["gold"]
			init_coin_num[1]=100
			coin_num[0]=init_coin_num[0]
			coin_num[1]=init_coin_num[1]
			ai_nodes=[]
			ai_nodes.append(null)
			var t_node=Node.new()
			t_node.set_script(load("res://ai/ai.gd"))
			add_child(t_node)
			t_node.init(self, level_data)
			ai_nodes.append(t_node)
			start_battle()
			update_hotkey_ui(0)
		if Global.pvp_mode:
			server.start_clinet()
		if Global.replay_mode:
			get_node(chara_gen_ui_path).visible=false
			get_node(item_use_ui_path).visible=false
			server.start_replay(Global.replay_data)

func start_battle():
	Global.rng=RandomNumberGenerator.new()
	Global.rng.seed=0
	fx_mgr=get_node("FxMgr")
	spawn_nodes.append(get_node(spawn1_path))
	spawn_nodes.append(get_node(spawn2_path))
	char_root=get_node(char_root_path)
	chara_gen_ui=get_node(chara_gen_ui_path)
	item_use_ui=get_node(item_use_ui_path)
	spawn_building("base", 0)
	spawn_building("base", 1)
	var cancel_cb = funcref(self, "cancel_cb")
	var go_home_cb = funcref(self, "go_home_cb")
	get_node(comfirm_path).set_btn1("Cancel", cancel_cb)
	get_node(comfirm_path).set_btn2("Ok", go_home_cb)     
	game_start=true
	update_stats_ui()

func cancel_cb():
	if Global.level_mode:
		get_tree().paused = false
		get_node(comfirm_path).visible=false

func go_home_cb():
	if Global.level_mode:
		get_tree().paused = false
		stop_game(false)
	elif Global.pvp_mode:
		chara_inputs[find_local_team_id()].append(-1)
	elif Global.replay_mode:
		get_tree().change_scene(Global.home_scene)
	get_node(comfirm_path).visible=false

func stop_game(b_win, force_summary=false):
	pass

func spawn_building(build_name, team_id):
	var new_char = build_res.instance()
	char_root.add_child(new_char)
	var spawn_pos = spawn_nodes[team_id]
	init_object(new_char, spawn_pos.position, build_name, "1", team_id, false)

func spawn_chara(chara_name, lv, team_id):
	var char_res=load(Global.chara_file_path+chara_name+".tscn")
	var new_char = char_res.instance()
	char_root.add_child(new_char)
	var spawn_pos = spawn_nodes[team_id]
	init_object(new_char, spawn_pos.position, chara_name, str(lv), team_id, true)

func init_object(res, spawn_pos, chara_name, lv, team_id, b_rand_y):
	res.on_create(self)
	team_charas[team_id].append(res)
	chara_count[team_id]=chara_count[team_id]+1
	res.set_attr_data(Global.chara_tb[chara_name], lv, chara_count[team_id])
	res.set_team(team_id, find_local_team_id()==team_id)
	res.set_x_pos(spawn_pos,b_rand_y)
	update_chara_list_ui()

func request_use_item(item_name, team_id):
	pass

func remove_chara(chara):
	team_charas[chara.team_id].erase(chara)
	chara.queue_free()    
	
func change_coin(change_val, team_id):
	if change_val>0:
		coin_num[team_id]=coin_num[team_id]+change_val
	else:
		if -change_val<=coin_num[team_id]:
			coin_num[team_id]=coin_num[team_id]+change_val
	update_stats_ui()

func check_chara_build(chara_cost, team_id):
	if chara_cost<=coin_num[team_id]:
		return true
	return false

func update_chara_list_ui():
	var chara_num_stats=[{},{}]
	for c in char_root.get_children():
		if is_instance_valid(c)==false:
			continue
		if c.info["type"]!="chara":
			continue
		if c.dead==true:
			continue
		if not c.chara_name in chara_num_stats[c.team_id]:
			chara_num_stats[c.team_id][c.chara_name]=0
		chara_num_stats[c.team_id][c.chara_name]=chara_num_stats[c.team_id][c.chara_name]+1
	for i in range(0,2):
		var chara_infos=[]
		for chara_name in chara_num_stats[i]:
			var lv=0
			for j in range(0,5):
				if chara_hotkey[i][j]==null:
					continue
				if chara_name==chara_hotkey[i][j]["name"]:
					lv=chara_hotkey[i][j]["lv"]
					break
			var chara_info={}
			chara_info["name"]=chara_name
			chara_info["lv"]=lv
			chara_info["num"]=chara_num_stats[i][chara_name]
			chara_infos.append(chara_info)
		if i==0:
			get_node(chara1_list_path).update_list(chara_infos)
		else:
			get_node(chara2_list_path).update_list(chara_infos)

func get_total_used_diamond():
	pass
	# if init_diamond_num[0]==0 and init_diamond_num[1]==0:
	# 	return 0
	# var diamond_expand=init_diamond_num[0]-diamond_num[0]+init_diamond_num[1]-diamond_num[1]
	# var item_diamond=0
	# for team_id in range(0,2):
	# 	for i in range(5,10):
	# 		if init_items_num[team_id][i] != null:
	# 			var used_num = init_items_num[team_id][i]["num"]-chara_hotkey[team_id][i]["num"]
	# 			if used_num>0:
	# 				var single_cost = Global.items_tb[init_items_num[team_id][i]["name"]]["price"]
	# 				item_diamond=item_diamond+single_cost*used_num
	# return item_diamond+diamond_expand

func update_stats_ui():
	get_node(coin1_label_path).text="Coin: "+str(coin_num[0])
	update_hk_mask()

func use_item_cb(item):
	if item.custom_val-1<0:
		return false
	var local_team=find_local_team_id()
	if not item.index in chara_inputs[local_team]:
		chara_inputs[local_team].append(item.index+5)
	return true

func find_local_team_id():
	for i in range(0,2):
		if player_setting[i]=="local":
			return i
	return -1

func start_chara_cb(item):
	var local_team=find_local_team_id()
	if check_chara_build(item.custom_val,local_team):
		if not item.index in chara_inputs[local_team]:
			chara_inputs[local_team].append(item.index)
			return true
		return false
	else:
		return false

func update_hk_mask():
	for c in chara_gen_ui.get_items():
		if c.has_item==false:
			continue
		c.set_mask(!check_chara_build(c.custom_val, find_local_team_id()))

func update_hotkey_ui(_local_team_id):
	for i in range(len(Global.user_data["equip"][0])):
		var chara_name=Global.user_data["equip"][0][i]
		if chara_name=="":
			continue
		var lv = Global.get_my_chara_info(chara_name)
		var build_cost=Global.chara_tb[chara_name]["build_cost"]
		var build_time=Global.chara_tb[chara_name]["build_time"]
		var icon_file_path=Global.icon_img_file_path+chara_name+".png"
		var icon_texture=load(icon_file_path)
		var click_cb = funcref(self, "start_chara_cb")
		chara_gen_ui.get_child(i).on_create(icon_texture, build_time, build_cost, {"name":chara_name, "lv":lv}, click_cb,i)
		var hk_info={}
		hk_info["countdown"]=0
		hk_info["lv"]=lv
		hk_info["name"]=chara_name
		chara_hotkey[_local_team_id][i]=hk_info
	for i in range(len(Global.user_data["equip"][1])):
		var item_name=Global.user_data["equip"][1][i]
		if item_name=="":
			continue
		var num = Global.get_my_item_info(item_name)
		var item_db=Global.items_tb[item_name]
		var icon_file_path=Global.icon_img_file_path+item_name+".png"
		var icon_texture=load(icon_file_path)
		var click_cb = funcref(self, "use_item_cb")
		item_use_ui.get_child(i).on_create(icon_texture, item_db["delay"], num, {"name":item_name},click_cb,i)
		var hk_info={}
		hk_info["countdown"]=0
		hk_info["num"]=num
		hk_info["name"]=item_name
		chara_hotkey[_local_team_id][i+5]=hk_info

func process_frame():
	frame_id=frame_id+1
	for _team_id in range(0,2):
		for item in chara_hotkey[_team_id]:
			if item ==null:
				continue
			item["countdown"]=item["countdown"]-frame_delay

func _physics_process(_delta):
	if game_start==false:
		return    
	if frame_time_countdown>0:
		frame_time_countdown=frame_time_countdown-1
		process_frame()
	else:
		if server.process_keyframe()==false:
			Global.paused=true
			return  
		else:
			Global.paused=false
			frame_time_countdown=keyframe_step
			process_frame()

func _on_Return_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_node(comfirm_path).visible==false:
				get_node(comfirm_path).visible=true
				if Global.pvp_mode!=true:
					get_tree().paused = true
				if Global.replay_mode:
					get_node(comfirm_path).hide_btn(1)
