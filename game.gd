extends Node2D

export (Resource) var char_res
export (Resource) var build_res
export (NodePath) var char_root_path
export (NodePath) var spawn1_path
export (NodePath) var spawn2_path
export (NodePath) var chara_gen_ui_path
export (NodePath) var item_use_ui_path
export (NodePath) var base1_path
export (NodePath) var base2_path
export (NodePath) var foreground_path
export (NodePath) var summary_path
export (NodePath) var game_status_path
export (NodePath) var comfirm_path
export (NodePath) var timer_label_path
export (NodePath) var lobby_path
export (NodePath) var lobby_msg_path
export (NodePath) var chara1_list_path
export (NodePath) var chara2_list_path
export (NodePath) var meat1_label_path
export (NodePath) var meat2_label_path
export (NodePath) var diamond1_label_path
export (NodePath) var diamond2_label_path
export (NodePath) var diamond_pool_label_path
export (NodePath) var diamond_pool_path
export (NodePath) var server_path
export (NodePath) var cam_path

var fx_mgr
var char_root
var chara_gen_ui
var item_use_ui
var frame_time_countdown=0
var frame_delay=0.02
var fps=int(1/frame_delay)
var keyframe_step=10
var keyframe_p_s=int(fps/keyframe_step)
var scene_min=440
var scene_max=3500

var stop=false
var timer_ui_delay=1

var next_replay_time=0
var next_replay_index=0

var player_setting=["local","ai"] #local, remote, ai

#input args
var level_data={}
var chara_lv=0
var reward_discount=[1,1]
var base_hp

var server
var recording_data=[[],[]]
var replay_data=[[],[]]
var live_chara_count=[0,0]
var chara_count=[0,0]
var chara_hotkey=[[null,null,null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null,null,null]]

var meat_num=[0,0]
var init_meat_num=[0,0]
var diamond_num=[0,0]
var init_diamond_num=[0,0]
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
var other_frame_id=-1

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
            level_data=Global.level_data["battle_data"]
            var info_t=Global.get_cur_level_info()
            chara_lv=info_t["chara_lv"]
            reward_discount[1]=Global.global_data["level_reward_discount"][info_t["difficulty"]]
            reward_discount[0]=stepify(1/reward_discount[1],0.1)
            get_node(diamond1_label_path).get_parent().visible=false
            get_node(meat1_label_path).get_parent().visible=true
            get_node(diamond2_label_path).get_parent().visible=false
            get_node(meat2_label_path).get_parent().visible=true
            init_meat_num[0]=Global.global_data["level_init_gold"]
            init_meat_num[1]=Global.global_data["level_init_gold"]*Global.global_data["level_init_discount"][info_t["difficulty"]]
            base_hp=level_data["base_hp"]
            meat_num[0]=init_meat_num[0]
            meat_num[1]=init_meat_num[1]
            ai_nodes=[]
            ai_nodes.append(null)
            var t_node=Node.new()
            t_node.set_script(load("res://ai/"+level_data["script"]+".gd"))
            add_child(t_node)
            t_node.init(self, level_data["args"]["hotkey"], 1, chara_lv)
            ai_nodes.append(t_node)
            start_battle()
            update_hotkey_ui(0)
            last_items_num=chara_hotkey.duplicate(true)
            init_items_num=chara_hotkey.duplicate(true)
        if Global.pvp_mode:
            server.start_clinet()
        if Global.replay_mode:
            get_node(chara_gen_ui_path).visible=false
            get_node(item_use_ui_path).visible=false
            get_node(diamond1_label_path).get_parent().visible=false
            get_node(diamond2_label_path).get_parent().visible=false
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
    spawn_building("base1", 0)
    spawn_building("base2", 1)
    var cancel_cb = funcref(self, "cancel_cb")
    var go_home_cb = funcref(self, "go_home_cb")
    get_node(comfirm_path).set_btn1("Cancel", cancel_cb)
    get_node(comfirm_path).set_btn2("Ok", go_home_cb)
    update_timer_ui()        
    game_start=true

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

func get_battle_time():
    return server.cur_frame/keyframe_p_s

func get_item_used_stats(team_id):
    var items={}
    for i in range(5,10):
        if last_items_num[team_id][i] != null:
            var used_num = last_items_num[team_id][i]["num"]-chara_hotkey[team_id][i]["num"]
            if used_num>0:
                items[last_items_num[team_id][i]["name"]]=used_num
    if items.empty()==false:
        last_items_num=chara_hotkey.duplicate(true)
    return items

