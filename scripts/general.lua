lib = {}

---@class Statistics
---@field trains TrainStatistics
---@field power PowerStatistics
---@field production ProductionStatistics
---@field robots RobotStatistics
---@field other OtherStatistics

lib.on_init = function ()
	---@type table<string, Statistics>
	global.output = {}
	for _, force in pairs(game.forces) do
		global.output[force.name] = {}
	end
end

lib.migrations = {
	["2.0.0"] = function ()
		global.output = {}
	for _, force in pairs(game.forces) do
		global.output[force.name] = {}
	end
	end
}

---@class OtherStatistics
---@field tick uint
---@field evolution EvolutionStatistics
---@field research ResearchStatistics

---@class EvolutionStatistics
---@field evolution_factor double
---@field evolution_factor_by_pollution double
---@field evolution_factor_by_time double
---@field evolution_factor_by_killing_spawners double

lib.collect_other = function ()
	for _, force in pairs(game.forces) do
		---@type OtherStatistics
		global.output[force.name].other.evolution = {
			evolution_factor=force.evolution_factor,
			evolution_factor_by_pollution=force.evolution_factor_by_pollution,
			evolution_factor_by_time=force.evolution_factor_by_time,
			evolution_factor_by_killing_spawners=force.evolution_factor_by_killing_spawners
		}
	end
end

lib.events = {
	[defines.events.on_force_created] = function (evt)
		global.output[evt.force.name] = {}
	end,
	[defines.events.on_forces_merged] = function (evt)
		global.output[evt.source_name] = nil
	end
}

return lib