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
export (NodePath) var coin_pool_path

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
var frame_id=0
var item_mgr

var master_id=0
var input_queue=[]

#input args
var cur_frame=0

var replay_data=[[],[]]
var live_chara_count=[0,0]
var chara_count=[0,0]
var chara_hotkey=[[null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null]]

var coin_pool=0
var coin_num=[0,0]
var init_coin_num=[0,0]
var user_id_2_index={}

var my_inputs=[]
var ai_node=null
var spawn_nodes=[]

var game_start=false

func _ready():
	Global.rng=RandomNumberGenerator.new()
	Global.rng.seed=0
	fx_mgr=get_node("FxMgr")
	spawn_nodes.append(get_node(spawn1_path))
	spawn_nodes.append(get_node(spawn2_path))
	char_root=get_node(char_root_path)
	chara_gen_ui=get_node(chara_gen_ui_path)
	item_use_ui=get_node(item_use_ui_path)
	item_mgr=get_node("ItemMgr")
	item_mgr.on_create(self)
	get_node(coin_pool_path).visible=false
	Global.connect("battle_frame_recv", self, "recv_sync_frame")
	if Global.battle_mode=="level":
		get_node(coin1_label_path).get_parent().visible=true
		get_node(coin2_label_path).get_parent().visible=false
		coin_num[0]=Global.user_data["gold"]
		coin_num[1]=1000
		init_coin_num=coin_num.duplicate()
		ai_node=Node.new()
		ai_node.set_script(load("res://ai/ai.gd"))
		add_child(ai_node)
		ai_node.init(self, Global.levels_tb[Global.sel_level])
		for i in range(len(Global.user_data["equip"][0])):
			var chara_name=Global.user_data["equip"][0][i]
			if chara_name=="":
				continue
			var lv = Global.get_my_chara_info(chara_name)
			var hk_info={}
			hk_info["countdown"]=0
			hk_info["lv"]=lv
			hk_info["name"]=chara_name
			chara_hotkey[0][i]=hk_info
		for i in range(len(Global.user_data["equip"][1])):
			var item_name=Global.user_data["equip"][1][i]
			if item_name=="":
				continue
			var num = Global.get_my_item_info(item_name)
			var hk_info={}
			hk_info["countdown"]=0
			hk_info["num"]=num
			hk_info["name"]=item_name
			chara_hotkey[0][i+5]=hk_info
		coin_pool=Global.levels_tb[Global.sel_level]["reward"]
		update_hk_slot_ui(false)
		start_battle()
	elif Global.battle_mode=="pvp":
		var t_count=0
		get_node(coin_pool_path).visible=true
		for user_id in Global.battle_players:
			user_id_2_index[user_id]=t_count
			var player_info=Global.battle_players[user_id]
			coin_num[t_count]=player_info["gold"]
			var i=0
			for item in player_info["hk_slot"]:
				var hk_info=null
				if item[0]=="":    
					pass
				else:
					if i<5:
						var char_name=item[0]
						var char_lv=item[1]
						hk_info={}
						hk_info["countdown"]=0
						hk_info["lv"]=char_lv
						hk_info["name"]=char_name
					else:
						var item_name=item[0]
						var num=item[1]
						hk_info={}
						hk_info["countdown"]=0
						hk_info["num"]=num
						hk_info["name"]=item_name
				chara_hotkey[t_count][i]=hk_info
				i=i+1
			if user_id==Global.user_data["user_id"]:
				master_id=t_count
			t_count=t_count+1
		if master_id==0:
			get_node(coin1_label_path).get_parent().visible=true
			get_node(coin2_label_path).get_parent().visible=false
		else:
			get_node(coin1_label_path).get_parent().visible=false
			get_node(coin2_label_path).get_parent().visible=true
		init_coin_num=coin_num
		update_hk_slot_ui(false)
		start_battle()
		Global.send_ready_msg()
	elif Global.battle_mode=="replay":
		get_node(coin1_label_path).get_parent().visible=true
		get_node(coin2_label_path).get_parent().visible=false
		var replay_data=JSON.parse(Marshalls.base64_to_utf8(Global.total_level_data[Global.sel_level]["record"])).result 
		var kf_count=replay_data["kf_count"]
		input_queue=[]
		var ops=replay_data["ops"]
		for i in range(kf_count):
			var input=[[],[]]
			for j in range(2):
				var cmds=check_kf_exist(ops[j], i)
				if cmds!=null:
					input[j]=cmds
			input_queue.append(input)
		coin_num=replay_data["coin"]
		chara_hotkey=[[],[]]
		for j in range(2):
			var hk_slots=replay_data["hotkeys"][j]
			for i in range(hk_slots.size()):
				var slot=hk_slots[i]
				var hk_info=null
				if slot[0]!="":
					hk_info={}
					if i<5:
						hk_info["countdown"]=0
						hk_info["lv"]=slot[1]
						hk_info["name"]=slot[0]
					else:
						hk_info["countdown"]=0
						hk_info["num"]=slot[1]
						hk_info["name"]=slot[0]
				chara_hotkey[j].append(hk_info)
		update_hk_slot_ui(true)
		start_battle()

