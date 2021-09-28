local handler = require("event_handler")

local forcestats = require("scripts.forcestats")
local statics = require("scripts.statics")

commands.add_command("collectdata", nil, function ()
	forcestats.collect_production()
	forcestats.collect_loginet()
	statics.collect_statics()

	global.tick = game.tick
	game.print("done")
	game.write_file("game.txt", game.table_to_json(global), false)
end)

handler.add_lib(forcestats)
handler.add_lib(statics)

script.on_init(function ()
	global.stats = {}
end)