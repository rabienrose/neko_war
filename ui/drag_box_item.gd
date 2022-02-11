extends TextureRect
export (NodePath) var icon_path
export (NodePath) var num_path

var custom_data=null
var click_cb=null
var drag_cb=null

func _ready():
    material=material.duplicate()

func set_icon(icon_texture):
    get_node(icon_path).texture=icon_texture

func set_num(num):
    get_node(num_path).text=str(num)

func set_data(chara_name):
    custom_data=chara_name

func set_cb(chara_item_click_cb):
    click_cb=chara_item_click_cb

func set_highlight(b_true):
    if b_true:
        material.set_shader_param("width",5)
    else:
        material.set_shader_param("width",0)

func _on_ItemItem_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed==true:
            if custom_data!=null:
                click_cb.call_func(custom_data)
                set_highlight(true)
    if event is InputEventScreenDrag:
        if drag_cb!=null:
            drag_cb.call_func(custom_data, event.position)
            
