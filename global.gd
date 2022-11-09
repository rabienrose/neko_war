extends Node

signal money_change(val)
signal request_battle(lv)
signal show_level_info(lv)

var char_tb_file_path="res://nakama/configs/characters.json"
var user_data_path="user://user.json"
var global_data_path="res://nakama/configs/global.json"
var token_path="user://token.txt"
var device_id_path="user://device_id.txt"
var levels_info_path="res://nakama/configs/levels.json"
var items_info_path="res://nakama/configs/items.json"
var skills_info_path="res://nakama/configs/skills.json"
var atk_bufs_info_path="res://nakama/configs/atk_buf.json"
var icon_img_file_path="res://binary/images/icons/"
var chara_file_path="res://objects/"

var game_scene="res://game.tscn"
var home_scene="res://home.tscn"
var login_scene="res://ui/login.tscn"

var rank_data=[]
var level_data={}
var user_data={}
var chara_tb={}
var levels_tb={}
var items_tb={}
var skills_tb={}
var atk_buf_tb={}
var chara_anim={}
var lv_name_list=[]
var global_data={}

var replay_data={}

var sel_level=""

var local_mode=false
var device_id

var http
var server_url=""

var rng 

var replay_mode=false
var pvp_mode=false
var level_mode=true
var server_mode=false

var paused=false

var scheme = "http"
var host = "127.0.0.1"
var port = 7350
var server_key = "nakama_nekowar"
var client 
var session

func _ready():
	client= Nakama.create_client(server_key, host, port, scheme,3,NakamaLogger.LOG_LEVEL.ERROR)
	rng = RandomNumberGenerator.new()
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
	f = File.new()
	f.open(levels_info_path, File.READ)
	content = f.get_as_text()
	levels_tb = JSON.parse(content).result
	if global_data["b_local_server"]==1:
		server_url="http://127.0.0.1:9100"
	else:
		server_url="http://"+global_data["flask_ip"]+":9100"
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
	var read_object_id = NakamaStorageObjectId.new("user", "basic", Global.session.user_id)
	var result = yield(Global.client.read_storage_objects_async(Global.session, [read_object_id]), "completed")
	if result.is_exception():
		print(result)
		return
	else:
		for o in result.objects:
			user_data=JSON.parse(o.value).result
			level_data=user_data["levels"]
			var account = yield(client.get_account_async(Global.session), "completed")
			var username = account.user.username
			var avatar_url = account.user.avatar_url
			var user_id = account.user.id
			user_data["nickname"]=username
			user_data["avatar_url"]=avatar_url
			user_data["user_id"]=user_id
		get_tree().change_scene(home_scene)

func save_equip_info(b_chara, index, name):
	if local_mode:
		return

func save_user_data():
	if local_mode:
		var f=File.new()
		f.open(user_data_path, File.WRITE)
		var temp_json_str=JSON.print(user_data)
		f.store_string(temp_json_str)
		f.close()        

func get_enmey_team_id(team_id):
	var ret=[0,1]
	if team_id==1:
		ret=[1,0]
	return ret

func upload_pvp_summery(recording,token1,token2,diamond1,diamond2):
	pass
	# if http!=null:
	# 	return
	# http=HTTPRequest.new()
	# http.pause_mode=Node.PAUSE_MODE_PROCESS
	# http.connect("request_completed", self, "default_http_cb")
	# add_child(http)
	# var query_info={}
	# query_info["token1"]=token1
	# query_info["token2"]=token2
	# query_info["diamond1"]=diamond1
	# query_info["diamond2"]=diamond2
	# query_info["recording"]=recording
	# var query = JSON.print(query_info)
	# var headers = ["Content-Type: application/json"]
	# http.request(server_url+"/pvp_summary", headers, false, HTTPClient.METHOD_POST, query)

func upload_level_summery(recording, time, level_id, chara_lv, difficulty):
	var query_info={}
	query_info["recording"]=recording
	query_info["level_id"]=level_id
	var payload = JSON.print(query_info)
	yield(client.rpc_async(session, "level_battle_summary", JSON.print(payload)), "completed")

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

func get_my_chara_info(chara_name):
	if chara_name in user_data["characters"]:
		return user_data["characters"][chara_name]
	else:
		return null

func get_my_item_info(item_name):
	if item_name in user_data["items"]:
		return user_data["items"][item_name]
	else:
		return null

func _physics_process(delta):
	pass

func check_token():
	var f=File.new()
	if f.file_exists(token_path):
		f.open(token_path, File.READ)
		var content = f.get_as_text()
		var json_auth=JSON.parse(content).result
		var email=json_auth[0]
		var pw=json_auth[1]
		f.close()
		return [email, pw]
	else:
		return null

func store_token(email, pw):
	var f=File.new()
	f.open(token_path, File.WRITE)
	var json_auth=JSON.print([email,pw])
	f.store_string(json_auth)
	f.close()

func login_remote(email, account, pw, b_reg):
	if account=="":
		account=null
	Global.session = yield(Global.client.authenticate_email_async(email, pw, account,b_reg), "completed")
	if Global.session.is_exception():
		print("login error!!!!")
		print(Global.session)
		return
	store_token(email, pw)
	Global.fetch_user_remote()

func get_cur_level_info():
	var vec_s=sel_level.split("_")
	return {"id":vec_s[0], "chara_lv":int(vec_s[1]), "difficulty":int(vec_s[2])}
