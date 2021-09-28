local handler = require("event_handler")

local forcestats = require("scripts.forcestats")
local statics = require("scripts.statics")
local power = require("scripts.power")
local trains = require("scripts.trains")
local general = require("scripts.general")
local migrations = require("scripts.migrations")

commands.add_command("collectdata", nil, function (params)
	forcestats.collect_production()
	general.collect_other()
	if settings.global["graftorio-logistic-items"] then forcestats.collect_loginet() end
	statics.collect_statics()
	power.collect_power()
	trains.collect_trains()

	if params.parameter == "rcon" then
		game.print("RCON!")
		rcon.print(game.table_to_json(global.output))
	else
		game.write_file("game.prom", game.table_to_json(global.output), false)
	end
end)

handler.add_lib(general)
handler.add_lib(forcestats)
handler.add_lib(statics)
handler.add_lib(power)
handler.add_lib(trains)

script.on_configuration_changed(function (data)
	if not data.mod_changes["awf-graftorioMod"] then return end
	local old_version = data.mod_changes["awf-graftorioMod"].old_version

	for _, lib in pairs({general, forcestats, statics, power, trains}) do
		if lib.migrations then
			for version, migration in pairs(lib.migrations) do
				if migrations.is_newer_version(old_version, version) then migration() end
			end
		end
	end
end)