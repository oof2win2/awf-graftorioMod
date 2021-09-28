local handler = require("event_handler")

local forcestats = require("scripts.forcestats")
local statics = require("scripts.statics")
local general = require("scripts.general")

commands.add_command("collectdata", nil, function ()
	forcestats.collect_production()
	if settings.global["graftorio-logistic-items"] then forcestats.collect_loginet() end
	statics.collect_statics()

	game.print("done")
	game.write_file("game.txt", game.table_to_json(global.output), false)
end)

handler.add_lib(forcestats)
handler.add_lib(statics)
handler.add_lib(general)