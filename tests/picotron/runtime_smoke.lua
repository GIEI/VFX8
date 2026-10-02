-- Stage the Picotron modules under /desktop/vfx8-picotron-runtime/vfx8 first.
-- Run with Picotron: picotron.exe -home <temporary-home> -x runtime_smoke.lua
window{width = 240, height = 136, title = "VFX8 Picotron runtime smoke"}

include("/desktop/vfx8-picotron-runtime/vfx8/particles.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/screen_fx.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/pixel_deform.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/palette_fx.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/pseudo3d.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/flames.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/electricity.lua")

local dt = 1 / 60

local particles = vfx8_particles.new({quality = "low", seed = 7})
assert(particles:emit("explosion", 120, 68, {count = 8}) > 0)
particles:update(dt)
particles:draw()

local screen_fx = vfx8_screen_fx.new({width = 240, height = 136, seed = 9})
screen_fx:impulse(3, -1, 0.12)
assert(screen_fx:shockwave(120, 68, 2, 8, 0.2))
screen_fx:update(dt)
local rendered = false
screen_fx:render(function()
  rendered = true
  rectfill(0, 0, 239, 135, 1)
end)
assert(rendered)

local deform = vfx8_pixel_deform.new({quality = "low"})
deform:set_rotation(120, 68, 0.1)
deform:set_squash(1.2, 0.8, 0.2)
deform:update(dt)
assert(deform:wave_offset(16, 0.5) == deform:wave_offset(16, 0.5))
local scale_x, scale_y = deform:scale()
assert(scale_x > 0 and scale_y > 0)

local palette = vfx8_palette_fx.new({color_count = 64})
assert(palette:set_cycle(1, 4, 2))
assert(palette:set_filter("night"))
palette:flash(2, 5, 7, 0.1)
palette:update(dt)
assert(type(palette:map_color(3)) == "number")

local pseudo3d = vfx8_pseudo3d.new({quality = "low"})
pseudo3d:set_camera(2, 48, 18, 0.2)
assert(pseudo3d:add_object(0, 60, 8, 4))
pseudo3d:update(dt)
local projected_x, projected_y = pseudo3d:project(0, 60, 4)
assert(type(projected_x) == "number" and type(projected_y) == "number")
local texture = userdata("u8", 64, 64)
for y = 0, 63 do
  for x = 0, 63 do
    texture:set(x, y, (x + y) % 16)
  end
end
assert(pseudo3d:set_mode7({source = texture, width = 64, height = 64, scale = 0.6}))
pseudo3d:draw()
pseudo3d:set_mode7(false)
pseudo3d:draw()

local flames = vfx8_flames.new({quality = "low", seed = 11})
assert(flames:emit_campfire(120, 100, {count = 4}) > 0)
flames:update(dt)
flames:draw()

local electricity = vfx8_electricity.new({quality = "low", seed = 13})
assert(electricity:strike(40, 40, 200, 80) > 0)
electricity:update(dt)
electricity:draw()

store("/appdata/vfx8_picotron_runtime_smoke.pod", {passed = true, version = 1})
printh("VFX8 Picotron runtime smoke passed")
exit()
