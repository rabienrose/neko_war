extends Node

signal money_change(val)
signal request_battle(lv)
signal show_level_info(lv)
signal battle_frame_recv(frame_data)

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
var total_level_data={}
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

var device_id

var http
var server_url=""

var rng 


var battle_mode="level" #level, pvp, replay

var scheme = "http"
var host = "127.0.0.1"
var port = 7350
var server_key = "nakama_nekowar"
var client 
var session
var socket
var battle_id=""
var battle_players
var level_battle_id=""

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
			var account = yield(client.get_account_async(Global.session), "completed")
			var username = account.user.username
			var avatar_url = account.user.avatar_url
			var user_id = account.user.id
			user_data["nickname"]=username
			user_data["avatar_url"]=avatar_url
			user_data["user_id"]=user_id

func get_enmey_team_id(team_id):
	var ret=[0,1]
	if team_id==1:
		ret=[1,0]
	return ret

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
	if not str(next_lv) in chara_tb[chara_name]["attrs"]:
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
		return false
	store_token(email, pw)
	return true

func _on_NakamaSocket_received_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent):
	pass
	
func battle_frame_receive(match_state: NakamaRTAPI.MatchData):
	var code = match_state.op_code
	var raw = match_state.data
	if code ==0: #frame data
		var decoded= JSON.parse(raw).result
		emit_signal("battle_frame_recv", decoded)
	elif code ==1: #match ready
		battle_players= JSON.parse(raw).result
		battle_mode="pvp"
		get_tree().change_scene(game_scene)
		# emit_signal("match_ready", decoded)

func _on_NakamaSocket_connection_error(error: int) -> void:
	var error_message = "Unable to connect with code %s" % error
	print(error_message)
	socket = null

func _on_NakamaSocket_received_error(error: NakamaRTAPI.Error) -> void:
	var error_message = str(error)
	print("battle recv error: ", error_message)
	socket = null

func connect_to_server_async():
	socket = Nakama.create_socket_from(client)
	var result= yield(socket.connect_async(session), "completed")
	socket.connect("received_match_presence", self, "_on_NakamaSocket_received_match_presence")
	socket.connect("received_match_state", self, "battle_frame_receive")
	socket.connect("connection_error", self, "_on_NakamaSocket_connection_error")
	socket.connect("received_error", self, "_on_NakamaSocket_received_error")

func battle_frame_send(frame_data):
	yield(socket.send_match_state_async(battle_id, 0, JSON.print(frame_data)), "completed")

func request_end_battle():
	yield(socket.send_match_state_async(battle_id, 99, JSON.print({})), "completed")

func send_battle_result(b_win):
	var msg={}
	if b_win:
		msg["re"]="winner"
	else:
		msg["re"]="loser"
	yield(socket.send_match_state_async(battle_id, 2, JSON.print(msg)), "completed")

func send_ready_msg():
	yield(socket.send_match_state_async(battle_id, 1, JSON.print({})), "completed")

func send_level_battle_inputs(inputs):
	socket.send_match_state_async(level_battle_id, 0, JSON.print(inputs))

func end_level_battle(b_win, record):
	socket.send_match_state_async(level_battle_id, 2, JSON.print({"b_win":b_win, "record": record, "time":Time.get_date_string_from_system()}))

func request_level_battle(level_name):
	if socket==null or socket.is_connected_to_host()==false:
		yield(connect_to_server_async(), "completed")
	if level_battle_id=="":
		var ret = yield(Global.client.rpc_async(session, "request_level_battle", level_name), "completed")
		level_battle_id=ret.payload
		yield(socket.join_match_async(level_battle_id), "completed")
		battle_mode="level"
		sel_level=level_name
		get_tree().change_scene(game_scene)

func join_battle_async():
	if socket==null or socket.is_connected_to_host()==false:
		yield(connect_to_server_async(), "completed")
	if battle_id=="":
		var ret = yield(client.rpc_async(session, "request_match"), "completed")
		battle_id=ret.payload
		yield(socket.join_match_async(battle_id), "completed")

func leave_match():
	yield(socket.leave_match_async(battle_id), "completed")
	battle_id=""

func fetch_user_and_go_home():
	yield(Global.fetch_all_data(), "completed") 
	get_tree().change_scene(home_scene)
	get_tree().paused=false

func fetch_level_data():
	var querys=[]
	for level_name in levels_tb:
		querys.append(NakamaStorageObjectId.new("level", level_name))
	var result = yield(Global.client.read_storage_objects_async(session, querys), "completed")
	total_level_data={}
	for item in result.objects:
		total_level_data[item.key]=JSON.parse(item.value).result

func fetch_all_data():
	yield(fetch_level_data(), "completed")
	yield(fetch_user_remote(), "completed")
