-- VFX8 demo harness. Put both Lua files in a Picotron cartridge.
include("demo_extension.lua")
include("vfx8/particles.lua")

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

function _init()
  window{width = 240, height = 136, title = "VFX8 demo", resizeable = false}
  refresh_fx()
end

function _update()
  tick = (tick + 1) % 240
  if btnp(0) then selected = (selected + 3) % 5 + 1; refresh_fx() end
  if btnp(1) then selected = selected % 5 + 1; refresh_fx() end
  if btnp(2) then quality = quality % 3 + 1; refresh_fx() end
  if btnp(3) then quality = (quality + 1) % 3 + 1; refresh_fx() end
  if btnp(5) then fx_enabled = not fx_enabled; refresh_fx() end
  if keyp("z") and active and active.cycle_preset then active.cycle_preset() end
  if keyp("c") and active and active.cycle_shape then active.cycle_shape() end
  if btnp(4) and active and active.trigger then active.trigger(120, 70) end
  if active and active.update then active.update(1 / 60) end
end

local function draw_scene()
  cls(1)
  rectfill(0, 29, 239, 108, 2)
  for x = 0, 239, 16 do line(x, 29, x, 108, 13) end
  for y = 29, 108, 16 do line(0, y, 239, y, 13) end
  rectfill(0, 101, 239, 108, 3)
  local x = 28 + tick % 180
  rectfill(x - 4, 66, x + 4, 74, 8)
  line(114, 70, 126, 70, 7)
  line(120, 64, 120, 76, 7)
end

function _draw()
  if active and active.render_scene then
    active.render_scene(draw_scene)
  else
    draw_scene()
  end
  if active and active.draw then active.draw() end
  rectfill(0, 0, 239, 27, 0)
  print("VFX8 DEMO  " .. names[selected], 4, 3, 7)
  print("QUALITY: " .. qualities[quality] .. "   FX: " .. (fx_enabled and "ON" or "OFF"), 4, 14, 10)
  if active and active.label then print(active.label(), 4, 23, 11) end
  rectfill(0, 110, 239, 135, 0)
  local status = not fx_enabled and "FX DISABLED" or (active and "READY" or "NOT IMPLEMENTED")
  print(status, 4, 112, active and 11 or 6)
  print("LEFT/RIGHT: MODULE   UP/DOWN: QUALITY", 4, 120, 7)
  print("O: FIRE X: FX Z: PRESET C: SHAPE", 4, 128, 7)
end
