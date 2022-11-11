local util =  {}
local nk = require("nakama")

function util.get_user_info(user_id)
    local object_ids = {
        { collection = "user", key = "basic", user_id = user_id },
    }
    local objects = nk.storage_read(object_ids)
    return objects[1].value
end

function util.update_user_info(user_id, info)
    local new_objects = {
        {
            collection = "user",
            key = "basic",
            value = info,
            permission_read = 1,
            permission_write = 0,
            user_id=user_id
        }
    }
    nk.storage_write(new_objects)
end

function util.print_table(data)
    for k,v in pairs(data) do
        print(k,v)
    end
end

function util.table_size(t)
    local num=0
    for _,_ in pairs(t) do
        num=num+1
    end
    return num
end

function util.load_json(file_path)
    local contents = nk.file_read(file_path)
    return nk.json_decode(contents)
end

function util.load_game_info_to_db()
    local charas_tb = util.load_json("../configs/characters.json")
    local items_tb = util.load_json("../configs/items.json")
    local global_tb = util.load_json("../configs/global.json")
    local new_objects = {
        {
            collection = "global",
            key = "items_tb",
            value = items_tb,
            permission_read = 0,
            permission_write = 0,
        },
        {
            collection = "global",
            key = "charas_tb",
            value = charas_tb,
            permission_read = 0,
            permission_write = 0,
        },
        {
            collection = "global",
            key = "global_tb",
            value = global_tb,
            permission_read = 0,
            permission_write = 0,
        }
    }
    nk.storage_write(new_objects)
    -- util.fetch_game_info()
end

function util.get_user_slots(user_id)
    local user_info = util.get_user_info(user_id)
    local hk_slot={}
    for k,v in ipairs(user_info["equip"][1]) do
        if v~="" then
            local info={v,user_info["characters"][v]}
            table.insert(hk_slot,info)
        else
            local info={"",-1}
            table.insert(hk_slot,info)
        end
    end
    for k,v in ipairs(user_info["equip"][2]) do
        if v~="" then
            local info={v,user_info["items"][v]}
            table.insert(hk_slot,info)
        else
            local info={"",-1}
            table.insert(hk_slot,info)
        end
    end
    local battle_info={
        hk_slot=hk_slot,
        gold=user_info.gold
    }
    return battle_info
end

function util.fetch_game_info()
    local object_ids = {
        { collection = "global", key = "items_tb"},
    }
    local objects = nk.storage_read(object_ids)
end

function util.get_level_data(level_name)
    local object_ids = {
        { collection = "level", key = level_name},
    }
    local objects = nk.storage_read(object_ids)
    if #objects>0 then
        return objects[1].value
    else
        return nil
    end
end

function util.update_level_data(level_name, data)
    local new_objects = {
        {
            collection = "level",
            key = level_name,
            value = data,
            permission_read = 2,
            permission_write = 0,
        },
    }
    nk.storage_write(new_objects)
end

function util.submit_coin_record(user_id, user_name, coin, note)
    nk.leaderboard_record_write(util.coin_rank_id, user_id, user_name, coin, 0, {note=note})
end
util.coin_rank_id = "coin_rank"
return util