func stop_game(b_win):
    if Global.level_mode:
        var lv_gold=level_data["gold"]
        var lv_info=Global.get_cur_level_info()
        lv_gold=lv_gold*Global.global_data["difficulty_gold_coef"][lv_info["difficulty"]]*Global.global_data["chara_gold_coef"][lv_info["chara_lv"]]
        if b_win==false:
            lv_gold=0
        get_node(summary_path).show_summary(b_win, true,lv_gold,true)
        if b_win:
            Global.user_data["gold"]=Global.user_data["gold"]+lv_gold
            var recording=server.get_recording_data()
            Global.upload_level_summery(recording, get_battle_time(), lv_info["id"], lv_info["chara_lv"], lv_info["difficulty"])
    if Global.pvp_mode:
        get_node(diamond_pool_path).visible=false
        var local_team=find_local_team_id()
        var used_diamond=init_diamond_num[local_team]-diamond_num[local_team]
        var diamond_change=0
        if b_win:
            diamond_change=get_total_used_diamond()-used_diamond
        else:
            diamond_change=-used_diamond
        get_node(summary_path).show_summary(b_win, true,diamond_change,false)
        if find_local_team_id()==0:
            var recording=server.get_recording_data()
            var result="team1"
            if b_win==false:
                result="team2"
            Global.upload_pvp_summery(recording,result ,Global.token, server.enemy_token, used_diamond, get_total_used_diamond()-used_diamond)
        server.exit_battle()    
    if Global.replay_mode:
        get_node(comfirm_path).hide_btn(1)
        get_node(comfirm_path).visible=true
        get_tree().paused = true

func get_charas_in_range(min_x, max_x, targets):
    var temp_chars=targets
    var out_charas=[]
    for chara in temp_chars:
        if chara.position.x>=min_x and chara.position.x<=max_x:
            out_charas.append(chara)
    return out_charas

func spawn_building(build_name, team_id):
    var new_build = build_res.instance()
    get_node(foreground_path).add_child(new_build)
    var temp_pos_node=get_node(base1_path)
    if team_id==1:
        temp_pos_node=get_node(base2_path)
    init_object(new_build, temp_pos_node.position.x, build_name, 1, team_id)
    new_build.max_hp=base_hp
    new_build.hp=new_build.max_hp

func spawn_chara(chara_name, lv, team_id):
    var new_char = char_res.instance()
    char_root.add_child(new_char)
    var spawn_pos = spawn_nodes[team_id]
    init_object(new_char, spawn_pos.position.x+Global.rng.randf_range(-50,50), chara_name, lv, team_id)

func init_object(res, spawn_pos, chara_name, lv, team_id):
    res.on_create(self)
    team_charas[team_id].append(res)
    var chara_dat = Global.chara_tb[chara_name]
    var create_info={}
    lv=str(lv)
    create_info["hp"]=chara_dat["attrs"][lv]["hp"]
    if chara_dat["type"]=="chara":
        create_info["lv"]=lv
        create_info["atk"]=chara_dat["attrs"][lv]["atk"]
        create_info["mov_spd"]=chara_dat["attrs"][lv]["mov_spd"]
        create_info["atk_spd"]=chara_dat["attrs"][lv]["atk_spd"]
        create_info["range"]=chara_dat["attrs"][lv]["range"]
        create_info["flee"]=chara_dat["attrs"][lv]["flee"]
        create_info["deff"]=chara_dat["attrs"][lv]["deff"]
        create_info["cri"]=chara_dat["attrs"][lv]["cri"]
        create_info["luk"]=chara_dat["attrs"][lv]["luk"]
        create_info["atk_num"]=chara_dat["attrs"][lv]["atk_num"]
        create_info["drop_gold"]=chara_dat["drop_gold"]
        create_info["skills"]=chara_dat["skills"]
        create_info["atk_buf"]=chara_dat["atk_buf"]
        create_info["target_scheme"]=chara_dat["target_scheme"]
        create_info["self_destroy"]=chara_dat["self_destroy"]
        create_info["reward_discount"]=reward_discount[team_id]
        chara_count[team_id]=chara_count[team_id]+1
        live_chara_count[team_id]=live_chara_count[team_id]+1
        create_info["index"]=chara_count[team_id]
    create_info["chara_name"]=chara_name
    res.set_attr_data(create_info)
    var anim_data=Global.get_char_anim(chara_name, chara_dat["type"])
    var anim_info=Global.chara_tb[chara_name]["appearance"]
    res.set_anim(anim_data, anim_info)
    res.set_team(team_id, find_local_team_id()==team_id)
    res.set_x_pos(spawn_pos)
    update_chara_list_ui()

