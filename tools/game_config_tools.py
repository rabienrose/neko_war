import copy
import json

lv_num=10

other_fix_buildings={
    "base1":
    {
        "name":"base1",
        "type":"building",
        "attrs":{
            "1":{
                "hp":300
            }
        },
        "appearance":{
            "file_name":"base1",
            "y_offset":-165,
            "shoot_offset":[0,0],
            "hit_y_offset":-30,
            "atk_frame":[],
            "shoot_fx":[],
            "atk_fx":[],
            "bullet_fx":[],
            "hit_fx":[],
            "die_fx":[
                {"type":"prefab","res":"explosion"}
            ]
        }
    },
    "base2":
    {
        "name":"base2",
        "type":"building",
        "attrs":{
            "1":{
                "hp":300
            }
        },
        "appearance":{
            "file_name":"base2",
            "y_offset":-145,
            "shoot_offset":[0,0],
            "hit_y_offset":-30,
            "atk_frame":[],
            "shoot_fx":[],
            "atk_fx":[],
            "bullet_fx":[],
            "hit_fx":[],
            "die_fx":[
                {"type":"prefab","res":"explosion"}
            ]
        }
    }
}

attr_inter_method={
    "hp":["linear",0],
    "atk":["linear",0],
    "mov_spd":["linear",0],
    "atk_spd":["linear",1],
    "range":["linear",0],
    "luk":["linear",2],
    "deff":["linear",2],
    "cri":["linear",2],
    "flee":["linear",2],
    "atk_num":["linear",0],
    "upgrade_cost":["log",0],
}

chara_template={
        "name":"sword",
        "type":"chara",
        "chance":0.5,
        "desc":"La la la la la.",
        "max_lv":lv_num,
        "build_cost":20,
        "build_time":2,
        "self_destroy":False,
        "atk_buf":[
        ],
        "skills":[
        ],
        "target_scheme":{
            "group":["enemy"],
            "type":["chara","building"],
            "sel_type":"new"
        },
        "drop_gold":20,
        "attrs":{
        },
        "appearance":{
            "file_name":"sword",
            "y_offset":-70,
            "hit_y_offset":0,
            "shoot_offset":[10,20],
            "atk_frame":[5,5,9],
            "shoot_fx":[],
            "atk_fx":[],
            "bullet_fx":[],
            "hit_fx":[
                {"type":"frame","res":"impact","anim":"fx_1"},
                {"type":"frame","res":"impact","anim":"fx_2"}
            ],
            "die_fx":[
                {"type":"prefab","res":"explosion"}
            ]
        }
    }

chara_skill_list={
    "skeleton_mage":[
        {"name":"heal_all","chance":1.0}
    ],
    "skeleton_boss":[
        {"name":"dash_short","chance":1.0}
    ]
}

chara_atk_buf_list={
    "spider":[
        {"name":"push_short","chance":1.0}
    ]

}

chara_bullet_fx_list={
    "bow":[
        {"type":"prefab","res":"arrow"}
    ],
    "skeleton_archer":[
        {"type":"prefab","res":"fire_ball"}
    ]

}

chara_hit_fx_list={
    "slime":[
        {"type":"prefab","res":"fire_wall"}
    ],
    "skeleton_boss":[
        {"type":"prefab","res":"midas"}
    ],
    "bat":[
        {"type":"prefab","res":"lightning_bolt"}
    ],
    "skeleton_spear":[
        {"type":"prefab","res":"sun"}
    ],
    "spider":[
        {"type":"prefab","res":"earth"}
    ]
}

chara_shoot_fx_list={
}

def round_val(val, round_num):
    if round_num==0:
        return int(val)
    else:
        return round(val, round_num)

def get_lvs_value_linear(s_val, e_val, lv_num, round_num):
    out_vals=[]
    step=(e_val-s_val)/(lv_num-1)
    for i in range(lv_num):
        out_vals.append(round_val(s_val+i*step,round_num))
    return out_vals

def get_lvs_value_log(s_val, e_val, lv_num, round_num):
    out_vals=[]
    step=pow(e_val/s_val,1/(lv_num-1))
    for i in range(lv_num):
        out_vals.append(round_val(s_val*pow(step,i),round_num))
    return out_vals

def fill_on_attr(attr_name, vals, attrs):
    for i in range(lv_num):
        attrs[str(i+1)][attr_name]=vals[i]

