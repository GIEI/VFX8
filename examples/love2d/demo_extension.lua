local particle_module = require("vfx8.particles")
local screen_module = require("vfx8.screen_fx")
local deform_module = require("vfx8.pixel_deform")
local palette_module = require("vfx8.palette_fx")
local pseudo3d_module = require("vfx8.pseudo3d")
local flames_module = require("vfx8.flames")
local electricity_module = require("vfx8.electricity")
local fx = {}
local particles, preset, shape = nil, "explosion", "point"
local presets = {"explosion", "sparks", "trail", "smoke", "dust"}
local shapes = {"point", "line", "area"}
fx[1] = {
  on_enter = function(quality) particles = particle_module.new({quality = quality}) end,
  on_exit = function() if particles then particles:clear() end end,
  trigger = function(x, y)
    if not particles then return end
    if shape == "line" then particles:emit_line(preset, x - 20, y, x + 20, y, {spread = 2})
    elseif shape == "area" then particles:emit_area(preset, x - 16, y - 10, 32, 20)
    else particles:emit(preset, x, y) end
  end,
  update = function(dt) if particles then particles:update(dt) end end,
  draw = function() if particles then particles:draw() end end,
  stats = function()
    if particles then return particles:stats() end
    return 0, 0, 0
  end,
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
  on_enter = function(quality)
    screen_fx = screen_module.new({capacity = quality == "high" and 16 or 8})
  end,
  on_exit = function() if screen_fx then screen_fx:clear() end end,
  trigger = function(x, y)
    if not screen_fx then return end
    screen_fx:add_trauma(0.8)
    screen_fx:impulse(8, 3, 0.2)
    screen_fx:flash(0.08, {1, 1, 1})
    screen_fx:shockwave(x, y, 3, 16, 0.35)
  end,
  update = function(dt) if screen_fx then screen_fx:update(dt) end end,
  render_scene = function(draw_scene) if screen_fx then screen_fx:render(draw_scene) else draw_scene() end end,
  label = function() return "shake / flash / ring" end
}
local deform = nil
local rotate_screen = false
fx[3] = {
  on_enter = function(quality) rotate_screen = false; deform = deform_module.new({quality = quality}) end,
  on_exit = function() if deform then deform:clear() end end,
  trigger = function() if deform then deform:set_squash(1.35, 0.68, 0.3) end end,
  update = function(dt) if deform then deform:update(dt) end end,
  wave_offset = function(x, time) return deform and deform:wave_offset(x, time, 3.5, 48, 0.5) or 0 end,
  cycle_variant = function() rotate_screen = not rotate_screen end,
  rotation_enabled = function() return rotate_screen end,
  prepare_rotation = function(time, cx, cy) if deform then deform:set_rotation(cx, cy, rotate_screen and time * 0.35 or 0) end end,
  rotate_point = function(x, y) if deform and rotate_screen then return deform:rotate_point(x, y) end return x, y end,
  rotation_bounds = function(left, top, right, bottom, margin) if deform then return deform:rotation_bounds(left, top, right, bottom, margin) end return left, top, right, bottom end,
  scale = function() if deform then return deform:scale() end return 1, 1 end,
  visible = function(x, y, amount) return not deform or deform:visible(x, y, amount) end,
  label = function() return rotate_screen and "wave + grid rotation" or "wave only" end
}
local palette_fx, palette_mode = nil, 1
local palette_modes = {"color cycle", "night filter", "sepia filter", "mono filter", "glow pulse", "custom dusk map", "negative flash"}
local custom_dusk_map = {0, 1, 1, 2, 3, 4, 5, 6, 2, 3, 5, 4, 1, 2, 3, 6}
local demo_palette = {
  {0.05, 0.07, 0.14}, {0.11, 0.17, 0.27}, {0.49, 0.15, 0.32}, {0.12, 0.46, 0.34},
  {0.67, 0.32, 0.21}, {0.36, 0.37, 0.42}, {0.76, 0.77, 0.80}, {0.95, 0.93, 0.78},
  {0.95, 0.35, 0.27}, {0.98, 0.58, 0.19}, {0.98, 0.82, 0.25}, {0.88, 0.35, 0.54},
  {0.50, 0.85, 0.95}, {0.20, 0.27, 0.36}, {0.55, 0.57, 0.63}, {0.95, 0.74, 0.58}
}
fx[4] = {
  on_enter = function(quality)
    palette_fx = palette_module.new({quality = quality, color_count = 16})
    palette_fx:set_invert_palette(demo_palette)
    palette_mode = 1
    palette_fx:set_cycle(8, 11, 2)
  end,
  on_exit = function() if palette_fx then palette_fx:clear() end end,
  trigger = function() if palette_fx then if palette_mode == 7 then palette_fx:invert(0.18) else palette_fx:flash(8, 11, 6, 0.18) end end end,
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
local pseudo_colors = {sky = {0.025, 0.035, 0.09}, ground = {0.04, 0.20, 0.16}, road_a = {0.07, 0.12, 0.22}, road_b = {0.09, 0.17, 0.29}, edge = {0.28, 0.78, 0.68}}
fx[5] = {
  on_enter = function(quality)
    pseudo = pseudo3d_module.new({quality = quality, width = 240, height = 110, horizon = 32, lane_count = 3})
    if not pseudo_texture then
      local image_data = love.image.newImageData(64, 64)
      for y = 0, 63 do
        for x = 0, 63 do
          local tile = math.floor(x / 8) + math.floor(y / 8)
          local stripe = math.floor((x + y * 2) / 8) % 2
          local shade = (tile % 2 == 0 and 0.16 or 0.2) + stripe * 0.045
          image_data:setPixel(x, y, shade, shade * 1.45, shade * 1.8, 1)
        end
      end
      pseudo_texture = love.graphics.newImage(image_data)
      pseudo_texture:setFilter("nearest", "nearest")
    end
    pseudo:set_mode7(pseudo_texture, {scale = 0.09})
    pseudo_time = 0
    pseudo_curve = true
  end,
  on_exit = function() if pseudo then pseudo:clear() end end,
  trigger = function()
    if pseudo then pseudo:add_object(((pseudo.object_count % 3) - 1) * 0.48, 100, 10, 5) end
  end,
  update = function(dt)
    if pseudo then
      pseudo:update(dt)
      pseudo_time = pseudo_time + dt
      pseudo:set_road(nil, nil, pseudo_curve and math.sin(pseudo_time * 0.25) * 0.55 or 0)
    end
  end,
  draw_scene = function() if pseudo then pseudo:draw(pseudo_colors) end end,
  cycle_variant = function()
    if pseudo then
      local lanes = pseudo.lane_count == 3 and 2 or 3
      pseudo_curve = not pseudo_curve
      pseudo:set_road(nil, lanes, pseudo_curve and 0.65 or 0)
      pseudo:set_camera(pseudo.camera_x == 0 and 12 or 0, nil, pseudo.speed == 18 and 30 or 18)
    end
  end,
  label = function() return "mode 7 / starfield / objects " .. (pseudo and pseudo.object_count or 0) end
}
local flames, flame_mode, flame_accumulator = nil, 1, 0
local flame_modes = {"campfire", "flamethrower jet"}
fx[6] = {
  on_enter = function(quality)
    flames = flames_module.new({quality = quality})
    flame_mode, flame_accumulator = 1, 0
  end,
  on_exit = function() if flames then flames:clear() end end,
  trigger = function(x, y)
    if not flames then return end
    if flame_mode == 2 then flames:emit_jet(x, y, 1, -0.06)
    else flames:emit_campfire(x, y + 25, {count = 12}) end
  end,
  update = function(dt)
    if not flames then return end
    if flame_mode == 1 then
      flame_accumulator = flame_accumulator + dt
      while flame_accumulator >= 1 / 60 do
        flames:emit_campfire(120, 99)
        flame_accumulator = flame_accumulator - 1 / 60
      end
    end
    flames:update(dt)
  end,
  draw = function() if flames then flames:draw() end end,
  cycle_variant = function() flame_mode = flame_mode % 2 + 1 end,
  stats = function() if flames then return flames:stats() end return 0, 0, 0 end,
  label = function() return flame_modes[flame_mode] end
}
local electricity, electric_variant = nil, 1
fx[7] = {
  on_enter = function(quality) electricity = electricity_module.new({quality = quality}); electric_variant = 1 end,
  on_exit = function() if electricity then electricity:clear() end end,
  trigger = function(x, y)
    if not electricity then return end
    if electric_variant == 1 then electricity:strike(x, y, 208, 42)
    else electricity:strike(24, 42, x, y, {branches = 0, jaggedness = 3}) end
  end,
  update = function(dt) if electricity then electricity:update(dt) end end,
  draw = function() if electricity then electricity:draw() end end,
  cycle_variant = function() electric_variant = electric_variant % 2 + 1 end,
  stats = function() if electricity then return electricity:stats() end return 0, 0, 0 end,
  label = function() return electric_variant == 1 and "branched arc" or "clean bolt" end
}
return fx
