extends Node

var game

func _ready():
    pass # Replace with function body.

func on_create(game_obj):
    game=game_obj

func use_item(item_name, team_id):
    if item_name=="red_potion":
        for c in game.char_root.get_children():
            if c.team_id==team_id and c.info["type"]=="chara":
                c.attr["atk"]=c.attr["atk"]+1
    elif item_name=="cost_zero":
        pass
    elif item_name=="cd_zero":
        pass
    elif item_name=="range_char_slow":
        pass
