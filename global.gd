extends Node

signal money_change(val)
signal request_battle(lv)
signal request_go_home
signal show_level_info(lv)


var char_tb_file_path="res://configs/characters.json"
var user_data_path="user://user.json"
var token_path="user://token.txt"
var device_id_path="user://device_id.txt"
var levels_info_path="res://configs/levels.json"
var items_info_path="res://configs/items.json"
var skills_info_path="res://configs/skills.json"
var atk_bufs_info_path="res://configs/atk_buf.json"
var char_img_file_path="res://binary/images/charas/"
var item_img_file_path="res://binary/images/items/"

var game_scene="res://game.tscn"
var home_scene="res://home.tscn"
var login_scene="res://ui/login.tscn"

var level_data={}
var user_data={}
var chara_tb={}
var items_tb={}
var skills_tb={}
var atk_buf_tb={}
var chara_anim={}
var lv_name_list=[]

var sel_level="0/0/0"

var lottery_price=70

var local_mode=true
var token
var device_id

var http
var server_url="http://127.0.0.1:9100"

var rng 

func _ready():
    rng = RandomNumberGenerator.new()
    if local_mode:
        var f = File.new()
        if f.file_exists(user_data_path):
            f.open(user_data_path, File.READ)
            var out_str = f.get_as_text()
            user_data = JSON.parse(out_str).result
            f.close()
        else:
            user_data={}
            user_data["gold"]=0
            var chara_info={}
            chara_info["name"]="sword"
            chara_info["lv"]=1
            user_data["characters"]=[chara_info]
            var equip_info={}
            equip_info["chara"]=["sword","","","",""]
            equip_info["item"]=["","","","",""]
            user_data["equip"]=equip_info
            user_data["levels"]={}
            user_data["items"]=[]
    var f=File.new()
    f.open(char_tb_file_path, File.READ)
    var content = f.get_as_text()
    chara_tb = JSON.parse(content).result
    f.close()
    f = File.new()
    f.open(items_info_path, File.READ)
    content = f.get_as_text()
    items_tb = JSON.parse(content).result
    f.close()
    f.open(skills_info_path, File.READ)
    content = f.get_as_text()
    skills_tb = JSON.parse(content).result
    f.close()
    f.open(atk_bufs_info_path, File.READ)
    content = f.get_as_text()
    atk_buf_tb = JSON.parse(content).result
    f.close()
    connect("request_battle",self,"on_request_start_battle")
    connect("request_go_home",self,"on_request_go_home")

func check_update():
    pass

func update_user_remote():
    if http!=null:
        return
    http=HTTPRequest.new()
    http.connect("request_completed", self, "on_get_user")
    add_child(http)
    var query_info={}
    query_info["token"]=token
    var query = JSON.print(query_info)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/request_user_info", headers, false, HTTPClient.METHOD_POST, query)

func update_levels_remote():
    if http!=null:
        return
    http=HTTPRequest.new()
    http.connect("request_completed", self, "on_get_levels")
    add_child(http)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/request_levels_info", headers, false, HTTPClient.METHOD_POST)

func on_get_user(result, response_code, headers, body):
    http.queue_free()
    http=null
    var re_json = JSON.parse(body.get_string_from_utf8()).result
    user_data=re_json["data"]
    update_levels_remote()

func on_get_levels(result, response_code, headers, body):
    http.queue_free()
    http=null
    var re_json = JSON.parse(body.get_string_from_utf8()).result
    lv_name_list.append(re_json["data"]["level_id"])
    level_data=re_json["data"]["battle_data"]
    get_tree().change_scene(home_scene)

func save_user_data():
    var f=File.new()
    f.open(user_data_path, File.WRITE)
    var temp_json_str=JSON.print(user_data)
    f.store_string(temp_json_str)
    f.close()

func save_battle_record(data):
    var f=File.new()
    f.open("user://temp_battle_record.json", File.WRITE)
    var temp_json_str=JSON.print(data)
    f.store_string(temp_json_str)
    f.close()

func load_battle_record():
    var f=File.new()
    f.open("user://temp_battle_record.json", File.READ)
    var out_str = f.get_as_text()
    var data = JSON.parse(out_str).result
    f.close()
    return data

func get_char_anim(char_name, type):
    var anim_file = chara_tb[char_name]["appearance"]
    if not anim_file in chara_anim:
        chara_anim[anim_file]=load("res://anim_sprite/"+type+"/"+char_name+".tres")
    return chara_anim[anim_file]

func get_fx_frame_anim(fx_name):
    return load("res://anim_sprite/effect/"+fx_name+".tres")

func check_prob_pass(p):
    var temp_r=rng.randf_range(0,1)
    return temp_r<=p

func rand_in_list(list_data):
    return list_data[floor(rng.randf_range(0,1)*len(list_data))]

func on_request_start_battle(lv):
    sel_level=lv
    get_tree().change_scene(game_scene)

func on_request_go_home():
    get_tree().change_scene(home_scene)

func delete_children(node):
    for n in node.get_children():
        node.remove_child(n)

func get_upgrade_price(chara_name, cur_lv):
    var next_lv=cur_lv+1
    if next_lv>chara_tb[chara_name]["max_lv"]:
        return -1
    return Global.chara_tb[chara_name]["attrs"][str(next_lv)]["upgrade_cost"]

func expend_user_money(val):
    if user_data["gold"]-val<0:
        return false
    user_data["gold"]=user_data["gold"]-val
    emit_signal("money_change", user_data["gold"])
    save_user_data()

func get_my_chara_info(chara_name):
    for item in user_data["characters"]:
        if item["name"]==chara_name:
            return item
    return null

func get_my_charas_dict():
    var chara_dict={}
    for item in user_data["characters"]:
        chara_dict[item["name"]]=item
    return chara_dict

func get_my_item_info(item_name):
    for item in user_data["items"]:
        if item["name"]==item_name:
            return item
    return null

func _physics_process(delta):
    pass

func check_token():
    var f=File.new()
    if f.file_exists(token_path):
        f.open(token_path, File.READ)
        var content = f.get_as_text()
        token=content
        f.close()
        return true
    else:
        return false

func store_token():
    var f=File.new()
    f.open(token_path, File.WRITE)
    f.store_string(token)
    f.close()
