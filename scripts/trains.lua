local lib = {}

lib.collect_trains = function ()
	for _, force in pairs(game.forces) do
		local trainstats = {
			total=0,
			moving=0,
			waiting_at_station=0,
			waiting_at_signal=0,
			time_travelling=0
		}
		for _, train in pairs(force.get_trains()) do
			trainstats.total = trainstats.total + 1
			if train.state == defines.train_state.wait_signal then
				trainstats.waiting_at_signal = trainstats.waiting_at_signal + 1
			elseif train.state == defines.train_state.wait_station then
				trainstats.waiting_at_station = trainstats.waiting_at_station + 1
			end
		end
	end
end

return lib