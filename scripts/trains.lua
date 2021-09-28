local lib = {}

lib.collect_trains = function ()
	for _, force in pairs(game.forces) do
		---@class TrainStatistics
		---@field total int
		---@field waiting_time_station int
		---@field waiting_time_signal int
		---@field time_travelling int
		local trainstats = {
			total=0,
			waiting_time_station=0,
			waiting_time_signal=0,
			time_travelling=0,
		}
		for _, train in pairs(force.get_trains()) do
			trainstats.total = trainstats.total + 1
			if train.state == defines.train_state.wait_signal then
				trainstats.waiting_time_signal = trainstats.waiting_time_signal + 1
			elseif train.state == defines.train_state.wait_station then
				trainstats.waiting_time_station = trainstats.waiting_time_station + 1
			end
		end

		if global.trains.data[force.name] then
			for _, train in pairs(global.trains.data[force.name].trains) do
				trainstats.waiting_time_signal = trainstats.waiting_time_signal + train.waiting_time_signal
				trainstats.waiting_time_station = trainstats.waiting_time_station + train.waiting_time_station
				trainstats.time_travelling = trainstats.time_travelling + train.travelling_time
			end
		end

		global.output[force.name].trains = trainstats
	end
end

---@class SavedTrain
---@field id uint
---@field force string
---@field travelling_since uint
---@field travelling_time uint
---@field waiting_since uint
---@field waiting_time_signal uint
---@field waiting_time_station uint
---@field previous_state defines.train_state

---@class SavedStation
---@field position Position
---@field force string
---@field surface SurfaceIdentification
---@field unitnumber uint|nil

---@class ForceTrainStats
---@field stations SavedStation[]
---@field trains SavedTrain[]

---Get a force of a train
---@param train LuaTrain|SavedTrain
---@return string
local function get_train_force(train)
	local name
	if rawget(train, "force") ~= nil then return rawget(train, "force") end -- this is to bypass the typecheck and make it work for SavedTrain
	name = name or (train.locomotives.front_movers and train.locomotives.front_movers[1] and train.locomotives.front_movers[1].force.name)
	name = name or (train.locomotives.back_movers and train.locomotives.back_movers[1] and train.locomotives.back_movers[1].force.name)
	name = name or (train.cargo_wagons[1] and train.cargo_wagons[1].force.name)
	name = name or (train.fluid_wagons[1] and train.fluid_wagons[1].force.name)
	return name
end

---@param train LuaTrain
---@return SavedTrain
local function create_train(train)
	local train_force = get_train_force(train)
	---@type SavedTrain
	local saved_train = {
		id=train.id,
		force=train_force,
		travelling_since=game.tick,
		travelling_time=0,
		waiting_since=game.tick,
		waiting_time_signal=0,
		waiting_time_station=0,
		previous_state=train.state,
	}
	if not global.trains.data[train_force] then
		global.trains.data[train_force] = {
			trains = {},
			stations = {},
		}
	end
	global.trains.data[train_force].trains[train.id] = saved_train
	return saved_train
end

---@param train LuaTrain|SavedTrain
---@return nil
local function remove_train(train)
	global.trains.data[get_train_force(train)].trains[train.id] = nil
end

---@param train LuaTrain
---@return SavedTrain
local function get_saved_train(train)
	local train_force = get_train_force(train)
	local saved_train = global.trains.data[train_force] and global.trains.data[train_force].trains[train.id]
	if not saved_train then
		saved_train = create_train(train)
		global.trains.data[train_force].trains[train.id] = saved_train
	end
	return saved_train
end

---@param id uint
---@return SavedTrain|nil
local function get_saved_train_id(id)
	for _, force in pairs(game.forces) do
		if global.trains.data[force.name] then
			local saved_train = global.trains.data[force.name].trains[id]
			if saved_train then return saved_train end
		end
	end
	return nil
end

---@param train SavedTrain
local function store_saved_train(train)
	global.trains.data[train.force].trains[train.id] = train
end

--- Handle a train arriving at a station
---@param train LuaTrain
---@return SavedTrain
local function train_arrival(train)
	local target_station = train.path_end_stop
	if not target_station then return end
	local train_force = get_train_force(train)
	if not global.trains.data[train_force].stations[serpent.line(target_station.position)] then
		global.trains.data[train_force].stations[serpent.line(target_station.position)] = {
			visitors=0,
			name=target_station.backer_name,
			position=target_station.position,
			surface=target_station.surface.name,
			force=target_station.force.name,
			unitnumber=target_station.unit_number
		}
	end
	local saved_station = global.trains.data[train_force].stations[serpent.line(target_station.position)]
	saved_station.visitors = saved_station.visitors + 1

	local saved_train = global.trains.data[train_force].trains[train.id]
	if not saved_train then
		saved_train = create_train(train)
	end
	return saved_train
end

