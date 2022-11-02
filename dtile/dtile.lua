----------------------------------------------------------------------
-- LICENSE
----------------------------------------------------------------------

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

-- https://github.com/klaytonkowalski/defold-tilemap-animator

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

local dtile = {}

dtile.animation_groups = {}
dtile.tilemap_url = nil
dtile.tilemap_grid = {}
dtile.tilemap_layers = {}
dtile.tilemap_start_x = 0
dtile.tilemap_start_y = 0
dtile.tilemap_end_x = 0
dtile.tilemap_end_y = 0
dtile.tilemap_width = 0
dtile.tilemap_height = 0
dtile.msg_passing = false
dtile.msg_passing_url = nil
dtile.initialized = false

dtile.msg = {
	animation_loop_complete = hash("animation_loop_complete"),
	animation_trigger_complete = hash("animation_trigger_complete")
}

----------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------

local function timer_callback(self, handle, time_elapsed)
	for key, value in pairs(dtile.animation_groups) do
		if value.handle ~= nil then
			if value.handle == handle then
				value.frame = value.frame + 1
				if value.frame > #value.sequence then
					value.frame = 1
					if dtile.msg_passing then
						msg.post(dtile.msg_passing_url, dtile.msg.animation_loop_complete, { tile_id = key })
					end
				end
				for i = 1, #value.instances do
					local instance = value.instances[i]
					tilemap.set_tile(dtile.tilemap_url, instance.layer, instance.x, instance.y, value.sequence[value.frame])
				end
				return
			end
		else
			for i = 1, #value.instances do
				local instance = value.instances[i]
				if instance.handle == handle then
					instance.frame = instance.frame + 1
					if instance.frame > #value.sequence then
						if value.reset then
							instance.frame = 1
							tilemap.set_tile(dtile.tilemap_url, instance.layer, instance.x, instance.y, key)
						else
							instance.frame = #value.sequence
						end
						timer.cancel(instance.handle)
						instance.handle = nil
						if dtile.msg_passing then
							msg.post(dtile.msg_passing_url, dtile.msg.animation_trigger_complete, { tile_id = key, x = instance.x, y = instance.y, layer = instance.layer })
						end
					else
						tilemap.set_tile(dtile.tilemap_url, instance.layer, instance.x, instance.y, value.sequence[instance.frame])
					end
				end
			end
		end
	end
end

local function configure_animation_groups_instances()
	for i = 1, #dtile.tilemap_layers do
		dtile.tilemap_grid[dtile.tilemap_layers[i]] = {}
		for j = dtile.tilemap_start_y, dtile.tilemap_end_y do
			table.insert(dtile.tilemap_grid[dtile.tilemap_layers[i]], {})
			for k = dtile.tilemap_start_x, dtile.tilemap_end_x do
				local tile_id = tilemap.get_tile(dtile.tilemap_url, dtile.tilemap_layers[i], k, j)
				table.insert(dtile.tilemap_grid[dtile.tilemap_layers[i]][j], tile_id)
				if dtile.animation_groups[tile_id] ~= nil then
					if dtile.animation_groups[tile_id].trigger then
						table.insert(dtile.animation_groups[tile_id].instances, { x = k, y = j, layer = dtile.tilemap_layers[i], frame = 1, handle = nil })
					else
						table.insert(dtile.animation_groups[tile_id].instances, { x = k, y = j, layer = dtile.tilemap_layers[i] })
					end
				end
			end
		end
	end
end

local function configure_animation_groups()
	for key, value in pairs(dtile.animation_groups) do
		if value.trigger then
			value["instances"] = {}
		else
			value["instances"] = {}
			value["frame"] = 1
			value["handle"] = timer.delay(1 / value.frequency, true, timer_callback)
		end
	end
end

function dtile.init(animation_groups, tilemap_url, tilemap_layers)
	if dtile.initialized then return end
	dtile.animation_groups = animation_groups
	dtile.tilemap_url = tilemap_url
	dtile.tilemap_layers = tilemap_layers
	local x, y, w, h = tilemap.get_bounds(tilemap_url)
	dtile.tilemap_start_x = x
	dtile.tilemap_start_y = y
	dtile.tilemap_end_x = x + w - 1
	dtile.tilemap_end_y = y + h - 1
	dtile.tilemap_width = w
	dtile.tilemap_height = h
	configure_animation_groups()
	configure_animation_groups_instances()
	dtile.initialized = true
