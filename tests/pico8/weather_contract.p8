pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Exercise bounded rain directions and snow deposits on native PICO-8.
#include ../../src/pico8/rain.lua
#include ../../src/pico8/snow.lua

local qualities={"low","medium","high"}
local passed=false

function _init()
 for q in all(qualities) do
  local rain=vfx8_rain.new({quality=q,width=128,height=96,intensity="storm",angle=16,seed=7})
  local count,capacity=rain:stats()
  assert(count==capacity and capacity>0)
  rain.x[1],rain.y[1],rain.speeds[1]=64,20,100
  rain:update(0.1)
  assert(rain.x[1]>64 and rain.y[1]>20,"oblique rain must move right and down")
  assert(rain:set_angle(90)==35)
  rain:set_intensity("light"); assert(rain:stats()<capacity)
  rain:set_intensity("heavy"); assert(rain:stats()>0)
  rain:update(1/60); rain:draw(); rain:clear()
  assert(rain:stats()==0)

  local snow=vfx8_snow.new({quality=q,width=128,height=96,speed=100,intensity="storm",settle_min=1,settle_max=1,seed=13})
  local ledge=snow:add_surface(0,6,128)
  assert(ledge and snow:set_surface(ledge,0,6,128))
  for i=1,snow.count do snow.x[i],snow.y[i]=20+i,0 end
  snow:update(0.1)
  local flakes,limit,deposits=snow:stats()
  assert(flakes==limit and deposits>0)
  snow:draw(); snow:clear_surfaces(); snow:clear()
  assert(snow:stats()==0)
 end
 passed=true
 printh("VFX8_WEATHER_PROFILE_CONTRACT,PASS")
end

function _update60() end
function _draw() cls(0); print(passed and "WEATHER CONTRACT PASSED" or "WEATHER CONTRACT FAILED",2,2,passed and 11 or 8) end
