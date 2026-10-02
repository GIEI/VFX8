pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include ../../src/pico8/screen_fx.lua

local fx = nil
local checks = 0

function _init()
  camera(11, 7)
  fx = vfx8_screen_fx.new({width = 128, height = 128})
  fx.flash_time, fx.flash_duration, fx.flash_color = 1, 1, 7
end

function _update60()
  fx:update(1 / 60)
end

function _draw()
  cls(0)
  fx.offset_x, fx.offset_y = 3, -2
  fx:render(function()
    assert(peek2(0x5f28) == 14 and peek2(0x5f2a) == 5,
      "render must compose shake with the incoming camera")
    camera(40, 30)
    checks += 1
  end)
  assert(peek2(0x5f28) == 11 and peek2(0x5f2a) == 7,
    "render must restore the incoming camera after the scene callback")
  if checks == 1 then
    assert(pget(127, 127) == 7, "screen overlays must use screen coordinates")
  end
  if checks == 10 then
    printh("PICO8_SCREEN_FX_CAMERA_CONTRACT_PASSED")
    checks += 1
  end
end
