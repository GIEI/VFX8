local fx = {}
local particles, preset, shape = nil, "explosion", "point"
local presets = {"explosion", "sparks", "trail", "smoke", "dust"}
local shapes = {"point", "line", "area"}
fx[1] = {
  on_enter = function(quality) particles = vfx8_particles.new({quality = quality}) end,
  on_exit = function() if particles then particles:clear() end end,
  trigger = function(x, y)
    if not particles then return end
    if shape == "line" then particles:emit_line(preset, x - 20, y, x + 20, y, {spread = 2})
    elseif shape == "area" then particles:emit_area(preset, x - 16, y - 10, 32, 20)
    else particles:emit(preset, x, y) end
  end,
  update = function(dt) if particles then particles:update(dt) end end,
  draw = function() if particles then particles:draw() end end,
  cycle_preset = function()
    for i = 1, 5 do if presets[i] == preset then preset = presets[i % 5 + 1]; return end end
  end,
  cycle_shape = function()
    for i = 1, 3 do if shapes[i] == shape then shape = shapes[i % 3 + 1]; return end end
  end,
  label = function() return preset .. " / " .. shape end
}
local screen_fx = nil
fx[2] = {
  on_enter = function(quality) screen_fx = vfx8_screen_fx.new({capacity = quality == "high" and 12 or 6}) end,
  on_exit = function() if screen_fx then screen_fx:clear() end end,
  trigger = function(x, y)
    if not screen_fx then return end
    screen_fx:add_trauma(0.8)
    screen_fx:impulse(5, 2, 0.2)
    screen_fx:flash(0.08, 7)
    screen_fx:shockwave(x, y, 3, 12, 0.35)
  end,
  update = function(dt) if screen_fx then screen_fx:update(dt) end end,
  render_scene = function(draw_scene) if screen_fx then screen_fx:render(draw_scene) else draw_scene() end end,
  label = function() return "shake / flash / ring" end
}
local deform = nil
local rotate_enabled = false
fx[3] = {
  on_enter = function(quality) deform = vfx8_pixel_deform.new({quality = quality}); rotate_enabled = false end,
  on_exit = function() if deform then deform:clear() end end,
  trigger = function() if deform then deform:set_squash(1.35, 0.68, 0.3) end end,
  update = function(dt) if deform then deform:update(dt) end end,
  wave_offset = function(x, time) return deform and deform:wave_offset(x, time, 3.5, 48, 0.5) or 0 end,
  cycle_variant = function() rotate_enabled = not rotate_enabled end,
  rotation_enabled = function() return rotate_enabled end,
  prepare_rotation = function(time, cx, cy) if deform then deform:set_rotation(cx, cy, rotate_enabled and time * 0.35 or 0) end end,
  rotate_point = function(x, y) if deform and rotate_enabled then return deform:rotate_point(x, y) end return x, y end,
  rotation_bounds = function(left, top, right, bottom, margin) if deform then return deform:rotation_bounds(left, top, right, bottom, margin) end return left, top, right, bottom end,
  scale = function() if deform then return deform:scale() end return 1, 1 end,
  visible = function(x, y, amount) return not deform or deform:visible(x, y, amount) end,
  label = function() return rotate_enabled and "wave + grid rotation" or "wave only" end
}
local palette_fx, palette_mode = nil, 1
local palette_modes = {"color cycle", "night filter", "sepia filter", "mono filter", "glow pulse", "custom dusk map", "negative flash"}
local custom_dusk_map = {0, 1, 1, 2, 3, 4, 5, 6, 2, 3, 5, 4, 1, 2, 3, 6}
local demo_palette = {
  {0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},
  {0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},
  {1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},
  {0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}
}
fx[4] = {
  on_enter = function(quality)
    palette_fx = vfx8_palette_fx.new({quality = quality, color_count = 16})
    palette_fx:set_invert_palette(demo_palette)
    palette_mode = 1
    palette_fx:set_cycle(8, 11, 2)
  end,
  on_exit = function() if palette_fx then palette_fx:clear() end end,
  trigger = function() if palette_fx then if palette_mode == 7 then palette_fx:invert(0.18) else palette_fx:flash(8, 11, 7, 0.18) end end end,
  update = function(dt) if palette_fx then palette_fx:update(dt) end end,
  map_color = function(index) return palette_fx and palette_fx:map_color(index) or index end,
  cycle_variant = function()
    palette_mode = palette_mode % 7 + 1
    palette_fx:clear_cycle(); palette_fx:clear_filter(); palette_fx:clear_invert(); palette_fx:set_pulse(-1, -1, 0)
    if palette_mode == 1 then palette_fx:set_cycle(8, 11, 2)
    elseif palette_mode == 2 then palette_fx:set_filter("night")
    elseif palette_mode == 3 then palette_fx:set_filter("sepia")
    elseif palette_mode == 4 then palette_fx:set_filter("mono")
    elseif palette_mode == 5 then palette_fx:set_pulse(8, 10, 4)
    else palette_fx:set_filter_map(custom_dusk_map) end
  end,
  label = function() return palette_modes[palette_mode] end
}
local pseudo = nil
local pseudo_time = 0
local pseudo_curve = true
local pseudo_texture = nil
local function prepare_pseudo_texture()
  if pseudo_texture then return end
  pseudo_texture = userdata("u8", 64, 64)
  for y = 0, 63 do
    for x = 0, 63 do
      local color = (math.floor(x / 8) + math.floor(y / 8)) % 2 == 0 and 5 or 6
      if x % 8 == 0 or y % 8 == 0 then color = 13 end
      pseudo_texture:set(x, y, color)
    end
  end
