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
export (NodePath) var pvp_label_path
export (NodePath) var level_container_path
export (NodePath) var chara_container_path
export (NodePath) var item_container_path
export (NodePath) var lottery_container_path
export (NodePath) var pvp_container_path
export (NodePath) var rank_list_path
export (NodePath) var lottery_price_path
export (NodePath) var tab_dots_path
export (NodePath) var rank_path
export (NodePath) var pvp_cost_label_path
export (NodePath) var user_stats_path
export (NodePath) var replay_btn_path
export (NodePath) var user_setting_path

export (NodePath) var tip_start_battle_arrow_path

export (Resource) var level_item_res
export (Resource) var drop_item_res
export (Resource) var tab_dot_res
export (Resource) var rank_item_res

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
var cur_sel_chara=""
var cur_sel_item=""
var cur_drag_chara=""
var cur_drag_item=""

var chara_lv_num=10
var hardness_num=7
var cur_level_page_ind=0

var http

func _ready():
	get_tree().paused = false
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
	init_tab_dots(len(Global.lv_name_list))
	set_tab_dot_sel(0)
	update_levels_ui(Global.lv_name_list[cur_level_page_ind])
	update_characters_ui()
	update_items_ui()
	update_status()
	update_lottery_ui()
	update_pvp_ui()

func on_show_level_info(lv_name):
#    if not "start_level" in Global.user_data["tips"]:
#        get_node(tip_start_battle_arrow_path).visible=true
	Global.sel_level=lv_name
	var level_info=Global.get_cur_level_info()
	var str_temp=""
	str_temp=str_temp+str(Global.level_data["battle_data"]["gold"])+" gold\n"
	str_temp=str_temp+"Lv: "+str(level_info["chara_lv"])+"\n"
	str_temp=str_temp+"Difficulty: "+str(level_info["difficulty"])+"\n"
	var stat_name=str(level_info["chara_lv"])+"_"+str(level_info["difficulty"])
	if "record" in Global.level_data and stat_name in Global.level_data["record"]:
		get_node(replay_btn_path).visible=true
	else:
		get_node(replay_btn_path).visible=false
	if "stats" in Global.level_data and stat_name in Global.level_data["stats"]:
		str_temp=str_temp+"Record: "+Global.level_data["stats"][stat_name]["user"]+" ("+str(Global.level_data["stats"][stat_name]["time"])+" s)\n"
	if Global.sel_level in Global.user_data["levels"]:
		str_temp=str_temp+"My Record: "+str(Global.user_data["levels"][Global.sel_level]["time"])+" s\n"
		str_temp=str_temp+"Count: "+str(Global.user_data["levels"][Global.sel_level]["num"])+"\n"
	str_temp=str_temp+"\n"
	for chara_t in Global.level_data["battle_data"]["args"]["hotkey"]:
		str_temp=str_temp+chara_t+" "
	get_node(level_info_path).text=str_temp

func chara_item_click_cb(chara_name):
	var chara_db = Global.chara_tb[chara_name]
	var str_temp=""
	var my_chara_info = Global.get_my_chara_info(chara_name)
	cur_sel_chara=chara_name
	var lv=my_chara_info["lv"]
	var t_attr_info=chara_db["attrs"][str(lv+1)]
	var t_attr_info_next=null
	if lv<chara_db["max_lv"]:
		t_attr_info_next=chara_db["attrs"][str(lv+1)]
	for key in t_attr_info:
		if key == "upgrade_cost":
			continue
		var next_lv=""
		if t_attr_info_next!=null:
			var val_change=t_attr_info_next[key]-t_attr_info[key]
			if val_change!=0:
				next_lv=" ("+str(val_change)+")"
		str_temp=str_temp+key+": "+str(t_attr_info[key])+next_lv+"\n"
	chara_info.text=str_temp
	clear_grid_highlight(chara_grid)
	clear_grid_highlight(chara_hotkey)
	var upgrage_price=Global.get_upgrade_price(chara_name, lv)
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

func clear_item_hk_slot(slot_id):
	var item = item_hotkey.get_child(slot_id)
	item.clear()
	Global.user_data["equip"]["item"][slot_id]=""

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

func make_lv_name(level_id,chara_lv,hard_id):
	return str(level_id)+"_"+str(chara_lv)+"_"+str(hard_id)

func add_lv_grid_item(lv_name):
	var level_item = level_item_res.instance()
	level_item.container=level_grid
	if lv_name in Global.user_data["levels"]:
		level_item.set_lock(false, lv_name)
	else:
		level_item.set_lock(true, lv_name)
	level_grid.add_child(level_item)

func update_levels_ui(level_id):
	Global.delete_children(level_grid)
	for chara_lv in range(chara_lv_num):
		for hard_id in range(hardness_num):
			var lv_name=make_lv_name(level_id,chara_lv,hard_id)
			add_lv_grid_item(lv_name)
	if Global.sel_level=="":
		on_show_level_info(make_lv_name(level_id,0,0))

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
	get_node(lottery_price_path).text=str(Global.global_data["lottery_price"])+" Gold"  

