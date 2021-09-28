local handler = require("event_handler")

local forcestats = require("scripts.forcestats")
local statics = require("scripts.statics")
local power = require("scripts.power")
local trains = require("scripts.trains")
local general = require("scripts.general")

commands.add_command("collectdata", nil, function (params)
	forcestats.collect_production()
	forcestats.collect_other()
	if settings.global["graftorio-logistic-items"] then forcestats.collect_loginet() end
	statics.collect_statics()
	power.collect_power()
	trains.collect_trains()

	game.write_file("game.txt", game.table_to_json(global.output), false)
end)

handler.add_lib(forcestats)
handler.add_lib(statics)
handler.add_lib(power)
handler.add_lib(general)