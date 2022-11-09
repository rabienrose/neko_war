extends TextureRect

export (NodePath) var account_path
export (NodePath) var account_label_path
export (NodePath) var pw_path
export (NodePath) var alert_path
export (NodePath) var email_path

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

func on_alert_ok():
	get_node(alert_path).visible=false

func show_alert(alert_text):
	var t_node = get_node(alert_path)
	t_node.visible=true
	t_node.set_text(alert_text)
	t_node.set_btn1("OK",funcref(self, "on_alert_ok"))
	t_node.hide_btn(2)

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
	pass

func login(b_reg):
	var account=get_node(account_path).text
	var pw=get_node(pw_path).text
	var email=get_node(email_path).text
	if len(pw)<8:
		show_alert("Password should more then 7 letters")
		return
	if not "@" in email:
		show_alert("email format wrong!")
		return
	if email!="" and pw!="":
		Global.login_remote(email, account, pw, b_reg)

func _on_LoginBtn_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			login(false)

func _on_RegistBtn_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_node(account_path).text=="":
				get_node(account_label_path).visible=true
				get_node(account_path).visible=true
			else:
				login(true)

func _on_ClearBtn_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			get_node(account_path).text=""
			get_node(pw_path).text=""


func _on_Login_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			OS.hide_virtual_keyboard()
