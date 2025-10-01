local MAP_NAME = "The Four-team wall"

local tree_def = {
    grow_time_min = 30,
    grow_time_max = 120,
}

local apple_def = {
    respawn_time_min = 30,
    respawn_time_max = 120,
}

local function grow_ctf_tree(pos, is_apple_tree)
    local x, y, z = pos.x, pos.y, pos.z
    local height = math.random(4, 7)

    local c_tree   = minetest.get_content_id("default:tree")
    local c_leaves = minetest.get_content_id("ctf_map:leaves2")
    local c_air    = minetest.get_content_id("air")
    local c_ignore = minetest.get_content_id("ignore")

    local vm = minetest.get_voxel_manip()
    local minp, maxp = vm:read_from_map(
        {x = x - 3, y = y, z = z - 3},
        {x = x + 3, y = y + height + 3, z = z + 3}
    )
    local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
    local data = vm:get_data()

    for yy = 0, height - 1 do
        local vi = a:index(x, y + yy, z)
        data[vi] = c_tree
    end

    local leaf_start = y + height - 3
    for yy = leaf_start, y + height - 1 do
        local rel_y = yy - leaf_start
        local radius_xz = 2 - math.floor(rel_y / 2)
        for zz = -2, 2 do
            for xx = -2, 2 do
                if (xx*xx + zz*zz) <= (radius_xz * radius_xz + 1) then
                    local vi = a:index(x + xx, yy, z + zz)
                    if data[vi] == c_air or data[vi] == c_ignore then
                        data[vi] = c_leaves
                    end
                end
            end
        end
    end

    local top_y = y + height
    for _, off in ipairs({
        {x = 0, z = 0}, {x = 1, z = 0}, {x = -1, z = 0},
        {x = 0, z = 1}, {x = 0, z = -1},
    }) do
        local vi = a:index(x + off.x, top_y, z + off.z)
        if data[vi] == c_air or data[vi] == c_ignore then
            data[vi] = c_leaves
        end
    end

    vm:set_data(data)
    vm:write_to_map()
    vm:update_map()

    if is_apple_tree then
        local current_mode = ctf_modebase.current_mode
        if current_mode ~= "classes" and current_mode ~= "nade_fight" then
            local apple_y = y + height - 3
            local possible_pos = {
                {x = x + 1, y = apple_y, z = z},
                {x = x - 1, y = apple_y, z = z},
                {x = x,     y = apple_y, z = z + 1},
                {x = x,     y = apple_y, z = z - 1},
            }

            local num_apples = math.random(2, 4)
            for i = 1, num_apples do
                local p = table.remove(possible_pos, math.random(#possible_pos))
                local generator_pos = {x = p.x, y = p.y, z = p.z}
                local node = minetest.get_node_or_nil(generator_pos)
                if node and (node.name == "air" or node.name == "ctf_map:leaves2") then
                    minetest.set_node(generator_pos, {name = "ctf_map:apple_generator"})
                    minetest.set_node(generator_pos, {name = "default:apple"})
                end
            end
        end
    end
end

minetest.register_node("ctf_map:sapling2", {
    description = "Fast apple tree",
    drawtype = "plantlike",
    tiles = {"default_sapling.png"},
    inventory_image = "default_sapling.png",
    wield_image = "default_sapling.png",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = {
        type = "fixed",
        fixed = {-4/16, -0.5, -4/16, 4/16, 7/16, 4/16}
    },
    groups = {
        snappy = 2, dig_immediate = 3, flammable = 2,
        attached_node = 1, sapling = 1, not_in_creative_inventory = 1
    },
    sounds = default.node_sound_leaves_defaults(),
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(
            math.random(tree_def.grow_time_min, tree_def.grow_time_max)
        )
    end,
    on_timer = function(pos)
        if minetest.get_node_light(pos) then
            grow_ctf_tree(pos, true)
        end
    end,
})

minetest.register_node("ctf_map:leaves2", {
    description = "CTF Apple Tree Leaves",
    drawtype = "allfaces_optional",
    waving = 1,
    tiles = {"default_leaves.png"},
    special_tiles = {"default_leaves_simple.png"},
    paramtype = "light",
    is_ground_content = false,
    groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1, not_in_creative_inventory = 1},
    drop = {
        max_items = 1,
        items = {
            {items = {"ctf_map:sapling2"}, rarity = 15},
        }
    },
    sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("ctf_map:apple_generator", {
    description = "Apple Generator (invisible)",
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    drop = "",
    groups = {not_in_creative_inventory = 1},
    on_timer = function(pos, elapsed)
        minetest.set_node(pos, {name = "default:apple"})
        return false
    end,
})

local old_after_dig = minetest.registered_nodes["default:apple"].after_dig_node

local function on_new_match()
    minetest.override_item("default:apple", {
        after_dig_node = function(pos, oldnode, oldmeta, digger)
            if old_after_dig then
                old_after_dig(pos, oldnode, oldmeta, digger)
            end
            minetest.set_node(pos, {name = "ctf_map:apple_generator"})
            local delay = math.random(apple_def.respawn_time_min, apple_def.respawn_time_max)
            minetest.get_node_timer(pos):start(delay)
        end,
    })
end

local function on_match_end()
    minetest.override_item("default:apple", {
        after_dig_node = old_after_dig
    })
end

ctf_api.register_on_new_match(function()
    if ctf_map.current_map and ctf_map.current_map.name == MAP_NAME then
        on_new_match()
    end
end)

ctf_api.register_on_match_end(function()
    if ctf_map.current_map and ctf_map.current_map.name == MAP_NAME then
        on_match_end()
    end
end)
