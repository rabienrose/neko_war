extends Control

export (NodePath) var level_grid_path
export (NodePath) var level_info_path
export (NodePath) var chara_grid_path
export (NodePath) var chara_info_path
export (NodePath) var item_grid_path
export (NodePath) var item_info_path
export (NodePath) var lottory_item_path
export (NodePath) var lottory_info_path
export (NodePath) var chara_hotkey_path
export (NodePath) var item_hotkey_path
export (NodePath) var drag_icon_path
export (NodePath) var drag_icon_bg_path
export (NodePath) var upgrade_btn_path
export (NodePath) var upgrade_btn_bg_path
export (NodePath) var level_label_path
export (NodePath) var chara_label_path
export (NodePath) var item_label_path
export (NodePath) var lottery_label_path
export (NodePath) var level_container_path
export (NodePath) var chara_container_path
export (NodePath) var item_container_path
export (NodePath) var lottery_container_path
export (NodePath) var lottery_price_path

export (Resource) var level_item_res
export (Resource) var drop_item_res

var level_grid
var level_info
var chara_grid
var chara_info
var item_grid
var item_info
var drag_icon
var drag_icon_bg

var chara_hotkey=[]
var item_hotkey=[]

var cur_level_page=0
var cur_sel_level=-1
var cur_sel_chara=""
var cur_sel_item=""
var cur_drag_chara=""
var cur_drag_item=""


func _ready():
    Global.connect("show_level_info",self, "on_show_level_info")
    level_grid=get_node(level_grid_path)
    level_info=get_node(level_info_path)
    chara_grid=get_node(chara_grid_path)
    chara_info=get_node(chara_info_path)
    item_grid=get_node(item_grid_path)
    item_info=get_node(item_info_path)
    chara_hotkey=get_node(chara_hotkey_path)
    item_hotkey=get_node(item_hotkey_path)
    drag_icon=get_node(drag_icon_path)
    drag_icon_bg=get_node(drag_icon_bg_path)
    var click_cb = funcref(self, "chara_item_click_cb")
    for c in chara_hotkey.get_children():
        c.set_cb(click_cb)
    click_cb = funcref(self, "item_item_click_cb")
    for c in item_hotkey.get_children():
        c.set_cb(click_cb)
    update_levels_ui()
    update_characters_ui()
    update_items_ui()
    update_status()
    update_lottery_ui()

func on_show_level_info(lv):
    cur_sel_level=lv
    var str_temp=""
    str_temp=str_temp+Global.levels_tb[lv]["title"]+"\n\n"
    str_temp=str_temp+"Level: "+str(lv)+"\n\n"
    str_temp=str_temp+"Description:\n"+Global.levels_tb[lv]["desc"]+"\n\n"
    get_node(level_info_path).text=str_temp

func chara_item_click_cb(chara_name):
    var chara_db = Global.chara_tb[chara_name]
    var str_temp=""
    var my_chara_info = Global.get_my_chara_info(chara_name)
    cur_sel_chara=chara_name
    str_temp=str_temp+chara_db["name"]+"\n\n"
    str_temp=str_temp+"Description:\n"+chara_db["desc"]+"\n\n"
    chara_info.text=str_temp
    clear_grid_highlight(chara_grid)
    clear_grid_highlight(chara_hotkey)
    var upgrage_price=Global.get_upgrade_price(chara_name, my_chara_info["lv"])
    if upgrage_price>0:
        get_node(upgrade_btn_bg_path).visible=true
        get_node(upgrade_btn_path).text=str("UP  ("+str(upgrage_price)+")")
    else:
        get_node(upgrade_btn_bg_path).visible=false

func item_item_click_cb(item_name):
    var item_db = Global.items_tb[item_name]
    var str_temp=""
    var my_item_info = Global.get_my_item_info(item_name)
    cur_sel_item=item_name
    str_temp=str_temp+item_db["name"]+"\n\n"
    str_temp=str_temp+"Price: "+str(item_db["price"])+"\n\n"
    str_temp=str_temp+"Description:\n"+item_db["desc"]+"\n\n"
    item_info.text=str_temp
    clear_grid_highlight(item_grid)
    clear_grid_highlight(item_hotkey)

func clear_grid_highlight(grid_node):
    for c in grid_node.get_children():
        c.set_highlight(false)

func set_chara_hk_slot(slot_id, chara_name):
    var item = chara_hotkey.get_child(slot_id)
    var icon_file_path=Global.char_img_file_path+chara_name+"/icon.png"
    var icon_texture=load(icon_file_path)
    item.set_icon(icon_texture)
    var info = Global.get_my_chara_info(chara_name)
    if info==null:
        return
    item.set_num(info["lv"])
    item.set_data(chara_name)
    Global.user_data["equip"]["chara"][slot_id]=chara_name
    Global.save_user_data()

func clear_item_hk_slot(slot_id):
    var item = item_hotkey.get_child(slot_id)
    item.clear()
    Global.user_data["equip"]["item"][slot_id]=""
    Global.save_user_data()

