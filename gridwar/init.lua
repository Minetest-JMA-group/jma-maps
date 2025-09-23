local MAP_NAME = "GridWar"
local DEATH_BARRIER_Y_OFFSET = 5
local RESPAWN_Y_OFFSET = 3
local AIR_LIGHT_LEVEL = 5

local enabled = false

minetest.register_node("ctf_map:glowing_air", {
    description = "Glowing Air",
    drawtype = "airlike",
    paramtype = "light",
    light_source = AIR_LIGHT_LEVEL,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    air_equivalent = true,
    drop = "",
    groups = {not_in_creative_inventory = 1}
})


local world_bound_pos1, world_bound_pos2 = nil, nil
ctf_api.register_on_new_match(function ()
    if ctf_map.current_map and ctf_map.current_map.name == MAP_NAME then
        enabled = true
        minetest.after(0, function ()
            world_bound_pos1 = ctf_map.current_map.pos1
            world_bound_pos2 = ctf_map.current_map.pos2
        end)
    end
end)

ctf_api.register_on_match_end(function ()
    if ctf_map.current_map and ctf_map.current_map.name == MAP_NAME then
        enabled = false
        world_bound_pos1 = nil
        world_bound_pos2 = nil
    end
end)

minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if reason and reason.type == "fall" then
        if enabled then
            return 0
        end
    end
    return hp_change
end, true)

-- teleport barriers

local function is_below_death_barrier(player)
    if not world_bound_pos1 then return false end
    return player:get_pos().y < world_bound_pos1.y + DEATH_BARRIER_Y_OFFSET
end

local function respawn_player_at_top(player)
    if not world_bound_pos2 then return end
    local pos = player:get_pos()
    local new_pos = {x = pos.x, y = world_bound_pos2.y - RESPAWN_Y_OFFSET, z = pos.z}
    player:set_pos(new_pos)
end

minetest.register_globalstep(function ()
    if not enabled then
        return
    end
    for _, player in ipairs(minetest:get_connected_players()) do
        if is_below_death_barrier(player) then
            respawn_player_at_top(player)
        end
    end
end)