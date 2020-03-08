# Defold Tilemap Animator
Defold Tilemap Animator (DTA) allows for easy runtime tile animations in a [Defold game engine](https://defold.com) project. DTA was developed as a utility library for a separate game. Since Defold does not offer animated tiles, I decided to share this project with the community.

See the section titled [Example](#Example) to run an HTML5 version of DTA in your browser.

**Note**: This project will continue to see improvements and new features in the future. If you have feedback or suggestions, please let me know!

## Installation
To install DTA into your project, add one of the following to your game.project dependencies:
1. https://github.com/planksoftware/defold-tilemap-animator/archive/master.zip
2. URL of a [specific release](https://github.com/planksoftware/defold-tilemap-animator/releases)

Option 1 will keep you in line with the latest updates, however stability may be vary.  
Option 2 will allow you to stick with a stable and battle-tested version.

## Configuration
DTA works entirely out of a single Lua module, which may be referenced using the require path `dta.dta`.

### Step 1 - Hierarchy
To begin, you will need a script component which retains a lifespan equivalent to that of your tilemap. For example, the following collection hierarchy will suffice:

```
Collection           -- Some collection
    | Game_Object    -- Some game object
        | Tilemap    -- Tilemap you wish to animate
        | Script     -- Script to initialize DTA
```

### Step 2 - Script and Module
Import the DTA module into your script like so:  
`local dta = require "dta.dta"`

Defold's Tile Source asset allows us to create tile animations in the Editor. However, these built-in tile animations do not affect tiles in runtime--they're actually meant to be assigned to Sprite components. Therefore, creating animations in a Tile Source will not suffice for our needs.

Create a new Lua module. This is where you will create and assign animation groups to our tiles. Your Lua module should simply return a table in the following format:

```
return {
    [<start_tile>] = { end_tile = <end_tile>, playback = <playback>, step = <step> },
    ...
}
```

The table maintains a key of type `<start_tile>`, which may be found in your tilesource file by hovering over the first tile in your animation. For each key, a table must be provided. This table defines the animation's attributes, including:
1. `<end_tile>`: May be found in your tilesource file by hovering over the last tile in your animation.
2. `<playback>`: A string denoting one of the following animation styles:
    - `"loop_forward"`: Loops the animation forward.
    - `"loop_pingpong"`: Loops the animation in a forward-backward fashion.
    - `"loop_corolla"`: Loops the animation in a 1-2-1-3-1-4-etc fashion.
    - `"loop_backward"`: Loops the animation backward.
3. `<step>`: Seconds until the next frame is loaded.

**Note**: You may add as many animation groups as you desire. Ideally, you should add one animation group for each animation in your tilesource file, as you would using Defold's built-in Tile Source animation editor. Do not specify the same value for both `<start_tile>` and `<end_tile>`--the animation range should span at least two tiles.

Now that your animation groups are created, you need to initialize DTA to work with these groups. Navigate back to your script file. Provide the following three statements in your `init()` function:

```
-- Import animation groups from user-created Lua module.
local animation_groups = require "<animation_group_module>"

-- List tilemap layer ids.
local tilemap_layer_ids = { "<tilemap_layer_id_1>", ... }

-- Initialize and run DTA.
dta.init(animation_groups, "<tilemap_relative_url>", tilemap_layer_ids)
```

DTA only requires three pieces of information to begin animating a tilemap:
1. `<animation_groups>`: Table containing your custom animation groups.
2. `<tilemap_relative_url>`: Relative URL from your script to your tilemap.
3. `<tilemap_layer_ids>`: Table containing your tilemap's layer ids.

You're all done! After being initialized, DTA will immediately begin animating your tilemap.

## Example

A straightforward and lightweight [example project](https://github.com/planksoftware/defold-tilemap-animator/tree/master/example) is available if you need additional help with configuration. Since the master branch is frequently updating, you may notice unused content in the latest example project.

[Click here to run an HTML5 version of DTA in your browser.](http://planksoftware.com/html/defold_tilemap_automator.html)  
**Note**: The HTML5 version is not working outside of the Editor. This will be fixed soon.
