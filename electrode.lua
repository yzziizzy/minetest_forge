

if minetest.get_modpath("technic") ~= nil then
	
	
	local max_heat = 0;

	function meltNear(pos, node) 
		
		local meta = minetest.get_meta(pos)
		local input = meta:get_int("LV_EU_input")
		local heat = meta:get_int("stored_eu")
		local current_charge = meta:get_int("internal_EU_charge")
		
		if false and input < electrode_min_demand then 
			meta:set_string("infotext", "Electrode Unpowered")
			return
		end

		heat = heat + input
		print(heat)
		meta:set_string("infotext", "Electrode Active")
		
		local ore_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 3, y=pos.y - 6,z=pos.z - 3},
			{x=pos.x + 3, y=pos.y, z=pos.z + 3},
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
		
		meta:set_int("stored_eu", math.min(max_heat, heat)
	)
	end

	
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
		meta:set_int("LV_EU_demand", 10000000)
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
	technic.register_machine("LV", mn..":electrode", technic.receiver)
	technic.register_machine("LV", mn..":electrode_on", technic.battery)
	
	
	
end



