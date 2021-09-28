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

-- sourced from flib
local version_pattern = "%d+"
local version_format = "%02d"
local function format_version(version, format)
	if version then
	  format = format or version_format
	  local tbl = {}
	  for v in string.gmatch(version, version_pattern) do
		tbl[#tbl+1] = string.format(format, v)
	  end
	  if next(tbl) then
		return table.concat(tbl, ".")
	  end
	end
	return nil
  end

--- Check if current_version is newer than old_version.
local function is_newer_version(old_version, current_version)
	local v1 = format_version(old_version)
	local v2 = format_version(current_version)
	if v1 and v2 then
	  if v2 > v1 then
		return true
	  end
	  return false
	end
	return nil
  end

lib.on_configuration_changed = function(data)
	if not data.mod_changes["awf-graftorioMod"] then return end
	local old_version = data.mod_changes["awf-graftorioMod"].old_version
	
	if is_newer_version(old_version, "2.0.0") then lib.on_init() end
end

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