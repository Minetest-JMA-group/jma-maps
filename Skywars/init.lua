minetest.register_node("ctf_map:loot_block", {
    description = "Loot Block Spawner",
    tiles = {"default_chest_top.png^[colorize:#FFFF00:80"},
    groups = {unbreakable=1, not_in_creative_inventory=1},
    sounds = default.node_sound_stone_defaults(),
    diggable = false,
    pointable = true,
    walkable = true,
    drop = "",
    on_blast = function() end,
})

local loot_table = {
    {item = "default:sword_steel", chance = 15, type = "weapon", sword_type = "steel"},
    {item = "default:sword_mese", chance = 5, type = "weapon", sword_type = "mese"},
    {item = "default:sword_diamond", chance = 2, type = "weapon", sword_type = "diamond"},
    {item = "default:diamond", chance = 5},
    {item = "default:blueberries 10", chance = 15},
    {item = "ctf_map:damage_cobble 10", chance = 10},
    {item = "wind_charge:wind_charge 10", chance = 15},
    {item = "default:cobble 50", chance = 15},
    {item = "ctf_map:spike 10", chance = 5},
    {item = "ctf_landmine:landmine 2", chance = 4},
    {item = "default:mese_crystal 2", chance = 9}
}

local function get_random_loot()
    local rnd = math.random(100)
    local cumulative = 0

    for _, entry in ipairs(loot_table) do
        local mode = ctf_modebase.current_mode

        if mode == "classes" then
            if entry.type == "weapon" then
                goto continue
            end
        elseif mode == "nade_fight" then
            if entry.type == "weapon" and entry.sword_type == "diamond" then
                goto continue
            end
        end

        cumulative = cumulative + entry.chance
        if rnd <= cumulative then
            return entry.item
        end

        ::continue::
    end

    return nil
end

local function player_in_radius(pos, radius)
    local objs = minetest.get_objects_inside_radius(pos, radius)
    for _, obj in ipairs(objs) do
        if obj:is_player() then
            return true
        end
    end
    return false
end

minetest.register_abm({
    label = "Loot Block Spawner",
    nodenames = {"ctf_map:loot_block"},
    interval = 1,
    chance = 1,
    action = function(pos, node)
        if not player_in_radius(pos, 5) then
            return
        end

        local objs = minetest.get_objects_inside_radius({x=pos.x, y=pos.y+1, z=pos.z}, 1.5)
        local item_count = 0
        for _, obj in ipairs(objs) do
            if not obj:is_player() then
                local ent = obj:get_luaentity()
                if ent and ent.name == "__builtin:item" then
                    item_count = item_count + 1
                end
            end
        end

        if item_count >= 10 then
            return
        end

        local item = get_random_loot()
        if item then
            local drop_pos = {x=pos.x, y=pos.y+1, z=pos.z}
            minetest.add_item(drop_pos, item)
        end
    end,
})

local world_bound_pos1, world_bound_pos2 = nil, nil
local MAP_NAME = "Skywars"

local function clear_loot_items()
    if not world_bound_pos1 or not world_bound_pos2 then
        return
    end

    local loot_blocks = minetest.find_nodes_in_area(world_bound_pos1, world_bound_pos2, {"ctf_map:loot_block"})

    for _, pos in ipairs(loot_blocks) do
        local objs = minetest.get_objects_inside_radius(
            {x = pos.x, y = pos.y + 1, z = pos.z}, 1.5
        )
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "__builtin:item" then
                obj:remove()
            end
        end
    end
end

ctf_api.register_on_new_match(function()
    if ctf_map.current_map and ctf_map.current_map.name == MAP_NAME then
        minetest.after(0, function()
            world_bound_pos1 = ctf_map.current_map.pos1
            world_bound_pos2 = ctf_map.current_map.pos2
            clear_loot_items()
        end)
    end
end)

ctf_api.register_on_match_end(function()
    if ctf_map.current_map and ctf_map.current_map.name == MAP_NAME then
        clear_loot_items()
        world_bound_pos1 = nil
        world_bound_pos2 = nil
    end
end)
