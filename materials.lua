local forge = ...

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
forge.register_ore("technic:brass_block", 200, {brass = 1})
forge.register_ore("default:glass", 200, {glass = 1})

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
