extends Control

export (NodePath) var lock_path
export (NodePath) var unlock_path
export (NodePath) var lv_label_path
export (NodePath) var delay_label_path

var lv_name=""
var container
var dragged=false

func set_lock(b_lock, _lv_name):
    lv_name=_lv_name
    if b_lock:
        get_node(lock_path).visible=true
        get_node(unlock_path).visible=false
    else:
        get_node(lock_path).visible=false
        get_node(unlock_path).visible=true
        var v_s = lv_name.split("_")
        get_node(lv_label_path).text=v_s[1]
        get_node(delay_label_path).text=v_s[2]

func _ready():
    get_node(unlock_path).material=get_node(unlock_path).material.duplicate()
    get_node(lock_path).material=get_node(lock_path).material.duplicate()

func set_highlight(b_true):
    if b_true:
        get_node(unlock_path).material.set_shader_param("width",8)
        get_node(lock_path).material.set_shader_param("width",8)
    else:
        get_node(unlock_path).material.set_shader_param("width",0)
        get_node(lock_path).material.set_shader_param("width",0)

func _on_UnLock_gui_input(event):
    if event is InputEventScreenDrag:
        dragged=true
    if event is InputEventScreenTouch:
        if event.pressed==false and dragged==false:
            container.clear_highlight()
            set_highlight(true)
            Global.emit_signal("show_level_info",lv_name)
        else:
            dragged=false

func _on_Lock_gui_input(event):
    if event is InputEventScreenDrag:
        dragged=true
    if event is InputEventScreenTouch:
        if event.pressed==false and dragged==false:
            container.clear_highlight()
            set_highlight(true)
            Global.emit_signal("show_level_info",lv_name)
        else:
            dragged=false