def generate_one_chara_config(name,chara_attr):
    info=copy.deepcopy(chara_template)
    info["name"]=name
    for i in range(lv_num):
        info["attrs"][str(i+1)]={}
    for key in attr_inter_method:
        val_range=[chara_attr[key][0], chara_attr[key][1]]
        if attr_inter_method[key][0]=="linear":
            vals = get_lvs_value_linear(val_range[0], val_range[1], lv_num,attr_inter_method[key][1])
        else:
            vals = get_lvs_value_log(val_range[0], val_range[1], lv_num,attr_inter_method[key][1])
        fill_on_attr(key, vals, info["attrs"])
    info["appearance"]["file_name"]=name
    info["drop_gold"]=int(chara_attr["drop_gold"])
    info["build_cost"]=int(chara_attr["build_cost"])
    info["build_time"]=chara_attr["build_time"]
    info["chance"]=chara_attr["chance"]
    info["appearance"]["y_offset"]=chara_attr["y_offset"]
    info["appearance"]["shoot_offset"]=chara_attr["shoot_offset"]
    info["appearance"]["atk_frame"]=chara_attr["atk_frame"]
    info["appearance"]["hit_y_offset"]=chara_attr["hit_y_offset"]
    info["target_scheme"]["sel_type"]=chara_attr["atk_ai"]
    if name=="slime":
        info["self_destroy"]=True
    if name=="bee":
        info["target_scheme"]["type"]=["building"]
    return info

def convert_tb_cell_2_vec(cell_string):
    s_vec=cell_string.split("|")
    out_v=[]
    for i in s_vec:
        out_v.append(float(i))
    return out_v

def generate_chara_config(chara_attr_tb):
    total_chara_config={}
    for chara_name in chara_names:
        total_chara_config[chara_name]=generate_one_chara_config(chara_name, chara_attr_tb[chara_name])
    for key in other_fix_buildings:
        total_chara_config[key]=other_fix_buildings[key]
    for chara_name in chara_skill_list:
        total_chara_config[chara_name]["skills"]=chara_skill_list[chara_name]
    for chara_name in chara_atk_buf_list:
        total_chara_config[chara_name]["atk_buf"]=chara_atk_buf_list[chara_name]
    for chara_name in chara_bullet_fx_list:
        total_chara_config[chara_name]["appearance"]["bullet_fx"]=chara_bullet_fx_list[chara_name]
    for chara_name in chara_hit_fx_list:
        total_chara_config[chara_name]["appearance"]["hit_fx"]=chara_hit_fx_list[chara_name]
    for chara_name in chara_shoot_fx_list:
        total_chara_config[chara_name]["appearance"]["shoot_fx"]=chara_shoot_fx_list[chara_name]
    f=open("../configs/characters.json",'w')
    json.dump(total_chara_config, f)


level_template={
    "lv":0,
    "gold":100,
    "spawn_delay":15,
    "init_gold":100,
    "cell_sequence":[],
    "base_hp":100,
}

def generate_levels_config(seq, type_id, total_levs, gold_scale):
    min_delay=0.5
    delay_lv=7
    delay_times=[]
    for i in range(delay_lv):
        delay_times.append(round(min_delay*pow(1.5,delay_lv-i-1),1))
    for delay_id in range(delay_lv):
        for lv in range(lv_num):
            temp_level_info=copy.deepcopy(level_template)
            temp_level_info["name"]=str(type_id)+"/"+str(lv)+"/"+str(delay_id)
            temp_level_info["cell_sequence"]=seq
            temp_level_info["spawn_delay"]=delay_times[delay_id]
            temp_level_info["lv"]=lv+1
            temp_level_info["gold"]=int(100*pow(gold_scale,lv+delay_id*4))
            temp_level_info["base_hp"]=int(100*pow(1.2,lv+delay_id))
            total_levs[temp_level_info["name"]]=temp_level_info
    f=open("../configs/levels.json",'w')
    json.dump(total_levs, f)


f=open("../configs/attr.csv",'r')
lines = f.readlines()
chara_attr_tb={}
chara_names=[]
for line in lines:
    line=line[:-1]
    line_vec=line.split(",")
    if line_vec[0]=="Chamo":
        for chara_name in line_vec:
            if chara_name=="Chamo" or chara_name=="attr_type":
                continue
            chara_attr_tb[chara_name]={}
            chara_names.append(chara_name)
    else:
        attr_name=line_vec[0]
        attr_type=line_vec[1]
        for i in range(2,len(line_vec)):
            var = line_vec[i]
            if attr_type=="numbers":
                var=convert_tb_cell_2_vec(var)
            elif attr_type=="number":
                var=float(var)
            chara_attr_tb[chara_names[i-2]][attr_name]=var
f.close()

# generate_chara_config(chara_attr_tb)
total_levs={}
generate_levels_config(["sword"],2,total_levs,1.1)
generate_levels_config(["sword","bow"],1,total_levs,1.1)
generate_levels_config(["skeleton_shield","sword","skeleton_shield","bow"],0,total_levs,1.1)



    
    