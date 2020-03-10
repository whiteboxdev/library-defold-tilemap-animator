-- RETURN USER-CREATED ANIMATION GROUPS.

-- Format:    key       = <start_tile> (tilesource number)
--            { value } = <end_tile>   (tilesource number)
--                        <playback>   (animation style)
--                        <step>       (frame duration in seconds)

-- Playbacks: "loop_forward"
--            "loop_backward"
--            "loop_pingpong"
--            "loop_corolla"

return {
	[1]  = { end_tile = 9,  playback = "loop_forward",  step = 1 / 5  },
	[11] = { end_tile = 19, playback = "loop_backward", step = 1 / 5  },
	[21] = { end_tile = 29, playback = "loop_pingpong", step = 1 / 4  },
	[31] = { end_tile = 39, playback = "loop_corolla",  step = 1 / 4  }
}