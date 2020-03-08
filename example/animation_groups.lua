-- RETURN USER-CREATED ANIMATION GROUPS.

-- Format:
--            key   = start_tile     (tilesource number)
--            value =
--                    [1] = end_tile (tilesource number)
--                    [2] = playback (animation style)
--                    [3] = step     (frame duration in seconds)

-- Playbacks:
--            "loop_forward"
--            "loop_backward"
--            "loop_pingpong"
--            "loop_corolla"

return {
	[1]  = { end_tile = 4,  playback = "loop_corolla",  step = 1 / 3 },
	[5]  = { end_tile = 6,  playback = "loop_forward",  step = 1 / 1 },
	[7]  = { end_tile = 13, playback = "loop_forward",  step = 1 / 5 },
	[14] = { end_tile = 18, playback = "loop_forward",  step = 1 / 4 },
	[20] = { end_tile = 22, playback = "loop_pingpong", step = 1 / 2 },
	[23] = { end_tile = 31, playback = "loop_backward", step = 1 / 6 },
	--[33] = { end_tile = 40, playback = "once_forward",  step = 1 / 2 },
	--[41] = { end_tile = 48, playback = "once_forward",  step = 1 / 2 }
}