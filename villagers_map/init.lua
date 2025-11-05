local MAP_NAME = "The villagers' map"
local merchants = {}
local last_attacker = {}
local ITEMS_PER_PAGE = 4

minetest.register_node("ctf_map:disappearing_block", {
    description = "Temporary Block",
    drawtype = "glasslike",
    tiles = {"default_glass.png^[colorize:#00FF0080"},
    paramtype = "light",
    sunlight_propagates = true,
    groups = { not_in_creative_inventory = 1},
    sounds = default.node_sound_glass_defaults(),
})

local function remove_temp_blocks()
    local map = ctf_map.current_map
    if not map then return end
    local minp, maxp = map.pos1, map.pos2
    local step = 80

    for x = minp.x, maxp.x, step do
        for y = minp.y, maxp.y, step do
            for z = minp.z, maxp.z, step do
                local chunk_min = {x=x, y=y, z=z}
                local chunk_max = {
                    x=math.min(x+step, maxp.x),
                    y=math.min(y+step, maxp.y),
                    z=math.min(z+step, maxp.z),
                }
                local nodes = minetest.find_nodes_in_area(chunk_min, chunk_max, {"ctf_map:disappearing_block"})
                for _, pos in ipairs(nodes) do
                    minetest.remove_node(pos)
                end
            end
        end
    end
end

minetest.register_craftitem("ctf_map:jma_coin", {
    description = "JMA Coin",
    inventory_image = "ctf_map_jma_coin.png",
    stack_max = 60,
    groups = {not_in_creative_inventory=1, immortal=1},
})

local merchant_blocks = {
    {name="blockseller", type="blocks"},
    {name="swordseller", type="swords"},
    {name="itemseller", type="items"},
}

for _, def in ipairs(merchant_blocks) do
    minetest.register_node("ctf_map:" .. def.name, {
        description = def.type .. " Merchant",
        tiles = {"default_chest_top.png"},
        groups = {cracky=0, not_in_creative_inventory=1},
        drop = "",
    })
end

local trades = {
    blocks = {
        {give="default:cobble 99", price=5, display_name="Cobblestone 99"},
        {give="default:wood 99", price=7, display_name="Wood 99"},
        {give="default:tree 25", price=7, display_name="Tree 25"},
        {give="default:stone 99", price=6, display_name="Stone 99"},
        {give="default:desert_stone 99", price=6, display_name="Desert Stone 99"},
        {give="default:sand 50", price=8, display_name="Sand 50"},
        {give="default:gravel 50", price=8, display_name="Gravel 50"},
        {give="default:brick 50", price=8, display_name="Brick 50"},
        {give="ctf_map:damage_cobble 25", price=25, display_name="Damage Cobblestone 25"},
        {give="ctf_map:reinforced_cobble 25", price=25, display_name="Reinforced Cobblestone 25"},
        {give="ctf_landmine:landmine 15", price=15, display_name="Landmine 15"},
        {give="ctf_map:spike 15", price=15, display_name="Spike 15"},
        {give="ctf_teams:door_steel 4", price=15, display_name="Steel Door 4"},
        {give="default:ladder_wood 50", price=5, display_name="Wooden Ladder 50"},
    },
    swords = {
        {give="default:sword_steel", price=15, display_name="Steel Sword"},
        {give="default:sword_mese", price=25, display_name="Mese Sword"},
        {give="default:sword_diamond", price=50, display_name="Diamond Sword"},
        {give="default:pick_steel", price=10, display_name="Steel Pickaxe"},
        {give="default:pick_mese", price=15, display_name="Mese Pickaxe"},
        {give="default:pick_diamond", price=30, display_name="Diamond Pickaxe"},
        {give="default:axe_wood", price=5, display_name="Wooden Axe"},
        {give="default:axe_steel", price=10, display_name="Steel Axe"},
        {give="default:axe_mese", price=20, display_name="Mese Axe"},
        {give="default:axe_diamond", price=40, display_name="Diamond Axe"},
        {give="ctf_ranged:shotgun_loaded", price=60, display_name="Shotgun"},
        {give="ctf_ranged:rifle_loaded", price=10, display_name="Rifle"},
        {give="ctf_ranged:sniper_loaded", price=40, display_name="Sniper"},
        {give="ctf_ranged:pistol_loaded", price=5, display_name="Pistol"},
    },
    items = {
        {give="bucket:bucket_water", price=20, display_name="Water Bucket"},
        {give="default:torch 30", price=5, display_name="Torch 30"},
        {give="wind_charges:wind_charge 15", price=10, display_name="Wind Charge 15"},
        {give="ctf_healing:medkit", price=10, display_name="Medkit"},
        {give="ctf_healing:bandage", price=10, display_name="Bandage"},
        {give="ctf_ranged:ammo 10", price=10, display_name="Ammo 10"},
        {give="ctf_mode_nade_fight:small_frag", price=10, display_name="Small Frag Grenade"},
        {give="heal_block:heal", price=100, display_name="Healing Block"},
    },
}


