-- MIT License

-- Copyright (c) 2020 Klayton Kowalski

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

----------------------------------------------------------------------
-- DEPENDENCIES
----------------------------------------------------------------------

local dta = {}

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

dta.animation_groups      = {}
dta.animation_groups_loop = {}
dta.animation_groups_once = {}

dta.tilemap_relative_path = nil
dta.tilemap_layer_ids     = {}
dta.tilemap_start_x       = 0
dta.tilemap_start_y       = 0
dta.tilemap_width         = 0
dta.tilemap_height        = 0
dta.tilemap_tiles         = {}

----------------------------------------------------------------------
-- PLAYBACKS
----------------------------------------------------------------------

function dta.loop_forward(data)
	data["frame"] = data["frame"] + 1
	if data["frame"] > data["end_tile"] then
		data["frame"] = data["start_tile"]
	end
end

function dta.loop_backward(data)
	data["frame"] = data["frame"] - 1
	if data["frame"] < data["start_tile"] then
		data["frame"] = data["end_tile"]
	end
end

function dta.loop_pingpong(data)
	if data["extra"] == 0 then
		data["frame"] = data["frame"] + 1
		if data["frame"] > data["end_tile"] then
			data["frame"] = data["end_tile"] - 1
			data["extra"] = 1
		end
	else
		data["frame"] = data["frame"] - 1
		if data["frame"] < data["start_tile"] then
			data["frame"] = data["start_tile"] + 1
			data["extra"] = 0
		end
	end
end

function dta.loop_corolla(data)
	if data["extra"] > 0 then
		data["extra"] = -data["extra"]
		data["frame"] = data["start_tile"]
	else
		data["extra"] = -data["extra"] + 1
		data["frame"] = data["start_tile"] + data["extra"]
		if data["frame"] > data["end_tile"] then
			data["frame"] = data["start_tile"] + 1
			data["extra"] = 1
		end
	end
end

function dta.once_forward(data, instance_data)
	instance_data["frame"] = instance_data["frame"] + 1
	if instance_data["frame"] > data["end_tile"] then
		instance_data["frame"] = data["start_tile"]
		instance_data["extra"] = 9999
	end
end

function dta.once_backward(data, instance_data)
	instance_data["frame"] = instance_data["frame"] - 1
	if instance_data["frame"] <= data["start_tile"] then
		instance_data["frame"] = data["start_tile"]
		instance_data["extra"] = 9999
	end
end

function dta.once_pingpong(data, instance_data)
	if instance_data["extra"] == 0 then
		instance_data["frame"] = instance_data["frame"] + 1
		if instance_data["frame"] > data["end_tile"] then
			instance_data["frame"] = data["end_tile"] - 1
			instance_data["extra"] = 1
		end
	else
		instance_data["frame"] = instance_data["frame"] - 1
		if instance_data["frame"] <= data["start_tile"] then
			instance_data["frame"] = data["start_tile"]
			instance_data["extra"] = 9999
		end
	end
end

function dta.once_corolla(data, instance_data)
	if instance_data["extra"] > 0 then
		instance_data["extra"] = -instance_data["extra"]
		instance_data["frame"] = data["start_tile"]
		if data["start_tile"] - instance_data["extra"] >= data["end_tile"] then
			instance_data["extra"] = 9999
		end
	else
		instance_data["extra"] = -instance_data["extra"] + 1
		instance_data["frame"] = data["start_tile"] + instance_data["extra"]
	end
end

dta.playbacks_loop = {
	loop_forward  = dta.loop_forward,
	loop_backward = dta.loop_backward,
	loop_pingpong = dta.loop_pingpong,
	loop_corolla  = dta.loop_corolla
}

dta.playbacks_once = {
	once_forward  = dta.once_forward,
	once_backward = dta.once_backward,
	once_pingpong = dta.once_pingpong,
	once_corolla  = dta.once_corolla
}

----------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------

function dta.ternary(condition, ret_true, ret_false)
	return condition and ret_true or ret_false
end

function dta.set_tile_once(start_tile, frame, tile_pos)
	local data = dta.tilemap_tiles[start_tile][tile_pos]
	tilemap.set_tile(dta.tilemap_relative_path, data["layer_id"], data["x"], data["y"], frame)
end

function dta.timer_callback_once(self, handle, time_elapsed)
	for start_tile, data in pairs(dta.animation_groups_once) do
		local instance_data = data["instances"][handle]
		if instance_data ~= nil then
			instance_data["elapsed"] = instance_data["elapsed"] + time_elapsed
			if instance_data["elapsed"] >= data["step"] then
				instance_data["elapsed"] = 0
				dta.playbacks_once[data["playback"]](data, instance_data)
				dta.set_tile_once(start_tile, instance_data["frame"], instance_data["tile_pos"])
				if instance_data["extra"] == 9999 then
					timer.cancel(handle)
					data["instances"][handle] = nil
				end
			end
		end
	end
