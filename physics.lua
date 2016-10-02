local modname = minetest.get_current_modname()
local minetest, nodeupdate, vector = minetest, nodeupdate, vector
local random, pairs = math.random, pairs

local cools_to, melt_densities, random_melt_product = ...

local function melt(pos, node)
	local node_name = node and node.name or minetest.get_node(pos).name
	minetest.set_node(pos, {name=random_melt_product(node_name)})
	return true
end

local function cool_down(pos, node)
	local node_name = node and node.name or minetest.get_node(pos).name
	local cold_name = cools_to[node_name]
	if not cold_name then
		return false
	end

	minetest.set_node(pos, {name = cold_name})
	nodeupdate(pos)
	return true
end

local function swap_nodes(pos1, node1, pos2, node2)
	-- swap_node is faster than set_node, avoiding node destructors/constructors
	-- also metadata is not reset, which two molten_ores don't have anyway
	minetest.swap_node(pos1, node2 or minetest.get_node(pos2))
	minetest.swap_node(pos2, node1 or minetest.get_node(pos1))
end

-- fluid dynamics
minetest.register_abm({
	nodenames = {"group:molten_ore"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if minetest.get_item_group(node.name, "molten_ore") < 3 then
			return
		end

		local flow_name = node.name.."_flowing"

		-- look below
		local flow_nodes = minetest.find_nodes_in_area(
			{x=pos.x , y=pos.y - 1, z=pos.z},
			{x=pos.x , y=pos.y - 1, z=pos.z},
			"group:molten_ore_flowing"
		)

		for _,fp in pairs(flow_nodes) do
			swap_nodes(pos, node, fp)
			return
		end

		-- look one node out
		flow_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y - 1, z=pos.z + 1},
			"group:molten_ore_flowing"
		)

		for _,fp in pairs(flow_nodes) do
			-- check above to make sure it can get here
			local na = minetest.get_node({x=fp.x, y=fp.y+1, z=fp.z})
			local g = minetest.get_item_group(na.name, "molten_ore")
			if g > 0 then
				swap_nodes(pos, node, fp)
				return
			end
		end

		-- look two nodes out
		flow_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 2, y=pos.y - 1, z=pos.z - 2},
			{x=pos.x + 2, y=pos.y - 1, z=pos.z + 2},
			"group:molten_ore_flowing"
		)

		for _,fp in pairs(flow_nodes) do
			-- check above
			local na = minetest.get_node({x=fp.x, y=fp.y+1, z=fp.z})
			local ga = minetest.get_item_group(na.name, "molten_ore")

			if ga > 0 then
				-- check between above and node
				local nb = minetest.get_node({x=(fp.x + pos.x) / 2, y=pos.y, z=(fp.z + pos.z) / 2})
				local gb = minetest.get_item_group(nb.name, "molten_ore")

				if gb > 0 then
					swap_nodes(pos, node, fp)
					return
				end
			end
		end
	end,
})

-- dense metals sink to the bottom
minetest.register_abm({
	nodenames = {"group:molten_ore_source"},
	neightbors = {"group:molten_ore_source"},
	interval = 4,
	chance = 2,
	action = function(pos, node)
		-- look one node out
		local light_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y - 1, z=pos.z + 1},
			"group:molten_ore_source"
		)

		for _,fp in pairs(light_nodes) do
			local n = minetest.get_node(fp)

			local sd = melt_densities[node.name]
			local dd = melt_densities[n.name]

			if dd and sd and dd < sd then
				swap_nodes(pos, node, fp, n)
				return
			end
		end
	end,
})

local function is_heated(pos, node)
	-- don't cool near active electrodes
	if minetest.find_node_near(pos, 4, {modname..":electrode_on"}) then
		return true
	end

	-- don't cool near heater bricks
	if minetest.find_node_near(pos, 1, {modname..":furnace_heater"}) then
		return true
	end
	return false
end

-- air cooling
minetest.register_abm({
	nodenames = {"group:molten_ore"},
	interval = 10,
	chance = 15,
	action = function(pos, node)
		if is_heated(pos, node) then
			return
		end

		-- let ore fall before cooling
		local below = minetest.get_node_or_nil({x=pos.x, y=pos.y-1, z=pos.z})
		if below then
			if 0 ~= minetest.get_item_group(below.name, "molten_ore_flowing") then
				return
			end

			-- melt cools 3 times more slowly over refractory materials
			-- helps prevent clogs in structures
			if 0 ~= minetest.get_item_group(below.name, "refractory") then
				if random(3) >= 2 then
					return
				end
			end
		end

		if cool_down(pos, node) then
			minetest.sound_play("default_cool_lava",
				{pos = pos, max_hear_distance = 16, gain = 0.25})
		end
	end,
})

local function spawnSteam(pos)
	pos.y = pos.y+1
	minetest.add_particlespawner({
		amount = 20,
		time = 3,
		minpos = vector.subtract(pos, 2 / 2),
		maxpos = vector.add(pos, 2 / 2),
		minvel = {x=-0.1, y=0, z=-0.1},
		maxvel = {x=0.1,  y=0.5,  z=0.1},
		minacc = {x=-0.1, y=0.1, z=-0.1},
		maxacc = {x=0.1, y=0.3, z=0.1},
		minexptime = 1,
		maxexptime = 3,
		minsize = 10,
		maxsize = 20,
		texture = modname.."_steam.png^[colorize:white:120",
	})
end

-- water cooling
minetest.register_abm({
	nodenames = {"group:molten_ore"},
	neighbors = {
		"default:water_source",
		"default:water_flowing",
		"default:river_water_source",
		"default:river_water_flowing"
	},
	interval = 2,
	chance = 2,
	action = function(pos, node)
		if cool_down(pos, node) then
			spawnSteam(pos)
			minetest.sound_play("default_cool_lava",
				{pos = pos, max_hear_distance = 16, gain = 0.25})
		end
	end,
})

local function try_conduct(pos, node)
	local node = minetest.get_node_or_nil(pos)
	if node and 0 == minetest.get_item_group(node.name, "refractory") and
				0 == minetest.get_item_group(node.name, "molten_ore") then
		melt(pos, node)

		-- avoid conduction loops around heaters
		if not is_heated(pos, node) then
			-- but conserve energy if possible, which also protects from
			-- melting entire mountains from a single molten ore
			cool_down(pos, node)
		end
		return true
	end
	return false
end

local heat_conduct_dirs = {
	{1, 0}, {-1, 0}, {0, 1}, {0, -1},
}

-- molten ore conducts heat, either remelting other things or destroying them
minetest.register_abm({
	nodenames = {"group:molten_ore_source"},
	interval = 5,
	chance = 40,
	action = function(pos, node)
		-- prefer the node below
		if try_conduct({x=pos.x, y=pos.y - 1, z=pos.z }) then
			return
		end

		-- then start with a random direction and rotate
		local start = random(4)
		for i=0, 3 do
			local dir = heat_conduct_dirs[(start + i) % 4 + 1]
			if try_conduct({x=pos.x + dir[1], y=pos.y, z=pos.z + dir[2]}) then
				return
			end
		end
		-- above is not destroyed
	end,
})
