local lib = {}

local function on_built (evt)
	---@type LuaEntity
	local entity = evt.created_entity or evt.entity

	if entity.type == "electric-pole" and entity.electric_network_id then
		if global.power.networks[entity.force.index] == nil then global.power.networks[entity.force.index] = {} end
		global.power.networks[entity.force.index][entity.electric_network_id] = {
			networkid=entity.electric_network_id,
			position=entity.position,
			surface=entity.surface.index,
			unitnumber=entity.unit_number,
			force=entity.force.name,
			type=entity.type,
		}
	elseif entity.type == "power-switch"  then
		global.power.switches[entity.unit_number] = {
			position=entity.position,
			surface=entity.surface.name,
			unitnumber=entity.unit_number,
			force=entity.force.name,
			type=entity.type
		}
	end
end

local function on_destroyed (evt)
	---@type LuaEntity
	local entity = evt.created_entity or evt.entity
	if entity.type == "electric-pole" and entity.electric_network_id then
		global.power.networks[entity.force.index][entity.electric_network_id] = nil
	elseif entity.type == "power-switch"  then
		global.power.switches[entity.unit_number] = nil
	end
end

---@param surface LuaSurface
---@param unit_number number
local function remove_power_pole(surface, unit_number)

end

lib.collect_power = function ()
	for forceindex, networks in pairs(global.power.networks) do
		local force = game.forces[forceindex]
		global.output[force.name].power = {}
		---@class PowerStatistics
		---@field input double|uint64
		---@field output double|uint64
		local statistics = {
			input=0,
			output=0,
		}
		
		local surfaces = {}
		for networkindex, network in pairs(networks) do
			---@type LuaSurface
			local surface = surfaces[network.surface] or game.get_surface(network.surface)
			if surfaces[network.surface] == nil then surfaces[network.surface] = surface end
	
			local entity = surface.find_entities_filtered{
				unitnumber=network.unitnumber,
			}[1]
			if entity then
				for _, value in pairs(entity.electric_network_statistics.input_counts) do
					statistics.input = statistics.input + value
				end
				for _, value in pairs(entity.electric_network_statistics.output_counts) do
					statistics.output = statistics.output + value
				end
			else
				networks[networkindex] = nil
			end
		end
		global.output[force.name].power = statistics
	end
end

lib.events = {
	[defines.events.on_built_entity] = on_built,
	[defines.events.script_raised_built] = on_built,
	[defines.events.on_robot_built_entity] = on_built,

	[defines.events.on_player_mined_entity] = on_destroyed,
	[defines.events.script_raised_destroy] = on_destroyed,
	[defines.events.on_robot_mined_entity] = on_destroyed,

	[defines.events.on_force_created] = function (evt)
		global.power.networks[evt.force.index] = {}
	end,
	[defines.events.on_forces_merging] = function (evt)
		for index, network in pairs(global.power.networks[evt.source.index]) do 
			network.force = evt.destination.name
			global.power.networks[evt.destination.index][index] = network
		end
		global.power.networks[evt.source.index] = nil
	end
}

lib.on_init = function ()
	global.power = {
		networks = {},
		switches = {}
	}
end
lib.migrations = {
	["2.0.0"] = function ()
		global.power = {
			networks = {},
			switches = {}
		}
	end
}

return lib