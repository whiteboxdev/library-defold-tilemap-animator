# Defold Tilemap Animator

Defold Tilemap Animator provides runtime tile animations in a Defold game engine project.

Please click the ☆ button on GitHub if this repository is useful or interesting. Thank you!

![alt text](https://github.com/whiteboxdev/library-defold-tilemap-animator/blob/master/assets/thumbnail.png?raw=true)

## Installation

Add the latest version to your project's dependencies:  
https://github.com/whiteboxdev/library-defold-tilemap-animator/archive/master.zip

## Configuration

Import the dtile Lua module into any script:
`local dtile = require "dtile.dtile"`

Instead of defining tile animations in Defold's `tilesource` file, dtile requires you to define your own tile animations in table format:

```
local animation_groups = {
    [<tile_id>] = { sequence = { <tile_id_1>, <tile_id_2>, ... }, trigger = <boolean>, frequency = <value>, reset = <boolean> },
    ...
}
```

1. `tile_id`: Tile id which begins your animation. This value can be found by hovering over the respective tile in your tilesource file.
2. `sequence`: Table defining this animation sequence. This allows you to create custom animation sequences, rather than being forced to conform to presets.
3. `trigger`: Indicates that this is a *trigger* animation rather than a *loop* animation. Trigger animations can be activated by a script at any time and roll exactly once.
4. `frequency`: Animation speed measured in `sequence` frames per second.
5. `reset`: *Only needed if this is a trigger animation.* Indicates that this animation should regain its start tile graphic on completion. Otherwise, this animation will quit rolling once the final `sequence` frame has been reached.

Each animation you wish to create should be added as an entry in the `animation_groups` table.

You are ready to initialize dtile. Call `dtile.init()` in your script:

```
local dtile = require "dtile.dtile"

local animation_groups = { ... }

function init(self, dt)
    dtile.init(animation_groups, <tilemap_url>, <layers>)
    dtile.toggle_message_passing(true, msg.url())
end
```

1. `animation_groups`: Table of tile animations explained above.
2. `tilemap_url`: URL to the animated tilemap.
3. `layers`: Table of hashed tilemap layer ids. For example: `{ hash("background"), hash("midground)", hash("foreground") }`.

If you wish to receive animation progress updates in your `on_message()` function, call `dtile.toggle_message_passing()`. This feature is set to `false` by default. If set to true, also pass in a URL to the script that will receive dtile messages.

dtile will now begin animating your tilemap. Of course, only loop tiles will show any activity. To animate a trigger tile, call `dtile.animate()`.

If you would like to cancel all animations--both loops and triggers--call `dtile.final()`. To start animating again, call `dtile.init()`.

## API: Properties

### dtile.msg

Table for referencing messages posted to your script's `on_message()` function:

```
dtile.msg =
{
    animation_loop_complete = hash("animation_loop_complete"),
    animation_trigger_complete = hash("animation_trigger_complete")
}
```

1. `animation_loop_complete`: Posted when a `trigger = false` animation group completes its `sequence`. The `message.tile_id` field contains the tile id which begins this animation sequence.
2. `animation_trigger_complete`: Posted when a trigger tile completes its `sequence`. The `message.tile_id` field contains the tile id which begins this animation sequence. The `message.x`, `message.y`, and `message.layer` fields contain this tile's `x` position, `y` position, and hashed `layer` id on the tilemap.

## API: Functions

### dtile.init(animation_groups, tilemap_url, tilemap_layers)

Initializes dtile. Must be called in order to begin animating tiles.

#### Parameters
1. `animation_groups`: Table defining your custom animation groups.
    1. `tile_id`: Tile id which begins your animation.
    2. `sequence`: Table defining this animation sequence.
    3. `trigger`: Indicates that this is a trigger animation rather than a loop animation.
    4. `frequency`: Animation speed measured in `sequence` frames per second.
    5. `reset`: Indicates that this animation should regain its start tile graphic on completion. *Only needed if this is a trigger animation.*
2. `tilemap_url`: URL to the animated tilemap.
3. `layers`: Table of hashed tilemap layer ids.

The format for the `animation_groups` table is as follows:

```
local animation_groups =
{
    [<tile_id>] = { sequence = { <tile_id_1>, <tile_id_2>, ... }, trigger = <boolean>, frequency = <value>, reset = <boolean> },
    ...
}
```

---

### dtile.final()

Cancels all loop and trigger animations and disables all animation functions. This is useful when transitioning between tilemaps, among other cases.

---

### dtile.animate(x, y, layer)

Activates a trigger animation. Does nothing if a trigger animation is not assigned to the specified tile.

#### Parameters
1. `x`: X-coordinate of tile.
2. `y`: Y-coordinate of tile.
3. `layer`: Hashed tilemap layer id of tile.

If you do not specify a `layer`, then dtile will activate all trigger animations at `[x, y]` regardless of layer.

---

### dtile.reset(x, y, layer)

Resets a trigger animation to its first frame. Does nothing if a trigger animation is not assigned to the specified tile.

#### Parameters
1. `x`: X-coordinate of tile.
2. `y`: Y-coordinate of tile.
3. `layer`: Hashed tilemap layer id of tile.

If you do not specify a `layer`, then dtile will reset all trigger animations at `[x, y]` regardless of layer.

---

### dtile.get_tile(x, y, layer)

Gets a tile in the loaded tilemap.

**Note:** This is a replacement for Defold's built-in [tilemap.get_tile()](https://defold.com/ref/tilemap/#tilemap.get_tile:url-layer-x-y). This function accounts for animations.

#### Parameters
1. `x`: X-coordinate of tile.
2. `y`: Y-coordinate of tile.
3. `layer`: Hashed tilemap layer id of tile.

If you do not specify a `layer`, then dtile will return a table containing the tile at `[x, y]` in each layer:

```
{
    [<layer>] = <tile_id>,
    ...
}
```

#### Returns

Returns a tile id or a table of tile ids.

Even if the tile is playing an animation, the first frame is returned. For example, a flower tile is animated across three frames and therefore three tile ids:

```
flower_sequence = [ tile_id = 1, tile_id = 2, tile_id = 3 ]
current_tile_id = 2 // The flower animation is on its second frame.
dtile.get_tile(<flower>) // Returns '1'.
```

To get the actual current tile id instead of the first frame, use [tilemap.get_tile()](https://defold.com/ref/tilemap/#tilemap.get_tile:url-layer-x-y).

---

### dtile.set_tile(layer, x, y, tile, h_flipped, v_flipped)

Replaces a tile in the loaded tilemap with a new tile.

**Note:** This is a replacement for Defold's built-in [tilemap.set_tile()](https://defold.com/ref/tilemap/#tilemap.set_tile:url-layer-x-y-tile-[h-flipped]-[v-flipped]). This function accounts for animations.

#### Parameters

See [tilemap.set_tile()](https://defold.com/ref/tilemap/#tilemap.set_tile:url-layer-x-y-tile-[h-flipped]-[v-flipped]).

---

### dtile.has_trigger_animation(tile_id)

Checks if a trigger animation is assigned to the specified `tile_id`.

#### Parameters

1. `tile_id`: Tile id number.

#### Returns

Returns a `bool`.

---

### dtile.toggle_message_passing(flag, url)

Toggles dtile's ability to post animation update messages to your script's `on_message()` function.

#### Parameters
1. `flag`: Boolean indicating whether to post messages.
2. `url`: URL to the script that should receive messages.
