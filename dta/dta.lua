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

-- https://github.com/gymratgames/defold-tilemap-animator

----------------------------------------------------------------------
-- DEPENDENCIES
----------------------------------------------------------------------

local dta = {}

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

dta.animation_groups = {}
dta.tilemap_url = nil
dta.tilemap_grid = {}
dta.tilemap_layers = {}
dta.tilemap_start_x = 0
dta.tilemap_start_y = 0
dta.tilemap_end_x = 0
dta.tilemap_end_y = 0
dta.tilemap_width = 0
dta.tilemap_height = 0
dta.msg_passing = false
dta.msg_passing_url = nil
dta.initialized = false

----------------------------------------------------------------------
-- CONSTANT VALUES
----------------------------------------------------------------------

dta.msg = {
	animation_loop_complete = hash("animation_loop_complete"),
	animation_trigger_complete = hash("animation_trigger_complete")
}

----------------------------------------------------------------------
-- VOLATILE FUNCTIONS
----------------------------------------------------------------------

local function timer_callback(self, handle, time_elapsed)
	for key, value in pairs(dta.animation_groups) do
		if value.handle ~= nil then
			if value.handle == handle then
				value.frame = value.frame + 1
				if value.frame > #value.sequence then
					value.frame = 1
					if dta.msg_passing then
						msg.post(dta.msg_passing_url, dta.msg.animation_loop_complete, { tile_id = key })
					end
				end
				for i = 1, #value.instances do
					local instance = value.instances[i]
					tilemap.set_tile(dta.tilemap_url, instance.layer, instance.x, instance.y, value.sequence[value.frame])
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
							tilemap.set_tile(dta.tilemap_url, instance.layer, instance.x, instance.y, key)
						else
							instance.frame = #value.sequence
						end
						timer.cancel(instance.handle)
						instance.handle = nil
						if dta.msg_passing then
							msg.post(dta.msg_passing_url, dta.msg.animation_trigger_complete, { tile_id = key, x = instance.x, y = instance.y, layer = instance.layer })
						end
					else
						tilemap.set_tile(dta.tilemap_url, instance.layer, instance.x, instance.y, value.sequence[instance.frame])
					end
				end
			end
		end
	end
end

local function configure_animation_groups_instances()
	for i = 1, #dta.tilemap_layers do
		dta.tilemap_grid[dta.tilemap_layers[i]] = {}
		for j = dta.tilemap_start_y, dta.tilemap_end_y do
			table.insert(dta.tilemap_grid[dta.tilemap_layers[i]], {})
			for k = dta.tilemap_start_x, dta.tilemap_end_x do
				local tile_id = tilemap.get_tile(dta.tilemap_url, dta.tilemap_layers[i], k, j)
				table.insert(dta.tilemap_grid[dta.tilemap_layers[i]][j], tile_id)
				if dta.animation_groups[tile_id] ~= nil then
					if dta.animation_groups[tile_id].trigger then
						table.insert(dta.animation_groups[tile_id].instances, { x = k, y = j, layer = dta.tilemap_layers[i], frame = 1, handle = nil })
					else
						table.insert(dta.animation_groups[tile_id].instances, { x = k, y = j, layer = dta.tilemap_layers[i] })
					end
				end
			end
		end
	end
end

local function configure_animation_groups()
	for key, value in pairs(dta.animation_groups) do
		if value.trigger then
			value["instances"] = {}
		else
			value["instances"] = {}
			value["frame"] = 1
			value["handle"] = timer.delay(1 / value.frequency, true, timer_callback)
		end
	end
end

function dta.init(animation_groups, tilemap_url, tilemap_layers)
	if dta.initialized then return end
	dta.animation_groups = animation_groups
	dta.tilemap_url = tilemap_url
	dta.tilemap_layers = tilemap_layers
	local x, y, w, h = tilemap.get_bounds(tilemap_url)
	dta.tilemap_start_x = x
	dta.tilemap_start_y = y
	dta.tilemap_end_x = x + w - 1
	dta.tilemap_end_y = y + h - 1
	dta.tilemap_width = w
	dta.tilemap_height = h
	configure_animation_groups()
	configure_animation_groups_instances()
	dta.initialized = true
end

function dta.final()
	if not dta.initialized then return end
	dta.initialized = false
	dta.tilemap_grid = {}
	for key, value in pairs(dta.animation_groups) do
		if value.handle ~= nil then
			timer.cancel(value.handle)
			for i = 1, #value.instances do
				local instance = value.instances[i]
				tilemap.set_tile(dta.tilemap_url, instance.layer, instance.x, instance.y, key)
			end
		else
			for i = 1, #value.instances do
				local instance = value.instances[i]
				if instance.handle ~= nil then
					timer.cancel(instance.handle)
					tilemap.set_tile(dta.tilemap_url, instance.layer, instance.x, instance.y, key)
				end
			end
		end
	end
end

function dta.animate(x, y, layer)
	if not dta.initialized then return end
	if layer ~= nil then
		local tile_id = dta.tilemap_grid[layer][y][x]
		local animation_group = dta.animation_groups[tile_id]
		if animation_group ~= nil and animation_group.trigger then
			for i = 1, #animation_group.instances do
				local instance = animation_group.instances[i]
				if instance.x == x and instance.y == y and instance.layer == layer and instance.handle == nil then
					instance.frame = 1
					instance.handle = timer.delay(1 / animation_group.frequency, true, timer_callback)
					tilemap.set_tile(dta.tilemap_url, layer, x, y, animation_group.sequence[1])
					return
				end
			end
		end
	else
		for i = 1, #dta.tilemap_layers do
			local tile_id = dta.tilemap_grid[dta.tilemap_layers[i]][y][x]
			local animation_group = dta.animation_groups[tile_id]
			if animation_group ~= nil and animation_group.trigger then
				for j = 1, #animation_group.instances do
					local instance = animation_group.instances[j]
					if instance.x == x and instance.y == y and instance.handle == nil then
						instance.frame = 1
						instance.handle = timer.delay(1 / animation_group.frequency, true, timer_callback)
						tilemap.set_tile(dta.tilemap_url, dta.tilemap_layers[i], x, y, animation_group.sequence[1])
						break
					end
				end
			end
		end
	end
end

function dta.toggle_message_passing(flag, url)
	dta.msg_passing = flag
	dta.msg_passing_url = url
end

return dta