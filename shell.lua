local modname = minetest.get_current_modname()

minetest.register_craftitem(modname..":refractory_clay_lump", {
	description = "Refractory Clay",
	inventory_image = "default_clay_lump.png^[colorize:white:120",
})

minetest.register_craftitem(modname..":refractory_clay_brick", {
	description = "Refractory Brick",
	inventory_image = "default_clay_brick.png^[colorize:white:120",
})

minetest.register_node(modname..":refractory_brick", {
	description = "Refractory Brick",
	tiles = { "default_brick.png^[colorize:white:120" },
	is_ground_content = true,
	groups = {cracky=1, level=1, refractory=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node(modname..":furnace_heater", {
	description = "Furnace Heater",
	tiles = { "default_brick.png^[colorize:blue:120" },
	is_ground_content = true,
	groups = {cracky=1, level=1, refractory=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = modname..":refractory_clay_lump 6",
	type = "shapeless",
	recipe = {
		'default:desert_sand',
		'default:sand',
		'default:clay_lump',
		'default:clay_lump',
		'default:clay_lump',
		'default:clay_lump',
	}
})

minetest.register_craft({
	output = modname..":refractory_clay_lump 4",
	type = "shapeless",
	recipe = {
		modname..':slag',
		modname..':slag',
		'default:clay_lump',
		'default:clay_lump',
	}
})

minetest.register_craft({
	output = modname..":furnace_heater 1",
	type = "shapeless",
	recipe = {
		'default:furnace',
		modname..":refractory_clay_brick",
		modname..":refractory_clay_brick",
		modname..":refractory_clay_brick",
		modname..":refractory_clay_brick",
	}
})

minetest.register_craft({
	type = "cooking",
	output = modname..":refractory_clay_brick",
	recipe = modname..":refractory_clay_lump",
})

minetest.register_craft({
	output = modname..':refractory_brick',
	recipe = {
		{modname..":refractory_clay_brick", modname..":refractory_clay_brick"},
		{modname..":refractory_clay_brick", modname..":refractory_clay_brick"},
	}
})

--[[
minetest.register_node(mn..":crucible_spout", {
	description = "Crucible Spout",
	drawtype="nodebox",
	tiles = { "default_stone.png" },
	is_ground_content = true,
	groups = {cracky=3, stone=1, refractory=3},
	paramtype = "light",
	sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			{-.4, -1.0 , -0.4, 0.4, -0.5, 0.4},
			{-.3, -1.25, -0.3, 0.3, -1.0, 0.3},
			{-.2, -1.5 , -0.2, 0.2, -1.25, 0.2},
		},
	},
	on_punch = function (pos, node)
		spoutPour(pos)
	end
})

local function spoutPour(pos)
	local ore_nodes = minetest.find_nodes_in_area(
		{x=pos.x - 2, y=pos.y , z=pos.z - 2},
		{x=pos.x + 2, y=pos.y + 4, z=pos.z + 2},
		modname..":molten_ore"
	)

	if ore_nodes == nil then
		return
	end

	local i = 0
	local tmp = {}

	for _,p in ipairs(ore_nodes) do

		i = i + 1

		table.insert(tmp, p)

		if i >= 4 then
			for _,p2 in ipairs(tmp) do
				minetest.set_node(p2, {name=modname..":molten_slag"})
			end

			minetest.set_node({x=pos.x, y=pos.y - 2, z=pos.z}, {name=modname..":hot_steelblock"})

			nodeupdate({x=pos.x, y=pos.y - 2, z=pos.z} )
			i = 0
			tmp = {}
			return
		end
	end
end
]]
