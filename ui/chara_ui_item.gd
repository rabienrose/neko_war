extends TextureRect

export (NodePath) var cost_label_path
export (NodePath) var icon_path
export (NodePath) var progress_path
export (NodePath) var cost_mask_path

var cost_label_node
var icon_node
var progress_node
var cost_mask_node

var chara_info
var gen_time
var icon_tex
var gen_cost
var has_item=false
var gen_countdown=0
var in_gen=false

func on_money_change(val):
    if has_item==false:
        return
    if gen_cost<=val:
        cost_mask_node.visible=false
    else:
        cost_mask_node.visible=true

func start_gen():
    in_gen=true
    gen_countdown=gen_time
    Global.emit_signal("expend_gold",gen_cost)

func _ready():
    cost_label_node=get_node(cost_label_path)
    icon_node=get_node(icon_path)
    progress_node=get_node(progress_path)
    cost_mask_node=get_node(cost_mask_path)
    Global.connect("money_change", self, "on_money_change")

func on_create(icon_tex, _gen_time, cost, _chara_info):
    gen_time=_gen_time
    gen_cost=cost
    has_item=true
    cost_label_node.text=str(cost)
    icon_node.texture=icon_tex
    chara_info=_chara_info


func _on_CharaUIItem_gui_input(event:InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed:
            if cost_mask_node.visible==false and progress_node.value==0:
                start_gen()

func _process(_delta):
    if gen_countdown>0:
        gen_countdown=gen_countdown-_delta
        progress_node.value=int(gen_countdown/gen_time*100)
    else:
        if in_gen:
            in_gen=false
            Global.emit_signal("request_spawn_chara", chara_info)
            progress_node.value=0


