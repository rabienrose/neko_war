extends HBoxContainer

export (NodePath) var item_root_path

var item_root

func _ready():
    item_root=get_node(item_root_path)

func get_items():
    return item_root.get_children()
