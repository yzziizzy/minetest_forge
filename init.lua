 

local mn = "forge"

local electrode_min_demand = 20

local forge = {}


local melt_total = {}
local melt_yields = {}
local meltable_ores = {} 
local cools_to = {}
local melt_densities = {}
local melt_energy_requirement = {}
local molten_sources = {}


function randomMelt(name) 
	if melt_total[name] == 0 then
		return mn..":molten_slag"
	end
	
	local r = math.random(melt_total[name])
	
	for k,v in pairs(melt_yields[name]) do
		r = r - v
		if r <= 0 then
			return mn..":molten_"..k
		end
	end
	
	return mn..":molten_slag"
end


minetest.register_craftitem(mn..":refractory_clay_lump", {
	description = "Refractory Clay",
	inventory_image = "default_clay_lump.png^[colorize:white:120",
})

minetest.register_craftitem(mn..":refractory_clay_brick", {
	description = "Refractory Brick",
	inventory_image = "default_clay_brick.png^[colorize:white:120",
})

minetest.register_node(mn..":slag", {
    description = "Slag",
    tiles = { "default_gravel.png^[colorize:brown:80" },
    is_ground_content = true,
    groups = {cracky=1, cobble=1, refractory=1},
    sounds = default.node_sound_stone_defaults(),
}) 

--[[
minetest.register_node(mn..":hot_steelblock", {
	description = "Hot Steel Block",
	tiles = {"default_steel_block.png^[colorize:red:120"},
	is_ground_content = false,
	light_source = 3,
	groups = {cracky = 1, falling_node = 1, level = 2, hot = 3, igniter = 1},
	sounds = default.node_sound_stone_defaults(),
})
]]


minetest.register_node(mn..":refractory_brick", {
    description = "Refractory Brick",
    tiles = { "default_brick.png^[colorize:white:120" },
    is_ground_content = true,
    groups = {cracky=3, refractory=3},
    sounds = default.node_sound_stone_defaults(),
}) 

minetest.register_craft({
	output = mn..':refractory_clay_lump 6',
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
	output = mn..':refractory_clay_lump 4',
	type = "shapeless",
	recipe = { 
		mn..':slag', 
		mn..':slag', 
		'default:clay_lump', 
		'default:clay_lump', 
	}
})


minetest.register_craft({
	type = "cooking",
	output = mn..":refractory_clay_brick",
	recipe = mn..":refractory_clay_lump",
})