func check_kf_exist(info, kf):
	for item in info:
		if item[0]==kf:
			return item[1]
	return null

func start_battle():
	spawn_building("base", 0)
	spawn_building("base", 1)
	var cancel_cb = funcref(self, "cancel_cb")
	var go_home_cb = funcref(self, "go_home_cb")
	get_node(comfirm_path).set_btn1("Cancel", cancel_cb)
	get_node(comfirm_path).set_btn2("Ok", go_home_cb)     
	update_stats_ui()
	game_start=true

func cancel_cb():
	if Global.battle_mode!="pvp":
		get_tree().paused = false
	get_node(comfirm_path).visible=false

func go_home_cb():
	if Global.battle_mode=="level":
		stop_game(false)
	elif Global.battle_mode=="pvp":
		my_inputs.append(-1)
	elif Global.battle_mode=="replay":
		get_tree().change_scene(Global.home_scene)
	get_node(comfirm_path).visible=false

func stop_game(b_win):
	if Global.battle_mode=="pvp":
		Global.send_battle_result(b_win)
	elif Global.battle_mode=="level":
		Global.end_level_battle(b_win, get_recording_data())
	get_node(summary_path).show_summary(b_win, true, coin_pool, false)

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
	chara_count[team_id]=chara_count[team_id]+1
	res.set_attr_data(Global.chara_tb[chara_name], lv, chara_count[team_id])
	res.set_team(team_id, master_id==team_id)
	res.set_x_pos(spawn_pos,b_rand_y)
	update_chara_list_ui()

func remove_chara(chara):
	chara.queue_free()    
	
func change_coin(change_val, team_id):
	if change_val>0:
		coin_num[team_id]=coin_num[team_id]+change_val
	else:
		if -change_val<=coin_num[team_id]:
			coin_num[team_id]=coin_num[team_id]+change_val
			if team_id!=master_id:
				coin_pool=coin_pool-change_val
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

func update_stats_ui():
	get_node(coin1_label_path).text="Coin: "+str(coin_num[0])
	get_node(coin2_label_path).text="Coin: "+str(coin_num[1])
	get_node(coin_pool_path).text="Reward: "+str(coin_pool)
	update_hk_mask()

func use_item_cb(item):
	if item.custom_val-1<0:
		return false
	if not item.index in my_inputs:
		my_inputs.append(item.index)
	return true

func start_chara_cb(item):
	if check_chara_build(item.custom_val,master_id):
		if not item.index in my_inputs:
			my_inputs.append(item.index)
			return true
		return false
	else:
		return false

func update_hk_mask():
	for c in chara_gen_ui.get_items():
		if c.has_item==false:
			continue
		c.set_mask(!check_chara_build(c.custom_val, master_id))

func update_hk_slot_ui(b_not_interactive):
	var i=0
	for item in chara_hotkey[master_id]:
		if item!=null:
			if i<5:
				var chara_name=item["name"]
				var lv=item["lv"]
				var build_cost=Global.chara_tb[chara_name]["build_cost"]
				var build_time=Global.chara_tb[chara_name]["build_time"]
				var icon_file_path=Global.icon_img_file_path+chara_name+".png"
				var icon_texture=load(icon_file_path)
				var click_cb = funcref(self, "start_chara_cb")
				chara_gen_ui.get_child(i).on_create(icon_texture, build_time, build_cost, {"name":chara_name, "lv":lv}, click_cb,i,b_not_interactive)
			else:
				var item_name=item["name"]
				var num=item["num"]
				var item_db=Global.items_tb[item_name]
				var icon_file_path=Global.icon_img_file_path+item_name+".png"
				var icon_texture=load(icon_file_path)
				var click_cb = funcref(self, "use_item_cb")
				item_use_ui.get_child(i-5).on_create(icon_texture, item_db["delay"], num, {"name":item_name},click_cb,i,b_not_interactive)
		i=i+1
		
