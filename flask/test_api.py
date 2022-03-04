import config
from user import UserInfo
from level_mgr import LevelMgr

def rand_a_level():
    level_mgr = LevelMgr()
    level_mgr.set_today_a_rand_level()

def add_level():
    level_mgr = LevelMgr()
    battle_data={}
    battle_data["gold"]=100
    battle_data["base_hp"]=200
    battle_data["script"]="ai"
    battle_data["args"]={}
    battle_data["args"]["hotkey"]=["sword","bow","bow","sword","sword"]
    level_mgr.add_level(battle_data, 1)

add_level()
rand_a_level()