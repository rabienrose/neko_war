from bson.objectid import ObjectId
import config
import random
from game import Game
from user import UserInfo
import json

class LevelMgr:
    def set_today_a_rand_level(self):
        cul_chances=[]
        level_ids=[]
        cur_cul_chance=0
        for x in config.level_table.find({}):
            cur_cul_chance=cur_cul_chance+x["chance"]
            cul_chances.append(cur_cul_chance)
            level_ids.append(x["_id"])
        r_num = random.randint(0,cur_cul_chance-1)
        level_ind= ""
        for i in range(len(cul_chances)):
            if cul_chances[i]>r_num:
                level_ind=i
                break
        if level_ind!=-1:
            game=Game()
            game.set_cul_level(str(level_ids[level_ind]))

    def get_daliy_level(self):
        game=Game()
        level_id = game.get_cul_level()
        query_ret=config.level_table.find_one({"_id":ObjectId(level_id)},{"_id":0,"battle_data":1,"stats":1})
        query_ret["level_id"]=level_id
        return query_ret

    def update_recording(self, level_id, stat_name, data):
        config.level_table.update_one({"_id":ObjectId(level_id)},{"$set":{"record."+stat_name:data}})

    def update_level_stats(self, token, recording_data, battle_time, level_id, chara_lv, difficulty):
        query_ret=config.level_table.find_one({"_id":ObjectId(level_id)},{"_id":0})
        stats={}
        if "stats" in query_ret:
            stats=query_ret["stats"]
        stat_name=str(chara_lv)+"_"+str(difficulty)
        user = UserInfo(token)
        user_info = user.get_info()
        if stat_name not in stats:
            stats[stat_name]={}
            stats[stat_name]["num"]=1
            stats[stat_name]["time"]=battle_time
            stats[stat_name]["user"]=user_info["nickname"]
            self.update_recording(level_id, stat_name, recording_data)
        else:
            stats[stat_name]["num"]=stats[stat_name]["num"]+1
        if stats[stat_name]["time"]>battle_time:
            stats[stat_name]["time"]=battle_time
            stats[stat_name]["user"]=user_info["nickname"]
            self.update_recording(level_id, stat_name, recording_data)
        config.level_table.update_one({"_id":ObjectId(level_id)},{"$set":{"stats":stats}})

        level_stat_name=level_id+"_"+str(chara_lv)+"_"+str(difficulty)
        if level_stat_name not in user_info["levels"]:
            user_info["levels"][level_stat_name]={}
            user_info["levels"][level_stat_name]["num"]=1
            user_info["levels"][level_stat_name]["time"]=battle_time
        else:
            user_info["levels"][level_stat_name]["num"]=user_info["levels"][level_stat_name]["num"]+1
        if user_info["levels"][level_stat_name]["time"]>battle_time:
            user_info["levels"][level_stat_name]["time"]=battle_time
        config.user_table.update_one({"_id":ObjectId(token)},{"$set":{"levels":user_info["levels"]}})
        
    def get_level_gold(self, chara_lv, difficulty, level_id):
        query_re = config.level_table.find_one({"_id":ObjectId(level_id)},{"_id":0,"battle_data.gold":1})
        level_base_gold=query_re["battle_data"]["gold"]
        f=open("../configs/global.json",'r')
        global_info = json.load(f)
        final_gold=level_base_gold*global_info["difficulty_gold_coef"][difficulty]*global_info["chara_gold_coef"][chara_lv]
        f.close()
        return final_gold

    def add_level(self, battle_data, chance):
        level_data={}
        level_data["battle_data"]=battle_data
        level_data["chance"]=chance
        print(level_data)
        config.level_table.insert_one(level_data)