func hp_comparison(a, b):
    return a.hp/a.max_hp > b.hp/b.max_hp

func index_comparison_inc(a, b):
    return a.chara_index < b.chara_index

func index_comparison_dec(a, b):
    return a.chara_index > b.chara_index

func get_charas_by_group(group_names, type_names, team_id):
    var targets=[]
    var b_chara=false
    var b_building=false
    if "chara" in type_names:
        b_chara=true
    if "building" in type_names:
        b_building=true
    if "self" in group_names:
        for c in team_charas[team_id]:
            if c.visible==false or c.dead==true:
                continue
            if c.type == "chara" and b_chara:
                targets.append(c)
            if c.type == "building" and b_building:
                targets.append(c)
    if "enemy" in group_names:
        var enemy_id=-1
        if team_id==0:
            enemy_id=1
        else:
            enemy_id=0
        for c in team_charas[enemy_id]:
            if c.visible==false or c.dead==true:
                continue
            if c.type == "chara" and b_chara:
                targets.append(c)
            if c.type == "building" and b_building:
                targets.append(c)
    return targets

func filter_targets(target_scheme, targets, amount, self_chara):
    if amount!=-1:
        var new_targets=[]
        if target_scheme["sel_type"]=="min_hp":
            targets.sort_custom(self, "hp_comparison")
        elif target_scheme["sel_type"]=="rand":
            targets.shuffle()
        elif target_scheme["sel_type"]=="new":
            targets.sort_custom(self, "index_comparison_dec")
        elif target_scheme["sel_type"]=="old":
            targets.sort_custom(self, "index_comparison_inc")
        elif target_scheme["sel_type"]=="near":
            var near_char=null
            var min_dist=-1
            for t in targets:
                var dist = abs(t.position.x-self_chara.position.x)
                if t==self_chara:
                    continue
                if near_char==null or dist<min_dist:
                    min_dist=dist
                    near_char=t
            if near_char!=null:
                targets=[near_char]
        for c in targets:
            new_targets.append(c)
            if len(new_targets)>=amount:
                break
        targets=new_targets
    return targets

func apply_op(op, val, base_val):
    if op=="add":
        base_val=base_val+val
    elif op=="mul":
        base_val=base_val*val
    return base_val

func create_buf(buf_info):
    var buf=Character.Buf.new()
    buf.name=buf_info["buf_name"]
    buf.type=buf_info["type"]
    buf.data=buf_info["data"]
    buf.is_time_limit=true
    buf.max_layer=buf_info["max_layer"]
    buf.time_remain=buf_info["duration"]
    return buf

func apply_skill(targets, skill_data, self_chara):
    if skill_data["type"]=="instance":
        var inst_type=skill_data["info"]["type"]
        if inst_type == "hp" or inst_type == "life_steal":
            if skill_data["info"]["data"]["op"]=="add":
                for chara in targets:
                    if is_instance_valid(chara) and chara.dead==false:
                        chara.change_hp(skill_data["info"]["data"]["val"],null)
                        if inst_type=="life_steal":
                            self_chara.change_hp(-skill_data["info"]["data"]["val"],null)
        elif inst_type == "attr":
            pass
    elif skill_data["type"]=="buf":
        var new_buf = create_buf(skill_data["info"])
        for chara in targets:
            chara.add_buf(new_buf)
    elif skill_data["type"]=="push":
        for chara in targets:
            chara.add_back_buf(skill_data["distance"])

func request_skill(skill_data, team_id, self_chara):
    var targets=get_charas_by_group(skill_data["target_scheme"]["group"],skill_data["target_scheme"]["type"], team_id)
    if self_chara!=null:
        var range_atk=self_chara.get_min_max_atk_range()
        targets=get_charas_in_range(range_atk[0], range_atk[1],targets)
    var target_num=-1
    if "amount" in skill_data["target_scheme"]:
        target_num = skill_data["target_scheme"]["amount"]
    if self_chara!=null:
        target_num=self_chara.atk_num
    if len(targets)>0:
        targets = filter_targets(skill_data["target_scheme"], targets, target_num, self_chara)

    if len(targets)>0:
        if self_chara!=null:
            if skill_data["name"]=="heal_all":
                var new_targets=[]
                for c in targets:
                    if c.hp<c.max_hp:
                        new_targets.append(c)
                if len(new_targets)==0:
                    return 
                else:
                    targets=new_targets
            self_chara.play_skill_anim(targets, skill_data["name"])
        else:
            apply_skill(targets, skill_data, null)

