extends Control

export (NodePath) var lock_path
export (NodePath) var unlock_path
export (NodePath) var lv_label_path

export (NodePath) var star1_path
export (NodePath) var star2_path
export (NodePath) var star3_path
export (NodePath) var star1e_path
export (NodePath) var star2e_path
export (NodePath) var star3e_path

var lv=-1
var container

func set_lock(b_lock, _lv, star_num):
    if b_lock:
        get_node(lock_path).visible=true
        get_node(unlock_path).visible=false
    else:
        lv=_lv
        get_node(lock_path).visible=false
        get_node(unlock_path).visible=true
        get_node(lv_label_path).text=str(lv)
        if star_num==0:
            get_node(star1_path).visible=false
            get_node(star1e_path).visible=true
            get_node(star2_path).visible=false
            get_node(star2e_path).visible=true
            get_node(star3_path).visible=false
            get_node(star3e_path).visible=true
        elif star_num==1:
            get_node(star1_path).visible=true
            get_node(star1e_path).visible=false
            get_node(star2_path).visible=false
            get_node(star2e_path).visible=true
            get_node(star3_path).visible=false
            get_node(star3e_path).visible=true
        elif star_num==2:
            get_node(star1_path).visible=true
            get_node(star1e_path).visible=false
            get_node(star2_path).visible=true
            get_node(star2e_path).visible=false
            get_node(star3_path).visible=false
            get_node(star3e_path).visible=true
        elif star_num==3:
            get_node(star1_path).visible=true
            get_node(star1e_path).visible=false
            get_node(star2_path).visible=true
            get_node(star2e_path).visible=false
            get_node(star3_path).visible=true
            get_node(star3e_path).visible=false
        else:
            get_node(star1_path).visible=false
            get_node(star1e_path).visible=false
            get_node(star2_path).visible=false
            get_node(star2e_path).visible=false
            get_node(star3_path).visible=false
            get_node(star3e_path).visible=false

func _ready():
    get_node(unlock_path).material=get_node(unlock_path).material.duplicate()

func set_highlight(b_true):
    if b_true:
        get_node(unlock_path).material.set_shader_param("width",5)
    else:
        get_node(unlock_path).material.set_shader_param("width",0)

func _on_UnLock_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            container.clear_highlight()
            set_highlight(true)
            Global.emit_signal("show_level_info",lv)
