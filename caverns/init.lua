function ctf_map.callbacks.caverns.on_place(mapmeta)
	local pos1 = mapmeta.pos1
	local pos2 = mapmeta.pos2
	--- @return Vector
	local function random_pos()
		local x = (math.random() * pos2.x) % pos2.x + pos1.x
		local y = (math.random() * pos2.y) % pos2.y + pos1.y
		local z = (math.random() * pos2.z) % pos2.z + pos1.z
		return { x = math.floor(x), y = math.floor(y), z = math.floor(z) }
	end
	--- @type Vector[]
	local mese_ores = {}
	--- @type Vector[]
	local diamond_ores = {}
	--- @type Vector[]
	local iron_ores = {}
	local size_x = math.abs(pos2.x - pos1.x)
	local size_y = math.abs(pos2.y - pos1.y)
	local size_z = math.abs(pos2.z - pos1.z)
	local size = size_x * size_y * size_z
	local to_place = math.floor(size / 50)
	local vector_right = { x = 1, y = 0, z = 0 }
	for _ = 1, to_place do
		local r = math.random()
		local pos = random_pos()
		local r2 = math.floor(r * 100) % 5
		local pos_up = vector.add(pos, { x = 0, y = 1, z = 0 })
		local pos_down = vector.add(pos, { x = 0, y = -1, z = 0 })
		local pos_left = vector.add(pos, { x = -1, y = 0, z = 0 })
		local pos_right = vector.add(pos, { x = 1, y = 0, z = 0 })
		if r <= 0.9 then
			if r > 0.45 then
				table.insert(mese_ores, pos)
				if r2 == 0 then
					table.insert(mese_ores, pos_up)
				elseif r2 == 1 then
					table.insert(mese_ores, pos_down)
				end
			else
				table.insert(diamond_ores, pos)
				if r2 == 0 then
					table.insert(diamond_ores, pos_left)
				elseif r2 == 1 then
					table.insert(diamond_ores, pos_right)
				end
			end
		elseif r >= 0.975 then
			table.insert(iron_ores, pos)
			if r2 == 0 then
				table.insert(iron_ores, pos_up)
			elseif r2 == 1 then
				table.insert(iron_ores, pos_down)
			elseif r2 == 2 then
				table.insert(mese_ores, pos_left)
			elseif r2 == 3 then
				table.insert(diamond_ores, pos_right)
			end
		end
	end
	local n_x = size_x + 1
	local n_y = size_y + 1
	--- @param pos Vector
	--- @return integer
	local function pos_to_index(pos)
		return math.abs(pos.z - pos1.z) * n_x * n_y + math.abs(pos.y - pos1.y) * n_x + math.abs(pos.x - pos1.x) + 1
		-- 229 * 229 * 229
	end
	local NODE_IRON = core.get_content_id("default:stone_with_iron")
	local NODE_DIAMOND = core.get_content_id("default:stone_with_diamond")
	local NODE_MESE = core.get_content_id("default:stone_with_mese")
	local NODE_STONE = core.get_content_id("default:stone")
	local vm = core.get_voxel_manip(pos1, pos2)
	local data = vm:get_data()
	--- @param pos Vector
	--- @param id number
	local function place_ore_if(pos, id)
		local index = pos_to_index(pos)
		if data[index] == core.CONTENT_AIR then
			return
		end
		if data[index] == NODE_STONE then
			data[index] = id
		end
	end
	for _, pos in ipairs(diamond_ores) do
		place_ore_if(pos, NODE_DIAMOND)
	end
	for _, pos in ipairs(mese_ores) do
		place_ore_if(pos, NODE_MESE)
	end
	for _, pos in ipairs(iron_ores) do
		place_ore_if(pos, NODE_IRON)
	end
	vm:set_data(data)
	vm:oswrite_to_map(false)
	vm:close()
end
