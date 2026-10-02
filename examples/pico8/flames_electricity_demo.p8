pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VFX8 flame and electric arc showcase for PICO-8.
#include ../../src/pico8/flames.lua
#include ../../src/pico8/electricity.lua

local quality_names={"low","medium","high"}
local effect_names={"flames","electricity"}
local quality=1
local selected=1
local variant=1
local tick=0
local flames,arcs=nil,nil
local function reset_effects()
 if flames then flames:clear() end
 if arcs then arcs:clear() end
 flames=vfx8_flames.new({quality=quality_names[quality]})
 arcs=vfx8_electricity.new({quality=quality_names[quality],seed=47})
end
function _init() reset_effects() end
function _update60()
 tick+=1
 if btnp(0) or btnp(1) then selected=selected%2+1; variant=1 end
 if btnp(2) then quality=quality%3+1; reset_effects() end
 if btnp(3) then quality=(quality+1)%3+1; reset_effects() end
 if btnp(4) then
  if selected==1 then
   if variant==1 then flames:emit_campfire(64,94,{count=12}) else flames:emit_jet(64,82,1,-0.12) end
  elseif variant==1 then arcs:strike(22,79,106,40,{life=0.18})
  else arcs:strike(22,79,106,40,{branches=0,jaggedness=3,life=0.18}) end
 end
 if btnp(5) then variant=variant%2+1 end
 if selected==1 and variant==1 then flames:emit_campfire(64,96) end
 flames:update(1/60); arcs:update(1/60)
end
function _draw()
 cls(1); rectfill(0,96,127,103,3); line(0,96,127,96,13)
 circfill(64,96,3,10); circfill(106,40,3,7)
 if selected==1 then flames:draw() else arcs:draw() end
 rectfill(0,0,127,26,0); print("VFX8 ELEMENTAL FX",3,3,7)
 print(effect_names[selected],3,13,12)
 local label=selected==1 and (variant==1 and "CAMPFIRE" or "FLAMETHROWER") or (variant==1 and "BRANCHED ARC" or "CLEAN BOLT")
 print(label.."  "..quality_names[quality],3,23,6)
 rectfill(0,108,127,127,0); print("LEFT/RIGHT: EFFECT  O: FIRE",3,114,7); print("X: VARIANT  UP/DOWN: QUALITY",3,122,7)
end
