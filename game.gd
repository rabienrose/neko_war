extends Node2D

export (Resource) var char_res
export (NodePath) var char_root_path
export (NodePath) var spawn1_path
export (NodePath) var spawn2_path
export (NodePath) var chara_gen_ui_path

var fx_mgr
var team_charas=[[],[]]
var char_root
var spawn_nodes=[]
var chara_gen_ui
var auto_spawn_countdown=0
var scene_min=440
var scene_max=3300
var gold=100

func _ready():
    fx_mgr=get_node("FxMgr")
    spawn_nodes.append(get_node(spawn1_path))
    spawn_nodes.append(get_node(spawn2_path))
    char_root=get_node(char_root_path)
    chara_gen_ui=get_node(chara_gen_ui_path)
    # spawn_chara("paohui", 1, 1)
    # spawn_chara("paohui", 2, 0)
    chara_gen_ui.set_item(0,"paohui",1)
    Global.emit_signal("money_change",100)
    Global.connect("request_spawn_chara", self, "on_request_spawn_chara")
    Global.connect("expend_gold", self, "expend_gold")

func get_charas_in_range(team_id, min_x, max_x):
    var temp_chars=team_charas[team_id]
    var out_charas=[]
    for chara in temp_chars:
        if chara.position.x>=min_x and chara.position.x<=max_x:
            out_charas.append(chara)
    return out_charas

func spawn_chara(chara_name, lv, team_id):
    var spawn_pos = spawn_nodes[team_id]
    var new_char = char_res.instance()
    new_char.on_create(self)
    team_charas[team_id].append(new_char)
    char_root.add_child(new_char)
    var temp_attr_data=Global.get_char_attr(chara_name,lv)
    new_char.set_attr_data(temp_attr_data)
    var anim_data=Global.get_char_anim(chara_name)
    new_char.set_anim(anim_data, Global.get_char_anim_info(chara_name))
    new_char.set_team(team_id)
    new_char.set_x_pos(spawn_pos.position.x)

func on_request_spawn_chara(chara_info):
    spawn_chara(chara_info["name"], chara_info["lv"], 0)

func remove_chara(chara):
    team_charas[chara.team_id].erase(chara)
    chara.dead=true
    chara.queue_free()

func expend_gold(val):
    if gold-val<0:
        return false
    else:
        change_gold(-val)
        return true
    
func change_gold(val):
    gold=gold+val
    Global.emit_signal("money_change",gold)

func _physics_process(delta):
    if auto_spawn_countdown>0:
        auto_spawn_countdown=auto_spawn_countdown-delta
    else:
        spawn_chara("paohui", 1, 1)
        var rnd_time = rand_range(1,10)
        auto_spawn_countdown=rnd_time
    
