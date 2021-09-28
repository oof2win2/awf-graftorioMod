local lib = {}

lib.collect_statics = function ()
	global.output.tick = game.tick

	global.output.online_players = {}
	for _, player in pairs(game.connected_players) do
		table.insert(global.output.online_players, player.name)
	end

	global.output.mods = {}
	for name, version in pairs(game.active_mods) do
		global.output.mods[name] = version
	end

	-- reason behind this is that the map gen settings can be changed during runtime so just get them fresh
	global.output.seed = {}
	for _, surface in pairs(game.surfaces) do
		global.output.seed[surface.name] = surface.map_gen_settings.seed
	end
end

return lib