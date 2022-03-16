import os
import oss2
import pymongo
import pprint
import json

f=open("configs/global.json",'r')
global_config = json.load(f)
f=open("configs/characters.json",'r')
chara_tb = json.load(f)
f=open("configs/items.json",'r')
items_tb = json.load(f)
f=open("configs/skills.json",'r')
skills_tb = json.load(f)

bucket_name='agent-war'
access_key_id = os.getenv('OSS_TEST_ACCESS_KEY_ID', 'LTAI5t7foo3Up9jKGSGNwg9h')
access_key_secret = os.getenv('OSS_TEST_ACCESS_KEY_SECRET', 'vvz7VgEa3ury3uFRQU6AFNCc7f9X8V')
use_internal=False
if use_internal:
    pass
else:
    endpoint = os.getenv('OSS_TEST_ENDPOINT', 'https://oss-cn-shanghai.aliyuncs.com') # external net
    if global_config["b_local_server"]==1:
        mongo_conn="mongodb://127.0.0.1:27017"
    else:
        mongo_conn="mongodb://"+global_config["flask_ip"]+":27017"

# bucket = oss2.Bucket(oss2.Auth(access_key_id, access_key_secret), endpoint, bucket_name)
pp=pprint.PrettyPrinter(width=41, compact=True)
myclient = pymongo.MongoClient(mongo_conn)
myclient.server_info()
user_table=myclient["neko_war"]["user"]
level_table=myclient["neko_war"]["level"]
game_table=myclient["neko_war"]["game"]



