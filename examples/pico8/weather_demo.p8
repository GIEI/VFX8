pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VFX8 rain and snow showcase for PICO-8.
#include ../../src/pico8/rain.lua
#include ../../src/pico8/snow.lua

local names={"RAIN","SNOW"}
local levels={"light","heavy","storm"}
local quality_names={"low","medium","high"}
local selected,quality,variant=1,1,1
local tick=0
local rain,snow=nil,nil

local function reset_effect()
 if rain then rain:clear() end
 if snow then snow:clear() end
 if selected==1 then
  local angles={0,0,0,16,16,16}
  local intensities={"light","heavy","storm","light","heavy","storm"}
  local mode=(variant-1)%6+1
  rain=vfx8_rain.new({quality=quality_names[quality],width=128,height=106,angle=angles[mode],intensity=intensities[mode],seed=11})
 else
  snow=vfx8_snow.new({quality=quality_names[quality],width=128,height=106,intensity=levels[variant],seed=17})
  snow:add_surface(12,70,36)
  snow:add_surface(78,88,38)
 end
end

function _init() reset_effect() end

function _update60()
 tick+=1
 if btnp(0) or btnp(1) then selected=selected%2+1; variant=1; reset_effect() end
 if btnp(2) then quality=quality%3+1; reset_effect() end
 if btnp(3) then quality=(quality+1)%3+1; reset_effect() end
 if btnp(4) or btnp(5) then
  local limit=selected==1 and 6 or 3
  variant=variant%limit+1
  reset_effect()
 end
 if rain then rain:update(1/60) end
 if snow then snow:update(1/60) end
end

function _draw()
 cls(1)
 rectfill(0,18,127,106,1)
 for x=0,128,16 do line(x,18,x,106,13) end
 for y=18,106,16 do line(0,y,127,y,13) end
 rectfill(12,70,47,73,5)
 rectfill(78,88,115,91,5)
 rectfill(0,100,127,106,3)
 if rain then rain:draw() end
 if snow then snow:draw() end
 rectfill(0,0,127,16,0)
 print("VFX8 WEATHER  "..names[selected],4,3,7)
 print(quality_names[quality].." / "..(selected==1 and ((variant>3 and "OBLIQUE / " or "VERTICAL / ")..levels[(variant-1)%3+1]) or levels[variant]),4,10,12)
 rectfill(0,110,127,127,0)
 print("LEFT/RIGHT: WEATHER",8,114,6)
 print("O/X: INTENSITY/DIRECTION",2,122,6)
end
