local lib = {}

---@class StaticStatistics
---@field tick uint
---@field online_players string[]
---@field mods table<string, string>
---@field seed table<string, uint>

lib.collect_statics = function ()
	local stats = {}
	stats.tick = game.tick

	stats.online_players = {}
	for _, player in pairs(game.connected_players) do
		table.insert(global.output.online_players, player.name)
	end

	stats.mods = {}
	for name, version in pairs(game.active_mods) do
		stats.mods[name] = version
	end

	-- reason behind this is that the map gen settings can be changed during runtime so just get them fresh
	stats.seed = {}
	for _, surface in pairs(game.surfaces) do
		stats.seed[surface.name] = surface.map_gen_settings.seed
	end
	for _, force in pairs(game.forces) do
		global.output[force.name].other = stats
	end
end

return lib