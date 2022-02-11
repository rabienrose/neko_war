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
var gen_time
var icon_tex
var has_item=false
var gen_countdown=0
var in_gen=false
var b_chara=true
var custom_val

func on_money_change(val):
    if b_chara==false:
        return
    if has_item==false:
        return
    if custom_val<=val:
        avia_mask_node.visible=false
    else:
        avia_mask_node.visible=true

func start_gen():
    in_gen=true
    gen_countdown=gen_time
    Global.emit_signal("expend_gold",custom_val)

func use_item():
    if b_chara:
        return
    in_gen=true
    gen_countdown=gen_time
    Global.emit_signal("request_use_item", custom_info)
    custom_val=custom_val-1
    cost_label_node.text=str(custom_val)
    var my_item_info = Global.get_my_item_info(custom_info["name"])
    my_item_info["num"]=custom_val
    Global.save_user_data()
    if custom_val==0:
        avia_mask_node.visible=true

func _ready():
    cost_label_node=get_node(cost_label_path)
    icon_node=get_node(icon_path)
    progress_node=get_node(progress_path)
    avia_mask_node=get_node(cost_mask_path)
    Global.connect("money_change", self, "on_money_change")

func on_create(icon_tex, _gen_time, val, _custom_info, _b_chara):
    gen_time=_gen_time
    custom_val=val
    has_item=true
    cost_label_node.text=str(custom_val)
    icon_node.texture=icon_tex
    custom_info=_custom_info
    b_chara=_b_chara

func _on_CharaUIItem_gui_input(event:InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed:
            if avia_mask_node.visible==false and progress_node.value==0:
                if b_chara:
                    start_gen()
                else:
                    use_item()

func shake_box():
    $AnimationPlayer.play("shake")

func _process(_delta):
    if gen_countdown>0:
        gen_countdown=gen_countdown-_delta
        progress_node.value=int(gen_countdown/gen_time*100)
    else:
        if in_gen:
            in_gen=false
            if b_chara:
                Global.emit_signal("request_spawn_chara", custom_info)
            progress_node.value=0
            shake_box()


