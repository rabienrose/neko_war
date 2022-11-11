local pvp_battle = {}
local nk = require("nakama")
local util = require("util")

function pvp_battle.match_init(_, _)
    local gamestate = {
        frame_id = 0,
        presences={},
        ready={},
        winner="",
        loser="",
        cost={},
        items={},
        all_ready=false,
        sent_4_ready=false
    }
    local tickrate = 5
    local label = "PVP"
    return gamestate, tickrate, label
end

function pvp_battle.match_join_attempt(_, _, _, state, presence, _)
    return state, true
end

function pvp_battle.match_join(_, dispatcher, _, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = util.get_user_slots(presence.user_id)
        state.ready[presence.user_id]=false
        state.cost[presence.user_id]=0
        state.items[presence.user_id]={}
    end
    return state
end

local function proc_a_user(user_id, state, b_win, cost)
    
    local user_info = util.get_user_info(user_id)
    if b_win then
        user_info.gold=user_info.gold+cost
    else
        user_info.gold=user_info.gold-cost
    end
    
    for k,v in pairs(state.items[user_id]) do
        if user_info.items[v]~=nil and user_info.items[v]>0 then
            user_info.items[v]=user_info.items[v]-1
        end
    end
    util.update_user_info(user_id, user_info)
    local account = nk.account_get_id(user_id)
    util.submit_coin_record(user_id, account.user.username, user_info.gold, "lalala")
end

local function proc_battle_result(state, winner, loser)
    local lose_cost=state.cost[loser]
    proc_a_user(winner, state, true, lose_cost)
    proc_a_user(loser, state, false, lose_cost)
end

function pvp_battle.match_leave(_, _, _, state, presences)
    if state.all_ready==true then
        local loser=""
        for _, presence in ipairs(presences) do
            loser=presence.user_id
        end
        local winner=""
        for k,_ in pairs(state.presences) do
            if k~=loser then
                winner=k
            end
        end
        proc_battle_result(state, winner, loser)
    end
    return nil
end

local function check_all_ready(state)
    if util.table_size(state.presences) ~=2 then
        return false
    end
    for k,v in pairs(state.presences) do
        if state.ready[k]==false then
            return false
        end
    end
    return true
end

function pvp_battle.match_loop(_, dispatcher, tick, state, messages)
    local temp_inputs={}
    for k,v in pairs(state.presences) do
        temp_inputs[k]={}
    end
    if state.all_ready==false then
        local p_count=util.table_size(state.presences)
        if p_count==2 then
            if state.sent_4_ready==false then
                local encoded = nk.json_encode(state.presences)
                dispatcher.broadcast_message(1, encoded) --match ready
                state.sent_4_ready=true
                return state
            end
        else
            return state
        end
    end
    for _, message in ipairs(messages) do
        local op_code = message.op_code
        local decoded = nk.json_decode(message.data)
        local msg_user_id=message.sender.user_id
        if op_code==99 then -- end match
            return nil
        elseif op_code==0 then -- new frame
            temp_inputs[msg_user_id]=decoded
            for k,v in pairs(decoded) do
                if v>=0 then
                    if v<5 then --chara
                        local chara_name=state.presences[msg_user_id].hk_slot[v+1][1]
                        local cost = Charas_tb[chara_name].build_cost
                        state.cost[msg_user_id]=state.cost[msg_user_id]+cost
                    else
                        local item_name=state.presences[msg_user_id].hk_slot[v+1][1]
                        table.insert(state.items[msg_user_id], item_name)
                    end
                end 
            end
        elseif op_code==1 then -- ready
            state.ready[msg_user_id]=true
            state.all_ready = check_all_ready(state)
        elseif op_code==2 then -- battle done
            if decoded["re"]=="winner" then
                state.winner=msg_user_id
            elseif decoded["re"]=="loser" then
                state.loser=msg_user_id
            end
            
            if state.winner~="" and state.loser~="" then
                proc_battle_result(state, state.winner, state.loser)
                return nil
            end
        end
    end
    if state.all_ready then
        local data = {
            frame_id=state.frame_id,
            inputs=temp_inputs
        }
        local encoded = nk.json_encode(data)
        dispatcher.broadcast_message(0, encoded) --frame data
        state.frame_id=state.frame_id+1
    end
    return state
end

function pvp_battle.match_terminate(_, _, _, state, _)
    return state
end

function pvp_battle.match_signal(_, _, _, state, data)
	return state, data
end

Charas_tb = util.load_json("../configs/characters.json")

return pvp_battle
