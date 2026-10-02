pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Standalone electric arc showcase for PICO-8.
#include ../../src/pico8/electricity.lua

local arcs=nil
local tick=0
local branch_mode=true
local strike_timer=0
local target_x=108
local target_y=34

local function strike()
 if branch_mode then
  arcs:strike(18,78,target_x,target_y,{life=0.16})
 else
  arcs:strike(18,78,target_x,target_y,{branches=0,jaggedness=3,life=0.16})
 end
end

function _init()
 arcs=vfx8_electricity.new({quality="medium",seed=47})
 strike()
end

function _update60()
 tick+=1
 strike_timer+=1/60
 target_x=104+sin(tick/23)*18
 target_y=38+sin(tick/37)*12
 if btnp(4) then strike() end
 if btnp(5) then branch_mode=not branch_mode; strike() end
 if strike_timer>=0.12 then strike_timer=0; strike() end
 arcs:update(1/60)
end

function _draw()
 cls(1)
 rectfill(0,96,127,127,0)
 line(0,96,127,96,5)
 circfill(18,78,3,12)
 circfill(target_x,target_y,3,10)
 arcs:draw()
 print("VFX8 ELECTRIC ARCS",3,3,7)
 print(branch_mode and "BRANCHED BOLT" or "CLEAN BOLT",3,13,12)
 print("O: STRIKE  X: STYLE",3,112,6)
end
