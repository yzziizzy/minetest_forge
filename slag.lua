local forge = ...
local modname = minetest.get_current_modname()

--------------------------------------------------------------------------------

minetest.register_node(modname..":slag", {
	description = "Slag",
	tiles = { "default_gravel.png^[colorize:brown:80" },
	groups = {cracky=3, cobble=1, refractory=1},
	sounds = default.node_sound_stone_defaults(),
})

forge.register_ore(modname..":slag", 600, {
	steel = 1,
	copper = 1,
	glass = 1,
	slag = 1000,
})

forge.register_metal({
	name="slag",
	Name="Slag",
	cools=modname..":slag",
	density=3,
})

--------------------------------------------------------------------------------

local slag_cement = modname..":slag_cement"
minetest.register_node(slag_cement, {
	description = "Slag cement",
	tiles = { "default_sand.png^[colorize:#ddeeee:120" },
	groups = { crumbly=3, falling_node=1 },
	sounds = default.node_sound_sand_defaults(),
})

minetest.register_craft({
	type = "cooking",
	output = "default:glass", -- Slag glass
	recipe = slag_cement,
})

forge.register_ore(modname..":slag_cement", 350, {
	steel = 1,
	copper = 1,
	glass = 100,
	slag = 900,
})



if minetest.get_modpath("technic") ~= nil then

	technic.register_grinder_recipe({
		input = { modname..":slag" },
		output = slag_cement
	})


	minetest.clear_craft({ output = "technic:concrete" })
	minetest.register_craft({
		output = "technic:concrete 5",
		recipe = {
			{slag_cement,"technic:rebar",slag_cement},
			{"technic:rebar",slag_cement,"technic:rebar"},
			{slag_cement,"technic:rebar",slag_cement},
		}
	})

	minetest.clear_craft({ output = "technic:concrete_post" })
	minetest.register_craft({
		output = "technic:concrete_post 12",
		recipe = {
			{slag_cement,"technic:rebar",slag_cement},
			{slag_cement,"technic:rebar",slag_cement},
			{slag_cement,"technic:rebar",slag_cement},
		}
	})

end

if minetest.get_modpath("gloopblocks") then
	minetest.register_craft({
		type = "shapeless",
		output = "gloopblocks:wet_cement 2",
		recipe = { "bucket:bucket_water", slag_cement, slag_cement },
		replacements = {{"bucket:bucket_water", "bucket:bucket_empty"},},
	})
end

if minetest.get_modpath("prefab") then
	minetest.register_craft({
		output = "prefab:concrete 5",
		recipe = {
			{slag_cement, "default:gravel", slag_cement},
			{"default:gravel", slag_cement, "default:gravel"},
			{slag_cement, "default:gravel", slag_cement},
		}
	})
end
