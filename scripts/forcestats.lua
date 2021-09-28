local lib = {}

lib.collect_production = function ()
	for _, force in pairs(game.forces) do
		---@class ProductionStatistics
		---@field item_input table<string, double|uint64>
		---@field item_output table<string, double|uint64>
		---@field fluid_input table<string, double|uint64>
		---@field fluid_output table<string, double|uint64>
		---@field kill_input table<string, double|uint64>
		---@field kill_output table<string, double|uint64>
		---@field build_input table<string, double|uint64>
		---@field build_output table<string, double|uint64>
		local stats = {
			item_input = {},
			item_output = {},
			fluid_input = {},
			fluid_output = {},
			kill_input = {},
			kill_output = {},
			build_input = {},
			build_output = {},
		}

		for name, count in pairs(force.item_production_statistics.input_counts) do
			local itemstats = stats.item_input[name] or {}
			itemstats.count = count
			stats.item_input[name] = itemstats
		end
		for name, count in pairs(force.item_production_statistics.output_counts) do
			local itemstats = stats.item_output[name] or {}
			itemstats.count = count
			stats.item_output[name] = itemstats
		end

		for name, count in pairs(force.fluid_production_statistics.input_counts) do
			local fluidstats = stats.fluid_input[name] or {}
			fluidstats.count = count
			stats.fluid_input[name] = fluidstats
		end
		for name, count in pairs(force.fluid_production_statistics.output_counts) do
			local fluidstats = stats.fluid_output[name] or {}
			fluidstats.count = count
			stats.fluid_output[name] = fluidstats
		end

		for name, count in pairs(force.kill_count_statistics.input_counts) do
			local killstats = stats.kill_input[name] or {}
			killstats.count = count
			stats.kill_input[name] = killstats
		end
		for name, count in pairs(force.kill_count_statistics.output_counts) do
			local killstats = stats.kill_output[name] or {}
			killstats.count = count
			stats.kill_output[name] = killstats
		end

		for name, count in pairs(force.entity_build_count_statistics.input_counts) do
			local buildstats = stats.build_input[name] or {}
			buildstats.count = count
			stats.build_input[name] = buildstats
		end
		for name, count in pairs(force.entity_build_count_statistics.output_counts) do
			local buildstats = stats.build_output[name] or {}
			buildstats.count = count
			stats.build_output[name] = buildstats
		end

		global.output[force.name].production = stats
	end
end

lib.collect_loginet = function ()
	for _, force in pairs(game.forces) do
		---@class RobotStatistics
		---@field all_construction_robots uint
		---@field available_construction_robot uint
		---@field all_logistic_robots uint
		---@field available_logistic_robots uint
		---@field charging_robot_count uint
		---@field to_charge_robot_count uint
		---@field items table<string, uint>
		---@field pickups table<string, uint>
		---@field deliveries table<string, uint>
		local stats = {
			all_construction_robots = 0,
			available_construction_robots = 0,

			all_logistic_robots = 0,
			available_logistic_robots = 0,

			charging_robot_count = 0,
			to_charge_robot_count = 0,

			items = {},
			pickups = {},
			deliveries = {},
		}
		for _, networks in pairs(force.logistic_networks) do
			for _, network in pairs(networks) do
				stats.available_construction_robots = network.available_construction_robots
				stats.all_construction_robots = network.all_construction_robots

				stats.available_logistic_robots = network.available_logistic_robots
				stats.all_logistic_robots = network.all_logistic_robots

				stats.charging_robot_count = 0
				stats.to_charge_robot_count = 0
				for _, cell in pairs(network.cells) do
					stats.charging_robot_count = (stats.charging_robot_count) + cell.charging_robot_count
					stats.to_charge_robot_count = (stats.to_charge_robot_count) + cell.to_charge_robot_count
				end

				if settings.global["graftorio-logistic-items"].value then
					for name, v in pairs(network.get_contents()) do
						stats.items[name] = (stats.items[name] or 0) + v
					end

					-- pickups and deliveries of items
					for _, point_list in pairs({network.provider_points, network.requester_points, network.storage_points}) do
						for _, point in pairs(point_list) do
							for name, qty in pairs(point.targeted_items_pickup) do
								stats.pickups[name] = (stats.pickups[name] or 0) + qty
							end
							for name, qty in pairs(point.targeted_items_deliver) do
								stats.deliveries[name] = (stats.deliveries[name] or 0) + qty
							end
						end
					end
				end
			end
		end
		global.output[force.name].robots = stats
	end
end

---@class ResearchStatistics
---@field current Research
---@field queue Research[]

---@class Research
---@field name string
---@field level uint
---@field progress double

lib.events = {
	[defines.events.on_research_finished] = function (evt)
		local research = evt.research
		if not global.output[research.force.name] then global.output[research.force.name] = {} end
		if not not global.output[research.force.name].other then global.output[research.force.name].other = {} end
		
		local force_research = global.output[research.force.name].other.research
		if not force_research then
			global.output[research.force.name].other.research = {
				current=nil,
				queue={},
			}
			force_research = global.output[research.force.name].other.research
		end
	end,
	[defines.events.on_research_started] = function (evt)
		-- move queue up
		local research = evt.research
		if not global.output[research.force.name] then global.output[research.force.name] = {} end
		if not not global.output[research.force.name].other then global.output[research.force.name].other = {} end

		local force_research = global.output[research.force.name].research
		if not force_research then
			global.output[research.force.name].research = {
				current=nil,
				queue={},
			}
			force_research = global.output[research.force.name].research
		end
	end,
	[defines.events.on_forces_merging] = function (evt)
		
	end
}

lib.on_nth_tick = {
	[60] = function ()
		for _, force in pairs(game.forces) do
			if not global.output[force.name].other then global.output[force.name].other = {} end

			local force_research = global.output[force.name].research
			if not force_research then
				global.output[force.name].research = {
					current=nil,
					queue={},
				}
				force_research = global.output[force.name].research
			end

			force_research.queue = {}
			for _, research in pairs(force.research_queue) do
				table.insert(force_research.queue, {
					name=research.name,
					level=research.level,
					progress=force.get_saved_technology_progress(research) or 0,
				})
			end
			if force_research.queue[1] then force_research.queue[1].progress = force.research_progress end
		end
	end,
}

return lib