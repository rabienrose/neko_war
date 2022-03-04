extends TextureRect

export (NodePath) var account_path
export (NodePath) var pw_path
export (NodePath) var alert_path

export var alert_ui_res:Resource

var http=null

const MODULO_8_BIT = 256

func getRandomInt():
    randomize()
    return randi() % MODULO_8_BIT

func uuidbin():
    return [
        getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
        getRandomInt(), getRandomInt(), ((getRandomInt()) & 0x0f) | 0x40, getRandomInt(),
        ((getRandomInt()) & 0x3f) | 0x80, getRandomInt(), getRandomInt(), getRandomInt(),
        getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
    ]

func v4():
    var b = uuidbin()
    return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
        b[0], b[1], b[2], b[3],
        b[4], b[5],
        b[6], b[7],
        b[8], b[9],
        b[10], b[11], b[12], b[13], b[14], b[15]
    ]

func login_remote(account, pw, b_reg):
    http=HTTPRequest.new()
    http.connect("request_completed", self, "on_regist_ret")
    add_child(http)
    var query_info={}
    query_info["account"]=account
    query_info["pw"]=pw
    query_info["device_id"]=Global.device_id
    query_info["device_type"]=OS.get_name()
    var query = JSON.print(query_info)
    var headers = ["Content-Type: application/json"]
    var api_str="/user_regist"
    if b_reg==false:
        api_str="/user_login"
    http.request(Global.server_url+api_str, headers, false, HTTPClient.METHOD_POST, query)

func on_alert_ok():
    get_node(alert_path).visible=false

func show_alert(alert_text):
    var t_node = get_node(alert_path)
    t_node.visible=true
    t_node.set_text(alert_text)
    t_node.set_btn1("OK",funcref(self, "on_alert_ok"))
    t_node.hide_btn(2)

func on_regist_ret(result, response_code, headers, body):
    var re_json = JSON.parse(body.get_string_from_utf8()).result
    if re_json["ret"]=="ok":
        if "data" in re_json:
            Global.token=re_json["data"]["token"]
            Global.store_token()
            Global.update_user_remote()
        else:
            show_alert("Login failed!")
    else:
        show_alert(re_json["desc"])
        
    http.queue_free()
    http=null

func get_device_id():
    var f=File.new()
    if f.file_exists(Global.device_id_path):
        f.open(Global.device_id_path, File.READ)
        Global.device_id = f.get_as_text()
        f.close()
    else:
        Global.device_id=v4()
        f=File.new()
        f.open(Global.device_id_path, File.WRITE)
        f.store_string(Global.device_id)
        f.close()
        
func _ready():
    get_device_id()

func _on_LoginBtn_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if http!=null:
                return
            var account=get_node(account_path).text
            var pw=get_node(pw_path).text
            if account!="" and pw!="":
                login_remote(account, pw, false)

func _on_RegistBtn_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if http!=null:
                return
            var account=get_node(account_path).text
            var pw=get_node(pw_path).text
            if account!="" and pw!="":
                login_remote(account, pw, true)


func _on_ClearBtn_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            get_node(account_path).text=""
            get_node(pw_path).text=""
