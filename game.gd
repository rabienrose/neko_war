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
export (NodePath) var lv_name_label_path

export (NodePath) var star1_path
export (NodePath) var star2_path
export (NodePath) var star3_path

var fx_mgr
var team_charas=[[],[]]
var char_root
var spawn_nodes=[]
var chara_gen_ui
var item_use_ui
var auto_spawn_countdown=0
var scene_min=440
var scene_max=3500
var gold=100
var stop=false
var battle_time=0
var timer_update_delay=1
var self_count=0
var live_self_count=0
var enemy_count=0
var live_enemy_count=0

var level_data=null

func _ready():
    level_data=Global.get_level_info(Global.sel_level)
    fx_mgr=get_node("FxMgr")
    spawn_nodes.append(get_node(spawn1_path))
    spawn_nodes.append(get_node(spawn2_path))
    char_root=get_node(char_root_path)
    chara_gen_ui=get_node(chara_gen_ui_path)
    item_use_ui=get_node(item_use_ui_path)
    spawn_building("base1", 0)
    spawn_building("base2", 1)
    gold=level_data["init_gold"]
    Global.emit_signal("money_change",gold)
    var cancel_cb = funcref(self, "cancel_cb")
    var go_home_cb = funcref(self, "go_home_cb")
    get_node(comfirm_path).set_btn1("Cancel", cancel_cb)
    get_node(comfirm_path).set_btn2("Ok", go_home_cb)
    update_hotkey_ui()
    update_timer_ui()
    get_node(lv_name_label_path).text="Lv: "+str(level_data["lv"])
    Global.connect("money_change",self,"on_money_change")

func cancel_cb():
    get_tree().paused = false
    get_node(comfirm_path).visible=false

func go_home_cb():
    get_tree().paused = false
    Global.emit_signal("request_go_home")

func stop_game(b_win):
    var lv_gold=level_data["gold"]
    var show_next=true
    show_next=false
    if b_win==false:
        lv_gold=0
    get_node(summary_path).show_summary(b_win, true,lv_gold,show_next)
    Global.user_data["gold"]=Global.user_data["gold"]+lv_gold
    var lv_str=Global.sel_level
    if b_win:
        if not lv_str in Global.user_data["levels"]:
            Global.user_data["levels"][lv_str]={"time":battle_time}
        else:
            if battle_time<Global.user_data["levels"][lv_str]["time"]:
                Global.user_data["levels"][lv_str]["time"]=battle_time
        Global.save_user_data()

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
    init_object(new_build, temp_pos_node, build_name, 1, team_id)
    new_build.max_hp=level_data["base_hp"]
    new_build.hp=new_build.max_hp

func spawn_chara(chara_name, lv, team_id):
    var new_char = char_res.instance()
    char_root.add_child(new_char)
    var spawn_pos = spawn_nodes[team_id]
    init_object(new_char, spawn_pos, chara_name, lv, team_id)

func init_object(res, spawn_pos, chara_name, lv, team_id):
    res.on_create(self)
    team_charas[team_id].append(res)
    var chara_dat = Global.chara_tb[chara_name]
    var create_info={}
    lv=str(lv)
    create_info["hp"]=chara_dat["attrs"][lv]["hp"]
    var temp_index=0
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
        if team_id==0:
            self_count=self_count+1
            live_self_count=live_self_count+1
            temp_index=self_count
        else:
            enemy_count=enemy_count+1
            live_enemy_count=live_enemy_count+1
            temp_index=enemy_count
        create_info["index"]=temp_index
    res.set_attr_data(create_info)
    var anim_data=Global.get_char_anim(chara_name, chara_dat["type"])
    var anim_info=Global.chara_tb[chara_name]["appearance"]
    res.set_anim(anim_data, anim_info)
    res.set_team(team_id)
    res.set_x_pos(spawn_pos.position.x)

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

func filter_targets(target_scheme, targets, amount):
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
    targets = filter_targets(skill_data["target_scheme"], targets, target_num)

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

func request_use_item(item_name):
    if item_name=="done_at_once":
        for item in chara_gen_ui.get_items():
            item.set_done()
    else:
        var item_dat=Global.items_tb[item_name]
        request_skill(item_dat, 0, null)

func on_request_spawn_chara(chara_info):
    spawn_chara(chara_info["name"], chara_info["lv"], 0)

func remove_chara(chara):
    team_charas[chara.team_id].erase(chara)
    chara.queue_free()

func expend_gold(val):
    if gold-val<0:
        return false
    else:
        change_gold(-val)
        return true
    
func change_gold(val):
    gold=gold+val
    Global.emit_signal("money_change",gold)

func update_timer_ui():
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
    request_use_item(item.custom_info["name"])
    if item.custom_val-1<0:
        return false
    item.set_val(item.custom_val-1)
    var my_item_info = Global.get_my_item_info(item.custom_info["name"])
    my_item_info["num"]=item.custom_val
    Global.save_user_data()
    return true

func start_chara_cb(item):
    return expend_gold(item.custom_val)

func end_chara_cb(item):
    on_request_spawn_chara(item.custom_info)

func on_money_change(val):
    for c in chara_gen_ui.get_items():
        if c.has_item==false:
            continue
        c.set_mask(c.custom_val>val)

func update_hotkey_ui():
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
        var delay_cb = funcref(self, "end_chara_cb")
        chara_gen_ui.get_child(i).on_create(icon_texture, build_time, build_cost, {"name":chara_name, "lv":lv}, click_cb, delay_cb)
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
        item_use_ui.get_child(i).on_create(icon_texture, item_db["delay"], num, {"name":item_name},click_cb,null)

func _physics_process(delta):
    timer_update_delay=timer_update_delay-delta
    if timer_update_delay<0:
        timer_update_delay=1
        update_timer_ui()
    battle_time=battle_time+delta
    if auto_spawn_countdown>0:
        auto_spawn_countdown=auto_spawn_countdown-delta
    else:
        var cell_index=enemy_count%len(level_data["cell_sequence"])
        spawn_chara(level_data["cell_sequence"][cell_index], level_data["lv"], 1)
        var rnd_time = level_data["spawn_delay"]*0.5+rand_range(0,1)*(level_data["spawn_delay"]*1.5-level_data["spawn_delay"]*0.5)
        auto_spawn_countdown=rnd_time

func _on_Return_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if get_node(comfirm_path).visible==false:
                get_node(comfirm_path).visible=true
                get_tree().paused = true