func update_pvp_ui():
	get_node(lottery_price_path).text=str(Global.global_data["pvp_price"])+" Diamond"  
	if len(Global.rank_data)==0:
		return
	Global.delete_children(get_node(rank_list_path))
	for item in Global.rank_data:
		var new_item = rank_item_res.instance()
		var note=""
		if "setting" in item and "not" in item["setting"]:
			note=item["setting"]["note"]
		new_item.set_data(item["nickname"],item["diamond"],item["last_pvp"],note)
		get_node(rank_list_path).add_child(new_item)

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
			if get_node(chara_container_path).visible==true or get_node(item_container_path).visible==true:
				for c in chara_hotkey.get_children():
					var t_pos=Vector2(event.position.x, event.position.y)
					if check_in_control(t_pos, c):
						if cur_drag_chara!="":
							set_chara_hk_slot(c.get_index(), cur_drag_chara)
							Global.save_equip_info(true,c.get_index(),cur_drag_chara)
				for c in item_hotkey.get_children():
					var t_pos=Vector2(event.position.x, event.position.y)
					if check_in_control(t_pos, c):
						if cur_drag_item!="":
							for i in range(len(Global.user_data["equip"]["item"])):
								if Global.user_data["equip"]["item"][i]==cur_drag_item:
									clear_item_hk_slot(i)
							set_item_hk_slot(c.get_index(), cur_drag_item)
							Global.save_equip_info(false,c.get_index(),cur_drag_item)
				cur_drag_chara=""
				cur_drag_item=""
				hide_drag_icon()

func init_tab_dots(num):
	var tab_dots=get_node(tab_dots_path)
	for _i in range(num):
		var new_dot = tab_dot_res.instance()
		tab_dots.add_child(new_dot)

func set_tab_dot_sel(ind):
	var tab_dots=get_node(tab_dots_path)
	for c_id in tab_dots.get_child_count():
		var c = tab_dots.get_child(c_id)
		if c_id==ind:
			c.get_child(0).visible=false
			c.get_child(1).visible=true
		else:
			c.get_child(0).visible=true
			c.get_child(1).visible=false

func hide_all_tabs():
	get_node(level_label_path).add_color_override("font_color", Color.white)
	get_node(chara_label_path).add_color_override("font_color", Color.white)
	get_node(item_label_path).add_color_override("font_color", Color.white)
	get_node(lottery_label_path).add_color_override("font_color", Color.white)
	get_node(pvp_label_path).add_color_override("font_color", Color.white)
	
	get_node(level_container_path).visible=false
	get_node(chara_container_path).visible=false
	get_node(item_container_path).visible=false
	get_node(lottery_container_path).visible=false
	get_node(pvp_container_path).visible=false

func update_status():
	get_node(user_stats_path).setting_node=get_node(user_setting_path)
	get_node(user_stats_path).set_gold(Global.user_data["gold"])
	get_node(user_stats_path).set_diamond(Global.user_data["diamond"])
	if "user" in Global.level_data["total_top"]:
		var top_info=Global.level_data["total_top"]
		get_node(user_stats_path).set_total_top(top_info["user"],top_info["num"])
	if "user" in Global.level_data["level_top"]:
		var top_info=Global.level_data["level_top"]
		get_node(user_stats_path).set_level_top(top_info["user"],top_info["num"])
	get_node(user_stats_path).set_user_name(Global.user_data["nickname"])

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
	elif name=="pvp":
		get_node(pvp_label_path).add_color_override("font_color", Color.red)
		get_node(pvp_container_path).visible=true

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
				if Global.user_data["diamond"]<item_sell_price:
					return
				request_a_buy(cur_sel_item)