minetest.register_craft({
	output = mn..':refractory_brick',
	recipe = {
		{mn..":refractory_clay_brick", mn..":refractory_clay_brick"},
		{mn..":refractory_clay_brick", mn..":refractory_clay_brick"},
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


function spoutPour(pos) 
	local ore_nodes = minetest.find_nodes_in_area(
		{x=pos.x - 2, y=pos.y , z=pos.z - 2},
		{x=pos.x + 2, y=pos.y + 4, z=pos.z + 2},
		mn..":molten_ore"
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
				minetest.set_node(p2, {name=mn..":molten_slag"})
			end
			
			minetest.set_node({x=pos.x, y=pos.y - 2, z=pos.z}, {name=mn..":hot_steelblock"})
			
			nodeupdate({x=pos.x, y=pos.y - 2, z=pos.z} )
			i = 0
			tmp = {}
			
			return
		end
	end
	
	
end

]]

local max_heat = 1000;

function meltNear(pos, node) 
	
	local meta = minetest.get_meta(pos)
	local input = meta:get_int("LV_EU_input")
	local heat = meta:get_int("stored_eu")
	local current_charge = meta:get_int("internal_EU_charge")
	
	if false and input < electrode_min_demand then 
		meta:set_string("infotext", "Electrode Unpowered")
		return
	end

	heat = math.min(max_heat, heat + input)
	
	meta:set_string("infotext", "Electrode Active")
	
	local ore_nodes = minetest.find_nodes_in_area(
		{x=pos.x - 2, y=pos.y - 4,z=pos.z - 2},
		{x=pos.x + 2, y=pos.y, z=pos.z + 2},
		meltable_ores
	)
	
	for _,p in ipairs(ore_nodes) do
		local n = minetest.get_node(p)
		local req = melt_energy_requirement[n.name]
		
		if heat < req then
			break
		end
		
		heat = heat - req
		
		local new = randomMelt(n.name)
		minetest.set_node(p, {name=new})
	end
	
	meta:set_int("stored_eu", heat)
end


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
	melt_energy_requirement[name] = eu_to_melt
end

-- these numbers represent the proportions of the node, not the minetest-style chances
forge.register_ore("default:desert_cobble", 400, {
	steel = 1,
	copper = 3,
	slag = 40,
})

forge.register_ore("default:cobble", 400, {
	steel = 3,
	copper = 1,
	slag = 40,
})

forge.register_ore("default:dirt", 550, {
	steel = 10,
	gold = 1,
	slag = 1000,
})
forge.register_ore("default:dirt_with_grass", 550, {
	steel = 10,
	gold = 1,
	slag = 1000,
})

forge.register_ore("default:gravel", 380, {
	steel = 2,
	gold = 1,
	slag = 100,
})

forge.register_ore("default:desert_sand", 350, {
	glass = 10,
	slag = 1,
})

forge.register_ore("default:sand", 350, {
	glass = 20,
	slag = 1,
})

forge.register_ore("default:sandstone", 370, {
	glass = 10,
	slag = 1,
})

forge.register_ore(mn..":slag", 600, {
	steel = 1,
	copper = 1,
	glass = 1,
	slag = 1000,
})

-- remelting
forge.register_ore("default:steelblock", 200, {steel = 1})
forge.register_ore("default:copperblock", 200, {copper = 1})
forge.register_ore("default:goldblock", 200, {gold = 1})
forge.register_ore("default:bronzeblock", 200, {bronze = 1})
forge.register_ore("moreores:tin_block", 100, {tin = 1})
forge.register_ore("moreores:silver_block", 200, {silver = 1})
forge.register_ore("technic:chromium_block", 200, {chromium = 1})
forge.register_ore("technic:zinc_block", 200, {zinc = 1})
forge.register_ore("technic:lead_block", 60, {lead = 1})
forge.register_ore("technic:stainless_steel_block", 200, {stainless_steel = 1})
forge.register_ore("technic:carbon_steel_block", 200, {steel = 1})
forge.register_ore("technic:cast_iron_block", 200, {steel = 1})
forge.register_ore("default:glass", 200, {glass = 1})


minetest.register_node(mn..":electrode", {
	description = "Electrode",
	drawtype = "nodebox",
	tiles = {"default_steel_block.png^[colorize:blue:10"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {cracky=3, refractory=1, technic_machine=1, technic_lv=1 },
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			{-.5, -2.5, -0.15, -.2, 0, 0.15},
			{.5, -2.5, -0.15, .2, 0, 0.15},
		},
	},
	on_punch = function (pos, node)
		minetest.set_node(pos, {name=mn..":electrode_on"})
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("enabled", 0)
		meta:set_int("active", 0)
		meta:set_string("power_flag", "LV")
		meta:get_int("stored_eu", 0)
		meta:set_int("LV_EU_demand", 0)	
	end,
})

minetest.register_craft({
	output = mn..':electrode',
	recipe = {
		{"technic:lv_cable0", "default:steelblock", "technic:lv_cable0"},
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
	}
})

local function set_electrode_demand(meta)
	local machine_name = "Electrode"
 	meta:set_int("LV_EU_demand", 20000)
-- 	meta:set_int("LV_EU_demand", electrode_demand)
	local input = meta:get_int("LV_EU_input")
	if input ~= nil then
		meta:set_string("infotext", (input > 0 and "%s Active" or "%s Unpowered"):format(machine_name))
	else
		meta:set_string("infotext", machine_name.. " has no network.")
	end
end


minetest.register_node(mn..":electrode_on", {
	description = "Electrode",
	drawtype = "nodebox",
	tiles = {"default_steel_block.png^default_torch.png^[colorize:blue:10"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	connect_sides = {"top"},
	groups = {cracky=3, refractory=1, technic_machine=1, technic_lv=1},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			{-.5, -2.5, -0.15, -.2, 0, 0.15},
			{.5, -2.5, -0.15, .2, 0, 0.15},
		},
	},
	on_punch = function (pos, node)
		
		minetest.set_node(pos, {name=mn..":electrode"})
		
		
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("enabled", 1)
		meta:set_int("active", 1)
		meta:set_string("power_flag", "LV")
		meta:set_int("stored_eu", 0)
		--meta:set_int("LV_EU_demand", 200)
		set_electrode_demand(meta)
	end,
	technic_run = meltNear,
})

-- technic.register_machine("LV", mn..":electrode", technic.receiver)
-- technic.register_machine("LV", mn..":electrode_on", technic.receiver)
technic.register_machine("LV", mn..":electrode", technic.battery)
technic.register_machine("LV", mn..":electrode_on", technic.battery)






