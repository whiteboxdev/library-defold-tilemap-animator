-- RETURN USER-CREATED ANIMATION GROUPS.
-- Format: table
--         key   = start_tile (from tilesource)
--         value = table
--                 [1] = end_tile (from_tilesource)
--                 [2] = playback ("loop_forward", "loop_pingpong")
--                 [3] = step (frame duration in seconds)
return {
	[1] = { end_tile = 4, playback = "loop_forward", step = 1 / 2 },
	[5] = { end_tile = 6, playback = "loop_forward", step = 1 / 2 },
	[7] = { end_tile = 13, playback = "loop_forward", step = 1 / 4 },
	[14] = { end_tile = 18, playback = "loop_forward", step = 1 / 4 },
	[20] = { end_tile = 22, playback = "loop_pingpong", step = 1 / 6 },
	[23] = { end_tile = 31, playback = "loop_pingpong", step = 1 / 6 }
}