pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include ../../src/pico8/palette_fx.lua

local fx = nil
local frame = 0
local samples = 0
local cpu_sum = 0
local cpu_min = 1
local cpu_max = 0
local checksum = 0

function _init()
  fx = vfx8_palette_fx.new({quality = "high", color_count = 16})
  fx:set_cycle(8, 11, 2)
  fx:set_filter("night")
  fx:set_pulse(8, 10, 4)
  fx:set_invert_palette({
    {0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},
    {0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},
    {1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},
    {0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}
  })
  fx:invert(1000)
  fx:flash(8, 11, 7, 1000)
end

function _update60()
  fx:update(1 / 60)
  frame += 1
end

function _draw()
  cls(0)
  for i = 0, 127 do checksum += fx:map_color((i + frame) % 16) end
  print("PALETTE MAP " .. samples .. "/600", 2, 2, 7)
  if frame > 3 then
    local cpu = stat(1)
    samples += 1
    cpu_sum += cpu
    cpu_min = min(cpu_min, cpu)
    cpu_max = max(cpu_max, cpu)
  end
  if samples == 600 then
    printh("PICO8_PALETTE_MAP,128,600," .. cpu_sum / samples .. "," .. cpu_min .. "," .. cpu_max .. "," .. checksum)
    samples += 1
  end
end
