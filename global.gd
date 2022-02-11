extends Node

signal money_change(val)
signal request_spawn_chara(chara_info)
signal expend_gold(val)
signal request_battle(lv)
signal show_level_info(lv)


var char_tb_file_path="res://configs/characters.json"
var user_data_path="user://user.json"
var levels_info_path="res://configs/levels.json"
var items_info_path="res://configs/items.json"
var char_img_file_path="res://binary/images/charas/"
var item_img_file_path="res://binary/images/items/"

var user_data={}
var chara_tb={}
var levels_tb=[]
var items_tb={}
var chara_anim={}

var lottery_price=70

func _ready():
    var f=File.new()
    f.open(char_tb_file_path, File.READ)
    var content = f.get_as_text()
    chara_tb = JSON.parse(content).result
    f.close()
    f = File.new()
    if f.file_exists(user_data_path):
        f.open(user_data_path, File.READ)
        var out_str = f.get_as_text()
        user_data = JSON.parse(out_str).result
        f.close()
    else:
        user_data={}
        user_data["gold"]=0
        var chara_info={}
        chara_info["name"]="paohui"
        chara_info["lv"]=1
        user_data["characters"]=[chara_info]
        var equip_info={}
        equip_info["chara"]=["paohui","paohui","","",""]
        equip_info["item"]=["hp_recover","","","",""]
        user_data["equip"]=equip_info
        user_data["levels"]={}
        var level_info={}
        level_info["lv"]=0
        level_info["star"]=2
        user_data["levels"][str(level_info["lv"])]=level_info
        var item_info={}
        item_info["name"]="hp_recover"
        item_info["num"]=10
        user_data["items"]=[item_info]
    f = File.new()
    f.open(levels_info_path, File.READ)
    content = f.get_as_text()
    levels_tb = JSON.parse(content).result
    f.close()
    f = File.new()
    f.open(items_info_path, File.READ)
    content = f.get_as_text()
    items_tb = JSON.parse(content).result
    f.close()
    connect("request_battle",self,"on_request_start_battle")

func save_user_data():
    var f=File.new()
    f.open(user_data_path, File.WRITE)
    var temp_json_str=JSON.print(user_data)
    f.store_string(temp_json_str)
    f.close()

func find_my_chara_info(chara_name):
    for item in Global.user_data["characters"]:
        if item["name"]==chara_name:
            return item
    return null

func find_my_item_info(item_name):
    for item in Global.user_data["items"]:
        if item["name"]==item_name:
            return item
    return null

func get_char_attr(char_name, lv):
    return chara_tb[char_name]["attrs"][str(lv)]

func get_char_anim_info(char_name):
    return chara_tb[char_name]["appearance"]

func get_char_anim(char_name):
    var anim_file = chara_tb[char_name]["appearance"]
    if not anim_file in chara_anim:
        chara_anim[anim_file]=load("res://anim_sprite/"+char_name+".tres")
    return chara_anim[anim_file]

func on_request_start_battle(lv):
    pass

func delete_children(node):
    for n in node.get_children():
        node.remove_child(n)

func expend_user_money(val):
    if user_data["gold"]-val<0:
        return false
    user_data["gold"]=user_data["gold"]-val
    emit_signal("money_change", user_data["gold"])
    save_user_data()
