local root = os.getenv("VFX8_TEST_ROOT")
local module = dofile(root .. "/src/love2d/pixel_deform.lua")

local defaults = module.new()
local old_wave = defaults:wave_offset(8, 0)
assert(math.abs(old_wave) < 0.00001, "the default phase and amplitude preserve the original wave result")
local sx, sy = defaults:scale()
assert(sx == 1 and sy == 1, "squash defaults remain neutral")
assert(defaults:visible(2, 3, 0, "ordered"), "zero dissolve amount keeps every pixel")
assert(not defaults:visible(2, 3, 1, "ordered"), "full dissolve removes every pixel")

local deform = module.new({amplitude = 3, wavelength = 20, speed = 0.5, wave_phase = 0, axis = "x", direction = 1})
local offset, axis = deform:wave_offset(5, 0)
assert(math.abs(offset - 3) < 0.00001 and axis == "x", "wave settings control amplitude, wavelength, and axis")
assert(deform:set_wave({direction = -1, phase = 0}))
local reversed = deform:wave_offset(5, 0)
assert(math.abs(reversed + 3) < 0.00001, "wave direction and phase are configurable")

deform:set_squash(1.4, 0.6, 0.2, 0, "linear", 0.25, 1)
deform:update(0.1)
local scale_x, scale_y, anchor_x, anchor_y = deform:scale()
assert(math.abs(scale_x - 1.2) < 0.00001 and math.abs(scale_y - 0.8) < 0.00001)
assert(anchor_x == 0.25 and anchor_y == 1, "squash returns its configurable normalized anchor")

local matrix = {}
for i = 1, 16 do matrix[i] = i - 1 end
assert(deform:set_dissolve(0.5, "ordered", "in", 0, matrix))
assert(deform:visible(3, 3, 0.5), "custom dissolve matrix is honored")
assert(not deform:set_dissolve(0.5, "unknown"), "invalid dissolve variants are rejected")
assert(not deform:set_dissolve(0.5, "ordered", "in", 0, {0}), "incomplete dissolve matrices are rejected")

local warp = module.new({warp_amplitude = 0, scroll_speed_x = 0, scroll_speed_y = 0, center_x = 10, center_y = 20, rotation = 0, sample_step = 2})
local x, y = warp:warp_point(12, 23, 0)
assert(x == 12 and y == 23 and warp:warp_step() == 2, "warp helper preserves identity coordinates and exposes its sample step")
local moved_x, moved_y = warp:warp_point(12, 23, 1, {amplitude = 0, scroll_speed_x = 3, scroll_speed_y = -2})
assert(moved_x == 15 and moved_y == 21, "texture sample coordinates honor independent scroll speeds")

print("LOVE pixel deformation runtime contract passed")
