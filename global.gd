extends Node

signal money_change(val)
signal request_battle(lv)
signal show_level_info(lv)


var char_tb_file_path="res://configs/characters.json"
var user_data_path="user://user.json"
var global_data_path="res://configs/global.json"
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

var rank_data=[]
var level_data={}
var user_data={}
var chara_tb={}
var items_tb={}
var skills_tb={}
var atk_buf_tb={}
var chara_anim={}
var lv_name_list=[]
var global_data={}

var replay_data={}

var sel_level="0_0_0"

var local_mode=false
var token
var device_id

var http
var server_url=""

var rng 

var replay_mode=false
var pvp_mode=false
var level_mode=true
var server_mode=false

var paused=false

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
    f.open(global_data_path, File.READ)
    content = f.get_as_text()
    global_data = JSON.parse(content).result
    f.close()
    if global_data["b_local_server"]==1:
        server_url="http://127.0.0.1:9100"
    else:
        server_url="http://"+global_data["game_server_ip"]+":9100"
    connect("request_battle",self,"on_request_start_battle")

func set_game_mode(mode):
    Global.replay_mode=false
    Global.pvp_mode=false
    Global.level_mode=false
    if mode=="pvp":
        Global.pvp_mode=true
    elif mode=="replay":
        Global.replay_mode=true
    elif mode=="level":
        Global.level_mode=true

func check_update():
    pass

func fetch_user_remote():
    if http!=null:
        return
    http=HTTPRequest.new()
    http.pause_mode=Node.PAUSE_MODE_PROCESS
    http.connect("request_completed", self, "on_get_user")
    add_child(http)
    var query_info={}
    query_info["token"]=token
    var query = JSON.print(query_info)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/request_user_info", headers, false, HTTPClient.METHOD_POST, query)

func fetch_levels_remote():
    if http!=null:
        return
    http=HTTPRequest.new()
    http.pause_mode=Node.PAUSE_MODE_PROCESS
    http.connect("request_completed", self, "on_get_levels")
    add_child(http)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/request_levels_info", headers, false, HTTPClient.METHOD_POST)

func fetch_rank_remote():
    if http!=null:
        return
    http=HTTPRequest.new()
    http.pause_mode=Node.PAUSE_MODE_PROCESS
    http.connect("request_completed", self, "on_get_rank")
    add_child(http)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/request_rank_info", headers, false, HTTPClient.METHOD_POST)

func on_get_user(result, response_code, headers, body):
    if response_code!=200:
        print("on_get_user network error!")
        return
    http.queue_free()
    http=null
    var re_json = JSON.parse(body.get_string_from_utf8()).result
    user_data=re_json["data"]
    fetch_levels_remote()

func on_get_levels(result, response_code, headers, body):
    if response_code!=200:
        print("on_get_levels network error!")
        return
    http.queue_free()
    http=null
    var re_json = JSON.parse(body.get_string_from_utf8()).result
    lv_name_list.append(re_json["data"]["level_id"])
    level_data=re_json["data"]
    fetch_rank_remote()

func on_get_rank(result, response_code, headers, body):
    if response_code!=200:
        print("on_get_rank network error!")
        return
    http.queue_free()
    http=null
    var re_json = JSON.parse(body.get_string_from_utf8()).result
    rank_data=re_json["data"]
    get_tree().change_scene(home_scene)

func save_equip_info(b_chara, index, name):
    if local_mode:
        return
    if http!=null:
        return
    http=HTTPRequest.new()
    http.connect("request_completed", self, "default_http_cb")
    add_child(http)
    var query_info={}
    query_info["token"]=token
    query_info["b_chara"]=b_chara
    query_info["hk_index"]=index
    query_info["name"]=name
    var query = JSON.print(query_info)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/update_equip_info", headers, false, HTTPClient.METHOD_POST, query)

func save_user_data():
    if local_mode:
        var f=File.new()
        f.open(user_data_path, File.WRITE)
        var temp_json_str=JSON.print(user_data)
        f.store_string(temp_json_str)
        f.close()        

func default_http_cb(result, response_code, headers, body):
    http.queue_free()
    http=null

func upload_pvp_summery(recording,result,token1,token2,diamond1,diamond2):
    if http!=null:
        return
    http=HTTPRequest.new()
    http.pause_mode=Node.PAUSE_MODE_PROCESS
    http.connect("request_completed", self, "default_http_cb")
    add_child(http)
    var query_info={}
    query_info["result"]=result
    query_info["token1"]=token1
    query_info["token2"]=token2
    query_info["diamond1"]=diamond1
    query_info["diamond2"]=diamond2
    query_info["recording"]=recording
    var query = JSON.print(query_info)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/pvp_summary", headers, false, HTTPClient.METHOD_POST, query)

func upload_level_summery(recording, time, level_id, chara_lv, difficulty):
    if http!=null:
        return
    http=HTTPRequest.new()
    http.pause_mode=Node.PAUSE_MODE_PROCESS
    http.connect("request_completed", self, "default_http_cb")
    add_child(http)
    var query_info={}
    query_info["token"]=token
    query_info["recording"]=recording
    query_info["time"]=int(time)
    query_info["level_id"]=level_id
    query_info["chara_lv"]=chara_lv
    query_info["difficulty"]=difficulty
    var query = JSON.print(query_info)
    var headers = ["Content-Type: application/json"]
    http.request(server_url+"/update_level_stats", headers, false, HTTPClient.METHOD_POST, query)

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

func get_cur_level_info():
    var vec_s=sel_level.split("_")
    return {"id":vec_s[0], "chara_lv":int(vec_s[1]), "difficulty":int(vec_s[2])}
