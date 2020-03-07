local dta = {}

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

dta.animation_groups = {}
dta.tilemap_relative_path = nil
dta.tilemap_layer_ids = {}
dta.tilemap_width = 0
dta.tilemap_height = 0

----------------------------------------------------------------------
-- PLAYBACK FUNCTIONS
----------------------------------------------------------------------

function dta.pb_func_loop_forward(key, value)
	value["frame"] = value["frame"] + 1
	if key + value["frame"] == value["end_tile"] + 1 then
		value["frame"] = 0
	end
end

function dta.pb_func_loop_pingpong(key, value)
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

dta.playback_functions = {
	loop_forward = dta.pb_func_loop_forward,
	loop_pingpong = dta.pb_func_loop_pingpong
}

----------------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------------

function dta.sweep_tile(prev_tile, new_tile)
	for i = 1, #dta.tilemap_layer_ids do
		for j = 1, dta.tilemap_height do
			for k = 1, dta.tilemap_width do
				if tilemap.get_tile(dta.tilemap_relative_path, dta.tilemap_layer_ids[i], k, j) == prev_tile then
					tilemap.set_tile(dta.tilemap_relative_path, dta.tilemap_layer_ids[i], k, j, new_tile)
				end
			end
		end
	end
end

function dta.timer_callback(self, handle, time_elapsed)
	for key, value in pairs(dta.animation_groups) do
		if value["handle"] == handle then
			value["elapsed"] = value["elapsed"] + time_elapsed
			if value["elapsed"] >= value["step"] then
				local prev_tile = key + value["frame"]
				dta.playback_functions[value["playback"]](key, value)
				dta.sweep_tile(prev_tile, key + value["frame"])
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
	dta.extend_animation_groups(animation_groups)
end

return dta