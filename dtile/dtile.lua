--------------------------------------------------------------------------------
-- LICENSE
--------------------------------------------------------------------------------

-- Copyright (c) 2024 Klayton Kowalski

-- This software is provided 'as-is', without any express or implied warranty.
-- In no event will the authors be held liable for any damages arising from the use of this software.

-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it freely,
-- subject to the following restrictions:

-- 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
--    If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.

-- 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.

-- 3. This notice may not be removed or altered from any source distribution.

--------------------------------------------------------------------------------
-- INFORMATION
--------------------------------------------------------------------------------

-- https://github.com/whiteboxdev/library-defold-tilemap-animator

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

dtile.msg =
{
	animation_loop_complete = hash("animation_loop_complete"),
	animation_trigger_complete = hash("animation_trigger_complete")
}

----------------------------------------------------------------------
-- LOCAL FUNCTIONS
----------------------------------------------------------------------

local function timer_callback(self, handle, time_elapsed)
	for key, value in pairs(dtile.animation_groups) do
		if value.handle then
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
				if dtile.animation_groups[tile_id] then
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

----------------------------------------------------------------------
-- MODULE FUNCTIONS
----------------------------------------------------------------------

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

function dtile.final()
	if not dtile.initialized then return end
	dtile.initialized = false
	dtile.tilemap_grid = {}
	for key, value in pairs(dtile.animation_groups) do
		if value.handle then
			timer.cancel(value.handle)
			for i = 1, #value.instances do
				local instance = value.instances[i]
				tilemap.set_tile(dtile.tilemap_url, instance.layer, instance.x, instance.y, key)
			end
		else
			for i = 1, #value.instances do
				local instance = value.instances[i]
				if instance.handle then
					timer.cancel(instance.handle)
					tilemap.set_tile(dtile.tilemap_url, instance.layer, instance.x, instance.y, key)
				end
			end
		end
	end
end

function dtile.animate(x, y, layer)
	if not dtile.initialized then return end
	if layer then
		local tile_id = dtile.tilemap_grid[layer][y][x]
		local animation_group = dtile.animation_groups[tile_id]
		if animation_group and animation_group.trigger then
			for i = 1, #animation_group.instances do
				local instance = animation_group.instances[i]
				if instance.x == x and instance.y == y and instance.layer == layer and not instance.handle then
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
			if animation_group and animation_group.trigger then
				for j = 1, #animation_group.instances do
					local instance = animation_group.instances[j]
					if instance.x == x and instance.y == y and not instance.handle then
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

function dtile.reset(x, y, layer)
	if not dtile.initialized then return end
	if layer then
		local tile_id = dtile.tilemap_grid[layer][y][x]
		local animation_group = dtile.animation_groups[tile_id]
		if animation_group and animation_group.trigger then
			for i = 1, #animation_group.instances do
				local instance = animation_group.instances[i]
				if instance.x == x and instance.y == y and instance.layer == layer then
					if instance.handle then
						timer.cancel(instance.handle)
						instance.handle = nil
					end
					instance.frame = 1
					tilemap.set_tile(dtile.tilemap_url, layer, x, y, animation_group.sequence[1])
					return
				end
			end
		end
	else
		for i = 1, #dtile.tilemap_layers do
			local tile_id = dtile.tilemap_grid[dtile.tilemap_layers[i]][y][x]
			local animation_group = dtile.animation_groups[tile_id]
			if animation_group and animation_group.trigger then
				for j = 1, #animation_group.instances do
					local instance = animation_group.instances[j]
					if instance.x == x and instance.y == y then
						if instance.handle then
							timer.cancel(instance.handle)
							instance.handle = nil
						end
						instance.frame = 1
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
	if group then
		for i = 1, #group.instances do
			if group.instances[i].x == x and group.instances[i].y == y and group.instances[i].layer then
				if group.trigger then
					if group.instances[i].handle then
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
	if dtile.animation_groups[tile] then
		if dtile.animation_groups[tile].trigger then
			table.insert(dtile.animation_groups[tile].instances, { x = x, y = y, layer = layer, frame = 1, handle = nil })
		else
			table.insert(dtile.animation_groups[tile].instances, { x = x, y = y, layer = layer })
		end
	end
end

function dtile.has_trigger_animation(tile_id)
	return dtile.animation_groups[tile_id] and dtile.animation_groups[tile_id].trigger or false
end

function dtile.toggle_message_passing(flag, url)
	dtile.msg_passing = flag
	dtile.msg_passing_url = url
end

return dtile