---Handle a train departing from a station
---@param train LuaTrain
---@return SavedTrain
local function train_departure(train)
	local target_station = train.path_end_stop
	if not target_station then return end
	local train_force = get_train_force(train)
	if not global.trains.data[train_force].stations[serpent.line(target_station.position)] then
		global.trains.data[train_force].stations[serpent.line(target_station.position)] = {
			visitors=0,
			name=target_station.backer_name,
			position=target_station.position,
			surface=target_station.surface.name,
			force=target_station.force.name,
			unitnumber=target_station.unit_number
		}
	end
	local saved_station = global.trains.data[train_force].stations[target_station.backer_name]
	saved_station.visitors = saved_station.visitors + 1

	local saved_train = global.trains.data[train_force].trains[train.id]
	if not saved_train then
		saved_train = create_train(train)
	end
	return saved_train
end

local function on_train_changed_state(event)
	if settings.global["graftorio-train-tracking"].value then
		---@type LuaTrain
		local train = event.train
		local saved_train = get_saved_train(train)
		
		if train.state == defines.train_state.arrive_station then
			train_arrival(train)
		elseif train.state == defines.train_state.on_the_path and event.old_state == defines.train_state.wait_station then
			train_departure(train)
			
			-- stopped waiting at the station, departed
			saved_train.waiting_time_station = saved_train.waiting_time_station + (game.tick - saved_train.waiting_since)
			saved_train.travelling_since = game.tick
		
		-- started waiting
		elseif train.state == defines.train_state.wait_signal then
			saved_train.travelling_time = saved_train.travelling_time + (game.tick - saved_train.travelling_since)
			saved_train.waiting_since = game.tick
		elseif train.state == defines.train_state.wait_station then
			saved_train.travelling_time = saved_train.travelling_time + (game.tick - saved_train.travelling_since)
			saved_train.waiting_since = game.tick
		
		-- stopped waiting at signal
		elseif train.state == defines.train_state.on_the_path and event.old_state == defines.train_state.wait_signal then
			saved_train.waiting_time_signal = saved_train.waiting_time_signal + (game.tick - saved_train.waiting_since)
			saved_train.travelling_since = game.tick
		end
		saved_train.previous_state = train.state

		store_saved_train(saved_train)
	end
end

---Get a LuaTrain from a SavedTrain
---@param saved_train SavedTrain
---@return LuaTrain
local function get_lua_train(saved_train)
	---@type LuaForce
	local force
	for _, game_force in pairs(game.forces) do
		if game_force.name == saved_train.force then force = game_force end
	end
	if not force then error("Force does not exist") end
	for _, train in pairs(force.get_trains()) do
		if train.id == saved_train.id then return train end
	end
end

local function check_trains()
	for _, force in pairs(game.forces) do
		if global.trains.data[force.name] then
			local force_trains = force.get_trains()
			for _, saved_train in pairs(global.trains.data[force.name].trains) do
				local train = force_trains[saved_train.id]
			end
		end
	end
end

---Merge two saved trains
---@param id1 uint
---@param id2 uint
---@param new_train LuaTrain
---@return SavedTrain
local function merge_saved_trains(id1, id2, new_train)
	---@type SavedTrain
	local new_saved_train = create_train(new_train)
	local train1 = get_saved_train_id(id1)
	local train2 = get_saved_train_id(id2)
	new_saved_train.travelling_time = train1.travelling_time + train2.travelling_time
	new_saved_train.waiting_time_signal = train1.waiting_time_signal + train2.waiting_time_signal
	new_saved_train.waiting_time_station = train1.waiting_time_station + train2.waiting_time_station
	remove_train(train1)
	remove_train(train2)

	store_saved_train(new_saved_train)
	return new_saved_train
end

---@param event table
local function on_train_created (event)
	if event.old_train_id_1 and event.old_train_id_2 then
		return merge_saved_trains(event.old_train_id_1, event.old_train_id_2, event.train)
	end
	create_train(event.train)
end

lib.events = {
	[defines.events.on_train_changed_state] = on_train_changed_state,
	[defines.events.on_train_created] = on_train_created,
	[defines.events.on_force_created] = function (evt)
		global.output[evt.force.name].trains = {}
	end,
	[defines.events.on_forces_merging] = function (evt)
		---@type LuaForce
		local old_force = evt.source
		---@type LuaForce
		local destination = evt.destination
		for id, saved_train in global.trains.data[old_force.name].trains do
			global.trains.data[destination.name].trains[id] = table.deep_copy(saved_train)
		end
		for position, saved_station in global.trains.data[old_force.name].stations do
			global.trains.data[destination.name].stations[position] = table.deep_copy(saved_station)
		end
	end
}


lib.on_init = function ()
	for _, force in pairs(game.forces) do
		global.output[force.name].trains = {}
	end

	global.trains = {
		---@type table<string, ForceTrainStats>
		data={},
	}
end

return lib