-- registers the molten liquids and densities
forge.register_metal = function(opts) 

	cools_to[mn..":molten_"..opts.name] = opts.cools 
	melt_densities[mn..":molten_"..opts.name] = opts.density 
	table.insert(molten_sources, mn..":molten_"..opts.name)
	
	
	minetest.register_node(mn..":molten_"..opts.name, {
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
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = mn..":molten_"..opts.name.."_flowing",
		liquid_alternative_source = mn..":molten_"..opts.name,
		liquid_viscosity = 2,
		liquid_renewable = false,
		liquid_range = 2,
		damage_per_second = 2 * 2,
		post_effect_color = {a = 192, r = 255, g = 64, b = 0},
		groups = {lava = 2, liquid = 2, hot = 3, igniter = 1, molten_ore=3, molten_ore_source=1},
	})



	minetest.register_node(mn..":molten_"..opts.name.."_flowing", {
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
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = mn..":molten_"..opts.name.."_flowing",
		liquid_alternative_source = mn..":molten_"..opts.name,
		liquid_viscosity = 2,
		liquid_renewable = false,
		liquid_range = 2,
		damage_per_second = 1 * 2,
		post_effect_color = {a = 192, r = 255, g = 64, b = 0},
		groups = {lava = 2, liquid = 2, hot = 3, igniter = 1, molten_ore=1, molten_ore_flowing=1,
			not_in_creative_inventory = 1},
	})

end -- forge.register_metal




forge.register_metal({
	name="steel",
	Name="Steel",
	cools="default:steelblock",
	density=10,
})
	
forge.register_metal({
	name="copper",
	Name="Copper",
	cools="default:copperblock",
	density=8,
})

forge.register_metal({
	name="bronze",
	Name="Bronze",
	cools="default:bronzeblock",
	density=9,
})

forge.register_metal({
	name="gold",
	Name="Gold",
	cools="default:goldblock",
	density=20,
})
forge.register_metal({
	name="silver",
	Name="Silver",
	cools="moreores:silver_block",
	density=16,
})

forge.register_metal({
	name="zinc",
	Name="Zinc",
	cools="technic:zinc_block",
	density=4,
})

forge.register_metal({
	name="tin",
	Name="Tin",
	cools="moreores:tin_block",
	density=4,
})

forge.register_metal({
	name="chromium",
	Name="Chromium",
	cools="technic:chromium_block",
	density=12,
})

forge.register_metal({
	name="lead",
	Name="Lead",
	cools="technic:lead_block",
	density=19,
})

forge.register_metal({
	name="carbon_steel",
	Name="Carbon Steel",
	cools="technic:carbon_steel_block",
	density=10,
})

forge.register_metal({
	name="stainless_steel",
	Name="Stainless Steel",
	cools="technic:stainless_steel_block",
	density=10,
})

forge.register_metal({
	name="cast_iron",
	Name="Cast Iron",
	cools="technic:cast_iron_block",
	density=10,
})

forge.register_metal({
	name="brass",
	Name="Brass",
	cools="technic:brass_block",
	density=7,
})

forge.register_metal({
	name="glass",
	Name="Glass",
	cools="default:glass",
	density=3,
})
	
forge.register_metal({
	name="slag",
	Name="Slag",
	cools=mn..":slag",
	density=3,
})

-- air cooling
minetest.register_abm({
	nodenames = {"group:molten_ore"},
	interval = 10,
	chance = 15,
	action = function(pos)
		local node = minetest.get_node_or_nil(pos)
	
		local cold = cools_to[node.name]
		
		if node == nil or cold == nil then 
			return 
		end
	
		-- don't cool near active electrodes
		if nil ~= minetest.find_node_near(pos, 4, {mn..":electrode_on"}) then
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
				if math.random(3) >= 2 then
					return
				end
			end
		end
		
		
		
		minetest.set_node(pos, {name = cold})
		nodeupdate(pos)
		minetest.sound_play("default_cool_lava",
			{pos = pos, max_hear_distance = 16, gain = 0.25})
	end,
})


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
	action = function(pos)
		local node = minetest.get_node_or_nil(pos)
		local cold = cools_to[node.name]
		
		if node == nil or cold == nil then 
			return 
		end
		
		minetest.set_node(pos, {name = cold})
		nodeupdate(pos)
		spawnSteam(pos)
		minetest.sound_play("default_cool_lava",
			{pos = pos, max_hear_distance = 16, gain = 0.25})
	end,
})


function spawnSteam(pos) 
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
		texture = mn.."_steam.png^[colorize:white:120",
	})
	
