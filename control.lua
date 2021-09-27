local forcestats = require("scripts.forcestats")
-- local gatherdata = require("scripts.gatherdata")

commands.add_command("collectdata", nil, function ()
	forcestats.collect_production()
	forcestats.collect_loginet()

	global.tick = game.tick
	game.write_file("game.txt", game.table_to_json(global), false, 0)
end)

script.on_init(function ()
	global.stats = {}
end)