func process_frame():
	for _team_id in range(0,2):
		for item in chara_hotkey[_team_id]:
			if item ==null:
				continue
			item["countdown"]=item["countdown"]-frame_delay
	
func send_my_inputs():
	if my_inputs.size()>0:
		Global.battle_frame_send(my_inputs)
		my_inputs=[]

func recv_sync_frame(frame_data):
	if input_queue.size()!=frame_data["frame_id"]:
		print("recv_sync_frame error!!!")
		assert(false)
	var input=[[],[]]
	for user_id in frame_data["inputs"]:
		input[user_id_2_index[user_id]]=frame_data["inputs"][user_id]
	input_queue.append(input)
	if get_tree().paused:
		get_tree().paused=false

func _physics_process(_delta):
	if game_start==false:
		return   
	frame_id=frame_id+1
	if frame_time_countdown>0:
		frame_time_countdown=frame_time_countdown-1
	else:
		process_keyframe()
		frame_time_countdown=keyframe_step-1
	process_frame()

func process_keyframe():
	if Global.battle_mode=="pvp":
		send_my_inputs()
	elif Global.battle_mode=="level":
		if my_inputs.size()>0:
			Global.send_level_battle_inputs(my_inputs)
		input_queue.append([my_inputs,ai_node.ai_get_op()])
		my_inputs=[]
	if cur_frame>=input_queue.size():
		get_tree().paused=true
	else:
		var inputs = input_queue[cur_frame]
		for _team_id in range(0,2):
			if len(inputs[_team_id])>0:
				for key in inputs[_team_id]:
					if key==-1:
						if _team_id==master_id:
							stop_game(false)
						else:
							stop_game(true)
					elif key<5:
						var chara_name=chara_hotkey[_team_id][key]["name"]
						var chara_info=Global.chara_tb[chara_name]
						if chara_hotkey[_team_id][key]["countdown"]<=0 and check_chara_build(chara_info["build_cost"],_team_id):
							chara_hotkey[_team_id][key]["countdown"]=chara_info["build_time"]
							spawn_chara(chara_name, chara_hotkey[_team_id][key]["lv"], _team_id)
							change_coin(-chara_info["build_cost"], _team_id)
					else:
						var item_name=chara_hotkey[_team_id][key]["name"]
						chara_hotkey[_team_id][key]["num"]=chara_hotkey[_team_id][key]["num"]-1
						item_mgr.use_item(item_name, _team_id)
						if _team_id==master_id:
							var ui_item=item_use_ui.get_child(key-5)
							ui_item.set_val(chara_hotkey[_team_id][key]["num"])
						update_stats_ui()
		cur_frame=cur_frame+1

func _on_Return_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_node(comfirm_path).visible==false:
				get_node(comfirm_path).visible=true
				if Global.battle_mode!="pvp":
					get_tree().paused = true

func get_recording_data():
	var recording_data={}
	var ops=[[],[]]
	var t=0
	for item in input_queue:
		if item[0].size()!=0:
			ops[0].append([t,item[0]])
		if item[1].size()!=0:
			ops[1].append([t,item[1]])
		t=t+1
	recording_data["ops"]=ops
	recording_data["hotkeys"]=[[],[]]
	recording_data["coin"]=init_coin_num
	recording_data["kf_count"]=input_queue.size()
	for i in range(2):
		for item in chara_hotkey[i]:
			if item != null:
				if "lv" in item:
					recording_data["hotkeys"][i].append([item["name"],item["lv"]])
				else:
					recording_data["hotkeys"][i].append([item["name"],item["num"]])
			else:
				recording_data["hotkeys"][i].append(["",-1])
	return Marshalls.utf8_to_base64(JSON.print(recording_data)) 
