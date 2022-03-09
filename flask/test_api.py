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

def update_level_stats():
    token="6221ab307521a80278ab3c05"
    recording_data="aaaaaaaaaa"
    battle_time=30
    level_id="6221d9414544092b0af2279b"
    chara_lv=3
    difficulty=4
    level_mgr = LevelMgr()
    level_mgr.update_level_stats(token, recording_data, battle_time, level_id, chara_lv, difficulty)

def get_lv_gold():
    level_mgr = LevelMgr()
    gold = level_mgr.get_level_gold(2,3,"6221d9414544092b0af2279b")
    user=UserInfo("6221ab307521a80278ab3c05")
    user.change_gold(gold)

# get_lv_gold()
# add_level()
rand_a_level()