local lib = {}

lib.collect_production = function ()
	for _, force in pairs(game.forces) do
		if not global.stats[force.name] then global.stats[force.name] = {} end
		local stats = global.stats[force.name].production or {
			item_input = {},
			item_output = {},
			fluid_input = {},
			fluid_output = {},
		}
		for name, amount in pairs(force.item_production_statistics.input_counts) do
			local itemstats = stats.item_input[name] or {
				count=amount,
			}
			stats.item_input[name] = itemstats
		end
		for name, amount in pairs(force.item_production_statistics.output_counts) do
			local itemstats = stats.item_output[name] or {
				count=amount,
			}
			stats.item_output[name] = itemstats
		end

		for name, amount in pairs(force.fluid_production_statistics.input_counts) do
			local fluidstats = stats.fluid_input[name] or {
				count=amount,
			}
			stats.fluid_input[name] = fluidstats
		end

		for name, amount in pairs(force.fluid_production_statistics.output_counts) do
			local fluidstats = stats.fluid_output[name] or {
				count=amount,
			}
			stats.fluid_output[name] = fluidstats
		end
		global.stats[force.name].production = stats
	end
end

lib.collect_loginet = function ()
	for _, force in pairs(game.forces) do
		local stats = global.stats[force.name].robots or {
			all_construction_bots = 0,
			available_construction_bots = 0,

			all_logistic_robots = 0,
			available_logistic_robots = 0,

			charging_robot_count = 0,
			to_charge_robot_count = 0,

			items = {},
			pickups = {},
			deliveries = {},
		}
		for _, network in pairs(force.logistic_networks) do
			log(network.available_construction_bots)
			stats.available_construction_bots = (stats.available_construction_bots or 0) + network.available_construction_bots
			stats.all_construction_robots = (stats.all_construction_robots or 0) + network.all_construction_robots

			stats.available_logistic_robots = (stats.available_logistic_robots or 0) + network.available_logistic_robots
			stats.all_logistic_robots = (stats.all_logistic_robots or 0) + network.all_logistic_robots

			for _, cell in pairs(network.cells) do
				stats.charging_robot_count = (stats.charging_robot_count or 0) + cell.charging_robot_count
				stats.to_charge_robot_count = (stats.to_charge_robot_count or 0) + cell.to_charge_robot_count
			end

			if settings.runtime["graftorio-logistic-items"].value then
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
		global.stats[force.name] = stats
	end
end

lib.events = {
	[defines.events.on_research_finished] = function (evt)
		local research = evt.research
		local force_research = global.stats[research.force.name].research
		if not force_research then
			global.stats[research.force.name].research = {
				current=nil,
				queue={},
			}
		end

		force_research.current = nil
	end,
	[defines.events.on_research_started] = function (evt)
		-- move queue up
		local research = evt.research
		local force_research = global.stats[research.force.name].research
		if not force_research then
			global.stats[research.force.name].research = {
				current=nil,
				queue={},
			}
		end

		if force_research.queue[1] then
			force_research.current = force_research.queue[1]
			table.remove(force_research.queue, 1)
		else
			force_research.current = {
				name=research.name,
				level = research.level,
				progress=0
			}
		end
	end
}
lib.on_nth_tick = {
	[settings.startup["graftorio-checking-rate"].value*60] = function ()
		for _, force in pairs(game.forces) do
			local force_research = global.stats[research.force.name].research
			if not force_research then
				global.stats[research.force.name].research = {
					current=nil,
					queue={},
				}
			end

			force_research.queue = {}
			for _, research in force.research_queue do
				table.insert(force_research.queue, {
					name=research.name,
					level=research.level,
					progress=force.get_saved_technology_progress(research),
				})
			end
			force_research.current = {
				name=force.current_research.name,
				level=force.current_research.level,
				progress=force.get_saved_technology_progress(force.current_research),
			}
		end
	end,
}

return lib