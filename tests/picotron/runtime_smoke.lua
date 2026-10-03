-- Stage the Picotron modules under /desktop/vfx8-picotron-runtime/vfx8 first.
-- Run with Picotron: picotron.exe -home <temporary-home> -x runtime_smoke.lua
window{width = 240, height = 136, title = "VFX8 Picotron profile smoke"}

include("/desktop/vfx8-picotron-runtime/vfx8/particles.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/screen_fx.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/pixel_deform.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/palette_fx.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/pseudo3d.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/flames.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/electricity.lua")
include("/desktop/vfx8-picotron-runtime/demo_extension.lua")

assert(type(fx) == "table", "demo extension did not expose its effect adapter")
for index = 1, 7 do
  assert(type(fx[index]) == "table", "demo extension is missing effect adapter " .. index)
end

local dt = 1 / 60
local qualities = {"low", "medium", "high"}
local presets = {"explosion", "sparks", "trail", "smoke", "dust"}
local filters = {"night", "sepia", "mono"}
local colors = {
  {0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},
  {0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},
  {1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},
  {0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}
}
local custom_map = {0,1,1,2,3,4,5,6,2,3,5,4,1,2,3,6}
local scene_colors = {sky=1, ground=3, road_a=1, road_b=13, edge=11, stars={7,6,5}}
local texture = userdata("u8", 64, 64)
for y = 0, 63 do
  for x = 0, 63 do
    texture:set(x, y, (flr(x / 8) + flr(y / 8)) % 2 == 0 and 5 or 6)
  end
end

for quality in all(qualities) do
  local particles = vfx8_particles.new({quality = quality, seed = 7})
  assert(particles:emit("unknown", 120, 68) == 0)
  for preset in all(presets) do
    assert(particles:emit(preset, 120, 68) > 0)
    particles:update(dt)
    particles:draw()
    particles:clear()
    assert(particles:emit_line(preset, 90, 60, 150, 60) > 0)
    particles:update(dt)
    particles:draw()
    particles:clear()
    assert(particles:emit_area(preset, 100, 54, 40, 24) > 0)
    particles:update(dt)
    particles:draw()
    particles:clear()
  end

  local screen_fx = vfx8_screen_fx.new({width = 240, height = 136, seed = 9})
  screen_fx:add_trauma(0.8)
  local trauma_only = vfx8_screen_fx.new({width = 240, height = 136, seed = 9})
  trauma_only:add_trauma(0.8)
  trauma_only:update(dt)
  local trauma_x, trauma_y = trauma_only:get_shake_offset()
  assert(trauma_x ~= 0 or trauma_y ~= 0, "add_trauma must start a visible shake envelope")
  screen_fx:impulse(5, 2, 0.2)
  screen_fx:flash(0.08, 7)
  assert(screen_fx:shockwave(120, 68, 3, 12, 0.35))
  screen_fx:update(dt)
  screen_fx:render(function()
    rectfill(0, 0, 239, 135, 1)
    particles:draw()
  end)
  screen_fx:clear()

  local deform = vfx8_pixel_deform.new({quality = quality})
  for _, amount in ipairs({0.25, 0.5, 0.75}) do
    deform:set_rotation(120, 68, amount)
    deform:set_squash(1 + amount, 1 - amount / 2, 0.2)
    deform:update(dt)
    assert(type(deform:wave_offset(16, amount)) == "number")
    local x, y = deform:rotate_point(128, 68)
    assert(type(x) == "number" and type(y) == "number")
    local left, top, right, bottom = deform:rotation_bounds(0, 0, 240, 136, 4)
    assert(left < right and top < bottom)
    assert(type(deform:visible(20, 20, amount)) == "boolean")
    assert(type(deform:visible(20, 20, amount, "checker")) == "boolean")
    assert(type(deform:visible(20, 20, amount, "spiral")) == "boolean")
  end

  local palette = vfx8_palette_fx.new({quality = quality, color_count = 16})
  assert(not palette:set_filter("unknown"))
  assert(palette:set_invert_palette(colors))
  assert(palette:set_cycle(8, 11, 2))
  for filter in all(filters) do
    assert(palette:set_filter(filter))
    palette:update(dt)
    assert(type(palette:map_color(8)) == "number")
  end
  palette:clear_filter()
  assert(palette:set_filter_map(custom_map))
  palette:set_pulse(8, 10, 4)
  palette:flash(8, 11, 7, 0.18)
  assert(palette:invert(0.18))
  palette:update(dt)
  assert(type(palette:map_color(8)) == "number")
  palette:clear()

  local pseudo3d = vfx8_pseudo3d.new({quality = quality, width = 240, height = 110, horizon = 34, lane_count = 3})
  assert(not pseudo3d:set_mode7("invalid"))
  pseudo3d:set_camera(12, 42, 30, 0.2)
  pseudo3d:set_road(96, 3, -0.2)
  assert(pseudo3d:add_object(0, 60, 8, 4))
  pseudo3d:update(dt)
  assert(type(pseudo3d:project(0, 60, 4)) == "number")
  assert(pseudo3d:set_mode7({source = texture, width = 64, height = 64, scale = 0.6}))
  pseudo3d:draw(scene_colors)
  pseudo3d:set_mode7(false)
  pseudo3d:draw(scene_colors)
  pseudo3d:clear()

  local flames = vfx8_flames.new({quality = quality, seed = 11})
  assert(flames:emit_jet(80, 72, 0, 0, {count = 4}) == 0)
  assert(flames:emit_campfire(120, 100, {count = 4}) > 0)
  flames:update(dt)
  flames:draw()
  flames:clear()
  assert(flames:emit_jet(80, 72, 1, -0.1, {count = 4}) > 0)
  flames:update(dt)
  flames:draw()
  flames:clear()

  local electricity = vfx8_electricity.new({quality = quality, seed = 13})
  assert(electricity:strike(40, 40, 40, 40, {branches = 0}) == 0)
  assert(electricity:strike(40, 40, 200, 80) > 0)
  electricity:update(dt)
  electricity:draw()
  electricity:clear()
  assert(electricity:strike(40, 40, 200, 80, {branches = 0, jaggedness = 3}) > 0)
  electricity:update(dt)
  electricity:draw()
  electricity:clear()
  store("/appdata/vfx8_picotron_" .. quality .. "_profile_smoke.pod", {passed = true, profile = quality})
  printh("VFX8 Picotron " .. quality .. " profile smoke passed")
end

store("/appdata/vfx8_picotron_runtime_smoke.pod", {passed = true, profiles = 3, version = 2})
printh("VFX8 Picotron runtime smoke passed: all effects, variants, and profiles")
exit()
