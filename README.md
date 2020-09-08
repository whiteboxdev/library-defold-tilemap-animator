# Defold Tilemap Animator
Defold Tilemap Animator (DTA) 0.1.0 provides runtime tile animations in a Defold game engine project. This includes both looping animations and trigger animations.

Visit [my website](https://gymratgames.github.io/html/extensions.html#dta) to see an animated gif of the example project.  
An [example project](https://github.com/gymratgames/defold-tilemap-animator/tree/master/example) is available if you need additional help with configuration.

Please click the "Star" button on GitHub if you find this asset to be useful!  
Consider supporting me on [Patreon](https://www.patreon.com/klaytonkowalski) if you like my work.

![alt text](https://github.com/gymratgames/defold-tilemap-animator/blob/master/assets/thumbnail.png?raw=true)

## Installation
To install DTA into your project, add one of the following links to your `game.project` dependencies:
  - https://github.com/gymratgames/defold-tilemap-animator/archive/master.zip
  - URL of a [specific release](https://github.com/gymratgames/defold-tilemap-animator/releases)

## Configuration
Import the DTA Lua module into any script:
`local dta = require "dta.dta"`

Instead of defining tile animations in Defold's `tilesource` file, DTA requires you to define your own tile animations in table format:

```
local animation_groups = {
    [<tile_id>] = { sequence = { <tile_id_1>, <tile_id_2>, ... }, trigger = <boolean>, frequency = <value> },
    ...
}
```

1. `tile_id`: Tile id which begins your animation. This value can be found by hovering over the respective tile in your `tilesource` file.
2. `sequence`: Table defining this animation sequence. This allows you to create custom animation sequences, rather than being forced to conform to presets.
3. `trigger`: Indicates that this is a *trigger* animation rather than a *loop* animation. Trigger animations can be activated by a script at any time and only roll once.
4. `frequency`: Animation speed measured in `sequence` frames per second.

Each animation you wish to create should be added as an entry in the `animation_groups` table. **Note** that tiles assigned to a trigger animation will regain their starting graphic (defined by `[<tile_id>]`) rather than lingering on their final `sequence` frame.

You are ready to initialize DTA. Call `dta.init()` in your script:

```
local dta = require "dta.dta"

local animation_groups = { ... }

function init(self, dt)
    dta.init(animation_groups, <tilemap_url>, <layers>)
    dta.toggle_message_passing(true, msg.url())
end
```

1. `animation_groups`: Table of tile animations explained above.
2. `tilemap_url`: URL to the animated tilemap.
3. `layers`: Table of hashed tilemap layer ids. For example: `{ hash("background"), hash("midground)", hash("foreground") }`.

If you wish to receive animation progress updates in your `on_message()` function, call `dta.toggle_message_passing()`. This feature is set to `false` by default. If set to true, also pass in a URL to the script that will receive DTA messages.

DTA will now begin animating your tilemap. Of course, only `trigger = false` tiles will show any activity. To animate a `trigger = true` tile, call `dta.animate()`.

## API: Properties

### dta.msg

Table for referencing messages posted to your script's `on_message()` function:

```
dta.msg = {
    animation_loop_complete = hash("animation_loop_complete"),
    animation_trigger_complete = hash("animation_trigger_complete")
}
```

1. `animation_loop_complete`: Posted when a `trigger = false` animation group completes its `sequence`. The `message.tile_id` field contains the tile id which begins this animation sequence.
2. `animation_trigger_complete`: Posted when a trigger tile completes its `sequence`. The `message.tile_id` field contains the tile id which begins this animation sequence. The `message.x`, `message.y`, and `message.layer` fields contain this tile's `x` position, `y` position, and hashed `layer` id on the tilemap.

## API: Functions

### dta.init(animation_groups, tilemap_url, tilemap_layers)

Initializes DTA. Must be called in order to begin animating tiles.

#### Parameters
1. `animation_groups`: Table defining your custom animation groups.
    1. `tile_id`: Tile id which begins your animation.
    2. `sequence`: Table defining this animation sequence.
    3. `trigger`: Indicates that this is a trigger animation rather than a loop animation.
    4. `frequency`: Animation speed measured in `sequence` frames per second.
2. `tilemap_url`: URL to the animated tilemap.
3. `layers`: Table of hashed tilemap layer ids.

The format for the `animation_groups` table is as follows:

```
local animation_groups = {
    [<tile_id>] = { sequence = { <tile_id_1>, <tile_id_2>, ... }, trigger = <boolean>, frequency = <value> },
    ...
}
```

---

### dta.animate(x, y, layer)

Activates a trigger animation. If the specified tile has not been assigned a trigger animation, then this function does nothing.

#### Parameters
1. `x`: X-coordinate of tile.
2. `y`: Y-coordinate of tile.
3. `layer`: Hashed tilemap layer id of tile.

If you do not specify a `layer`, then DTA will activate all trigger animations at `[x, y]` regardless of layer.

---

### dta.toggle_message_passing(flag, url)

Toggles DTA's ability to post animation update messages to your script's `on_message()` function.

#### Parameters
1. `flag`: Boolean indicating whether to post messages.
2. `url`: URL to the script that should receive messages.