end
local pseudo_colors = {sky = 1, ground = 3, road_a = 1, road_b = 13, edge = 11, stars = {7, 6, 5}}
fx[5] = {
  on_enter = function(q) prepare_pseudo_texture(); pseudo = vfx8_pseudo3d.new({quality = q, width = 240, height = 110, horizon = 34, lane_count = 3}); pseudo:set_mode7({source = pseudo_texture, width = 64, height = 64, scale = 0.6}); pseudo_time = 0; pseudo_curve = true end,
  on_exit = function() if pseudo then pseudo:clear() end end,
  trigger = function() if pseudo then pseudo:add_object(((pseudo.object_count % 3) - 1) * 0.48, 100, 11, 6) end end,
  update = function(dt) if pseudo then pseudo:update(dt); pseudo_time = pseudo_time + dt; pseudo:set_road(nil, nil, pseudo_curve and math.sin(pseudo_time * 0.25) * 0.55 or 0) end end,
  draw_scene = function() if pseudo then pseudo:draw(pseudo_colors) end end,
  cycle_variant = function() if pseudo then pseudo_curve = not pseudo_curve; pseudo:set_road(nil, pseudo.lane_count == 3 and 2 or 3, pseudo_curve and 0.65 or 0); pseudo:set_camera(pseudo.camera_x == 0 and 12 or 0, nil, pseudo.speed == 18 and 30 or 18) end end,
  label = function() return "mode 7 / stars / objects " .. (pseudo and pseudo.object_count or 0) end
}
local flames, flame_mode, flame_accumulator = nil, 1, 0
fx[6] = {
  on_enter = function(q) flames = vfx8_flames.new({quality = q}); flame_mode, flame_accumulator = 1, 0 end,
  on_exit = function() if flames then flames:clear() end end,
  trigger = function(x, y) if not flames then return end; if flame_mode == 2 then flames:emit_jet(x, y, 1, -0.06) else flames:emit_campfire(x, y + 25, {count = 12}) end end,
  update = function(dt)
    if not flames then return end
    if flame_mode == 1 then flame_accumulator = flame_accumulator + dt; while flame_accumulator >= 1 / 60 do flames:emit_campfire(120, 99); flame_accumulator = flame_accumulator - 1 / 60 end end
    flames:update(dt)
  end,
  draw = function() if flames then flames:draw() end end,
  cycle_variant = function() flame_mode = flame_mode % 2 + 1 end,
  stats = function() if flames then return flames:stats() end return 0, 0, 0 end,
  label = function() return flame_mode == 1 and "campfire" or "flamethrower jet" end
}
local electricity, electric_variant = nil, 1
fx[7] = {
  on_enter = function(q) electricity = vfx8_electricity.new({quality = q}); electric_variant = 1 end,
  on_exit = function() if electricity then electricity:clear() end end,
  trigger = function(x, y) if not electricity then return end; if electric_variant == 1 then electricity:strike(x, y, 212, 38) else electricity:strike(24, 38, x, y, {branches = 0, jaggedness = 3}) end end,
  update = function(dt) if electricity then electricity:update(dt) end end,
  draw = function() if electricity then electricity:draw() end end,
  cycle_variant = function() electric_variant = electric_variant % 2 + 1 end,
  stats = function() if electricity then return electricity:stats() end return 0, 0, 0 end,
  label = function() return electric_variant == 1 and "branched arc" or "clean bolt" end
}
