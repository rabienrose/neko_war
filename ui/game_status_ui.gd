extends HBoxContainer

export (NodePath) var gold_label_path
export (NodePath) var diamond_label_path

export (NodePath) var user_name_path
export (NodePath) var total_top_path
export (NodePath) var level_top_path

var setting_node

var anim_player
var last_gold=-1

var http=null

func set_total_top(user, num):
	var text="Total: "+str(num)+" ("+user+")"
	get_node(total_top_path).text=text

func set_level_top(user, num):
	var text="Level: "+str(num)+" ("+user+")"
	get_node(level_top_path).text=text

func set_user_name(user_name):
	get_node(user_name_path).text=user_name

func set_gold(val):
	get_node(gold_label_path).text=str(val)

func on_setting_submit(setting_data):
	if http!=null:
		return
	http=HTTPRequest.new()
	http.pause_mode=Node.PAUSE_MODE_PROCESS
	http.connect("request_completed", self, "default_http_cb")
	add_child(http)
	var query_info={}
	query_info["token"]=Global.token
	query_info["note"]=setting_data["note"]
	var query = JSON.print(query_info)
	var headers = ["Content-Type: application/json"]
	http.request(Global.server_url+"/modify_user_setting", headers, false, HTTPClient.METHOD_POST, query)

func default_http_cb(result, response_code, headers, body):
	http.queue_free()
	http=null

func on_get_user_setting(result, response_code, headers, body):
	http.queue_free()
	http=null
	var re_json = JSON.parse(body.get_string_from_utf8()).result
	if "note" in re_json["data"]:
		setting_node.set_note(re_json["data"]["note"])
		setting_node.set_submit_cb(funcref(self, "on_setting_submit"))
		setting_node.visible=true

func _on_Nickname_gui_input(event:InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			if http!=null:
				return
			http=HTTPRequest.new()
			http.pause_mode=Node.PAUSE_MODE_PROCESS
			http.connect("request_completed", self, "on_get_user_setting")
			add_child(http)
			var query_info={}
			query_info["token"]=Global.token
			var query = JSON.print(query_info)
			var headers = ["Content-Type: application/json"]
			http.request(Global.server_url+"/get_user_setting", headers, false, HTTPClient.METHOD_POST, query)
	

func set_diamond(val):
	get_node(diamond_label_path).text=str(val)

func _ready():
	pass
