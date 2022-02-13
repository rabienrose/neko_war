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
var star_num=3
var battle_time=0
var timer_update_delay=1

var level_data=null

func _ready():
    fx_mgr=get_node("FxMgr")
    spawn_nodes.append(get_node(spawn1_path))
    spawn_nodes.append(get_node(spawn2_path))
    char_root=get_node(char_root_path)
    chara_gen_ui=get_node(chara_gen_ui_path)
    item_use_ui=get_node(item_use_ui_path)
    spawn_building("base1", 0)
    spawn_building("base2", 1)
    Global.emit_signal("money_change",100)
    level_data=Global.get_level_info(Global.sel_level)
    var cancel_cb = funcref(self, "cancel_cb")
    var go_home_cb = funcref(self, "go_home_cb")
    get_node(comfirm_path).set_btn1("Cancel", cancel_cb)
    get_node(comfirm_path).set_btn2("Ok", go_home_cb)
    update_hotkey_ui()
    update_timer_ui()
    get_node(lv_name_label_path).text="Lv: "+str(level_data["lv"])

func cancel_cb():
    get_tree().paused = false
    get_node(comfirm_path).visible=false

func go_home_cb():
    get_tree().paused = false
    Global.emit_signal("request_go_home")

func stop_game(b_win):
    var lv_gold=level_data["gold"]
    if star_num==1:
        lv_gold=lv_gold*2
    elif star_num==2:
        lv_gold=lv_gold*4
    elif star_num==3:
        lv_gold=lv_gold*8
    if b_win==false:
        star_num=-1
        lv_gold=0
    var show_next=true
    if Global.get_max_level()<Global.sel_level+1:
        show_next=false
    get_node(summary_path).show_summary(star_num,true,lv_gold,show_next)
    Global.user_data["gold"]=Global.user_data["gold"]+lv_gold
    var lv_str=str(Global.sel_level)
    if b_win:
        if not lv_str in Global.user_data["levels"]:
            Global.user_data["levels"][lv_str]={"lv":Global.sel_level,"star":star_num}
        else:
            var my_level_info = Global.user_data["levels"][lv_str]
            if my_level_info["star"]<star_num:
                my_level_info["star"]=star_num
        Global.save_user_data()

func get_charas_in_range(team_id, min_x, max_x):
    var temp_chars=team_charas[team_id]
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

func spawn_chara(chara_name, lv, team_id):
    var new_char = char_res.instance()
    char_root.add_child(new_char)
    var spawn_pos = spawn_nodes[team_id]
    init_object(new_char, spawn_pos, chara_name, lv, team_id)
    new_char.play_anim("mov")

func init_object(res, spawn_pos, chara_name, lv, team_id):
    res.on_create(self)
    team_charas[team_id].append(res)
    var chara_dat = Global.chara_tb[chara_name]
    var create_info={}
    lv=str(lv)
    create_info["hp"]=chara_dat["attrs"][lv]["hp"]
    if chara_dat["type"]=="chara":
        create_info["atk"]=chara_dat["attrs"][lv]["atk"]
        create_info["mov_spd"]=chara_dat["attrs"][lv]["mov_spd"]
        create_info["atk_spd"]=chara_dat["attrs"][lv]["atk_spd"]
        create_info["drop_gold"]=chara_dat["drop_gold"]
        create_info["atk_num"]=chara_dat["attrs"][lv]["atk_num"]
    res.set_attr_data(create_info)
    var anim_data=Global.get_char_anim(chara_name)
    res.set_anim(anim_data, Global.get_char_anim_info(chara_name))
    res.set_team(team_id)
    res.set_x_pos(spawn_pos.position.x)

func customComparison(a, b):
    return a.hp/a.max_hp > b.hp/b.max_hp

func request_use_item(item_name):
    if item_name=="done_at_once":
        for item in chara_gen_ui.get_items():
            item.set_done()
    var item_dat=Global.items_tb[item_name]
    var targets=[]
    if item_dat["target"]["group"]=="self_chara":
        for c in team_charas[0]:
            if c["type"] == "chara":
                targets.append(c)
    if item_dat["target"]["group"]=="enemy_chara":
        for c in team_charas[1]:
            if c["type"] == "chara":
                targets.append(c)
    if item_dat["target"]["amount"]!=-1:
        var new_targets=[]
        if item_dat["target"]["sel_type"]=="min_hp":
            targets.sort_custom(self, "customComparison")
        elif item_dat["target"]["sel_type"]=="rand":
            targets.shuffle()
        for c in targets:
            if len(new_targets)>item_dat["target"]["amount"]:
                break
            new_targets.append(c)
        targets=new_targets
    if item_dat["info"]["type_duration"] == "instance":
        if item_dat["info"]["type"] == "hp":
            if item_dat["info"]["op"]=="add":
                for chara in targets:
                    chara.change_hp(item_dat["info"]["val"],null)
    elif item_dat["info"]["type_duration"] == "buf":
        if item_dat["info"]["type"] == "attr":
            var buf=Character.Buf.new()
            buf.name=item_dat["info"]["buf_name"]
            buf.type=item_dat["info"]["type"]
            buf.data={"attr":item_dat["info"]["attr"],"val":item_dat["info"]["val"],"op":item_dat["info"]["op"]}
            buf.is_time_limit=true
            buf.max_layer=item_dat["info"]["max_layer"]
            buf.time_remain=item_dat["info"]["duration"]
            for chara in targets:
                chara.add_buf(buf)

func on_request_spawn_chara(chara_info):
    spawn_chara(chara_info["name"], chara_info["lv"], 0)

func remove_chara(chara):
    team_charas[chara.team_id].erase(chara)
    chara.dead=true
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

func update_star_ui():
    if star_num==0:
        get_node(star1_path).visible=false
        get_node(star2_path).visible=false
        get_node(star3_path).visible=false
    elif star_num==1:
        get_node(star1_path).visible=true
        get_node(star2_path).visible=false
        get_node(star3_path).visible=false
    elif star_num==2:
        get_node(star1_path).visible=true
        get_node(star2_path).visible=true
        get_node(star3_path).visible=false

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
    var new_star_num=star_num
    if battle_time>level_data["star1_time"]:
        new_star_num=0
    elif battle_time>level_data["star2_time"] and battle_time<=level_data["star1_time"]:
        new_star_num=1
    elif battle_time>level_data["star3_time"] and battle_time<=level_data["star2_time"]:
        new_star_num=2
    if new_star_num<star_num:
        star_num=new_star_num
        update_star_ui()
    if auto_spawn_countdown>0:
        auto_spawn_countdown=auto_spawn_countdown-delta
    else:
        var pass_items=[]
        for n in level_data["rand_pool"]:
            var t_rand = rand_range(0,1)
            if t_rand<n["chance"]:
                pass_items.append(n)
        var final_pass=null
        if len(pass_items)==0:
            var rand_i = floor(rand_range(0,len(level_data["rand_pool"])))
            final_pass=level_data["rand_pool"][rand_i]
        elif len(pass_items)>1:
            var rand_i = floor(rand_range(0,len(pass_items)))
            final_pass=pass_items[rand_i]
        else:
            final_pass=pass_items[0]
        spawn_chara(final_pass["name"], final_pass["lv"], 1)
        var rnd_time = level_data["spawn_delay_min"]+rand_range(0,1)*(level_data["spawn_delay_max"]-level_data["spawn_delay_min"])
        auto_spawn_countdown=rnd_time

func _on_Return_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if get_node(comfirm_path).visible==false:
                get_node(comfirm_path).visible=true
                get_tree().paused = true

