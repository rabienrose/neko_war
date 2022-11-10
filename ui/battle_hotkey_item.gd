extends TextureRect

export (NodePath) var cost_label_path
export (NodePath) var icon_path
export (NodePath) var progress_path
export (NodePath) var cost_mask_path

var cost_label_node
var icon_node
var progress_node
var avia_mask_node

var custom_info
var delay_time
var icon_tex
var has_item=false
var countdown=0
var in_gen=false
var custom_val
var click_cb=null
var index

func _ready():
    cost_label_node=get_node(cost_label_path)
    icon_node=get_node(icon_path)
    progress_node=get_node(progress_path)
    avia_mask_node=get_node(cost_mask_path)

func on_create(icon_tex, _delay_time, val, _custom_info, _click_cb,_index):
    index=_index
    delay_time=_delay_time
    set_val(val)
    has_item=true
    cost_label_node.text=str(custom_val)
    icon_node.texture=icon_tex
    custom_info=_custom_info
    click_cb=_click_cb

func set_val(val):
    cost_label_node.text=str(val)
    custom_val=val
    if custom_val==0:
        avia_mask_node.visible=true

func set_mask(b_visible):
    avia_mask_node.visible=b_visible

func set_done():
    if in_gen:
        countdown=0

func _on_CharaUIItem_gui_input(event:InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed:
            if has_item and avia_mask_node.visible==false and progress_node.value==0:
                var go_on=true
                if click_cb!=null:
                    go_on = click_cb.call_func(self)
                if go_on:
                    in_gen=true
                    countdown=delay_time

func shake_box():
    $AnimationPlayer.play("shake")

func _physics_process(_delta):
    if countdown>0:
        countdown=countdown-_delta
        progress_node.value=int(countdown/delay_time*100)
    else:
        if in_gen:
            in_gen=false
            progress_node.value=0
            shake_box()


