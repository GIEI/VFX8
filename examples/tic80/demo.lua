-- VFX8 demo harness. Build this source before importing into TIC-80.
--#include "demo_extension.lua"

local names = {"particles", "screen fx", "pixel warp", "palette fx", "pseudo 3d"}
local qualities = {"low", "medium", "high"}
local selected, quality = 1, 1
local fx_enabled, active = true, nil
local tick = 0

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
  cls(1)
  rect(0, 29, 240, 80, 2)
  for x = 0, 239, 16 do line(x, 29, x, 108, 13) end
  for y = 29, 108, 16 do line(0, y, 239, y, 13) end
  rect(0, 101, 240, 8, 3)
  local x = 28 + tick % 180
  rect(x - 4, 66, 9, 9, 8)
  line(114, 70, 126, 70, 7)
  line(120, 64, 120, 76, 7)
end

function TIC()
  tick = (tick + 1) % 240
  -- TIC-80: up/down=0/1, left/right=2/3, A/B=4/5.
  if btnp(2) then selected = (selected + 3) % 5 + 1; refresh_fx() end
  if btnp(3) then selected = selected % 5 + 1; refresh_fx() end
  if btnp(0) then quality = quality % 3 + 1; refresh_fx() end
  if btnp(1) then quality = (quality + 1) % 3 + 1; refresh_fx() end
  if btnp(5) then fx_enabled = not fx_enabled; refresh_fx() end
  if btnp(4) and active and active.trigger then active.trigger(120, 70) end
  if active and active.update then active.update(1 / 60) end

  if active and active.render_scene then
    active.render_scene(draw_scene)
  else
    draw_scene()
  end
  if active and active.draw then active.draw() end
  rect(0, 0, 240, 28, 0)
  print("VFX8 DEMO  " .. names[selected], 4, 3, 7)
  print("QUALITY: " .. qualities[quality] .. "   FX: " .. (fx_enabled and "ON" or "OFF"), 4, 14, 10)
  rect(0, 110, 240, 26, 0)
  local status = not fx_enabled and "FX DISABLED" or (active and "READY" or "NOT IMPLEMENTED")
  print(status, 4, 112, active and 11 or 6)
  print("LEFT/RIGHT: MODULE   UP/DOWN: QUALITY", 4, 120, 7)
  print("A: TRIGGER   B: FX ON/OFF", 4, 128, 7)
end
