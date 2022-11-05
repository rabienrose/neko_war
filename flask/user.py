from bson.objectid import ObjectId
import config
import time
import random

class UserInfo:
    token=""
    def __init__(self, token:str) -> None:
        self.token=token

    def check_password(self, account:str, password:str):
        ret={}
        ret["ret"]="ok"
        query_re = config.user_table.find_one({"account":account},{"password":1})
        if query_re is None:
            ret["ret"]="fail"
            ret["desc"]="account not exist"
        else:
            if query_re["password"]!=password:
                ret["ret"]="fail"
                ret["desc"]="password not right"
            else:
                self.token = str(query_re["_id"])
        return ret

    def attach_name_pw(self, account:str, nickname:str, password:str):
        ret={}
        ret["ret"]="ok"
        query_re = config.user_table.find_one({"account":account})
        if query_re is not None:
            ret["ret"]="fail"
            ret["desc"]="account exist"
        else:
            user_info={}
            user_info["account"]=account
            user_info["nickname"]=nickname
            user_info["password"]=password
            user_info["devices"]=[]
            user_info["tips"]={}
            self.token = str(config.user_table.insert_one(user_info).inserted_id)
        return ret

    def update_device(self, device_id, device_type, ip):
        if self.token=="":
            return
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"devices":1})
        has_device=False
        for d in query_re["devices"]:
            if d["id"]==device_id:
                has_device=True
                d["num"]=d["num"]+1
                if ip not in d["ips"]:
                    d["ips"].append(ip)
                d["last_time"]=int(time.time())
                break
        if has_device==False:
            device_info={}
            device_info["id"]=device_id
            device_info["type"]=device_type
            device_info["num"]=1
            device_info["ips"]=[ip]
            device_info["last_time"]=int(time.time())
            query_re["devices"].append(device_info)
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"devices":query_re["devices"]}})

    def reset_user(self):
        user_info={}
        user_info["gold"]=0
        user_info["diamond"]=2000        
        user_info["characters"]=[{"name": "sword","lv": 0}]
        user_info["equip"]={"chara": ["sword","","","", ""],"item": ["","","","",""]}
        user_info["levels"]={}
        user_info["items"]=[]
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":user_info})

    def get_nickname(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"nickname":1})
        return query_re["nickname"]

    def get_info(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"account":0, "password":0, "devices":0})
        # query_re["token"]=self.token
        return query_re

    def get_level_pass_num(self, level_name):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"levels":1})
        if level_name=="":
            return len(query_re["levels"])
        else:
            temp_num=0
            for key in query_re["levels"]:
                if level_name in key:
                    temp_num=temp_num+1
            return temp_num

    def get_chara_lv(self, chara_infos, chara_name):
        for item in chara_infos:
            if item["name"]==chara_name:
                return item["lv"]
        return -1

    def inc_chara_lv(self, chara_infos, chara_name):
        for item in chara_infos:
            if item["name"]==chara_name:
                if config.chara_tb[chara_name]["max_lv"]>=item["lv"]+1:
                    item["lv"]=item["lv"]+1
                    config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"characters":chara_infos}})
                    return True
        return False

    def upgrade_chara(self, chara_name):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"levels":0})
        chara_lv = self.get_chara_lv(query_re["characters"], chara_name)
        if chara_lv==-1:
            return None
        upgrade_cost=config.chara_tb[chara_name]["attrs"][str(chara_lv+1)]["upgrade_cost"]
        if upgrade_cost<=query_re["gold"]:
            if self.inc_chara_lv(query_re["characters"], chara_name):
                self.change_gold(-upgrade_cost)
                return {"name":chara_name, "lv":chara_lv+1, "cost":upgrade_cost}
        return None

    def get_item_count(self, item_infos, item_name):
        for item in item_infos:
            if item["name"]==item_name:
                return item["num"]
        return -1

    def inc_item_count(self, item_infos, item_name):
        for item in item_infos:
            if item["name"]==item_name:
                    item["num"]=item["num"]+1
                    config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"items":item_infos}})
                    return True
        return False

    def dec_item_count(self, item_changes):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"items":1})
        item_infos=query_re["items"]
        for item_name in item_changes:
            for item in item_infos:
                if item["name"]==item_name:
                    item["num"]=item["num"]-item_changes[item_name]
                    break
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"items":item_infos}})
        return False

    def buy_item(self, item_name):
        item_price=config.items_tb[item_name]["price"]
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"diamond":1,"items":1})
        item_num=self.get_item_count(query_re["items"], item_name)
        if item_num!=-1:
            if item_price<=query_re["diamond"]:
                self.inc_item_count(query_re["items"], item_name)
                return {"name":item_name, "num":item_num, "cost":item_price}
        return None

    def draw_lottory(self):
        lottery_price=config.global_config["lottery_price"]
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"characters":1,"items":1,"diamond":1})
        result_info={}
        if lottery_price<=query_re["diamond"]:
            self.change_diamond(-lottery_price)
            #draw chara
            remain_charas=[]
            result_chara=None
            for chara_name in config.chara_tb:
                chara=config.chara_tb[chara_name]
                if chara_name in query_re["characters"]:
                    continue
                if chara["type"]!="chara":
                    continue
                t_rand = random.random()
                if t_rand<chara["chance"]:
                    remain_charas.append(chara)
            if len(remain_charas)>1:
                rand_i = random.randint(0,len(remain_charas)-1)
                result_chara=remain_charas[rand_i]
            elif len(remain_charas)==1:
                result_chara=remain_charas[0]
            if result_chara is not None:
                lv = self.get_chara_lv(query_re["characters"], result_chara["name"])
                if lv==-1:
                    chara_info_t={}
                    chara_info_t["name"]=result_chara["name"]
                    chara_info_t["lv"]=0
                    config.user_table.update_one({"_id":ObjectId(self.token)},{"$push":{"characters":chara_info_t}})
                    re_info = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"characters":1})
                    result_info["name"]=result_chara["name"]
                    result_info["info"]=re_info["characters"]
                    result_info["type"]="chara"
            if "name" not in result_info:
                #draw item
                result_item=None
                remain_items=[]
                for item_name in config.items_tb:
                    item = config.items_tb[item_name]
                    t_rand = random.random()
                    if t_rand<item["chance"]:
                        remain_items.append(item)
                    if len(remain_items)==0:
                        temp_items=[]
                        for item_name_1 in config.items_tb:
                            temp_items.append(config.items_tb[item_name_1])
                        rand_i = random.randint(0,len(temp_items)-1)
                        result_item=temp_items[rand_i]
                    elif len(remain_items)>1:
                        rand_i = random.randint(0,len(remain_items)-1)
                        result_item=remain_items[rand_i]
                    else:
                        result_item=remain_items[0]
                num =self.get_item_count(query_re["items"], result_item["name"])
                if num == -1 :
                    item_info_t={}
                    item_info_t["name"]=result_item["name"]
                    item_info_t["num"]=1
                    config.user_table.update_one({"_id":ObjectId(self.token)},{"$push":{"items":item_info_t}})
                else:
                    self.inc_item_count(query_re["items"], result_item["name"])
                re_info = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"items":1})
                result_info["name"]=result_item["name"]
                result_info["info"]=re_info["items"]
                result_info["type"]="item"
        return result_info

    def update_equip(self, b_chara, index, name):
        equip_type="chara"
        if b_chara==False:
            equip_type="item"
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"equip."+equip_type+"."+str(index):name}})

    def change_gold(self, gold):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"gold":1})
        new_gold=query_re["gold"]+gold
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"gold":new_gold}})

    def change_diamond(self, val):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"diamond":1})
        new_val=query_re["diamond"]+val
        if new_val<0:
            return False
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"diamond":new_val}})
        return True

    def set_last_pvp(self):
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"last_pvp":int(time.time())}})
        
    def get_setting(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"setting":1})
        if "setting" in query_re:
            return query_re["setting"]
        else:
            return {"note":""}

    def modify_setting(self, note_str):
        modify_data={}
        modify_data["note"]=note_str
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"setting":modify_data}})

    def set_tip_flag(flag_name):
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"tips."+flag_name:1}})