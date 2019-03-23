

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end



local function get_af_active_formspec(fuel_percent, item_percent)
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
-- 		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;fuel;.75,.5;2,4;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png^[lowpart:"..
		(100-fuel_percent)..":default_furnace_fire_fg.png]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..
-- 		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
-- 		"listring[context;dst]"..
-- 		"listring[current_player;main]"..
-- 		"listring[context;src]"..
-- 		"listring[current_player;main]"..
-- 		"listring[context;fuel]"..
-- 		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

function get_af_inactive_formspec()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
--		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;fuel;2.75,2.5;2,2;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png]"..
-- 		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
--		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end


local function grab_fuel(inv)
	
	local list = inv:get_list("fuel")
	for i,st in ipairs(list) do
		if st:get_name() == "forge:coke" then
			local fuel, remains
			fuel, remains = minetest.get_craft_result({
				method = "fuel", 
				width = 1, 
				items = {
					ItemStack(st:get_name())
				},
			})

			if fuel.time > 0 then
				-- Take fuel from fuel list
				st:take_item()
				inv:set_stack("fuel", i, st)
				
				return fuel.time
			end
		end
	end
	
	return 0 -- no fuel found
end



local function burner_on_timer(pos, elapsed)

	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local fuel_burned = meta:get_float("fuel_burned") or 0
	local cook_time_remaining = meta:get_float("cook_time_remaining") or 60
	
	local inv = meta:get_inventory()
	
	
	local burned = elapsed
	local turn_off = false
	
	print("\n\naf timer")
	print("fuel_burned: " .. fuel_burned)
	print("fuel_time: " .. fuel_time)

	
	if fuel_time > 0 and fuel_burned + elapsed < fuel_time then

		fuel_burned = fuel_burned + elapsed
		meta:set_float("fuel_burned", fuel_burned + elapsed)
	else
		local t = grab_fuel(inv)
		if t <= 0 then -- out of fuel
			--print("out of fuel")
			meta:set_float("fuel_time", 0)
			meta:set_float("fuel_burned", 0)
			
			burned = fuel_time - fuel_burned
			
			turn_off = true
		else
			-- roll into the next period
			fuel_burned =  elapsed - (fuel_time - fuel_burned)
			fuel_time = t
			
			--print("fuel remaining: " .. (fuel_time - fuel_burned))
		
			meta:set_float("fuel_time", fuel_time)
			meta:set_float("fuel_burned", fuel_burned)
		end
	end

	
	
	
	if burned > 0 then
		
		local remain = cook_time_remaining - burned
		print("remain: ".. remain);
		if remain > 0 then
			meta:set_float("cook_time_remaining", remain)
		else
			print("finished")
			
			local ore_nodes = minetest.find_nodes_in_area(
						{x=pos.x - 3, y=pos.y + 1,z=pos.z - 3},
						{x=pos.x + 3, y=pos.y + 5, z=pos.z + 3},
						forge.meltable_ores
					)
			if #ore_nodes > 0 then
				local i = math.random(1, #ore_nodes)
				local p = ore_nodes[i]
				local n = minetest.get_node(p)
				if n ~= nil then
					minetest.set_node(p, {name=forge.random_melt_product(n.name)})
				end
			end
			
			meta:set_float("cook_time_remaining", 4)
		end
		
		
	end
	
	
	
	if turn_off then
		swap_node(pos, "forge:burner")
		return
	end
	
	fuel_pct = math.floor((fuel_burned * 100) / fuel_time)
--	item_pct = math.floor((fuel_burned * 100) / fuel_time)
	meta:set_string("formspec", get_af_active_formspec(fuel_pct, 0))
	meta:set_string("infotext", "Fuel: " ..  fuel_pct)
	
	--minetest.get_node_timer(pos):start(1.0)
	return true
end





minetest.register_node("forge:burner_on", {
	description = "Forge Burner (active)",
	tiles = {
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png",
		{
			image = "default_furnace_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	paramtype2 = "facedir",
	groups = {cracky=1, refractory=1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,

	on_timer = burner_on_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_af_inactive_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		minetest.get_node_timer(pos):start(1.0)
		
	end,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	
	
	on_punch = function(pos)
		swap_node(pos, "forge:burner")
	end,
	
	
-- 	on_blast = function(pos)
-- 		local drops = {}
-- 		default.get_inventory_drops(pos, "src", drops)
-- 		default.get_inventory_drops(pos, "fuel", drops)
-- 		default.get_inventory_drops(pos, "dst", drops)
-- 		drops[#drops+1] = "machines:machine"
-- 		minetest.remove_node(pos)
-- 		return drops
-- 	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})






minetest.register_node("forge:burner", {
	description = "Forge Burner",
	tiles = {
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png", "default_furnace_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=1, refractory=1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,

	--on_timer = af_node_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_af_inactive_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		

	end,

	on_metadata_inventory_move = function(pos)
		--minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		--minetest.get_node_timer(pos):start(1.0)
	end,
	
	on_punch = function(pos, node, player)
		swap_node(pos, "forge:burner_on")
		minetest.get_node_timer(pos):start(1.0)
	end,
	
-- 	on_blast = function(pos)
-- 		local drops = {}
-- 		default.get_inventory_drops(pos, "src", drops)
-- 		default.get_inventory_drops(pos, "fuel", drops)
-- 		default.get_inventory_drops(pos, "dst", drops)
-- 		drops[#drops+1] = "machines:machine"
-- 		minetest.remove_node(pos)
-- 		return drops
-- 	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})








minetest.register_craft({
	output = 'forge:burner',
	recipe = {
		{'forge:refractory_clay_brick', 'forge:refractory_clay_brick', 'forge:refractory_clay_brick'},
		{'forge:refractory_clay_brick', 'default:furnace',        'forge:refractory_clay_brick'},
		{'forge:refractory_clay_brick', 'forge:refractory_clay_brick', 'forge:refractory_clay_brick'},
	}
})













if minetest.global_exists("bitumen") and bitumen then 




	minetest.register_node("forge:oil_burner_on", {
		description = "Forge Oil Burner (active)",
		tiles = {
			"default_steel_block.png", "default_steel_block.png",
			"default_steel_block.png", "default_steel_block.png",
			"default_steel_block.png",
			{
				image = "default_furnace_front_active.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 1.5
				},
			}
		},
		paramtype2 = "facedir",
		groups = {cracky=1, refractory=1},
		legacy_facedir_simple = true,
		is_ground_content = false,
		sounds = default.node_sound_stone_defaults(),
		drops = "forge:oil_burner",
		
		on_punch = function(pos)
			swap_node(pos, "forge:oil_burner")
		end,
		
	})






	minetest.register_node("forge:oil_burner", {
		description = "Forge Oil Burner",
		tiles = {
			"default_steel_block.png", "default_steel_block.png",
			"default_steel_block.png", "default_steel_block.png",
			"default_steel_block.png", "default_furnace_front.png"
		},
		paramtype2 = "facedir",
		groups = {cracky=1, refractory=1},
		legacy_facedir_simple = true,
		is_ground_content = false,
		sounds = default.node_sound_stone_defaults(),

		on_construct = function(pos)

		end,
		
		on_punch = function(pos, node, player)
			swap_node(pos, "forge:oil_burner_on")
		end,
		
	})




	minetest.register_abm({
		nodenames = {"forge:oil_burner_on"},
		interval = 2,
		chance   = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local npos = {x=pos.x, y=pos.y - 1, z=pos.z}
			local pnet = bitumen.pipes.get_net(npos)
			
			
			if not pnet or pnet.buffer <= 0 then
				print("oil burner: no oil in pipe")
				return -- no oil in the pipe
			end
			
			if pnet.fluid ~= "bitumen:heavy_oil" then
				print("barrel filler: bad_fluid ".. pnet.fluid)
				return -- incompatible fluids
			end
			
			
			local to_take = 1
			if pnet.buffer <= to_take then
				print("oil burner: not enough fuel")
				return
			end
			
			local taken, fluid = bitumen.pipes.take_fluid(npos, to_take)
			if fluid == "air" then
				print("oil burner: failed to take enough fuel")
				return
			end
			
			
			
			local ore_nodes = minetest.find_nodes_in_area(
				{x=pos.x - 1, y=pos.y + 1,z=pos.z - 1},
				{x=pos.x + 1, y=pos.y + 6, z=pos.z + 1},
				forge.meltable_ores
			)
			if #ore_nodes > 0 then
				local i = math.random(1, #ore_nodes)
				local p = ore_nodes[i]
				local n = minetest.get_node(p)
				if n ~= nil then
					minetest.set_node(p, {name=forge.random_melt_product(n.name)})
				end
			end
			
		end
	})



	minetest.register_craft({
		output = 'forge:oil_burner',
		type = "shapeless",
		recipe = {'forge:burner', 'bitumen:pipe'},
	})



end













