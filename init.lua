local random, max = math.random, math.max
local pairs, table = pairs, table
local minetest = minetest
local technic = technic

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local setting_melt_difficulty = 10

forge = {}


local melt_total = {}
local melt_yields = {}
local meltable_ores = {}
local cools_to = {}
local melt_densities = {}
local melt_energy_requirement = {}
local molten_sources = {}
forge.meltable_ores = meltable_ores

dofile(modpath .. "/shell.lua")
dofile(modpath.."/coke.lua")
dofile(modpath.."/burners.lua")
dofile(modpath.."/spout.lua")


-- technic support
dofile(modpath.."/electrode.lua")




forge.random_melt_product = function(name)
	if melt_total[name] == 0 or melt_total[name] == nil then
		return modname..":molten_slag"
	end

	local r = random(melt_total[name])

	for k,v in pairs(melt_yields[name]) do
		r = r - v
		if r <= 0 then
			return modname..":molten_"..k
		end
	end

	return modname..":molten_slag"
end
local random_melt_product = forge.random_melt_product

forge.max_heat = 0


forge.register_ore = function(name, eu_to_melt, yields)
	local y2 = {}
	local total = 0

	for k,v in pairs(yields) do
		total = total + v
		y2[k] = v
	end

	table.insert(meltable_ores, name)
	melt_yields[name] = y2
	melt_total[name] = total
	melt_energy_requirement[name] = eu_to_melt * setting_melt_difficulty

	forge.max_heat = max(forge.max_heat, melt_energy_requirement[name] * 1.5)
end

-- registers the molten liquids and densities
function forge.register_metal(opts)
	cools_to[modname..":molten_"..opts.name] = opts.cools
	melt_densities[modname..":molten_"..opts.name] = opts.density
	table.insert(molten_sources, modname..":molten_"..opts.name)

	minetest.register_node(modname..":molten_"..opts.name, {
		description = "Molten " .. opts.Name,
		inventory_image = minetest.inventorycube("default_lava.png"),
		drawtype = "liquid",
		tiles = {
			{
				name = "default_lava_source_animated.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
			},
		},
		special_tiles = {
			-- New-style lava source material (mostly unused)
			{
				name = "default_lava_source_animated.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
				backface_culling = false,
			},
		},
		paramtype = "light",
		light_source = default.LIGHT_MAX - 3,
		--walkable = false,
		--pointable = false,
		diggable = false,
	--	buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = modname..":molten_"..opts.name.."_flowing",
		liquid_alternative_source = modname..":molten_"..opts.name,
		liquid_viscosity = 2,
		liquid_renewable = false,
		liquid_range = 2,
		damage_per_second = 2 * 2,
		post_effect_color = {a = 192, r = 255, g = 64, b = 0},
		groups = {
			lava = 2, liquid = 2, hot = 3, igniter = 1, not_in_creative_inventory = 1,
			molten_ore=3, molten_ore_source=1,
		},
	})

	minetest.register_node(modname..":molten_"..opts.name.."_flowing", {
		description = "Molten "..opts.Name,
		inventory_image = minetest.inventorycube("default_lava.png"),
		drawtype = "flowingliquid",
		tiles = {"default_lava.png"},
		special_tiles = {
			{
				name = "default_lava_flowing_animated.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.3,
				},
			},
			{
				name = "default_lava_flowing_animated.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.3,
				},
			},
		},
		paramtype = "light",
		paramtype2 = "flowingliquid",
		light_source = default.LIGHT_MAX - 3,
	--	walkable = false,
	--	pointable = false,
		diggable = false,
	--	buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = modname..":molten_"..opts.name.."_flowing",
		liquid_alternative_source = modname..":molten_"..opts.name,
		liquid_viscosity = 2,
		liquid_renewable = false,
		liquid_range = 2,
		damage_per_second = 1 * 2,
		post_effect_color = {a = 192, r = 255, g = 64, b = 0},
		groups = {
			lava = 2, liquid = 2, hot = 3, igniter = 1,
			molten_ore=1, molten_ore_flowing=1,
			not_in_creative_inventory = 1
		},
	})
	
	-- ingot molds
	if nil ~= opts.ingot then
		-- TODO: hot
		minetest.register_node(modname..":mold_"..opts.name, {
			description = "Ingot Mold",
			tiles = {
				"default_silver_sand.png^(forge_ingots.png^[colorize:"..opts.ingot_color..")", "default_silver_sand.png", 
				"default_silver_sand.png", "default_silver_sand.png",
				"default_silver_sand.png", "default_silver_sand.png"
			},
			groups = {crumbly=3, refractory=1, falling_node=1},
			is_ground_content = false,
			sounds = default.node_sound_stone_defaults(),
			drop = { 
				max_items = 2,
				items = {
					{items = {"default:silver_sand"}},
					{items = {opts.ingot.." 9"}}
				}
			},
			--[[on_punch = function(pos, node, puncher)
				local inv = puncher:get_inventory()
				inv:add_item("main", opts.ingot.." 9")
				
				minetest.set_node(pos, {name = modname..":mold"})
			end,]]
		})
		
		
		minetest.register_abm({
			nodenames = {modname..":molten_"..opts.name},
			neightbors = {modname..":mold"},
			interval = 2,
			chance = 1,
			action = function(pos, node)
				-- look one node out
				local molds = minetest.find_nodes_in_area(
					{x=pos.x - 1, y=pos.y, z=pos.z - 1},
					{x=pos.x + 1, y=pos.y + 1, z=pos.z + 1},
					modname..":mold"
				)
				
				if #molds == 0 then
					return
				end
				
				local mold = molds[math.random(#molds)]
				
				minetest.set_node(mold, {name = modname..":mold_"..opts.name})
				minetest.set_node(pos, {name = "air"})
			end,
		})
		
		minetest.register_craft({
			output = modname..":mold 1",
			type = "shapeless",
			recipe = {
				'default:silver_sand',
				opts.ingot
			},
			replacements = {{opts.ingot, opts.ingot}},
		})
		
	end
	
	
	
	
	
	
	
	
	
end -- forge.register_metal

assert(loadfile(modpath .. "/slag.lua"))(forge)
assert(loadfile(modpath .. "/materials.lua"))(forge)
assert(loadfile(modpath .. "/physics.lua"))(cools_to, melt_densities, random_melt_product)
assert(loadfile(modpath .. "/electrode.lua"))(forge, melt_energy_requirement, meltable_ores, random_melt_product)


