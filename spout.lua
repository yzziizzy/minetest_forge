


local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end



minetest.register_node("forge:spout", {
	description = "Spout",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- top bar
			{-.3, .3, -.35, .3, .5, .35},
			
			-- sides
			{-.5, -.5, -.35, -.3, .5, .35},
			{.3, -.5, -.35, .5, .5, .35},
			
			-- bottom bar
			{-.3, -.5, -.35, .3, -.3, .35},
			
			-- gate
			{-.45, -.45, -.1, .45, .45, .1 },
		},
	},
	tiles = {"default_bronze_block.png"},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {cracky = 1, petroleum_fixture=1, refractory = 3},
	sounds = default.node_sound_glass_defaults(),
	on_place = minetest.rotate_node,

	on_punch = function(pos)
		swap_node(pos, "forge:spout_open")
	end,
})



minetest.register_node("forge:spout_open", {
	description = "Spout",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- top bar
			{-.3, .3, -.35, .3, .5, .35},
			
			-- sides
			{-.5, -.5, -.35, -.3, .5, .35},
			{.3, -.5, -.35, .5, .5, .35},
			
			-- bottom bar
			{-.3, -.5, -.35, .3, -.3, .35},
			
		},
	},
	tiles = {"default_bronze_block.png"},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {cracky = 1, petroleum_fixture=1, refractory = 3},
	sounds = default.node_sound_glass_defaults(),
	on_place = minetest.rotate_node,

	on_punch = function(pos)
		swap_node(pos, "forge:spout")
	end,
})




minetest.register_abm({
	nodenames = {"forge:spout_open"},
	interval = 4,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local node = minetest.get_node(pos)
		
		local back_dir = minetest.facedir_to_dir(node.param2)
		local backpos = vector.add(pos, back_dir) 
		local front_dir = vector.multiply(back_dir, -1)
		local frontpos = vector.add(pos, front_dir)
		
		local bnode = minetest.get_node(backpos)
		local fnode = minetest.get_node(frontpos)
		
		if fnode.name ~= "air" and bnode.name ~= "air" then
		--	print("forge spout: nowhere to flow to")
			return
		end
		
		local bdef = minetest.registered_nodes[bnode.name]
		local fdef = minetest.registered_nodes[fnode.name]
		
		if not bdef.groups.molten_ore_source and not fdef.groups.molten_ore_source then
		--	print("forge spout: no molten ore source")
			return
		end
		
		if fnode.name == "air" then
			minetest.set_node(frontpos, {name = bnode.name})
			minetest.set_node(backpos, {name = "air"})
		else
			minetest.set_node(backpos, {name = fnode.name})
			minetest.set_node(frontpos, {name = "air"})
		end
		
		
	end
})









minetest.register_craft({
	output = 'forge:spout',
	recipe = {
		{'forge:refractory_clay_brick', 'default:steel_ingot', 'forge:refractory_clay_brick'},
		{'', '', ''},
		{'', '', ''},
	}
})