local mode_restrictions = {
    classic = {
        ["ctf_healing:bandage"] = true,
        ["ctf_healing:medkit"] = true,
        ["ctf_ranged:sniper_loaded"] = true,
    },
    nade_fight = {
        ["default:sword_diamond"] = true,
    },
}

local function show_trade_formspec(player, mtype, page)
    page = page or 1
    local pname = player:get_player_name()
    local all_trades = trades[mtype]

    local filtered_trades = {}
    local restrictions = mode_restrictions[ctf_modebase.current_mode] or {}
    for _, t in ipairs(all_trades) do
        if not restrictions[t.give] then
            table.insert(filtered_trades, t)
        end
    end

    local total_pages = math.ceil(#filtered_trades / ITEMS_PER_PAGE)

    local parts = {
        "formspec_version[4]",
        "size[11,11]",
        "bgcolor[#1e1e1e;true]",
        "box[0,0;11,1.2;#2d2d2d]",
        "hypertext[0.5,0.2;10,1;title;<center><style size=20 color=#FFD700><b>Merchant: "
            ..minetest.formspec_escape(mtype).."</b></style></center>]",
        "hypertext[0.5,1.2;10,1;info;<style size=14 color=#CCCCCC>Welcome adventurer! Click an item to get it.</style>]",
        "field[0,0;0,0;page;;"..page.."]",
    }

    local start_index = (page-1)*ITEMS_PER_PAGE + 1
    local end_index = math.min(page*ITEMS_PER_PAGE, #filtered_trades)
    local y = 2
    for i = start_index, end_index do
        local t = filtered_trades[i]
        table.insert(parts, "box[0.3,"..y..";10.2,1.6;#2b2b2b]")
        table.insert(parts, "item_image_button[0.6,"..(y+0.2)..";1,1;"..t.give..";buy_"..minetest.formspec_escape(mtype).."_"..i..";]")
        table.insert(parts, "image[7.5,"..(y+0.2)..";1,1;ctf_map_jma_coin.png]")
        table.insert(parts, "label[8.4,"..(y+1.1)..";"..t.price.."]")
        y = y + 1.9
    end
    if page > 1 then table.insert(parts, "button[2,10;2,0.8;prev;« Previous]") end
    if page < total_pages then table.insert(parts, "button[7,10;2,0.8;next;Next »]") end
    minetest.show_formspec(pname, "ctf_map:trade_"..mtype, table.concat(parts, ""))
end



minetest.register_on_player_receive_fields(function(player, formname, fields)
    for mtype,_ in pairs(trades) do
        if formname == "ctf_map:trade_"..mtype then
            local page = tonumber(fields.page) or 1
            if fields.prev then
                page = math.max(page-1, 1)
                show_trade_formspec(player, mtype, page)
            elseif fields.next then
                local total_pages = math.ceil(#trades[mtype]/ITEMS_PER_PAGE)
                page = math.min(page+1, total_pages)
                show_trade_formspec(player, mtype, page)
            else
                for i=1,#trades[mtype] do
                    if fields["buy_"..mtype.."_"..i] then
                        local trade = trades[mtype][i]
                        local inv = player:get_inventory()
                        local price_item = "ctf_map:jma_coin "..trade.price
                        if not inv:contains_item("main", price_item) then
                            minetest.chat_send_player(player:get_player_name(), "You don't have enough JMA Coins!")
                        elseif not inv:room_for_item("main", trade.give) then
                            minetest.chat_send_player(player:get_player_name(), "Not enough space in inventory!")
                        else
                            inv:remove_item("main", price_item)
                            inv:add_item("main", trade.give)
							minetest.chat_send_player(player:get_player_name(), "You bought "..trade.display_name.." for "..trade.price.." JMA Coins!")
                        end
                    end
                end
            end
            return true
        end
    end
end)

local merchant_textures = {
    blocks = "merchant_blocks.png",
    swords = "merchant_swords.png",
    items  = "merchant_items.png",
}

local function register_merchant(name)
    local display_name = name
    if name == "blocks" then display_name = "Block Vendor"
    elseif name == "swords" then display_name = "Sword & Weapons Vendor"
    elseif name == "items" then display_name = "Item Vendor" end

    local texture = merchant_textures[name] or "character.png"

    minetest.register_entity("ctf_map:merchant_"..name, {
        initial_properties = {
            hp_max = 200000,
            physical = true,
            collide_with_objects = true,
            collisionbox = {-0.3,0,-0.3,0.3,1.9,0.3},
            visual = "mesh",
            mesh = "character.b3d",
            textures = {texture},
            visual_size = {x=1,y=1},
            nametag = display_name,
            nametag_color = "#FFD700",
        },
        merchant_type = name,
        set_skin = function(self, texture)
            self.object:set_properties({textures={texture}})
        end,
        on_step = function(self, dtime)
            local pos = self.object:get_pos()
            local closest, dist
            for _,player in ipairs(minetest.get_connected_players()) do
                local ppos = player:get_pos()
                local d = vector.distance(pos, ppos)
                if not dist or d < dist then closest, dist = player, d end
            end
            if closest then
                if dist <= 15 then
                    self.object:set_properties({nametag = display_name})
                    local dir = vector.direction(pos, closest:get_pos())
                    self.object:set_yaw(math.atan2(dir.z, dir.x)-math.pi/2)
                else
                    self.object:set_properties({nametag = ""})
                end
            end
        end,
        on_rightclick = function(self, clicker)
            show_trade_formspec(clicker, self.merchant_type)
        end,
    })
end

local function spawn_merchant(pos, type)
    local skin = merchant_textures[type]
    if not skin then
        minetest.log("error", "[ctf_map] No texture defined for merchant type: "..type)
        return
    end

    local obj = minetest.add_entity({x=pos.x, y=pos.y+0.5, z=pos.z}, "ctf_map:merchant_"..type)
    if obj then
        local lua = obj:get_luaentity()
        if lua then
            lua.merchant_type = type
            lua:set_skin(skin)
        end
        table.insert(merchants, obj)
    end
end



local function clear_merchants()
    for _, obj in ipairs(merchants) do
        if obj and obj:get_luaentity() then obj:remove() end
    end
    merchants = {}
end






for _, t in ipairs({"blocks","swords","items"}) do
    register_merchant(t)
end

ctf_api.register_on_new_match(function()
    local map = ctf_map.current_map
    if map and map.name == MAP_NAME then
        minetest.after(0, function()
            for _, player in ipairs(minetest.get_connected_players()) do
                local inv = player:get_inventory()
                inv:add_item("main", "ctf_map:jma_coin 5")
                minetest.chat_send_player(player:get_player_name(), minetest.colorize("#00FF00", "+5 JMA Coins"))
            end
        end)

        minetest.chat_send_all(minetest.colorize("#00FF00", "[Temporary Block] These blocks will disappear in 20 seconds..."))
        minetest.after(20, function()
            if ctf_map.current_map and ctf_map.current_map.name == MAP_NAME then
                remove_temp_blocks()
                minetest.chat_send_all(minetest.colorize("#FF0000", "[Temporary Block] All special blocks have disappeared!"))
            end
        end)
    end

    clear_merchants()
    if map and map.name == MAP_NAME then
        for _, def in ipairs(merchant_blocks) do
            local minp, maxp = map.pos1, map.pos2
            local step = 80
            for x = minp.x, maxp.x, step do
                for y = minp.y, maxp.y, step do
                    for z = minp.z, maxp.z, step do
                        local chunk_min = {x=x, y=y, z=z}
                        local chunk_max = {
                            x=math.min(x+step, maxp.x),
                            y=math.min(y+step, maxp.y),
                            z=math.min(z+step, maxp.z),
                        }
                        local positions = minetest.find_nodes_in_area(chunk_min, chunk_max, {"ctf_map:"..def.name})
                        for _, pos in ipairs(positions) do
                            spawn_merchant(pos, def.type)
                        end
                    end
                end
            end
        end
    end
end)

ctf_api.register_on_match_end(function()
    remove_temp_blocks()
    clear_merchants()
end)

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    if hitter and hitter:is_player() then
        last_attacker[player:get_player_name()] = hitter
    end
end)

minetest.register_on_dieplayer(function(player, reason)
    local map = ctf_map.current_map
    if not map or map.name ~= MAP_NAME then return end
    local attacker = last_attacker[player:get_player_name()]
    if attacker and attacker:is_player() then
        attacker:get_inventory():add_item("main", "ctf_map:jma_coin 3")
        minetest.chat_send_player(attacker:get_player_name(), minetest.colorize("#00FF00", "+3 JMA Coins"))
    end
    last_attacker[player:get_player_name()] = nil
end)

minetest.register_on_mods_loaded(clear_merchants)
minetest.register_on_shutdown(clear_merchants)