func request_use_item(item_name, team_id):
    if item_name=="done_at_once":
        for item in chara_gen_ui.get_items():
            item.set_done()
    else:
        var item_dat=Global.items_tb[item_name]
        request_skill(item_dat, team_id, null)

func remove_chara(chara):
    team_charas[chara.team_id].erase(chara)
    chara.queue_free()    
    
func change_meat(change_val, team_id):
    if change_val>0:
        meat_num[team_id]=meat_num[team_id]+change_val
    else:
        if -change_val<=meat_num[team_id]:
            meat_num[team_id]=meat_num[team_id]+change_val
        else:
            var remain_cost=-change_val-meat_num[team_id]
            if remain_cost<=diamond_num[team_id]:
                meat_num[team_id]=0
                diamond_num[team_id]=diamond_num[team_id]-remain_cost
            else:
                print("expend meat error!!")
    update_stats_ui()

func check_chara_build(chara_cost, team_id):
    if chara_cost<=meat_num[team_id]:
        return true
    else:
        if chara_cost<=diamond_num[team_id]+meat_num[team_id]:
            return true
    return false

func update_chara_list_ui():
    var chara_num_stats=[{},{}]
    for c in char_root.get_children():
        if is_instance_valid(c)==false:
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
    if init_diamond_num[0]==0 and init_diamond_num[1]==0:
        return 0
    var diamond_expand=init_diamond_num[0]-diamond_num[0]+init_diamond_num[1]-diamond_num[1]
    var item_diamond=0
    for team_id in range(0,2):
        for i in range(5,10):
            if init_items_num[team_id][i] != null:
                var used_num = init_items_num[team_id][i]["num"]-chara_hotkey[team_id][i]["num"]
                if used_num>0:
                    var single_cost = Global.items_tb[init_items_num[team_id][i]["name"]]["price"]
                    item_diamond=item_diamond+single_cost*used_num
    return item_diamond+diamond_expand

func update_stats_ui():
    get_node(meat1_label_path).text="Meat: "+str(meat_num[0])
    get_node(meat2_label_path).text="Meat: "+str(meat_num[1])
    get_node(diamond1_label_path).text="D: "+str(diamond_num[0])
    get_node(diamond2_label_path).text="D: "+str(diamond_num[1])
    get_node(diamond_pool_label_path).text=str(get_total_used_diamond())
    update_hk_mask()

func update_timer_ui():
    var battle_time=get_battle_time()
    var m = floor(battle_time/60)
    var s = floor(battle_time-m*60)
    if m<10:
        m="0"+str(m)
    else:
        m=str(m)
    if s<10:
        s="0"+str(s)
    else:
        s=str(s)
    var str_time=m+" : "+s
    get_node(timer_label_path).text=str_time

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
    for i in range(len(Global.user_data["equip"]["chara"])):
        var chara_name=Global.user_data["equip"]["chara"][i]
        if chara_name=="":
            continue
        var my_chara_info = Global.get_my_chara_info(chara_name)
        var lv=my_chara_info["lv"]
        var build_cost=Global.chara_tb[chara_name]["build_cost"]
        var build_time=Global.chara_tb[chara_name]["build_time"]
        var icon_file_path=Global.char_img_file_path+chara_name+"/icon.png"
        var icon_texture=load(icon_file_path)
        var click_cb = funcref(self, "start_chara_cb")
        chara_gen_ui.get_child(i).on_create(icon_texture, build_time, build_cost, {"name":chara_name, "lv":lv}, click_cb,i)
        var hk_info={}
        hk_info["countdown"]=0
        hk_info["lv"]=lv
        hk_info["name"]=chara_name
        chara_hotkey[_local_team_id][i]=hk_info
    for i in range(len(Global.user_data["equip"]["item"])):
        var item_name=Global.user_data["equip"]["item"][i]
        if item_name=="":
            continue
        var my_item_info = Global.get_my_item_info(item_name)
        var item_db=Global.items_tb[item_name]
        var num=my_item_info["num"]
        var icon_file_path=Global.item_img_file_path+item_name+"/icon.png"
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
    timer_ui_delay=timer_ui_delay-frame_delay
    if timer_ui_delay<0:
        timer_ui_delay=1
        update_timer_ui()
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