func set_item_hk_slot(slot_id, item_name):
    var item = item_hotkey.get_child(slot_id)
    var icon_file_path=Global.item_img_file_path+item_name+"/icon.png"
    var icon_texture=load(icon_file_path)
    item.set_icon(icon_texture)
    var info = Global.get_my_item_info(item_name)
    if info==null:
        return
    item.set_num(info["num"])
    item.set_data(item_name)
    Global.user_data["equip"]["item"][slot_id]=item_name
    Global.save_user_data()

func update_levels_ui():
    var last_pass_lv=-1
    for lv_info in Global.levels_tb:
        var level_item = level_item_res.instance()
        level_item.container=level_grid
        var lv_num=str(lv_info["lv"])
        if lv_num in Global.user_data["levels"]:
            level_item.set_lock(false, int(lv_num), Global.user_data["levels"][lv_num]["star"])
            last_pass_lv=lv_num
        else:
            if int(last_pass_lv)==int(lv_num)-1:
                level_item.set_lock(false, int(lv_num), -1)
            else:
                level_item.set_lock(true, -1, -1)
        level_grid.add_child(level_item)

func update_characters_ui():
    var click_cb = funcref(self, "chara_item_click_cb")
    var drag_cb = funcref(self, "drag_chara_icon_cb")
    Global.delete_children(chara_grid)
    for chara in Global.user_data["characters"]:
        var chara_name=chara["name"]
        var item = drop_item_res.instance()
        var icon_file_path=Global.char_img_file_path+chara_name+"/icon.png"
        var icon_texture=load(icon_file_path)
        item.set_icon(icon_texture)
        item.set_num(chara["lv"])
        item.set_data(chara_name)
        item.set_cb(click_cb)
        item.drag_cb=drag_cb
        chara_grid.add_child(item)
    var chara_equip_info=Global.user_data["equip"]["chara"]
    for i in range(len(chara_equip_info)):
        var chara_name=chara_equip_info[i]
        if chara_name=="":
            continue
        set_chara_hk_slot(i, chara_name)
    if cur_sel_chara!="":
        chara_item_click_cb(cur_sel_chara)

func update_items_ui():
    var click_cb = funcref(self, "item_item_click_cb")
    var drag_cb = funcref(self, "drag_item_icon_cb")
    Global.delete_children(item_grid)
    for item in Global.user_data["items"]:
        var item_name=item["name"]
        var itemitem = drop_item_res.instance()
        var icon_file_path=Global.item_img_file_path+item_name+"/icon.png"
        var icon_texture=load(icon_file_path)
        itemitem.set_icon(icon_texture)
        itemitem.set_num(item["num"])
        itemitem.set_data(item_name)
        itemitem.set_cb(click_cb)
        itemitem.drag_cb=drag_cb
        item_grid.add_child(itemitem)
    var item_equip_info=Global.user_data["equip"]["item"]
    for i in range(len(item_equip_info)):
        var item_name=item_equip_info[i]
        if item_name=="":
            continue
        set_item_hk_slot(i, item_name)

func update_lottery_ui():
    get_node(lottery_price_path).text=str(Global.lottery_price)+" Gold"  

func drag_chara_icon_cb(chara_name, pos):
    if cur_drag_chara=="":
        cur_drag_chara=chara_name
        set_icon(drag_icon, false, chara_name)
        drag_icon_bg.visible=true
    drag_icon_bg.set_global_position(pos+Vector2(-90,-90))

func set_icon(icon_node, b_item, name):
    var icon_file_path=Global.item_img_file_path+name+"/icon.png"
    if b_item==false:
        icon_file_path=Global.char_img_file_path+name+"/icon.png"
    var icon_texture=load(icon_file_path)
    icon_node.texture=icon_texture

func drag_item_icon_cb(item_name, pos):
    if cur_drag_item=="":
        cur_drag_item=item_name
        set_icon(drag_icon, true, item_name)
        drag_icon_bg.visible=true
    drag_icon_bg.set_global_position(pos+Vector2(-90,-90))

func hide_drag_icon():
    drag_icon_bg.visible=false

func check_in_control(query_pos, control):
    return control.get_global_rect().has_point(query_pos)

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed==false:
            for c in chara_hotkey.get_children():
                var t_pos=Vector2(event.position.x, event.position.y)
                if check_in_control(t_pos, c):
                    if cur_drag_chara!="":
                        set_chara_hk_slot(c.get_index(), cur_drag_chara)
                    if cur_drag_item!="":
                        for i in range(len(Global.user_data["equip"]["item"])):
                            if Global.user_data["equip"]["item"][i]==cur_drag_item:
                                clear_item_hk_slot(i)
                        set_item_hk_slot(c.get_index(), cur_drag_item)
            cur_drag_chara=""
            cur_drag_item=""
            hide_drag_icon()

