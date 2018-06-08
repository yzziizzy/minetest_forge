




local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end


minetest.register_node("forge:coke", {
    description = "Coke",
    tiles = { "default_coal_block.png^[colorize:black:180" },
    is_ground_content = true,
    groups = {cracky=1, level=3, refractory=3},
    sounds = default.node_sound_stone_defaults(),
}) 

-- -------------------------------------------------
--  enclosure determination



local function pushpos(t, v, p)
	local h = minetest.hash_node_position(p)
	if v[h] == nil then
		table.insert(t, p)
	end
end


local function find_blob_extent(startpos)
	
	local blob = {}
	local stack = {}
	local visited = {}
	local shell = {}
	
	
	local node = minetest.get_node(startpos)
	if node.name == "air" then
		return nil
	end
	
	local bname = node.name
	
	table.insert(stack, startpos)
	
	while #stack > 0 do
		
		local p = table.remove(stack)
		local ph = minetest.hash_node_position(p)
		
		print("visiting "..minetest.pos_to_string(p))
		
		if visited[ph] == nil then
			visited[ph] = 1
			
			local pn = minetest.get_node(p)
			if pn then
				if pn.name == bname then
					blob[ph] = {x=p.x, y=p.y, z=p.z}
					
					pushpos(stack, visited, {x=p.x+1, y=p.y, z=p.z})
					pushpos(stack, visited, {x=p.x-1, y=p.y, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y+1, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y-1, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y, z=p.z+1})
					pushpos(stack, visited, {x=p.x, y=p.y, z=p.z-1})
				else
					shell[pn.name] = (shell[pn.name] or 0) + 1
				end
			end
		end
	end
	
	
	for _,p in pairs(blob) do
		print("blob "..minetest.pos_to_string(p))
	end
	
	for n,v in pairs(shell) do
		print("shell "..n.." - ".. v)
	end
	
	
	return blob, shell
end







-- ---------------------------------------------






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
	print(st:get_name())
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
	
	return 0 -- no fuel found
end



local function af_on_timer(pos, elapsed)

	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local fuel_burned = meta:get_float("fuel_burned") or 0
	local cook_time_remaining = meta:get_float("cook_time_remaining") or 10
	
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
			
			-- convert coal to coke
			local blobs = meta:get_string("blob") or ""
			local blob = minetest.deserialize(blobs)
			
			local p 
			for _,pp in pairs(blob) do 
				p = pp
				break
			end
			minetest.set_node(p, {name="forge:coke"})
			
			meta:set_string("blob", minetest.serialize(blob))
			
			meta:set_float("cook_time_remaining", 10)
		end
		
		
	end
	
	
	
	if turn_off then
		swap_node(pos, "forge:coke_furnace")
		return
	end
	
	fuel_pct = math.floor((fuel_burned * 100) / fuel_time)
--	item_pct = math.floor((fuel_burned * 100) / fuel_time)
	meta:set_string("formspec", get_af_active_formspec(fuel_pct, 0))
	meta:set_string("infotext", "Fuel: " ..  fuel_pct)
	
	--minetest.get_node_timer(pos):start(1.0)
	return true
end



local shell_nodes = {
	["forge:coke_furnace"] = 1,
	["forge:coke_furnace_on"] = 1,
	["default:brick"] = 1,
	["forge:refractory_brick"] = 1,
}

local function check_coke_oven(furnacepos)

	local fnode = minetest.get_node(furnacepos)
	local fdir = minetest.facedir_to_dir(fnode.param2)
	local seedp = vector.add(furnacepos, fdir)
	local seedn = minetest.get_node(seedp)
	
	if seedn == nil or seedn.name ~= "default:coalblock" then 
		print("not coal")
		return false
	end
	
	local fuel, oven = find_blob_extent(seedp)
	
	local oven_intact = 1
	for name,_ in pairs(oven) do
		if shell_nodes[name] == nil then
			print("failing for ".. name)
			oven_intact = 0
			break
		end
	end
	
	if oven_intact == 0 then
		print("not intact")
		return false
	end
	
	local meta = minetest.get_meta(furnacepos)
	meta:set_string("blob", minetest.serialize(fuel))
	
	return true
end


minetest.register_node("forge:coke_furnace_on", {
	description = "Coke furnace (active)",
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
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,

	on_timer = af_on_timer,

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
		swap_node(pos, "forge:coke_furnace")
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






minetest.register_node("forge:coke_furnace", {
	description = "Coke Furnace",
	tiles = {
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png", "default_furnace_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
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
		if check_coke_oven(pos) then
			swap_node(pos, "forge:coke_furnace_on")
			minetest.get_node_timer(pos):start(1.0)
		else
			minetest.chat_send_player(player:get_player_name(), "Coke oven is incomplete.")
		end
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
	output = 'forge:coke_furnace',
	recipe = {
		{'forge:refractory_clay_brick', 'forge:refractory_clay_brick', 'forge:refractory_clay_brick'},
		{'forge:refractory_clay_brick', '',        'forge:refractory_clay_brick'},
		{'forge:refractory_clay_brick', 'forge:refractory_clay_brick', 'forge:refractory_clay_brick'},
	}
})




minetest.register_craft({
	type = "fuel",
	recipe = "forge:coke",
	burntime = 120,
})
















