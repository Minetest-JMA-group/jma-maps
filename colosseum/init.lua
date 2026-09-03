--core.debug(dump(core.registered_nodes["xpanes:bar_flat"]));

xpanes.register_pane("ind_steel_bars", {
	description = "Indestructible Steel Bars",
	textures = {
		"xpanes_bar.png",
		"",
		"xpanes_bar_top.png"
	},
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	groups = {pane = 1},
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})
core.clear_craft({output = "xpanes:ind_steel_bars_flat 16"})

for _, t in ipairs({"", "_flat"}) do
	core.override_item("xpanes:ind_steel_bars" .. t, {
		diggable = false,
	})
end
