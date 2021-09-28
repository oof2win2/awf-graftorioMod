local lib = {}

lib.collect_statics = function ()
	global.tick = game.tick

	global.online_players = {}
	for _, player in pairs(game.connected_players) do
		table.insert(global.online_players, player.name)
	end

	global.mods = {}
	for name, version in pairs(game.active_mods) do
		global.mods[name] = version
	end

	-- reason behind this is that the map gen settings can be changed during runtime so just get them fresh
	global.seed = {}
	for _, surface in pairs(game.surfaces) do
		global.seed[surface.name] = surface.map_gen_settings.seed
	end
end

return lib