local root = os.getenv("VFX8_TEST_ROOT")
local module = dofile(root .. "/src/love2d/palette_fx.lua")
local palette = module.new({color_count = 4})
local source_map = {0, 2, 3, 1}

assert(palette:set_filter_map(source_map), "valid custom maps are accepted")
source_map[2] = 3
assert(palette:map_color(1) == 2 and palette:map_color(3) == 1,
  "custom entries are copied and map source indices to configured targets")
assert(not palette:set_filter_map({0, 2, 4, 1}), "out-of-range target indices are rejected")
assert(palette:map_color(1) == 2, "invalid maps leave the active mapping unchanged")
assert(not palette:set_filter("unknown"), "unknown presets are rejected")
assert(palette:map_color(1) == 2, "unknown presets leave the active mapping unchanged")
assert(palette:map_color(4) == 4, "indices outside the configured range pass through")

palette:clear_filter()
assert(palette:map_color(1) == 1, "clear_filter restores the identity mapping")
assert(palette:set_cycle(0, 3, 2), "valid color cycles are accepted")
assert(palette:map_color(0) == 0, "cycle phase starts immediately at the current time")
palette:update(0.1)
assert(palette:map_color(0) == 0, "cycle phase remains stable between integer steps")
for _ = 1, 4 do palette:update(0.1) end
assert(palette:map_color(0) == 1, "cached cycle phase advances during update")
palette:clear()
palette:set_pulse(2, 3, 1)
assert(palette:map_color(2) == 2, "pulse phase starts immediately at the current time")
for _ = 1, 5 do palette:update(0.1) end
assert(palette:map_color(2) == 3, "cached pulse phase advances during update")
palette:clear()
assert(palette:set_filter_map({0, 1.5, 2, 3}) == false, "fractional targets are rejected")
local rgb = {{0, 0, 0}, {1, 1, 1}, {1, 0, 0}, {0, 1, 1}}
assert(palette:set_invert_palette(rgb), "an RGB palette can build a nearest-color negative map")
assert(palette:invert(0.18), "inversion starts only after a map is configured")
assert(palette:map_color(0) == 1 and palette:map_color(1) == 0,
  "inversion remaps source colors to their nearest RGB complements")
assert(not palette:set_invert_palette({{0, 0, 0}}), "incomplete palettes are rejected")
assert(palette:map_color(0) == 1, "an invalid palette leaves the prior negative map intact")
palette:update(0.1)
assert(palette:map_color(0) == 1, "inversion stays active for its configured duration")
palette:update(0.1)
assert(palette:map_color(0) == 0, "inversion expires without changing the normal mapping")
assert(palette:invert(0.18))
palette:clear_invert()
assert(palette:map_color(0) == 0, "clear_invert disables the temporary negative map")
palette:clear()
assert(palette:map_color(1) == 1, "clear resets custom filter state")

print("LOVE palette runtime contract passed")