end

function dtile.cleanup()
	if not dtile.initialized then return end
	dtile.initialized = false
	dtile.tilemap_grid = {}
	for key, value in pairs(dtile.animation_groups) do
		if value.handle ~= nil then
			timer.cancel(value.handle)
			for i = 1, #value.instances do
				local instance = value.instances[i]
				tilemap.set_tile(dtile.tilemap_url, instance.layer, instance.x, instance.y, key)
			end
		else
			for i = 1, #value.instances do
				local instance = value.instances[i]
				if instance.handle ~= nil then
					timer.cancel(instance.handle)
					tilemap.set_tile(dtile.tilemap_url, instance.layer, instance.x, instance.y, key)
				end
			end
		end
	end
end

function dtile.animate(x, y, layer)
	if not dtile.initialized then return end
	if layer ~= nil then
		local tile_id = dtile.tilemap_grid[layer][y][x]
		local animation_group = dtile.animation_groups[tile_id]
		if animation_group ~= nil and animation_group.trigger then
			for i = 1, #animation_group.instances do
				local instance = animation_group.instances[i]
				if instance.x == x and instance.y == y and instance.layer == layer and instance.handle == nil then
					instance.frame = 1
					instance.handle = timer.delay(1 / animation_group.frequency, true, timer_callback)
					tilemap.set_tile(dtile.tilemap_url, layer, x, y, animation_group.sequence[1])
					return
				end
			end
		end
	else
		for i = 1, #dtile.tilemap_layers do
			local tile_id = dtile.tilemap_grid[dtile.tilemap_layers[i]][y][x]
			local animation_group = dtile.animation_groups[tile_id]
			if animation_group ~= nil and animation_group.trigger then
				for j = 1, #animation_group.instances do
					local instance = animation_group.instances[j]
					if instance.x == x and instance.y == y and instance.handle == nil then
						instance.frame = 1
						instance.handle = timer.delay(1 / animation_group.frequency, true, timer_callback)
						tilemap.set_tile(dtile.tilemap_url, dtile.tilemap_layers[i], x, y, animation_group.sequence[1])
						break
					end
				end
			end
		end
	end
end

function dtile.get_tile(x, y, layer)
	if not dtile.initialized then return end
	if layer then
		return dtile.tilemap_grid[layer][y][x]
	else
		local result = {}
		for i = 1, #dtile.tilemap_layers do
			local tile_id = dtile.tilemap_grid[dtile.tilemap_layers[i]][y][x]
			result[dtile.tilemap_layers[i]] = tile_id
		end
		return result
	end
end

function dtile.set_tile(layer, x, y, tile, h_flipped, v_flipped)
	if not dtile.initialized then return end
	local group = dtile.animation_groups[dtile.tilemap_grid[layer][y][x]]
	if group ~= nil then
		for i = 1, #group.instances do
			if group.instances[i].x == x and group.instances[i].y == y and group.instances[i].layer then
				if group.trigger then
					if group.instances[i].handle ~= nil then
						timer.cancel(group.instances[i].handle)
					end
				end
				table.remove(group.instances, i)
				break
			end
		end
	end
	tilemap.set_tile(dtile.tilemap_url, layer, x, y, tile, h_flipped, v_flipped)
	dtile.tilemap_grid[layer][y][x] = tile
	if dtile.animation_groups[tile] ~= nil then
		if dtile.animation_groups[tile].trigger then
			table.insert(dtile.animation_groups[tile].instances, { x = x, y = y, layer = layer, frame = 1, handle = nil })
		else
			table.insert(dtile.animation_groups[tile].instances, { x = x, y = y, layer = layer })
		end
	end
end

function dtile.toggle_message_passing(flag, url)
	dtile.msg_passing = flag
	dtile.msg_passing_url = url
end

return dtile