func _on_Upgrade_gui_input(event:InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed==true:
			if cur_sel_chara!="":
				var my_chara_info = Global.get_my_chara_info(cur_sel_chara)
				var chara_lv=my_chara_info["lv"]
				var upgrade_price=Global.get_upgrade_price(cur_sel_chara, chara_lv)
				if upgrade_price<0:
					return
				if Global.user_data["gold"]<upgrade_price:
					return
				request_a_upgrade(cur_sel_chara)

func request_a_draw():
	if http!=null:
		return
	http=HTTPRequest.new()
	http.pause_mode=Node.PAUSE_MODE_PROCESS
	http.connect("request_completed", self, "on_draw_result")
	add_child(http)
	var query_info={}
	query_info["token"]=Global.token
	var query = JSON.print(query_info)
	var headers = ["Content-Type: application/json"]
	http.request(Global.server_url+"/draw_a_lottery", headers, false, HTTPClient.METHOD_POST, query)

func request_a_buy(item_name):
	if http!=null:
		return
	http=HTTPRequest.new()
	http.pause_mode=Node.PAUSE_MODE_PROCESS
	http.connect("request_completed", self, "on_buy_result")
	add_child(http)
	var query_info={}
	query_info["token"]=Global.token
	query_info["item_name"]=item_name
	var query = JSON.print(query_info)
	var headers = ["Content-Type: application/json"]
	http.request(Global.server_url+"/buy_item", headers, false, HTTPClient.METHOD_POST, query)

func request_a_upgrade(chara_name):
	if http!=null:
		return
	http=HTTPRequest.new()
	http.pause_mode=Node.PAUSE_MODE_PROCESS
	http.connect("request_completed", self, "on_upgrade_result")
	add_child(http)
	var query_info={}
	query_info["token"]=Global.token
	query_info["chara_name"]=chara_name
	var query = JSON.print(query_info)
	var headers = ["Content-Type: application/json"]
	http.request(Global.server_url+"/upgrade_chara", headers, false, HTTPClient.METHOD_POST, query)

func change_gold(val):
	Global.user_data["gold"]=Global.user_data["gold"]+val
	update_status()

func change_diamond(val):
	Global.user_data["diamond"]=Global.user_data["diamond"]+val
	update_status()

func on_upgrade_result(result, response_code, headers, body):
	if response_code!=200:
		print("on_upgrade_result network error!")
		return
	http.queue_free()
	http=null
	var re_json = JSON.parse(body.get_string_from_utf8()).result
	if re_json["ret"]=="ok":
		var chara_name=re_json["data"]["name"]
		var lv=re_json["data"]["lv"]
		var cost=re_json["data"]["cost"]
		for chara in Global.user_data["characters"]:
			if chara["name"]==chara_name:
				chara["lv"]=lv
				change_gold(-cost)
				update_characters_ui()
				break

func on_buy_result(result, response_code, headers, body):
	if response_code!=200:
		print("on_buy_result network error!")
		return
	http.queue_free()
	http=null
	var re_json = JSON.parse(body.get_string_from_utf8()).result
	if re_json["ret"]=="ok":
		var chara_name=re_json["data"]["name"]
		var num=re_json["data"]["num"]
		var cost=re_json["data"]["cost"]
		for chara in Global.user_data["items"]:
			print(chara["name"])
			if chara["name"]==chara_name:
				chara["num"]=num
				change_diamond(-cost)
				update_items_ui()
				break

func on_draw_result(result, response_code, headers, body):
	if response_code!=200:
		print("on_draw_result network error!")
		return
	http.queue_free()
	http=null
	var re_json = JSON.parse(body.get_string_from_utf8()).result
	if re_json["data"]["type"]=="chara":
		Global.user_data["characters"]=re_json["data"]["info"]
		update_characters_ui()
		set_icon(get_node(lottory_item_path), false, re_json["data"]["name"])
	else:
		Global.user_data["items"]=re_json["data"]["info"]
		update_items_ui()
		set_icon(get_node(lottory_item_path), true, re_json["data"]["name"])
	change_diamond(-Global.global_data["lottery_price"])

func _on_TryBtn_gui_input(event:InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed==true:
			if Global.global_data["lottery_price"]>Global.user_data["diamond"]:
				return
			request_a_draw()
	
func _on_Level_gui_input(event):
	on_tab_button("level", event)

func _on_Character_gui_input(event):
	on_tab_button("chara", event)

func _on_Item_gui_input(event):
	on_tab_button("item", event)

func _on_Lottery_gui_input(event):
	on_tab_button("lottery", event)

func _on_PVP_gui_input(event):
	on_tab_button("pvp", event)

func _on_Start_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if Global.sel_level!="":
				Global.emit_signal("request_battle",Global.sel_level)

func _on_Left_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if cur_level_page_ind-1<0:
				return
			else:
				cur_level_page_ind=cur_level_page_ind-1
				update_levels_ui(Global.lv_name_list[cur_level_page_ind])
				set_tab_dot_sel(cur_level_page_ind)

func _on_Right_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if cur_level_page_ind+1>=len(Global.lv_name_list):
				return
			else:
				cur_level_page_ind=cur_level_page_ind+1
				update_levels_ui(Global.lv_name_list[cur_level_page_ind])
				set_tab_dot_sel(cur_level_page_ind)

func _on_GoBtn_gui_input(event:InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			if Global.user_data["diamond"]>=Global.global_data["pvp_price"]:
				Global.set_game_mode("pvp")
				get_tree().change_scene(Global.game_scene)
			
func _on_Replay_gui_input(event:InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			Global.set_game_mode("replay")
			var lv_info = Global.get_cur_level_info()
			var recording_name=str(lv_info["chara_lv"])+"_"+str(lv_info["difficulty"])
			Global.replay_data=JSON.parse(Global.level_data["record"][recording_name]).result
			get_tree().change_scene(Global.game_scene)
