local dta = {}

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

dta.animation_groups = {}
dta.tilemap_relative_path = nil
dta.tilemap_layer_ids = {}
dta.tilemap_width = 0
dta.tilemap_height = 0
dta.registrations = {}

dta.loop_playbacks = {
	loop_forward = true,
	loop_pingpong = true,
	loop_corolla = true,
	loop_backward = true
}

----------------------------------------------------------------------
-- PLAYBACK FUNCTIONS
----------------------------------------------------------------------

function dta.pb_func_loop_forward(handle, key, value)
	value["frame"] = value["frame"] + 1
	if key + value["frame"] == value["end_tile"] + 1 then
		value["frame"] = 0
	end
end

function dta.pb_func_loop_pingpong(handle, key, value)
	if value["extra"] == 0 then
		value["frame"] = value["frame"] + 1
		if key + value["frame"] == value["end_tile"] then
			value["extra"] = 1
		end
	elseif value["extra"] == 1 then
		value["frame"] = value["frame"] - 1
		if key + value["frame"] == key then
			value["extra"] = 0
		end
	end
end

function dta.pb_func_loop_corolla(handle, key, value)
	if value["extra"] <= 0 then
		value["extra"] = -value["extra"] + 1
		if key + value["extra"] == value["end_tile"] + 1 then
			value["extra"] = 1
		end
		value["frame"] = value["extra"]
	elseif value["extra"] > 0 then
		value["extra"] = -value["extra"]
		value["frame"] = 0
	end
end

function dta.pb_func_loop_backward(handle, key, value)
	value["frame"] = value["frame"] - 1
	if key + value["frame"] == key - 1 then
		value["frame"] = value["end_tile"] - key
	end
end

dta.playback_functions = {
	loop_forward = dta.pb_func_loop_forward,
	loop_pingpong = dta.pb_func_loop_pingpong,
	loop_corolla = dta.pb_func_loop_corolla,
	loop_backward = dta.pb_func_loop_backward
}

----------------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------------

function dta.sweep_tile(handle, new_tile)
	for i, tile_data in ipairs(dta.registrations[handle]) do
		tilemap.set_tile(dta.tilemap_relative_path, tile_data["layer"], tile_data["x"], tile_data["y"], new_tile)
	end
end

function dta.timer_callback(self, handle, time_elapsed)
	for key, value in pairs(dta.animation_groups) do
		if value["handle"] == handle then
			value["elapsed"] = value["elapsed"] + time_elapsed
			if value["elapsed"] >= value["step"] then
				local prev_tile = key + value["frame"]
				dta.playback_functions[value["playback"]](handle, key, value)
				dta.sweep_tile(handle, key + value["frame"])
				value["elapsed"] = 0
			end
		end
	end
end

function dta.extend_animation_groups()
	for key, value in pairs(dta.animation_groups) do
		value["handle"] = timer.delay(value["step"], true, dta.timer_callback)
		value["frame"] = 0
		value["elapsed"] = 0
		value["extra"] = 0
	end
end

function dta.setup_registrar()
	for key, value in pairs(dta.animation_groups) do
		dta.registrations[value["handle"]] = {}
	end
end

function dta.register_tiles()
	for i = 1, #dta.tilemap_layer_ids do
		for j = 1, dta.tilemap_height do
			for k = 1, dta.tilemap_width do
				local start_tile = tilemap.get_tile(dta.tilemap_relative_path, dta.tilemap_layer_ids[i], k, j)
				if dta.animation_groups[start_tile] ~= nil then
					local data = { layer = dta.tilemap_layer_ids[i], x = k, y = j }
					table.insert(dta.registrations[dta.animation_groups[start_tile]["handle"]], data)
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- USER FUNCTIONS
----------------------------------------------------------------------

function dta.init(animation_groups, tilemap_relative_path, tilemap_layer_ids)
	local x, y, w, h = tilemap.get_bounds(tilemap_relative_path)
	dta.tilemap_relative_path = tilemap_relative_path
	dta.animation_groups = animation_groups
	dta.tilemap_layer_ids = tilemap_layer_ids
	dta.tilemap_width = w
	dta.tilemap_height = h
	dta.extend_animation_groups()
	dta.setup_registrar()
	dta.register_tiles()
end

return dta