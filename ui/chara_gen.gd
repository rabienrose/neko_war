extends HBoxContainer

export (Array, NodePath) var path_list

var item_node_list=[]

func _ready():
    for item_path in path_list:
        item_node_list.append(get_node(item_path))

func set_item(index, chara_name,lv):
    var info = Global.get_char_attr(chara_name,lv)
    var cost=info["cost"]
    var gen_time=info["gen_time"]
    var icon_file_path=Global.char_img_file_path+chara_name+"/icon.png"
    var icon_texture=load(icon_file_path)
    item_node_list[index].on_create(icon_texture, gen_time, cost, {"name":chara_name, "lv":lv})