end
--[[
minetest.register_abm({
	nodenames = {mn..":hot_steelblock"},
	interval = 10,
	chance = 2,
	action = function(pos)
		minetest.set_node(pos, {name = "default:steelblock"})
	end,
})
]]



-- fluid dynamics
minetest.register_abm({
	nodenames = {"group:molten_ore"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local flow_nodes;

		local node = minetest.get_node(pos)
		if minetest.get_item_group(node.name, "molten_ore") < 3 then
			return
		end
		
		local flow_name = node.name.."_flowing" 
		
		-- look below
		flow_nodes = minetest.find_nodes_in_area(
			{x=pos.x , y=pos.y - 1, z=pos.z},
			{x=pos.x , y=pos.y - 1, z=pos.z},
			"group:molten_ore_flowing"
		)
		
		for _,fp in ipairs(flow_nodes) do
			local n = minetest.get_node(fp);
			minetest.set_node(fp, {name=node.name})
			minetest.set_node(pos, {name=n.name})
			return
		end	
		
		-- look one node out
		flow_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y - 1, z=pos.z + 1},
			"group:molten_ore_flowing"
		)
		
		for _,fp in ipairs(flow_nodes) do
			local n = minetest.get_node(fp);
			-- check above to make sure it can get here
			local na = minetest.get_node({x=fp.x, y=fp.y+1, z=fp.z})
			local g = minetest.get_item_group(na.name, "molten_ore")
	--		print("name: " .. na.name .. " l: " ..g)
			if g > 0 then
				minetest.set_node(fp, {name=node.name})
				minetest.set_node(pos, {name=n.name})
				return
			end
		end
	
		
		-- look two nodes out
		flow_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 2, y=pos.y - 1, z=pos.z - 2},
			{x=pos.x + 2, y=pos.y - 1, z=pos.z + 2},
			"group:molten_ore_flowing"
		)
		
		for _,fp in ipairs(flow_nodes) do
			local n = minetest.get_node(fp);
			
			-- check above
			local na = minetest.get_node({x=fp.x, y=fp.y+1, z=fp.z})
			local ga = minetest.get_item_group(na.name, "molten_ore")
			
			if ga > 0 then
				-- check between above and node
				local nb = minetest.get_node({x=(fp.x + pos.x) / 2, y=pos.y, z=(fp.z + pos.z) / 2})
				local gb = minetest.get_item_group(nb.name, "molten_ore")
				
				if gb > 0 then
				--print("name: " .. na.name .. " l: " ..ga .. " bname: " .. nb.name .. " lb: " ..gb)
					minetest.set_node(fp, {name=node.name})
					minetest.set_node(pos, {name=n.name})
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
	action = function(pos)
		local light_nodes;

		local node = minetest.get_node(pos)

		-- look one node out
		light_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y - 1, z=pos.z + 1},
			"group:molten_ore_source"
		)
		
		for _,fp in ipairs(light_nodes) do
			local n = minetest.get_node(fp);
			
			local sd = melt_densities[node.name]
			local dd = melt_densities[n.name]
			
			if dd and sd and dd < sd then
				minetest.set_node(fp, {name=node.name})
				minetest.set_node(pos, {name=n.name})
				return
			end
		
		end
	
	end,
})



-- ore destroys things
minetest.register_abm({
	nodenames = {"group:molten_ore_source"},
	interval = 5,
 	chance = 40,
	action = function(pos)
		local node = minetest.get_node_or_nil(pos)
		if 0 == minetest.get_item_group(node.name, "molten_ore_source") then
			return
		end
		
		-- this only works if destruction is slower than cooling
		local flowing_node = randomMelt(node.name) 
		
		local try_replace = function(p)
			local n = minetest.get_node_or_nil(p)
			if n ~= nil then
				if 0 == minetest.get_item_group(n.name, "refractory") then 
					if 0 == minetest.get_item_group(n.name, "molten_ore") then
						minetest.set_node(p, {name=flowing_node})
						return true
					end
				end
			end
			return false
		end
		
		-- below
		return (try_replace({x=pos.x    , y=pos.y - 1, z=pos.z    })
		or try_replace({x=pos.x + 1, y=pos.y    , z=pos.z    })
		or try_replace({x=pos.x    , y=pos.y    , z=pos.z + 1})
		or try_replace({x=pos.x    , y=pos.y    , z=pos.z - 1})
		or try_replace({x=pos.x - 1, y=pos.y    , z=pos.z    }))
		
		-- above is not destroyed
	end,
})