end

function dta.configure_animation_groups_once()
	for start_tile, data in pairs(dta.animation_groups) do
		if dta.playbacks_once[data["playback"]] ~= nil then
			dta.animation_groups_once[start_tile] = { start_tile = start_tile, end_tile = data["end_tile"], playback = data["playback"], step = data["step"], instances = {} }
		end
	end
end

function dta.set_tile_loop(start_tile, frame)
	for position, data in pairs(dta.tilemap_tiles[start_tile]) do
		tilemap.set_tile(dta.tilemap_relative_path, data["layer_id"], data["x"], data["y"], frame)
	end
end

function dta.timer_callback_loop(self, handle, time_elapsed)
	for start_tile, data in pairs(dta.animation_groups_loop) do
		if data["handle"] == handle then
			data["elapsed"] = data["elapsed"] + time_elapsed
			if data["elapsed"] >= data["step"] then
				data["elapsed"] = 0
				dta.playbacks_loop[data["playback"]](data)
				if dta.tilemap_tiles[start_tile] ~= nil then
					dta.set_tile_loop(start_tile, data["frame"])
				end
			end
		end
	end
end

function dta.configure_animation_groups_loop()
	for start_tile, data in pairs(dta.animation_groups) do
		if dta.playbacks_loop[data["playback"]] ~= nil then
			local handle = timer.delay(data["step"], true, dta.timer_callback_loop)
			local frame = dta.ternary(data["playback"] == "loop_backward", data["end_tile"], start_tile)
			dta.animation_groups_loop[start_tile] = { start_tile = start_tile, end_tile = data["end_tile"], playback = data["playback"], step = data["step"], handle = handle, frame = frame, elapsed = 0, extra = 0 }
		end
	end
end

function dta.configure_animation_groups()
	dta.configure_animation_groups_loop()
	dta.configure_animation_groups_once()
end

function dta.configure_tilemap_tiles()
	local map_length_x = dta.tilemap_start_x + dta.tilemap_width - 1
	local map_length_y = dta.tilemap_start_y + dta.tilemap_height - 1
	for i = 1, #dta.tilemap_layer_ids do
		for j = dta.tilemap_start_y, map_length_y do
			for k = dta.tilemap_start_x, map_length_x do
				local start_tile = tilemap.get_tile(dta.tilemap_relative_path, dta.tilemap_layer_ids[i], k, j)
				if dta.animation_groups[start_tile] ~= nil then
					local data = { start_tile = start_tile, layer_id = dta.tilemap_layer_ids[i], x = k, y = j }
					if dta.tilemap_tiles[start_tile] == nil then
						dta.tilemap_tiles[start_tile] = {}
					end
					dta.tilemap_tiles[start_tile][k + (j - 1) * dta.tilemap_width] = data
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- USER FUNCTIONS
----------------------------------------------------------------------

function dta.init(animation_groups, tilemap_relative_path, tilemap_layer_ids)
	dta.animation_groups = animation_groups
	dta.configure_animation_groups()
	local x, y, w, h = tilemap.get_bounds(tilemap_relative_path)
	dta.tilemap_relative_path = tilemap_relative_path
	dta.tilemap_layer_ids = tilemap_layer_ids
	dta.tilemap_start_x = x
	dta.tilemap_start_y = y
	dta.tilemap_width = w
	dta.tilemap_height = h
	dta.configure_tilemap_tiles()
end

function dta.animate(tile_x, tile_y)
	for i = 1, #dta.tilemap_layer_ids do
		local tile = tilemap.get_tile(dta.tilemap_relative_path, dta.tilemap_layer_ids[i], tile_x, tile_y)
		if dta.animation_groups_once[tile] ~= nil then
			local handle = timer.delay(dta.animation_groups_once[tile]["step"], true, dta.timer_callback_once)
			local frame = dta.ternary(dta.animation_groups_once[tile]["playback"] == "once_backward", dta.animation_groups_once[tile]["end_tile"], tile + 1)
			local tile_pos = tile_x + (tile_y - 1) * dta.tilemap_width
			local data = { handle = handle, frame = frame, elapsed = 0, extra = 0, tile_pos = tile_pos }
			dta.animation_groups_once[tile]["instances"][handle] = data
			tilemap.set_tile(dta.tilemap_relative_path, dta.tilemap_layer_ids[i], tile_x, tile_y, frame)
		end
	end
end

return dta