func hide_all_tabs():
    get_node(level_label_path).add_color_override("font_color", Color.white)
    get_node(chara_label_path).add_color_override("font_color", Color.white)
    get_node(item_label_path).add_color_override("font_color", Color.white)
    get_node(lottery_label_path).add_color_override("font_color", Color.white)
    
    get_node(level_container_path).visible=false
    get_node(chara_container_path).visible=false
    get_node(item_container_path).visible=false
    get_node(lottery_container_path).visible=false

func update_status():
    Global.emit_signal("money_change",Global.user_data["gold"])

func show_tab(name):
    if name=="level":
        get_node(level_label_path).add_color_override("font_color", Color.red)
        get_node(level_container_path).visible=true
    elif name=="chara":
        get_node(chara_label_path).add_color_override("font_color", Color.red)
        get_node(chara_container_path).visible=true
    elif name=="item":
        get_node(item_label_path).add_color_override("font_color", Color.red)
        get_node(item_container_path).visible=true
    elif name=="lottery":
        get_node(lottery_label_path).add_color_override("font_color", Color.red)
        get_node(lottery_container_path).visible=true

func on_tab_button(btn_name, event):
    if event is InputEventScreenTouch:
        if event.pressed==true:
            hide_all_tabs()
            show_tab(btn_name)

func _on_Buy_gui_input(event:InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed==true:
            if cur_sel_item!="":
                var item_sell_price=Global.items_tb[cur_sel_item]["price"]
                if Global.expend_user_money(item_sell_price)==false:
                    return
                var my_item_info = Global.get_my_item_info(cur_sel_item)
                my_item_info["num"]=my_item_info["num"]+1
                update_items_ui()

func _on_Upgrade_gui_input(event:InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed==true:
            if cur_sel_chara!="":
                var my_chara_info = Global.get_my_chara_info(cur_sel_chara)
                var chara_lv=my_chara_info["lv"]
                var upgrade_price=Global.get_upgrade_price(cur_sel_chara, chara_lv)
                if upgrade_price<0:
                    return
                if Global.expend_user_money(upgrade_price)==false:
                    return
                my_chara_info["lv"]=my_chara_info["lv"]+1
                update_characters_ui()

func _on_TryBtn_gui_input(event:InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed==true:
            if Global.expend_user_money(Global.lottery_price)==false:
                return
            #draw chara
            var temp_my_charas=Global.get_my_charas_dict()
            var remain_charas=[]
            var result_chara=null
            for chara_name in Global.chara_tb:
                var chara=Global.chara_tb[chara_name]
                if chara_name in temp_my_charas:
                    continue
                if chara["type"]!="chara":
                    continue
                var t_rand = rand_range(0,1)
                if t_rand<chara["chance"]:
                    remain_charas.append(chara)
            if len(remain_charas)>1:
                var rand_i = floor(rand_range(0,len(remain_charas)))
                result_chara=remain_charas[rand_i]
            elif len(remain_charas)==1:
                result_chara=remain_charas[0]
            if result_chara!=null:
                var my_chara_info = Global.get_my_chara_info(result_chara["name"])
                if my_chara_info==null:
                    var chara_info_t={}
                    chara_info_t["name"]=result_chara["name"]
                    chara_info_t["lv"]=1
                    Global.user_data["characters"].append(chara_info_t)
                    set_icon(get_node(lottory_item_path), false, result_chara["name"])
                    Global.save_user_data()
                    update_characters_ui()
            else:
                #draw item
                var result_item=null
                var remain_items=[]
                for item_name in Global.items_tb:
                    var item = Global.items_tb[item_name]
                    var t_rand = rand_range(0,1)
                    if t_rand<item["chance"]:
                        remain_items.append(item)
                    if len(remain_items)==0:
                        var temp_items=[]
                        for item_name_1 in Global.items_tb:
                            temp_items.append(Global.items_tb[item_name_1])
                        var rand_i = floor(rand_range(0,len(temp_items)))
                        result_item=temp_items[rand_i]
                    elif len(remain_items)>1:
                        var rand_i = floor(rand_range(0,len(remain_items)))
                        result_item=remain_items[rand_i]
                    else:
                        result_item=remain_items[0]
                var my_item_info = Global.get_my_item_info(result_item["name"])
                if my_item_info==null:
                    var item_info_t={}
                    item_info_t["name"]=result_item["name"]
                    item_info_t["num"]=1
                    Global.user_data["items"].append(item_info_t)
                else:
                    my_item_info["num"]=my_item_info["num"]+1
                set_icon(get_node(lottory_item_path), true, result_item["name"])
                Global.save_user_data()
                update_items_ui()
    
func _on_Level_gui_input(event):
    on_tab_button("level", event)

func _on_Character_gui_input(event):
    on_tab_button("chara", event)

func _on_Item_gui_input(event):
    on_tab_button("item", event)

func _on_Lottery_gui_input(event):
    on_tab_button("lottery", event)

func _on_Rank_gui_input(event):
    on_tab_button("rank", event)

func _on_Start_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if cur_sel_level>=0:
                Global.emit_signal("request_battle",cur_sel_level)
