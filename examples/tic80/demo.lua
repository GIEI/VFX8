-- VFX8 demo harness. Build this source before importing into TIC-80.
--#include "demo_extension.lua"
--#include "../../src/tic80/particles.lua"
--#include "../../src/tic80/screen_fx.lua"
--#include "../../src/tic80/pixel_deform.lua"
--#include "../../src/tic80/palette_fx.lua"
--#include "../../src/tic80/pseudo3d.lua"
--#include "../../src/tic80/flames.lua"
--#include "../../src/tic80/electricity.lua"

local names = {"particles", "screen fx", "pixel warp", "palette fx", "pseudo 3d", "flames", "electricity"}
local qualities = {"low", "medium", "high"}
local selected, quality = 1, 1
local fx_enabled, active = true, nil
local tick = 0
local wave_time = 0
local wave_samples = {}

local function scene_color(index)
  if active and active.map_color then return active.map_color(index) end
  return index
end

local function refresh_fx()
  if active and active.on_exit then active.on_exit() end
  active = nil
  if fx_enabled then
    active = fx[selected]
    if active and active.on_enter then active.on_enter(qualities[quality]) end
  end
end

refresh_fx()

local function draw_scene()
  local x = 28 + tick % 180
  if active and active.prepare_rotation then active.prepare_rotation(wave_time, x, 70) end
  local rotating = active and active.rotation_enabled and active.rotation_enabled()
  local min_x, min_y, max_x, max_y = 0, 29, 240, 109
  if rotating then min_x, min_y, max_x, max_y = active.rotation_bounds(0, 29, 240, 109, 8) end
  local grid_x, grid_y = math.floor(min_x / 16) * 16, 29 + math.floor((min_y - 29) / 16) * 16
  local wave_x = math.floor(min_x / 4) * 4
  local wave_count = math.floor((max_x - wave_x + 3) / 4)
  cls(scene_color(1))
  rect(0, 29, 240, 80, scene_color(2))
  clip(0, 29, 240, 80)
  for gx = grid_x, max_x, 16 do
    local x1, y1, x2, y2 = gx, min_y, gx, max_y
    if rotating then x1, y1 = active.rotate_point(x1, y1); x2, y2 = active.rotate_point(x2, y2) end
    line(x1, y1, x2, y2, scene_color(13))
  end
  if active and active.wave_offset then
    for i = 0, wave_count do wave_samples[i] = active.wave_offset(wave_x + i * 4, wave_time) end
  end
  for y = grid_y, max_y, 16 do
    if active and active.wave_offset then
      for i = 0, wave_count - 1 do
        local x1, y1 = wave_x + i * 4, y + wave_samples[i]
        local x2, y2 = x1 + 4, y + wave_samples[i + 1]
        if rotating then x1, y1 = active.rotate_point(x1, y1); x2, y2 = active.rotate_point(x2, y2) end
        line(x1, y1, x2, y2, scene_color(13))
      end
    else
      local x1, y1, x2, y2 = min_x, y, max_x, y
      if rotating then x1, y1 = active.rotate_point(x1, y1); x2, y2 = active.rotate_point(x2, y2) end
      line(x1, y1, x2, y2, scene_color(13))
    end
  end
  clip()
  rect(0, 101, 240, 8, scene_color(3))
  if active and active.scale then
    local sx, sy = active.scale()
    local w, h = math.floor(9 * sx), math.floor(9 * sy)
    local px, py = x - 4 + (9 - w) / 2, 66 + (9 - h) / 2
    for iy = 0, h - 1 do for ix = 0, w - 1 do
      if active.visible(px + ix, py + iy, (tick % 120) / 120) then
        pix(px + ix, py + iy, scene_color(8))
      end
    end end
  else rect(x - 4, 66, 9, 9, scene_color(8)) end
  local x1, y1, x2, y2 = 114, 70, 126, 70
  line(x1, y1, x2, y2, scene_color(7))
  x1, y1, x2, y2 = 120, 64, 120, 76
  line(x1, y1, x2, y2, scene_color(7))
end

function TIC()
  tick = (tick + 1) % 240
  wave_time = wave_time + 1 / 60
  -- TIC-80: up/down=0/1, left/right=2/3, A/B=4/5.
  if btnp(2) then selected = (selected + 5) % 7 + 1; refresh_fx() end
  if btnp(3) then selected = selected % 7 + 1; refresh_fx() end
  if btnp(0) then quality = quality % 3 + 1; refresh_fx() end
  if btnp(1) then quality = (quality + 1) % 3 + 1; refresh_fx() end
  if btnp(5) then fx_enabled = not fx_enabled; refresh_fx() end
  if btnp(6) and active then
    if active.cycle_variant then active.cycle_variant()
    elseif active.cycle_preset then active.cycle_preset() end
  end
  if btnp(7) and active and active.cycle_shape then active.cycle_shape() end
  if btnp(4) and active and active.trigger then active.trigger(120, 70) end
  if active and active.update then active.update(1 / 60) end

  if active and active.draw_scene then
    active.draw_scene()
  elseif active and active.render_scene then
    active.render_scene(draw_scene)
  else
    draw_scene()
  end
  if active and active.draw then active.draw() end
  rect(0, 0, 240, 28, 0)
  print("VFX8 DEMO  " .. names[selected], 4, 3, 7)
  print("QUALITY: " .. qualities[quality] .. "   FX: " .. (fx_enabled and "ON" or "OFF"), 4, 14, 10)
  if active and active.label then print(active.label(), 4, 23, 11) end
  rect(0, 110, 240, 26, 0)
  local status = not fx_enabled and "FX DISABLED" or (active and "READY" or "NOT IMPLEMENTED")
  print(status, 4, 112, active and 11 or 6)
  print("LEFT/RIGHT: MODULE   UP/DOWN: QUALITY", 4, 120, 7)
  print("A: FIRE B: FX X: VARIANT/PRESET Y: SHAPE", 4, 128, 7)
end
