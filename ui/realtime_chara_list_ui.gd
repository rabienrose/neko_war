extends VBoxContainer

export (Resource) var item_res

export var b_right=false

func _ready():
    pass # Replace with function body.

func update_list(chara_infos):
    Global.delete_children(self)
    for c in chara_infos:
        var new_node = item_res.instance()
        var char_info_str=c["name"]+"("+str(c["lv"])+")    "+str(c["num"])
        if b_right:
            new_node.align=Label.ALIGN_RIGHT
            char_info_str=str(c["num"])+"    ("+str(c["lv"])+")"+c["name"]
        
        new_node.text=char_info_str
        add_child(new_node)
